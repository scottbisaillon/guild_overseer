namespace GuildOverseer.Scenes;

using System;
using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Library.Scenes;
using Gum.Forms.Controls;
using Gum.Wireframe;
using Microsoft.Xna.Framework;
using MonoGameGum;

public class LevelSelectScene : Scene
{
    #region Services
    private ActiveDungeonService ActiveDungeonService { get; set; } = default!;
    #endregion

    #region Configuration
    private readonly LevelOption[] _levels = [new("test_level_1", "Test Level 1")];
    #endregion

    #region State
    private ListBox LevelsList { get; set; } = default!;
    private Button NextButton { get; set; } = default!;
    #endregion

    #region Lifecycle
    public override void LoadContent()
    {
        ActiveDungeonService = Core.Instance.Services.GetService<ActiveDungeonService>();

        GumService.Default.Root.Children.Clear();

        var root = new StackPanel { Spacing = 10 };
        root.Anchor(Anchor.Center);
        root.AddToRoot();
        root.AddChild(new Label { Text = "Select Level" });

        LevelsList = new ListBox { Width = 400, Height = 200 };

        LevelsList.SelectionChanged += HandleLevelSelectionChanged;
        foreach (var level in _levels)
        {
            LevelsList.Items?.Add(level);
        }

        root.AddChild(LevelsList);

        var buttonRow = new StackPanel { Orientation = Orientation.Horizontal, Spacing = 10 };
        buttonRow.Anchor(Anchor.CenterHorizontally);
        root.AddChild(buttonRow);

        var backButton = new Button { Text = "Back" };
        backButton.Click += HandleBackButtonClicked;
        buttonRow.AddChild(backButton);

        NextButton = new Button { Text = "Next", IsEnabled = false };
        NextButton.Click += HandleNextButtonClicked;
        buttonRow.AddChild(NextButton);
    }

    public override void Draw(GameTime gameTime)
    {
        Core.GraphicsDevice.Clear(Color.DarkSlateGray);

        base.Draw(gameTime);
    }
    #endregion

    #region Events
    private void HandleLevelSelectionChanged(object arg1, SelectionChangedEventArgs args)
    {
        if (LevelsList.SelectedObject is LevelOption level)
        {
            NextButton.IsEnabled = true;
            ActiveDungeonService.SelectLevel(level);
        }
    }

    private void HandleBackButtonClicked(object? sender, EventArgs e) =>
        Core.ChangeScene(new TitleScene());

    private void HandleNextButtonClicked(object? sender, EventArgs e) =>
        Core.ChangeScene(new PartySelectScene());
    #endregion
}
