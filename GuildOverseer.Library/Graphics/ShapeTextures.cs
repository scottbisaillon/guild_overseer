namespace GuildOverseer.Library.Graphics;

using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

public static class ShapeTexture
{
    public static Texture2D CreatePixel(GraphicsDevice gd)
    {
        var texture = new Texture2D(gd, 1, 1);
        texture.SetData([Color.White]);
        return texture;
    }

    public static Texture2D CreateCircle(GraphicsDevice gd, int diameter)
    {
        var radius = diameter / 2f;
        var data = new Color[diameter * diameter];
        for (var y = 0; y < diameter; y++)
        {
            for (var x = 0; x < diameter; x++)
            {
                var dx = x - radius + 0.5f;
                var dy = y - radius + 0.5f;
                data[(y * diameter) + x] =
                    (dx * dx) + (dy * dy) <= radius * radius ? Color.White : Color.Transparent;
            }
        }
        var tex = new Texture2D(gd, diameter, diameter);
        tex.SetData(data);
        return tex;
    }
}
