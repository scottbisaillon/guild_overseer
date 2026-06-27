namespace GuildOverseer.Services;

using System.Collections.Generic;
using GuildOverseer.Data;
using Microsoft.Xna.Framework.Content;

public class UnitRegistry
{
    private readonly Dictionary<string, UnitData> _members = [];

    public void Load(ContentManager content)
    {
        foreach (var m in content.Load<UnitData[]>("data/members"))
        {
            _members[m.Id] = m;
        }
    }

    public UnitData Get(string id) => _members[id];
}
