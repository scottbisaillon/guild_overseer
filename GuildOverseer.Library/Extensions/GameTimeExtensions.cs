namespace GuildOverseer.Library.Extensions;

using Microsoft.Xna.Framework;

public static class GameTimeExtensions
{
    public static float Delta(this GameTime gameTime) =>
        (float)gameTime.ElapsedGameTime.TotalSeconds;
}
