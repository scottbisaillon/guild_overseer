using System;
using System.Collections.Generic;
using System.Linq;
using GuildOverseer.Data;
using GuildOverseer.Gameplay;
using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Library.Graphics;
using GuildOverseer.Library.Scenes;
using GuildOverseer.Services;
using Gum.Forms.Controls;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using MonoGameGum;

namespace GuildOverseer.Scenes;

public class DungeonScene : Scene
{
    private ActiveDungeonService _activeDungeonService = default!;

    private Texture2D _pixel = default!;
    private Texture2D _circle = default!;

    private readonly List<Unit> _units = [];

    public override void LoadContent()
    {
        GumService.Default.Root.Children.Clear();

        var registry = Core.Instance.Services.GetService<UnitRegistry>();
        _activeDungeonService = Core.Instance.Services.GetService<ActiveDungeonService>();

        _pixel = ShapeTexture.CreatePixel(Core.GraphicsDevice);
        _circle = ShapeTexture.CreateCircle(Core.GraphicsDevice, 48);

        PlaceColumn(
            _activeDungeonService.Party.Select(m => new Unit
            {
                Texture = _pixel,
                Faction = Faction.Ally,
                Color = Color.CornflowerBlue,
                MemberData = registry.Get(m),
            }),
            x: 250
        );

        PlaceColumn(
            [
                new Unit
                {
                    Texture = _circle,
                    Color = Color.IndianRed,
                    Faction = Faction.Enemy,
                    MemberData = new MemberData
                    {
                        Id = "enemy_1",
                        Name = "Enemy 1",
                        Stats = new Stats
                        {
                            MaxHealth = 10.0,
                            MovementSpeed = 100.0f,
                            AttackRange = 25.0f,
                        },
                    },
                },
                new Unit
                {
                    Texture = _circle,
                    Color = Color.IndianRed,
                    Faction = Faction.Enemy,
                    MemberData = new MemberData
                    {
                        Id = "enemy_2",
                        Name = "Enemy 2",
                        Stats = new Stats
                        {
                            MaxHealth = 10.0,
                            MovementSpeed = 150.0f,
                            AttackRange = 30.0f,
                        },
                    },
                },
                new Unit
                {
                    Texture = _circle,
                    Color = Color.IndianRed,
                    Faction = Faction.Enemy,
                    MemberData = new MemberData
                    {
                        Id = "enemy_3",
                        Name = "Enemy 3",
                        Stats = new Stats
                        {
                            MaxHealth = 10.0,
                            MovementSpeed = 75.0f,
                            AttackRange = 50.0f,
                        },
                    },
                },
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

        Core.SpriteBatch.End();

        base.Draw(gameTime);
    }

    private void PlaceColumn(IEnumerable<Unit> units, float x)
    {
        var list = units.ToList();
        float centerY = Core.GraphicsDevice.Viewport.Height / 2f;
        float spacing = 80f;
        float offset = centerY - (list.Count - 1) * spacing / 2f;
        for (int i = 0; i < list.Count; i++)
        {
            list[i].Position = new Vector2(x, offset + i * spacing);
            _units.Add(list[i]);
        }
    }

    private void AcquireTargets()
    {
        foreach (var unit in _units)
        {
            if (unit.Target != null)
                continue;

            Unit? nearest = null;
            float best = float.MaxValue;

            foreach (var other in _units)
            {
                if (unit.Faction == other.Faction)
                {
                    continue;
                }

                float distSq = Vector2.DistanceSquared(unit.Position, other.Position);
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
}
