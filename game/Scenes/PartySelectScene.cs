using System;
using System.Linq;
using System.Linq.Expressions;
using GuildOverseer.Data;
using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Library.Scenes;
using Gum.Forms.Controls;
using Gum.Wireframe;
using Microsoft.Xna.Framework;
using MonoGameGum;

namespace GuildOverseer.Scenes;

public class PartySelectScene : Scene
{
    private ActiveDungeonService ActiveDungeonService { get; set; } = default!;

    private ListBox MembersList { get; set; } = default!;
    private Label TotalSelectedLabel { get; set; } = default!;
    private Button NextButton { get; set; } = default!;

    public override void LoadContent()
    {
        GumService.Default.Root.Children.Clear();

        ActiveDungeonService = Core.Instance.Services.GetService<ActiveDungeonService>();

        var members = Content.Load<MemberData[]>("data/members");

        var root = new StackPanel { Spacing = 10 };
        root.Anchor(Anchor.Center);
        root.AddToRoot();

        root.AddChild(new Label { Text = "Select Party Members" });

        TotalSelectedLabel = new Label
        {
            Text = $"Selected: X / {ActiveDungeonService.MaxPartySize}",
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

    public override void Update(GameTime gameTime)
    {
        base.Update(gameTime);
    }

    public override void Draw(GameTime gameTime)
    {
        Core.GraphicsDevice.Clear(Color.DarkSlateGray);
        base.Draw(gameTime);
    }

    private void HandleMemberListSelectionChanged(object arg1, SelectionChangedEventArgs args)
    {
        var ids = MembersList.SelectedItems.Cast<MemberData>().Select(m => m.Id).ToList();
        ActiveDungeonService.SetParty(ids);
        RefreshUI();
    }

    private void HandleBackButtonClicked(object? sender, EventArgs e)
    {
        Core.ChangeScene(new LevelSelectScene());
    }

    private void HandleNextButtonClicked(object? sender, EventArgs e)
    {
        Core.ChangeScene(new DungeonScene());
    }

    private void RefreshUI()
    {
        TotalSelectedLabel.Text =
            $"Selected: {ActiveDungeonService.SelectedMembersCount} / {ActiveDungeonService.MaxPartySize}";
        NextButton.IsEnabled = ActiveDungeonService.CanStart;
    }
}
