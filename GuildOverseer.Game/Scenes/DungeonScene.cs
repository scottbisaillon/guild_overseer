namespace GuildOverseer.Scenes;

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using GuildOverseer.Gameplay;
using GuildOverseer.Gameplay.Systems;
using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Library.Extensions;
using GuildOverseer.Library.Graphics;
using GuildOverseer.Library.Scenes;
using GuildOverseer.Services;
using Gum.Forms.Controls;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameGum;

public class DungeonScene : Scene
{
    public delegate Entity UnitFactory(string id, Vector2 pos);

    private enum Outcome
    {
        InProgress,
        Draw,
        AlliesCleared,
        EnemiesCleared,
    }

    #region Service
    private ActiveDungeonService _activeDungeonService = default!;
    private CombatEvents _combat = default!;
    #endregion

    #region Assets
    private Texture2D _pixel = default!;
    private Texture2D _circle = default!;
    private SpriteFont _font = default!;
    #endregion

    #region State
    private readonly EntityStore _world = new();
    private SystemRoot _root = default!;
    private Outcome _outcome = Outcome.InProgress;
    private readonly Random _random = new();
    #endregion

    #region Lifecycle
    public override void LoadContent()
    {
        GumService.Default.Root.Children.Clear();

        var unitRegistry = Core.Instance.Services.GetService<UnitRegistry>();
        var enemyRegistry = Core.Instance.Services.GetService<EnemyRegistry>();
        var skillRegistry = Core.Instance.Services.GetService<SkillRegistry>();

        _activeDungeonService = Core.Instance.Services.GetService<ActiveDungeonService>();
        _combat = Core.Instance.Services.GetService<CombatEvents>();

        _combat.DamageDealt += HandleDamageDealt;

        _root = new SystemRoot(_world)
        {
            new TargetSystem(),
            new MoveSystem(),
            new CooldownSystem(),
            new AttackSystem(_combat),
            new DeathSystem(),
            new DamageNumberSystem(),
        };

        _pixel = ShapeTexture.CreatePixel(Core.GraphicsDevice);
        _circle = ShapeTexture.CreateCircle(Core.GraphicsDevice, 48);
        _font = _content.Load<SpriteFont>("fonts/default");

        var party = _activeDungeonService.Party.Select(unitRegistry.Get).ToList();
        foreach (var (member, pos) in party.Zip(ColumnPositions(party.Count, x: 250)))
        {
            _world.CreateEntity(
                new Position2D { Value = pos },
                new Sprite
                {
                    Texture = _pixel,
                    Color = Color.Green,
                    Size = 16,
                },
                new GlobalCooldown(),
                new CombatStats
                {
                    MoveSpeed = member.Stats.MovementSpeed,
                    AttackRangeSq = member.Stats.AttackRangeSq,
                },
                new Health { Current = member.Stats.MaxHealth },
                new SkillLoadout
                {
                    BasicAttack = skillRegistry.Create(member.BasicAttackId),
                    Skills = [.. member.SkillIds.Select(skillRegistry.Create)],
                },
                Tags.Get<UnitTag, Ally>()
            );
        }

        var enemies = Enumerable.Repeat(enemyRegistry.Get("enemy_1"), 10).ToList();
        foreach (
            var (enemy, pos) in enemies.Zip(ColumnPositions(enemies.Count, spacing: 40f, x: 1030))
        )
        {
            _world.CreateEntity(
                new Position2D { Value = pos },
                new Sprite
                {
                    Texture = _circle,
                    Color = Color.IndianRed,
                    Size = 16,
                },
                new GlobalCooldown(),
                new CombatStats
                {
                    MoveSpeed = enemy.Stats.MovementSpeed,
                    AttackRangeSq = enemy.Stats.AttackRangeSq,
                },
                new Health { Current = enemy.Stats.MaxHealth },
                new SkillLoadout
                {
                    BasicAttack = skillRegistry.Create(enemy.BasicAttackId),
                    Skills = [.. enemy.SkillIds.Select(skillRegistry.Create)],
                },
                Tags.Get<UnitTag, Enemy>()
            );
        }
    }

