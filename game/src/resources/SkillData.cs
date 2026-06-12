using Godot;

namespace Game;

[GlobalClass]
public partial class SkillData : Resource
{
    [Export]
    public string Id;

    [Export]
    public string DisplayName;

    [Export]
    public double BaseDamage;

    [Export]
    public double Cooldown;

    public SkillData()
        : this("", "", 0, 0) { }

    public SkillData(string id, string displayName, double baseDamage, double cooldown)
    {
        Id = id;
        DisplayName = displayName;
        BaseDamage = baseDamage;
        Cooldown = cooldown;
    }
}
