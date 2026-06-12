using Godot;

namespace Game;

public partial class CombatEvents : Node
{
    public static CombatEvents Instance { get; private set; } = null!;

    [Signal]
    public delegate void DamageDealtEventHandler(Unit target, double amount);

    [Signal]
    public delegate void UnitDiedEventHandler(Unit unit);

    public override void _Ready()
    {
        Instance = this;
    }

    public void EmitDamageDealt(Unit target, double amount)
    {
        EmitSignalDamageDealt(target, amount);
    }

    public void EmitUnitDied(Unit unit)
    {
        EmitSignal(SignalName.UnitDied, unit);
    }
}
