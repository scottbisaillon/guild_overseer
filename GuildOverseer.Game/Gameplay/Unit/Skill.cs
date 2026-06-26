namespace GuildOverseer.Gameplay;

using System;
using GuildOverseer.Data;
using GuildOverseer.Services;
using Microsoft.Xna.Framework;

public class Skill
{
    public required SkillData Data { get; init; }

    private float _timeUntilReady;

    public bool IsReady => _timeUntilReady <= 0.0f;

    public void Update(GameTime gameTime)
    {
        _timeUntilReady = Math.Max(
            0.0f,
            _timeUntilReady - (float)gameTime.ElapsedGameTime.TotalSeconds
        );
    }

    public void Execute(Unit source, Unit target, CombatEvents combat)
    {
        combat.DealDamage(source, target, Data.BaseDamage);
        _timeUntilReady = Data.Cooldown;
    }
}
