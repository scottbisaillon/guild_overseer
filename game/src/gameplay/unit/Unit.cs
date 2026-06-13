using System;
using System.Linq;
using Godot;
using GuildOverseer.Core.Autoload;
using GuildOverseer.Resources;

namespace GuildOverseer.Gameplay;

public partial class Unit : Node2D
{
    const double GCD = 1.0;

    private Sprite2D Visuals { get; set; } = default!;
    private Node Skills { get; set; } = default!;
    private ProgressBar HealthBar { get; set; } = default!;

    public UnitData Data { get; set; } = default!;

    public bool IsEnemy { get; set; } = false;

    private Unit? _target;
    private double _currentHealth;

    private double _timeUntilGcdReady = 0.0;

    public override void _Ready()
    {
        AddToGroup("combatants");

        Visuals = GetNode<Sprite2D>("Sprite2D");
        Skills = GetNode<Node>("Skills");
        HealthBar = GetNode<ProgressBar>("%HealthBar");

        _currentHealth = Data.Stats.MaxHealth;

        if (IsEnemy)
        {
            Visuals.Modulate = Colors.Red;
        }
        else
        {
            Visuals.Modulate = Colors.Blue;
        }

        foreach (var skill in Data.Skills)
        {
            Skills.AddChild(SkillRegistry.Instance.CreateSkillFromData(skill));
        }

        Skills.AddChild(SkillRegistry.Instance.CreateSkillFromData(Data.BasicAttack));

        HealthBar.Value = Data.Stats.MaxHealth;
        HealthBar.MaxValue = Data.Stats.MaxHealth;
        HealthBar.Size = new Vector2(Visuals.GetRect().Size.X, 4.0f);
        HealthBar.Position = new Vector2(
            -HealthBar.Size.X / 2,
            -(Visuals.GetRect().Size.Y / 2) - 10 - HealthBar.Size.Y
        );
    }

    public override void _Process(double delta)
    {
        _timeUntilGcdReady = Math.Max(0.0, _timeUntilGcdReady - delta);

        _target ??= AcquireTarget();

        if (!IsInstanceValid(_target))
        {
            _target = null;
            return;
        }

        if (IsTargetInRange())
        {
            if (_timeUntilGcdReady <= 0.0)
            {
                foreach (Skill skill in Skills.GetChildren().Cast<Skill>())
                {
                    if (skill.IsReady)
                    {
                        skill.Trigger(_target);
                        _timeUntilGcdReady = GCD;
                        break;
                    }
                }
            }

            return;
        }

        var dir = _target.GlobalPosition - GlobalPosition;
        if (dir.IsZeroApprox())
        {
            return;
        }

        GlobalPosition += dir.Normalized() * Data.Stats.MovementSpeed * (float)delta;
    }

    public void TakeDamage(double amount)
    {
        _currentHealth -= amount;

        HealthBar.Value -= amount;

        if (_currentHealth <= 0.0)
        {
            CombatEvents.Instance.EmitUnitDied(this);
            QueueFree();
        }
    }

    private Unit? AcquireTarget()
    {
        var candidateTargets = GetTree().GetNodesInGroup("combatants").Cast<Unit>();

        Unit? closestUnit = null;
        var closestDistanceSq = Double.MaxValue;
        foreach (var unit in candidateTargets)
        {
            if (unit == this || unit.IsEnemy == this.IsEnemy)
            {
                continue;
            }

            var distanceSq = GlobalPosition.DistanceSquaredTo(unit.GlobalPosition);
            if (distanceSq < closestDistanceSq)
            {
                closestUnit = unit;
                closestDistanceSq = distanceSq;
            }
        }

        return closestUnit;
    }

    private bool IsTargetInRange()
    {
        return _target != null
            && GlobalPosition.DistanceSquaredTo(_target.GlobalPosition) < Data.Stats.AttackRangeSq;
    }
}
