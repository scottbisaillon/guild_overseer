namespace GuildOverseer.Gameplay.Systems;

using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using GuildOverseer.Gameplay;
using Microsoft.Xna.Framework;

public class MoveSystem : QuerySystem<Position2D, Target, CombatStats>
{
    protected override void OnUpdate()
    {
        Query.ForEachEntity(
            (ref Position2D pos, ref Target target, ref CombatStats combatStats, Entity entity) =>
            {
                var targetPos = target.Value.GetComponent<Position2D>().Value;

                if (Vector2.DistanceSquared(pos.Value, targetPos) < combatStats.AttackRangeSq)
                {
                    return;
                }

                var dir = targetPos - pos.Value;

                if (dir.LengthSquared() > 0.0001f)
                {
                    dir.Normalize();
                    pos.Value += dir * combatStats.MoveSpeed * Tick.deltaTime;
                }
            }
        );
    }
}
