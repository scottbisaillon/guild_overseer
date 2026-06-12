using Godot;

namespace Game;

[GlobalClass]
public partial class AllUnits : Resource
{
    [Export]
    public Godot.Collections.Array<UnitData> UnitsList = [];

    [Export]
    public Godot.Collections.Array<UnitData> EnemiesList = [];

    public AllUnits()
        : this([], []) { }

    public AllUnits(
        Godot.Collections.Array<UnitData> units,
        Godot.Collections.Array<UnitData> enemies
    )
    {
        UnitsList = units;
        EnemiesList = enemies;
    }
}
