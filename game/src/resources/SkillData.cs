using Godot;

namespace GuildOverseer.Resources;

[GlobalClass]
public partial class SkillData : Resource
{
    [Export]
    public string Id { get; set; } = "";

    [Export]
    public string DisplayName { get; set; } = "";

    [Export]
    public double BaseDamage { get; set; } = 0.0;

    [Export]
    public double Cooldown { get; set; } = 0.0;
}
