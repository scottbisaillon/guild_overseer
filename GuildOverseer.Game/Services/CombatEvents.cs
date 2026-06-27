namespace GuildOverseer.Services;

using System;
using Friflo.Engine.ECS;

public readonly record struct DamageInfo(Entity Source, Entity Target, double Amount);

public class CombatEvents
{
    public event Action<DamageInfo>? DamageDealt;

    public void EmitDamageDealt(DamageInfo info) => DamageDealt?.Invoke(info);
}
