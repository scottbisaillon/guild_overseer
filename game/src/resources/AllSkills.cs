using Godot;

namespace Game;

[GlobalClass]
public partial class AllSkills : Resource
{
    [Export]
    public Godot.Collections.Array<SkillData> SkillsList = [];

    public AllSkills()
        : this([]) { }

    public AllSkills(Godot.Collections.Array<SkillData> skills)
    {
        SkillsList = skills;
    }
}
