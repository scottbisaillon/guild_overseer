namespace GuildOverseer.Gameplay.Systems;

using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using GuildOverseer.Gameplay;

public class DeathSystem : QuerySystem<Health>
{
    protected override void OnUpdate()
    {
        var buffer = CommandBuffer;
        Query.ForEachEntity(
            (ref Health health, Entity entity) =>
            {
                if (health.Current <= 0f)
                {
                    buffer.DeleteEntity(entity.Id);
                }
            }
        );
    }
}
