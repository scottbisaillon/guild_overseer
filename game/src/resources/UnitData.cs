using Godot;

namespace Game;

[GlobalClass]
public partial class UnitData : Resource
{
    [Export]
    public string Id { get; set; } = "";

    [Export]
    public string DisplayName { get; set; } = "";

    [Export]
    public UnitStats Stats { get; set; } = new();

    [Export]
    public SkillData BasicAttack { get; set; } = new();

    [Export]
    public Godot.Collections.Array<SkillData> Skills { get; set; } = [];
}
