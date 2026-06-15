namespace GuildOverseer.Library.Scenes;

using System;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;

public abstract class Scene : IDisposable
{
    protected ContentManager _content;

    public bool IsDisposed { get; private set; }

    public Scene()
    {
        _content = new ContentManager(Core.Content.ServiceProvider)
        {
            RootDirectory = Core.Content.RootDirectory,
        };
    }

    ~Scene() => Dispose(false);

    public virtual void Initialize() => LoadContent();

    public virtual void LoadContent() { }

    public virtual void UnloadContent() => _content.Unload();

    public virtual void Update(GameTime gameTime) { }

    public virtual void Draw(GameTime gameTime) { }

    public void Dispose()
    {
        Dispose(true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (IsDisposed)
        {
            return;
        }

        if (disposing)
        {
            UnloadContent();
            _content.Dispose();
        }

        IsDisposed = true;
    }
}
