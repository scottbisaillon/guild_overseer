using Godot;

[GlobalClass]
public partial class UnitStats : Resource
{
    [Export]
    public double MaxHealth;

    [Export]
    public double AttackRange;

    [Export]
    public float MovementSpeed;

    public double AttackRangeSq => AttackRange * AttackRange;

    public UnitStats()
        : this(0, 0, 0) { }

    public UnitStats(double maxHealth, double attackRange, float movementSpeed)
    {
        MaxHealth = maxHealth;
        AttackRange = attackRange;
        MovementSpeed = movementSpeed;
    }
}
