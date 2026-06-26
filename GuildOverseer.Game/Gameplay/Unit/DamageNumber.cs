namespace GuildOverseer.Gameplay;

using GuildOverseer.Library.Entity;
using GuildOverseer.Library.Extensions;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

public class DamageNumber : Entity
{
    #region Configuration
    public required SpriteFont Font { get; init; }
    public required string Text { get; init; }
    public required Vector2 Drift { get; init; }
    public float Lifetime { get; init; } = 1.0f;

    #endregion

    #region State
    public Vector2 Position;
    private float _elapsed;
    #endregion

    #region Derived
    public bool IsExpired => _elapsed >= Lifetime;
    #endregion

    #region Lifecycle
    public override void Update(GameTime gameTime)
    {
        var delta = gameTime.Delta();
        _elapsed += delta;
        Position += Drift * delta;
    }

    public override void Draw(SpriteBatch spriteBatch)
    {
        var alpha = 1f - (_elapsed / Lifetime);
        var origin = Font.MeasureString(Text) / 2f;
        spriteBatch.DrawString(
            Font,
            Text,
            Position,
            Color.White * alpha,
            0f,
            origin,
            1f,
            SpriteEffects.None,
            0f
        );
    }
    #endregion

    #region Behavior
    #endregion
}
