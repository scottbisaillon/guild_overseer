using Godot;

[GlobalClass]
public partial class UnitStats : Resource
{
    [Export]
    public double MaxHealth { get; set; } = 0.0;

    [Export]
    public double AttackRange { get; set; } = 0.0;

    [Export]
    public float MovementSpeed { get; set; } = 0.0f;

    public double AttackRangeSq => AttackRange * AttackRange;
}
