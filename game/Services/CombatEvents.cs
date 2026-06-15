using System;
using System.Runtime.ConstrainedExecution;
using GuildOverseer.Gameplay;

namespace GuildOverseer.Services;

public record DamageInfo(Unit Source, Unit Target, double Amount);

public class CombatEvents
{
    public event Action<DamageInfo>? DamageDealt;
    public event Action<Unit>? UnitDied;

    public void DealDamage(Unit source, Unit target, double amount)
    {
        var final = amount;
        bool wasAlive = target.IsAlive;

        target.TakeDamage(final);

        DamageDealt?.Invoke(new DamageInfo(source, target, final));

        Console.WriteLine(
            $"{source.MemberData.Name} damaged {target.MemberData.Name} for {final} damage"
        );

        if (wasAlive && !target.IsAlive)
        {
            Console.WriteLine($"{target.MemberData.Name} died");
            UnitDied?.Invoke(target);
        }
    }
}
