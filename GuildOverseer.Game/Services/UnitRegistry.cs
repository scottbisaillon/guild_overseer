namespace GuildOverseer.Services;

using System.Collections.Generic;
using GuildOverseer.Data;
using Microsoft.Xna.Framework.Content;

public class UnitRegistry
{
    private readonly Dictionary<string, MemberData> _members = [];

    public void Load(ContentManager content)
    {
        foreach (var m in content.Load<MemberData[]>("data/members"))
        {
            _members[m.Id] = m;
        }
    }

    public MemberData Get(string id) => _members[id];
}
