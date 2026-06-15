namespace GuildOverseer.Services;

using System.Collections.Generic;
using GuildOverseer.Data;
using Microsoft.Xna.Framework.Content;

public class SkillRegistry
{
    private readonly Dictionary<string, SkillData> _skills = [];

    public void Load(ContentManager content)
    {
        foreach (var s in content.Load<SkillData[]>("data/skills"))
        {
            _skills[s.Id] = s;
        }
    }

    public SkillData Get(string id) => _skills[id];
}
