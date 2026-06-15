namespace GuildOverseer.Library;

using System;
using GuildOverseer.Library.Scenes;
using Gum.Forms;
using Gum.Forms.Controls;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using MonoGameGum;

public class Core : Game
{
    internal static Core _instance;

    public static Core Instance => _instance;

    private static Scene _activeScene;

    private static Scene _nextScene;

    public static GraphicsDeviceManager Graphics { get; private set; }

    public static new GraphicsDevice GraphicsDevice { get; private set; }

    public static SpriteBatch SpriteBatch { get; private set; }

    public static new ContentManager Content { get; private set; }

    public Core(string title, int width, int height, bool fullScreen)
    {
        if (_instance != null)
        {
            throw new InvalidOperationException($"Only a single Core instance can be created");
        }

        _instance = this;

        Graphics = new GraphicsDeviceManager(this)
        {
            PreferredBackBufferWidth = width,
            PreferredBackBufferHeight = height,
            IsFullScreen = fullScreen,
        };

        Graphics.ApplyChanges();

        Window.Title = title;

        Content = base.Content;

        Content.RootDirectory = "Content";

        IsMouseVisible = true;
    }

    protected override void Initialize()
    {
        GraphicsDevice = base.GraphicsDevice;

        SpriteBatch = new SpriteBatch(GraphicsDevice);

        InitializeGum();

        base.Initialize();
    }

    protected override void Update(GameTime gameTime)
    {
        if (_nextScene != null)
        {
            TransitionScene();
        }

        _activeScene?.Update(gameTime);

        GumService.Default.Update(gameTime);

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        _activeScene?.Draw(gameTime);

        GumService.Default.Draw();

        base.Draw(gameTime);
    }

    public void Quit() => Exit();

    public static void ChangeScene(Scene next)
    {
        if (_activeScene != next)
        {
            _nextScene = next;
        }
    }

    public static void TransitionScene()
    {
        _activeScene?.Dispose();

        GC.Collect();

        _activeScene = _nextScene;

        _nextScene = null;

        _activeScene?.Initialize();
    }

    private void InitializeGum()
    {
        GumService.Default.Initialize(this, DefaultVisualsVersion.V3);
        if (GumService.Default.ContentLoader != null)
        {
            GumService.Default.ContentLoader.XnaContentManager = Content;
        }

        FrameworkElement.KeyboardsForUiControl.Add(GumService.Default.Keyboard);
        FrameworkElement.GamePadsForUiControl.AddRange(GumService.Default.Gamepads);
    }
}
