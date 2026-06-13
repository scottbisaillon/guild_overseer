using System.Runtime.CompilerServices;
using Godot;

namespace GuildOverseer.Debug;

public partial class DebugOverlay : Control
{
    private Label FpsLabel { get; set; } = null!;
    private Label VersionLabel { get; set; } = null!;

    public override void _Ready()
    {
        FpsLabel = GetNode<Label>("%FpsLabel");
        VersionLabel = GetNode<Label>("%VersionInfo");

        VersionLabel.Text =
            $"v{(string)ProjectSettings.GetSetting("application/config/version", "0.0.0")}";
    }

    public override void _Process(double delta)
    {
        FpsLabel.Text = $"FPS: {Engine.GetFramesPerSecond()}";
    }
}