    public override void Update(GameTime gameTime)
    {
        _root.Update(new UpdateTick(gameTime.Delta(), (float)gameTime.TotalGameTime.TotalSeconds));

        if (_outcome == Outcome.InProgress)
        {
            var alliesAlive = _world.Query().AllTags(Tags.Get<Ally>()).Count > 0;
            var enemiesAlive = _world.Query().AllTags(Tags.Get<Enemy>()).Count > 0;

            if (!alliesAlive || !enemiesAlive)
            {
                _outcome =
                    alliesAlive ? Outcome.EnemiesCleared
                    : enemiesAlive ? Outcome.AlliesCleared
                    : Outcome.Draw;
                ShowOutcomeOverlay();
            }
        }

        base.Update(gameTime);
    }

    public override void Draw(GameTime gameTime)
    {
        Core.GraphicsDevice.Clear(Color.DarkSlateGray);

        Core.SpriteBatch.Begin();

        var query = _world.Query<Sprite, Position2D>().AllComponents(ComponentTypes.Get<Sprite>());
        query.ForEachEntity(
            (ref Sprite sprite, ref Position2D pos, Entity entity) =>
            {
                var rect = new Rectangle(
                    (int)pos.Value.X - (sprite.Size / 2),
                    (int)(pos.Value.Y - (sprite.Size / 2)),
                    sprite.Size,
                    sprite.Size
                );
                Core.SpriteBatch.Draw(sprite.Texture, rect, sprite.Color);
            }
        );

        _world
            .Query<Position2D, DamageNumber>()
            .ForEachEntity(
                (ref Position2D pos, ref DamageNumber dn, Entity e) =>
                {
                    var alpha = 1f - (dn.Elapsed / dn.Lifetime);
                    var origin = _font.MeasureString(dn.Text) / 2f;
                    Core.SpriteBatch.DrawString(
                        _font,
                        dn.Text,
                        pos.Value,
                        Color.White * alpha,
                        0f,
                        origin,
                        1f,
                        SpriteEffects.None,
                        0f
                    );
                }
            );

        Core.SpriteBatch.End();

        base.Draw(gameTime);
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _combat.DamageDealt -= HandleDamageDealt;
            _pixel?.Dispose();
            _circle?.Dispose();
        }
        base.Dispose(disposing);
    }
    #endregion

    #region Events

    private void HandleDamageDealt(DamageInfo info)
    {
        var targetPosition = info.Target.GetComponent<Position2D>().Value;

        var spawn =
            targetPosition
            + new Vector2((_random.NextSingle() * 30f) - 15f, (_random.NextSingle() * 20f) - 10f);
        var angle = -MathHelper.PiOver2 + ((_random.NextSingle() - 0.5f) * 1.2f);
        var drift = new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * 40f;

        _world.CreateEntity(
            new Position2D { Value = spawn },
            new DamageNumber
            {
                Text = ((int)info.Amount).ToString(CultureInfo.InvariantCulture),
                Drift = drift,
                Lifetime = 1f,
            }
        );
    }
    #endregion

    #region Helpers

    private static IEnumerable<Vector2> ColumnPositions(int count, float x, float spacing = 80f)
    {
        var centerY = Core.GraphicsDevice.Viewport.Height / 2f;
        var offset = centerY - ((count - 1) * spacing / 2f);
        for (var i = 0; i < count; i++)
        {
            yield return new Vector2(x, offset + (i * spacing));
        }
    }

    private void ShowOutcomeOverlay()
    {
        var panel = new StackPanel { Spacing = 10 };
        panel.Anchor(Gum.Wireframe.Anchor.Center);
        panel.AddToRoot();

        var row = new StackPanel { Orientation = Orientation.Horizontal };
        row.Anchor(Gum.Wireframe.Anchor.CenterHorizontally);
        row.AddChild(new Label { Text = _outcome.ToString() });
        panel.AddChild(row);

        var button = new Button { Text = "Return" };
        button.Click += (s, e) => Core.ChangeScene(new TitleScene());
        panel.AddChild(button);
    }
    #endregion
}
