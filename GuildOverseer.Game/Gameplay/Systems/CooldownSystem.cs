namespace GuildOverseer.Gameplay.Systems;

using Friflo.Engine.ECS;
using Friflo.Engine.ECS.Systems;
using GuildOverseer.Gameplay;

public class CooldownSystem : QuerySystem<SkillLoadout>
{
    protected override void OnUpdate()
    {
        Query.ForEachEntity(
            (ref SkillLoadout loadout, Entity entity) =>
            {
                loadout.BasicAttack.Tick(Tick.deltaTime);
                foreach (var skill in loadout.Skills)
                {
                    skill.Tick(Tick.deltaTime);
                }
            }
        );
    }
}
