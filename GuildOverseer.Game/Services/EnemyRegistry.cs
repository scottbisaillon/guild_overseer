namespace GuildOverseer.Services;

using System.Collections.Generic;
using GuildOverseer.Data;
using Microsoft.Xna.Framework.Content;

public class EnemyRegistry
{
    private readonly Dictionary<string, UnitData> _enemies = [];

    public void Load(ContentManager content)
    {
        foreach (var e in content.Load<UnitData[]>("data/enemies"))
        {
            _enemies[e.Id] = e;
        }
    }

    public UnitData Get(string id) => _enemies[id];
}
