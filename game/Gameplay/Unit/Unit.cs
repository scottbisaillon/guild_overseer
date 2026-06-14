using GuildOverseer.Data;
using GuildOverseer.Library.Entity;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GuildOverseer.Gameplay;

public enum Faction
{
    Ally,
    Enemy,
}

public class Unit : Entity
{
    public required Texture2D Texture { get; init; }
    public required Color Color { get; init; }
    public required Faction Faction { get; init; }
    public int Size { get; init; } = 48;

    public required MemberData MemberData { get; init; }

    public Vector2 Position;

    public Unit? Target;

    public bool IsInRange =>
        Target != null
        && Vector2.DistanceSquared(Position, Target.Position) < MemberData.Stats.AttackRangeSq;

    public override void Update(GameTime gameTime)
    {
        if (Target == null)
        {
            return;
        }

        if (IsInRange)
        {
            return;
        }

        var delta = (float)gameTime.ElapsedGameTime.TotalSeconds;
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
            (int)Position.X - Size / 2,
            (int)(Position.Y - Size / 2),
            Size,
            Size
        );
        spriteBatch.Draw(Texture, rect, Color);
    }
}
