using Game;
using Godot;

[GlobalClass]
public partial class UnitData : Resource
{
    [Export]
    public string Id { get; set; }

    [Export]
    public string DisplayName { get; set; }

    [Export]
    public UnitStats Stats { get; set; }

    [Export]
    public SkillData BasicAttack { get; set; }

    [Export]
    public Godot.Collections.Array<SkillData> Skills { get; set; } = [];

    public UnitData()
        : this("", "", new(), new(), []) { }

    public UnitData(
        string id,
        string displayName,
        UnitStats stats,
        SkillData basicAttack,
        Godot.Collections.Array<SkillData> skills
    )
    {
        Id = id;
        DisplayName = displayName;
        Stats = stats;
        BasicAttack = basicAttack;
        Skills = skills;
    }
}
