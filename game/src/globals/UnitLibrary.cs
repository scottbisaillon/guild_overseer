using System.Collections.Generic;
using System.Data.Common;
using Godot;

namespace Game;

public partial class UnitLibrary : Node
{
    public static UnitLibrary Instance { get; private set; } = null!;

    public Dictionary<string, UnitData> PartyMembers { get; set; } = [];
    public Dictionary<string, UnitData> Enemies { get; set; } = [];

    private PackedScene _unitScene { get; set; } = null!;

    public override void _Ready()
    {
        Instance = this;

        _unitScene = GD.Load<PackedScene>("res://src/unit/Unit.tscn");

        var allUnits = GD.Load<AllUnits>("res://data/all_units.tres");

        foreach (var member in allUnits.UnitsList)
        {
            PartyMembers.Add(member.Id, member);
        }

        foreach (var enemy in allUnits.EnemiesList)
        {
            Enemies.Add(enemy.Id, enemy);
        }
    }

    public Unit BuildPartyMember(string id)
    {
        var data = PartyMembers[id];
        var unit = BuildUnit(data);
        return unit;
    }

    public Unit BuildEnemy(string id)
    {
        var data = Enemies[id];
        var unit = BuildUnit(data);
        unit.IsEnemy = true;
        return unit;
    }

    private Unit BuildUnit(UnitData data)
    {
        var unit = _unitScene.Instantiate<Unit>();
        unit.Data = data;
        return unit;
    }
}
