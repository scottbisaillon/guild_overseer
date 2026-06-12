using System;
using System.Linq;
using Game;
using Godot;

public partial class TestLevel : Node2D
{
    [Export]
    private PackedScene DamageNumberScene { get; set; } = null!;

    private Node2D PartyMemberSpawn { get; set; } = null!;
    private Node2D EnemySpawn { get; set; } = null!;

    public override void _Ready()
    {
        PartyMemberSpawn = GetNode<Node2D>("%PartyMemberSpawn");
        EnemySpawn = GetNode<Node2D>("%EnemySpawn");

        for (int i = 0; i < ActiveDungeonManager.Instance.SelectedMemberIds.Count; i++)
        {
            var member = UnitLibrary.Instance.BuildPartyMember(
                ActiveDungeonManager.Instance.SelectedMemberIds[i]
            );
            member.Position = GetSpawnLocation(
                ActiveDungeonManager.Instance.SelectedMemberIds.Count,
                i,
                PartyMemberSpawn.GlobalPosition
            );
            AddChild(member);
        }

        for (int i = 0; i < UnitLibrary.Instance.Enemies.Count; i++)
        {
            var enemy = UnitLibrary.Instance.BuildEnemy(
                UnitLibrary.Instance.Enemies.ElementAt(i).Value.Id
            );
            enemy.Position = GetSpawnLocation(
                UnitLibrary.Instance.Enemies.Count,
                i,
                EnemySpawn.GlobalPosition
            );
            AddChild(enemy);
        }

        CombatEvents.Instance.DamageDealt += (target, amount) =>
        {
            var damageNumber = DamageNumberScene.Instantiate<DamageNumber>();
            damageNumber.Text = amount.ToString();
            damageNumber.GlobalPosition = target.GlobalPosition;
            AddChild(damageNumber);
        };
    }

    public override void _Process(double delta) { }

    private Vector2 GetSpawnLocation(int total, int index, Vector2 origin)
    {
        var angle = index * (Math.Tau / total);
        return origin + Vector2.Up.Rotated((float)angle) * 50;
    }
}
