using System;
using Godot;
using GuildOverseer.Core.Autoload;
using GuildOverseer.Resources;

namespace GuildOverseer.Gameplay;

public partial class Skill(SkillData data) : Node
{
    public SkillData Data { get; set; } = data;

    private double TimeUntilReady = 0.0;

    public bool IsReady => TimeUntilReady <= 0.0;

    public override void _Process(double delta)
    {
        TimeUntilReady = Math.Max(0.0, TimeUntilReady - delta);
    }

    public void Trigger(Unit target)
    {
        target.TakeDamage(Data.BaseDamage);
        CombatEvents.Instance.EmitDamageDealt(target, Data.BaseDamage);
        TimeUntilReady = Data.Cooldown;
    }
}
