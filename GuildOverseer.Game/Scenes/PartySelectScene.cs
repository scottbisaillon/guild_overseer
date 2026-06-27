namespace GuildOverseer.Scenes;

using System;
using System.Linq;
using GuildOverseer.Data;
using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Library.Scenes;
using Gum.Forms.Controls;
using Gum.Wireframe;
using Microsoft.Xna.Framework;
using MonoGameGum;

public class PartySelectScene : Scene
{
    #region Services
    private ActiveDungeonService ActiveDungeonService { get; set; } = default!;
    #endregion

    #region State
    private ListBox MembersList { get; set; } = default!;
    private Label TotalSelectedLabel { get; set; } = default!;
    private Button NextButton { get; set; } = default!;
    #endregion

    #region Lifecycle
    public override void LoadContent()
    {
        GumService.Default.Root.Children.Clear();

        ActiveDungeonService = Core.Instance.Services.GetService<ActiveDungeonService>();

        var members = _content.Load<UnitData[]>("data/members");

        var root = new StackPanel { Spacing = 10 };
        root.Anchor(Anchor.Center);
        root.AddToRoot();

        root.AddChild(new Label { Text = "Select Party Members" });

        TotalSelectedLabel = new Label
        {
            Text = $"Selected: X / {ActiveDungeonService.MAX_PARTY_SIZE}",
        };
        root.AddChild(TotalSelectedLabel);

        MembersList = new ListBox
        {
            SelectionMode = SelectionMode.Multiple,
            Width = 400,
            Height = 200,
        };
        MembersList.SelectionChanged += HandleMemberListSelectionChanged;
        root.AddChild(MembersList);

        foreach (var member in members)
        {
            MembersList.Items?.Add(member);
        }

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

    public override void Update(GameTime gameTime) => base.Update(gameTime);

    public override void Draw(GameTime gameTime)
    {
        Core.GraphicsDevice.Clear(Color.DarkSlateGray);
        base.Draw(gameTime);
    }
    #endregion

    #region Events
    private void HandleMemberListSelectionChanged(object arg1, SelectionChangedEventArgs args)
    {
        var ids = MembersList.SelectedItems.Cast<UnitData>().Select(m => m.Id).ToList();
        ActiveDungeonService.SetParty(ids);
        RefreshUI();
    }

    private void HandleBackButtonClicked(object? sender, EventArgs e) =>
        Core.ChangeScene(new LevelSelectScene());

    private void HandleNextButtonClicked(object? sender, EventArgs e) =>
        Core.ChangeScene(new DungeonScene());
    #endregion

    #region Helpers
    private void RefreshUI()
    {
        TotalSelectedLabel.Text =
            $"Selected: {ActiveDungeonService.SelectedMembersCount} / {ActiveDungeonService.MAX_PARTY_SIZE}";
        NextButton.IsEnabled = ActiveDungeonService.CanStart;
    }
    #endregion
}
