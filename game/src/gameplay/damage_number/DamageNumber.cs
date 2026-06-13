using Godot;

namespace GuildOverseer.Gameplay;

public partial class DamageNumber : Label
{
    public override void _Ready()
    {
        var tween = CreateTween();

        tween.Parallel().TweenProperty(this, "position", new Vector2(0, -20), 1.0).AsRelative();
        tween.Parallel().TweenProperty(this, "modulate:a", 0, 1.0).AsRelative();
        tween.TweenCallback(Callable.From(() => QueueFree()));
    }
}
