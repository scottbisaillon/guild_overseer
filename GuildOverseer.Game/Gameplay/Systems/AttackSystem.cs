namespace GuildOverseer.Gameplay.Systems;

using System;
using System.Collections.Generic;
using System.Linq;
using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using GuildOverseer.Gameplay;
using GuildOverseer.Services;
using Microsoft.Xna.Framework;

public class AttackSystem : QuerySystem<Position2D, Target, GlobalCooldown, SkillLoadout>
{
    private readonly CombatEvents _combat;

    private readonly List<DamageInfo> _pending = [];

    public AttackSystem(CombatEvents combat)
    {
        _combat = combat;
        Filter.AnyComponents(ComponentTypes.Get<Target>());
    }

    protected override void OnUpdate()
    {
        _pending.Clear();
        Query.ForEachEntity(
            (
                ref Position2D pos,
                ref Target target,
                ref GlobalCooldown gcd,
                ref SkillLoadout loadout,
                Entity entity
            ) =>
            {
                gcd.Remaining = Math.Max(0f, gcd.Remaining - Tick.deltaTime);

                if (gcd.Remaining > 0f)
                {
                    return;
                }

                var memberData = entity.GetComponent<MemberDataComponent>().Value;
                var targetPos = target.Value.GetComponent<Position2D>().Value;

                if (
                    !(
                        Vector2.DistanceSquared(pos.Value, targetPos)
                        < memberData.Stats.AttackRangeSq
                    )
                )
                {
                    return;
                }

                ref var targetHealth = ref target.Value.GetComponent<Health>();

                var skill = loadout.Skills.FirstOrDefault(s => s.IsReady) ?? loadout.BasicAttack;
                _pending.Add(
                    new DamageInfo
                    {
                        Source = entity,
                        Target = target.Value,
                        Amount = skill.Data.BaseDamage,
                    }
                );

                targetHealth.Current -= skill.Data.BaseDamage;

                skill.Reset();

                gcd.Remaining = GlobalCooldown.GCD;
            }
        );

        foreach (var pending in _pending)
        {
            _combat.EmitDamageDealt(pending);
        }
    }
}
