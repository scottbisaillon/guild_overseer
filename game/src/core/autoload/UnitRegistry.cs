using System.Collections.Generic;
using Game;
using Godot;

namespace GuildOverseer.Core.Autoload;

public partial class UnitRegistry : Node
{
    public static UnitRegistry Instance { get; private set; } = null!;

    public Dictionary<string, UnitData> PartyMembers { get; set; } = [];
    public Dictionary<string, UnitData> Enemies { get; set; } = [];

    private PackedScene _unitScene { get; set; } = null!;

    public override void _Ready()
    {
        Instance = this;

        _unitScene = GD.Load<PackedScene>("res://src/unit/Unit.tscn");

        var manifest = GD.Load<UnitManifest>("res://data/unit_manifest.tres");

        foreach (var member in manifest.PartyMembers)
        {
            PartyMembers.Add(member.Id, member);
        }

        foreach (var enemy in manifest.Enemies)
        {
            Enemies.Add(enemy.Id, enemy);
        }
    }

    public Unit CreatePartyMember(string id)
    {
        var data = PartyMembers[id];
        var unit = CreateUnit(data);
        return unit;
    }

    public Unit CreateEnemy(string id)
    {
        var data = Enemies[id];
        var unit = CreateUnit(data);
        unit.IsEnemy = true;
        return unit;
    }

    private Unit CreateUnit(UnitData data)
    {
        var unit = _unitScene.Instantiate<Unit>();
        unit.Data = data;
        return unit;
    }
}
