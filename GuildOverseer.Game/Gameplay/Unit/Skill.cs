namespace GuildOverseer.Gameplay;

using System;
using GuildOverseer.Data;

public class Skill
{
    public required SkillData Data { get; init; }

    public float CooldownRemaining;

    public bool IsReady => CooldownRemaining <= 0.0f;

    public void Tick(float dt) => CooldownRemaining = Math.Max(0.0f, CooldownRemaining - dt);

    public void Reset() => CooldownRemaining = Data.Cooldown;
}
