namespace GuildOverseer.Scenes;

using System;
using GuildOverseer.Library;
using GuildOverseer.Library.Scenes;
using Gum.Forms.Controls;
using Microsoft.Xna.Framework;
using MonoGameGum;

public class TitleScene : Scene
{
    #region Lifecycle
    public override void LoadContent()
    {
        GumService.Default.Root.Children.Clear();

        var panel = new StackPanel();
        panel.Anchor(Gum.Wireframe.Anchor.Center);
        panel.AddToRoot();

        var playButton = new Button { Text = "Play" };
        playButton.Click += HandlePlayButtonClicked;
        panel.AddChild(playButton);

        var quitButton = new Button { Text = "Quit" };
        quitButton.Click += HandleQuitButtonClicked;
        panel.AddChild(quitButton);
    }

    public override void Draw(GameTime gameTime)
    {
        Core.GraphicsDevice.Clear(Color.DarkSlateGray);

        base.Draw(gameTime);
    }
    #endregion

    #region Events
    private void HandlePlayButtonClicked(object? sender, EventArgs e) =>
        Core.ChangeScene(new LevelSelectScene());

    private void HandleQuitButtonClicked(object? sender, EventArgs e) => Core.Instance.Quit();
    #endregion
}
