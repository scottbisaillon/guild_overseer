namespace GuildOverseer.Gameplay;

using System;
using System.Collections.Generic;
using System.Linq;
using GuildOverseer.Data;
using GuildOverseer.Library.Entity;
using GuildOverseer.Services;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

public enum Faction
{
    Ally,
    Enemy,
}

public class Unit : Entity
{
    #region Constants
    private const float GCD = 1.0f;
    #endregion

    #region Services
    public required CombatEvents Combat { get; init; }
    #endregion

    #region Configuration
    public required Texture2D Texture { get; init; }
    public required Texture2D HealthBarTexture { get; init; }
    public required Color Color { get; init; }
    public required Faction Faction { get; init; }
    public required MemberData MemberData
    {
        get => _memberData;
        init
        {
            _memberData = value;
            _currentHealth = value.Stats.MaxHealth;
        }
    }
    public required Skill BasicAttack { get; init; }
    public int Size { get; init; } = 48;
    public List<Skill> Skills { get; init; } = [];
    #endregion

    #region State
    public Vector2 Position;
    public Unit? Target;
    private double _currentHealth;
    private float _timeUntilReady;
    private MemberData _memberData = default!;
    #endregion

    #region Derived
    public float MaxHealth => (float)MemberData.Stats.MaxHealth;
    public bool IsAlive => _currentHealth > 0f;
    public bool IsInRange =>
        Target != null
        && Vector2.DistanceSquared(Position, Target.Position) < MemberData.Stats.AttackRangeSq;
    #endregion

    #region Lifecycle
    public override void Update(GameTime gameTime)
    {
        var delta = (float)gameTime.ElapsedGameTime.TotalSeconds;

        if (!IsAlive)
        {
            return;
        }

        BasicAttack.Update(gameTime);
        foreach (var skill in Skills)
        {
            skill.Update(gameTime);
        }

        _timeUntilReady = Math.Max(0.0f, _timeUntilReady - delta);

        if (Target == null)
        {
            return;
        }

        if (IsInRange)
        {
            if (_timeUntilReady <= 0.0f)
            {
                var skill = Skills.FirstOrDefault(s => s.IsReady) ?? BasicAttack;
                skill.Execute(this, Target, Combat);
                _timeUntilReady = GCD;
            }

            return;
        }

        var dir = Target.Position - Position;

        if (dir.LengthSquared() > 0.0001f)
        {
            dir.Normalize();
            Position += dir * delta * MemberData.Stats.MovementSpeed;
        }
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        var rect = new Rectangle(
            (int)Position.X - (Size / 2),
            (int)(Position.Y - (Size / 2)),
            Size,
            Size
        );
        spriteBatch.Draw(Texture, rect, Color);

        var backgroundRect = new Rectangle(
            (int)Position.X - (Size / 2),
            (int)(Position.Y - (Size / 2)) - 10,
            Size,
            4
        );

        var foregroundRect = new Rectangle(
            (int)Position.X - (Size / 2),
            (int)(Position.Y - (Size / 2)) - 10,
            (int)(Size * Math.Max(0, _currentHealth / MaxHealth)),
            4
        );

        spriteBatch.Draw(HealthBarTexture, backgroundRect, Color.Red);
        spriteBatch.Draw(HealthBarTexture, foregroundRect, Color.Green);
    }
    #endregion

    #region Behavior
    public void TakeDamage(double amount) => _currentHealth -= amount;
    #endregion
}
