using System;
using System.Threading.Tasks;
using Godot;
using GuildOverseer.Core.Constants;
using GuildOverseer.Levels;

namespace GuildOverseer.Core;

public partial class MainGame : Node2D
{
    public static MainGame Instance { get; private set; } = null!;

    private Node2D LevelRoot { get; set; } = null!;
    private Control ScreenRoot { get; set; } = null!;

    private BaseLevel? _currentLevel;
    private Control? _currentScreen;

    public override void _Ready()
    {
        Instance = this;

        LevelRoot = GetNode<Node2D>("%LevelRoot");
        ScreenRoot = GetNode<Control>("%ScreenRoot");

        ShowScreen(Scenes.Screens.MainMenu);
    }

    public void ShowScreen(string uid)
    {
        ClearScreen();

        var newScreenPacked = GD.Load<PackedScene>(uid);
        _currentScreen = newScreenPacked.Instantiate<Control>();
        ScreenRoot.AddChild(_currentScreen);
    }

    public void ClearScreen()
    {
        _currentScreen?.QueueFree();
        _currentScreen = null;
    }

    public void LoadLevel(string uid)
    {
        Callable.From(() => LoadLevelDeferred(uid)).CallDeferred();
    }

    public void UnloadLevel() { }

    private async Task LoadLevelDeferred(string levelUID)
    {
        if (_currentLevel != null)
        {
            _currentLevel.QueueFree();
            _currentLevel = null;
        }

        await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

        var newLevelPacked = GD.Load<PackedScene>(levelUID);

        _currentLevel = newLevelPacked.Instantiate() as BaseLevel;

        if (_currentLevel == null)
        {
            GD.PushError("Loaded level is not of type BaseLevel or does not exist");
            return;
        }

        LevelRoot.AddChild(_currentLevel);

        await ToSignal(GetTree(), SceneTree.SignalName.ProcessFrame);

        // TODO: Signal that the scene has fully loaded?
    }
}
