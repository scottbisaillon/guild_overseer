using System.Collections.Generic;
using Godot;
using GuildOverseer.Gameplay;
using GuildOverseer.Resources;

namespace GuildOverseer.Core.Autoload;

public partial class SkillRegistry : Node
{
    public static SkillRegistry Instance { get; set; } = default!;

    public Dictionary<string, SkillData> Skills = [];

    public override void _Ready()
    {
        Instance = this;

        var manifest = GD.Load<SkillManifest>("res://data/skill_manifest.tres");

        foreach (var skill in manifest.Skills)
        {
            Skills[skill.Id] = skill;
        }
    }

    public Skill CreateSkill(string id)
    {
        return new Skill(Skills[id]);
    }

    public Skill CreateSkillFromData(SkillData data)
    {
        return new Skill(data);
    }
}
