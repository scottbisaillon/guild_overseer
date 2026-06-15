namespace GuildOverseer.Scenes;

using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using GuildOverseer.Data;
using GuildOverseer.Gameplay;
using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Library.Graphics;
using GuildOverseer.Library.Scenes;
using GuildOverseer.Services;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameGum;

public class DungeonScene : Scene
{
    #region Services
    private ActiveDungeonService _activeDungeonService = default!;
    private CombatEvents _combat = default!;
    #endregion

    #region Assets
    private Texture2D _pixel = default!;
    private Texture2D _circle = default!;
    private SpriteFont _font = default!;
    #endregion

    #region State
    private readonly List<Unit> _units = [];
    private readonly List<DamageNumber> _damageNumbers = [];
    private readonly List<Unit> _pendingRemoval = [];
    private readonly Random _random = new();
    #endregion

    #region Encounter
    private readonly List<MemberData> _enemies =
    [
        new MemberData
        {
            Id = "enemy_1",
            Name = "Enemy 1",
            BasicAttackId = "basic_attack",
            SkillIds = [],
            Stats = new Stats
            {
                MaxHealth = 10.0,
                MovementSpeed = 100.0f,
                AttackRange = 25.0f,
            },
        },
        new MemberData
        {
            Id = "enemy_2",
            Name = "Enemy 2",
            BasicAttackId = "basic_attack",
            SkillIds = [],
            Stats = new Stats
            {
                MaxHealth = 10.0,
                MovementSpeed = 150.0f,
                AttackRange = 30.0f,
            },
        },
        new MemberData
        {
            Id = "enemy_3",
            Name = "Enemy 3",
            BasicAttackId = "basic_attack",
            SkillIds = [],
            Stats = new Stats
            {
                MaxHealth = 10.0,
                MovementSpeed = 75.0f,
                AttackRange = 50.0f,
            },
        },
    ];
    #endregion

    #region Lifecycle
    public override void LoadContent()
    {
        GumService.Default.Root.Children.Clear();

        var unitRegistry = Core.Instance.Services.GetService<UnitRegistry>();
        var skillRegistry = Core.Instance.Services.GetService<SkillRegistry>();

        _activeDungeonService = Core.Instance.Services.GetService<ActiveDungeonService>();
        _combat = Core.Instance.Services.GetService<CombatEvents>();

        _combat.UnitDied += HandleUnitDied;
        _combat.DamageDealt += HandleDamageDealt;

        _pixel = ShapeTexture.CreatePixel(Core.GraphicsDevice);
        _circle = ShapeTexture.CreateCircle(Core.GraphicsDevice, 48);
        _font = _content.Load<SpriteFont>("fonts/default");

        PlaceColumn(
            _activeDungeonService.Party.Select(mId =>
            {
                var memberData = unitRegistry.Get(mId);
                return new Unit
                {
                    Texture = _pixel,
                    HealthBarTexture = _pixel,
                    Faction = Faction.Ally,
                    Color = Color.CornflowerBlue,
                    Combat = _combat,
                    MemberData = memberData,
                    BasicAttack = new Skill { Data = skillRegistry.Get(memberData.BasicAttackId) },
                    Skills =
                    [
                        .. memberData.SkillIds.Select(sId => new Skill
                        {
                            Data = skillRegistry.Get(sId),
                        }),
                    ],
                };
            }),
            x: 250
        );

        PlaceColumn(
            [
                .. _enemies.Select(data => new Unit
                {
                    Texture = _circle,
                    HealthBarTexture = _pixel,
                    Faction = Faction.Enemy,
                    Color = Color.IndianRed,
                    Combat = _combat,
                    MemberData = data,
                    BasicAttack = new Skill { Data = skillRegistry.Get(data.BasicAttackId) },
                    Skills =
                    [
                        .. data.SkillIds.Select(sId => new Skill { Data = skillRegistry.Get(sId) }),
                    ],
                }),
            ],
            x: 1030
        );
    }

    public override void Update(GameTime gameTime)
    {
        AcquireTargets();

        foreach (var unit in _units)
        {
            unit.Update(gameTime);
        }

        foreach (var unit in _pendingRemoval)
        {
            _units.Remove(unit);
        }

        _pendingRemoval.Clear();

        foreach (var damageNumber in _damageNumbers)
        {
            damageNumber.Update(gameTime);
        }

        _damageNumbers.RemoveAll(e => e.IsExpired);

        base.Update(gameTime);
    }

    public override void Draw(GameTime gameTime)
    {
        Core.GraphicsDevice.Clear(Color.DarkSlateGray);

        Core.SpriteBatch.Begin();

        foreach (var unit in _units)
        {
            unit.Draw(Core.SpriteBatch);
        }

        foreach (var damageNumber in _damageNumbers)
        {
            damageNumber.Draw(Core.SpriteBatch);
        }

        Core.SpriteBatch.End();

        base.Draw(gameTime);
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing)
        {
            _combat.UnitDied -= HandleUnitDied;
            _combat.DamageDealt -= HandleDamageDealt;
            _pixel?.Dispose();
            _circle?.Dispose();
        }
        base.Dispose(disposing);
    }
    #endregion

    #region Events
    private void HandleUnitDied(Unit unit)
    {
        foreach (var u in _units)
        {
            if (u.Target == unit)
            {
                u.Target = null;
            }
        }
        _pendingRemoval.Add(unit);
    }

    private void HandleDamageDealt(DamageInfo info)
    {
        var spawn =
            info.Target.Position
            + new Vector2((_random.NextSingle() * 30f) - 15f, (_random.NextSingle() * 20f) - 10f);
        var angle = -MathHelper.PiOver2 + ((_random.NextSingle() - 0.5f) * 1.2f);
        var drift = new Vector2(MathF.Cos(angle), MathF.Sin(angle)) * 40f;

        _damageNumbers.Add(
            new DamageNumber
            {
                Font = _font,
                Text = ((int)info.Amount).ToString(CultureInfo.InvariantCulture),
                Position = spawn,
                Drift = drift,
            }
        );
    }
    #endregion

    #region Helpers
    private void PlaceColumn(IEnumerable<Unit> units, float x)
    {
        var list = units.ToList();
        var centerY = Core.GraphicsDevice.Viewport.Height / 2f;
        var spacing = 80f;
        var offset = centerY - ((list.Count - 1) * spacing / 2f);
        for (var i = 0; i < list.Count; i++)
        {
            list[i].Position = new Vector2(x, offset + (i * spacing));
            _units.Add(list[i]);
        }
    }

    private void AcquireTargets()
    {
        foreach (var unit in _units)
        {
            if (unit.Target != null)
            {
                continue;
            }

            Unit? nearest = null;
            var best = float.MaxValue;

            foreach (var other in _units)
            {
                if (unit.Faction == other.Faction)
                {
                    continue;
                }

                var distSq = Vector2.DistanceSquared(unit.Position, other.Position);
                if (distSq < best)
                {
                    nearest = other;
                    best = distSq;
                }
            }

            if (nearest != null)
            {
                unit.Target = nearest;
            }
        }
    }
    #endregion
}
