using Godot;

namespace GuildOverseer.Resources;

[GlobalClass]
public partial class SkillManifest : Resource
{
    [Export]
    public Godot.Collections.Array<SkillData> Skills = [];
}
