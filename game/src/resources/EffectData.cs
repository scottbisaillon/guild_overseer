using Godot;

namespace Game;

public partial class EffectData : Resource
{
    [Export]
    public string Id { get; set; } = "";

    [Export]
    public string DisplayName { get; set; } = "";

    [Export]
    public double Duration { get; set; } = 0.0;
}
