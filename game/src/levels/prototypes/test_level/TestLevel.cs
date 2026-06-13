using System;
using System.Linq;
using Godot;
using GuildOverseer.Core;
using GuildOverseer.Core.Autoload;
using GuildOverseer.Gameplay;

namespace GuildOverseer.Levels.Prototypes;

public partial class TestLevel : BaseLevel
{
    [Export]
    private PackedScene DamageNumberScene { get; set; } = default!;

    private Marker2D EnemySpawn { get; set; } = default!;

    public override void _Ready()
    {
        EnemySpawn = GetNode<Marker2D>("%EnemySpawn");

        for (int i = 0; i < ActiveDungeonManager.Instance.SelectedMemberIds.Count; i++)
        {
            var member = UnitRegistry.Instance.CreatePartyMember(
                ActiveDungeonManager.Instance.SelectedMemberIds[i]
            );
            member.Position = GetSpawnLocation(
                ActiveDungeonManager.Instance.SelectedMemberIds.Count,
                i,
                GetPartySpawnLocation()
            );
            MainGame.Instance.AddEntity(member);
        }

        for (int i = 0; i < UnitRegistry.Instance.Enemies.Count; i++)
        {
            var enemy = UnitRegistry.Instance.CreateEnemy(
                UnitRegistry.Instance.Enemies.ElementAt(i).Value.Id
            );
            enemy.Position = GetSpawnLocation(
                UnitRegistry.Instance.Enemies.Count,
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
            MainGame.Instance.AddEffect(damageNumber);
        };
    }

    private Vector2 GetSpawnLocation(int total, int index, Vector2 origin)
    {
        var angle = index * (Math.Tau / total);
        return origin + Vector2.Up.Rotated((float)angle) * 50;
    }

    public override Vector2 GetPartySpawnLocation()
    {
        return GetNode<Marker2D>("%PartyMemberSpawn").GlobalPosition;
    }
}
