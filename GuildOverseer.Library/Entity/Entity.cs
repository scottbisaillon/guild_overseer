using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace GuildOverseer.Library.Entity;

public abstract class Entity
{
    public abstract void Update(GameTime gameTime);
    public abstract void Draw(SpriteBatch spriteBatch);
}
