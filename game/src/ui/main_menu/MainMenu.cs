using Godot;
using GuildOverseer.Core;
using GuildOverseer.Core.Constants;

namespace GuildOverseer.Ui;

public partial class MainMenu : Control
{
    public Button EnterButton { get; set; } = default!;

    public override void _Ready()
    {
        EnterButton = GetNode<Button>("%Button");

        EnterButton.Pressed += () =>
        {
            MainGame.Instance.ShowScreen(Scenes.Screens.PartySelection);
        };
    }
}
