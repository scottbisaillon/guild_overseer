using System;
using GuildOverseer.Library.Scenes;
using Gum.Forms;
using Gum.Forms.Controls;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using MonoGameGum;

namespace GuildOverseer.Library;

public class Core : Game
{
    internal static Core s_instance;

    public static Core Instance => s_instance;

    private static Scene s_activeScene;

    private static Scene s_nextScene;

    public static GraphicsDeviceManager Graphics { get; private set; }

    public new static GraphicsDevice GraphicsDevice { get; private set; }

    public static SpriteBatch SpriteBatch { get; private set; }

    public static ContentManager Content { get; private set; }

    public Core(string title, int width, int height, bool fullScreen)
    {
        if (s_instance != null)
        {
            throw new InvalidOperationException($"Only a single Core instance can be created");
        }

        s_instance = this;

        Graphics = new GraphicsDeviceManager(this);

        Graphics.PreferredBackBufferWidth = width;
        Graphics.PreferredBackBufferHeight = height;
        Graphics.IsFullScreen = fullScreen;

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
        if (s_nextScene != null)
        {
            TransitionScene();
        }

        s_activeScene?.Update(gameTime);
        
        GumService.Default.Update(gameTime);

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        s_activeScene?.Draw(gameTime);
        
        GumService.Default.Draw();

        base.Draw(gameTime);
    }

    public void Quit() => Exit();

    public static void ChangeScene(Scene next)
    {
        if (s_activeScene != next)
        {
            s_nextScene = next;
        }
    }

    public static void TransitionScene()
    {
        s_activeScene?.Dispose();

        GC.Collect();

        s_activeScene = s_nextScene;

        s_nextScene = null;

        s_activeScene?.Initialize();
    }

    private void InitializeGum()
    {
        GumService.Default.Initialize(this, DefaultVisualsVersion.V3);
        if (GumService.Default.ContentLoader != null) GumService.Default.ContentLoader.XnaContentManager = Content;

        FrameworkElement.KeyboardsForUiControl.Add(GumService.Default.Keyboard);
        FrameworkElement.GamePadsForUiControl.AddRange(GumService.Default.Gamepads);
    }
}