using System.Collections.Generic;
using Godot;

namespace Game;

public partial class SkillLibrary : Node
{
    public static SkillLibrary Instance { get; set; } = null!;

    public Dictionary<string, SkillData> Skills = [];

    public override void _Ready()
    {
        Instance = this;

        var allSkills = GD.Load<AllSkills>("res://data/all_skills.tres");

        foreach (var skill in allSkills.SkillsList)
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
