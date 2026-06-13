using Godot;

namespace GuildOverseer.Resources;

[GlobalClass]
public partial class UnitManifest : Resource
{
    [Export]
    public Godot.Collections.Array<UnitData> PartyMembers = [];

    [Export]
    public Godot.Collections.Array<UnitData> Enemies = [];
}
