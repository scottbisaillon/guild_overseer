using System;
using System.Linq;
using Godot;

namespace Game;

public partial class Unit : Node2D
{
    const double GCD = 1.0;

    private ColorRect Visuals { get; set; } = null!;
    private Node Skills { get; set; } = null!;
    private ProgressBar HealthBar { get; set; } = null!;

    public UnitData Data { get; set; } = null!;

    public bool IsEnemy { get; set; } = false;

    private Unit? _target;
    private double _currentHealth;

    private double _timeUntilGcdReady = 0.0;

    public override void _Ready()
    {
        AddToGroup("combatants");

        Visuals = GetNode<ColorRect>("ColorRect");
        Skills = GetNode<Node>("Skills");
        HealthBar = GetNode<ProgressBar>("%HealthBar");

        _currentHealth = Data.Stats.MaxHealth;

        if (IsEnemy)
        {
            Visuals.Color = Colors.Red;
        }
        else
        {
            Visuals.Color = Colors.Blue;
        }

        foreach (var skill in Data.Skills)
        {
            Skills.AddChild(SkillLibrary.Instance.CreateSkillFromData(skill));
        }

        Skills.AddChild(SkillLibrary.Instance.CreateSkillFromData(Data.BasicAttack));

        HealthBar.Value = Data.Stats.MaxHealth;
        HealthBar.MaxValue = Data.Stats.MaxHealth;
        HealthBar.Size = new Vector2(Visuals.Size.X, 4.0f);
        HealthBar.Position = new Vector2(
            -HealthBar.Size.X / 2,
            -(Visuals.Size.Y / 2) - 10 - HealthBar.Size.Y
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
