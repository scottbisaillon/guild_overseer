namespace GuildOverseer.Gameplay.Systems;

using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using GuildOverseer.Gameplay;

public class DamageNumberSystem : QuerySystem<Position2D, DamageNumber>
{
    protected override void OnUpdate()
    {
        var buffer = CommandBuffer;
        Query.ForEachEntity(
            (ref Position2D pos, ref DamageNumber dn, Entity e) =>
            {
                dn.Elapsed += Tick.deltaTime;
                pos.Value += dn.Drift * Tick.deltaTime;
                if (dn.Elapsed >= dn.Lifetime)
                {
                    buffer.DeleteEntity(e.Id);
                }
            }
        );
    }
}
