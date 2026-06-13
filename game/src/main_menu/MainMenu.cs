using Godot;
using GuildOverseer.Core.Autoload;
using GuildOverseer.Core.Constants;

public partial class MainMenu : Control
{
    public Button EnterButton { get; set; } = null!;

    public override void _Ready()
    {
        EnterButton = GetNode<Button>("%Button");

        EnterButton.Pressed += () =>
        {
            MainGame.Instance.ShowScreen(Scenes.Screens.PartySelection);
        };
    }
}
