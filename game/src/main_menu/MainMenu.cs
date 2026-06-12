using System;
using Godot;

public partial class MainMenu : Control
{
    public Button EnterButton { get; set; } = null!;

    public override void _Ready()
    {
        EnterButton = GetNode<Button>("%Button");

        EnterButton.Pressed += () =>
        {
            GetTree().ChangeSceneToFile("res://src/party_selection/PartySelection.tscn");
        };
    }
}
