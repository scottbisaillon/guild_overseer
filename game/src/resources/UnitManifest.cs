using Godot;

namespace Game;

[GlobalClass]
public partial class UnitManifest : Resource
{
    [Export]
    public Godot.Collections.Array<UnitData> PartyMembers = [];

    [Export]
    public Godot.Collections.Array<UnitData> Enemies = [];
}
