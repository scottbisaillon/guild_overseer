namespace GuildOverseer.Gameplay.Systems;

using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using GuildOverseer.Gameplay;
using Microsoft.Xna.Framework;

public class TargetSystem : QuerySystem
{
    private ArchetypeQuery<Position2D> _units = default!;
    private ArchetypeQuery<Position2D> _targetAllies = default!;
    private ArchetypeQuery<Position2D> _targetEnemies = default!;

    protected override void OnAddStore(EntityStore store)
    {
        _units = store
            .Query<Position2D>()
            .AllTags(Tags.Get<UnitTag>())
            .WithoutAnyComponents(ComponentTypes.Get<Target>());
        _targetAllies = store.Query<Position2D>().AllTags(Tags.Get<Ally>());
        _targetEnemies = store.Query<Position2D>().AllTags(Tags.Get<Enemy>());
    }

    protected override void OnUpdate()
    {
        var buffer = CommandBuffer;
        foreach (var entity in _units.Entities)
        {
            var pos = entity.GetComponent<Position2D>().Value;
            Entity? nearest = null;
            var best = float.MaxValue;

            var candidates = entity.Tags.Has<Ally>() ? _targetEnemies : _targetAllies;

            foreach (var candidate in candidates.Entities)
            {
                if (entity == candidate)
                {
                    continue;
                }

                var candidatePos = candidate.GetComponent<Position2D>().Value;

                var distSq = Vector2.DistanceSquared(pos, candidatePos);
                if (distSq < best)
                {
                    best = distSq;
                    nearest = candidate;
                }
            }

            if (nearest != null)
            {
                buffer.AddComponent(entity.Id, new Target { Value = (Entity)nearest });
            }
        }
    }
}
