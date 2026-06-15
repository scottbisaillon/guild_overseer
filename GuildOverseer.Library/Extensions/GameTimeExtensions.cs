using Microsoft.Xna.Framework;

namespace GuildOverseer.Library.Extensions;

public static class GameTimeExtensions
{
    public static float Delta(this GameTime gameTime) =>
        (float)gameTime.ElapsedGameTime.TotalSeconds;
}
