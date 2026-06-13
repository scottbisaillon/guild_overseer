using Godot;

namespace Game;

[GlobalClass]
public partial class SkillManifest : Resource
{
    [Export]
    public Godot.Collections.Array<SkillData> Skills = [];
}
