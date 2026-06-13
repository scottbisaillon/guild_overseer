using System;
using System.Threading.Tasks;
using Godot;
using GuildOverseer.Core.Constants;
using GuildOverseer.Levels;

namespace GuildOverseer.Core;

public partial class MainGame : Node2D
{
    public static MainGame Instance { get; private set; } = default!;

    private Node2D LevelRoot { get; set; } = default!;
    private Node2D EntityRoot { get; set; } = default!;
    private Node2D EffectRoot { get; set; } = default!;
    private Control ScreenRoot { get; set; } = default!;

    private BaseLevel? _currentLevel;
    private Control? _currentScreen;

    public override void _Ready()
    {
        Instance = this;

        LevelRoot = GetNode<Node2D>("%LevelRoot");
        EffectRoot = GetNode<Node2D>("%EffectRoot");
        EntityRoot = GetNode<Node2D>("%EntityRoot");
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

    public void AddEntity(Node node)
    {
        EntityRoot.AddChild(node);
    }

    public void AddEffect(Node node)
    {
        EffectRoot.AddChild(node);
    }
}
