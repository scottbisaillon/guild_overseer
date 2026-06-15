namespace GuildOverseer.Services;

using System;
using GuildOverseer.Gameplay;

public record DamageInfo(Unit Source, Unit Target, double Amount);

public class CombatEvents
{
    public event Action<DamageInfo>? DamageDealt;
    public event Action<Unit>? UnitDied;

    public void DealDamage(Unit source, Unit target, double amount)
    {
        var final = amount;
        var wasAlive = target.IsAlive;

        target.TakeDamage(final);

        DamageDealt?.Invoke(new DamageInfo(source, target, final));

        if (wasAlive && !target.IsAlive)
        {
            Console.WriteLine($"{target.MemberData.Name} died");
            UnitDied?.Invoke(target);
        }
    }
}
