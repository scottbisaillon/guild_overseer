using System.Collections.Generic;
using Godot;

namespace Game;

public partial class ActiveDungeonManager : Node
{
    public static ActiveDungeonManager Instance { get; private set; } = null!;

    public List<string> SelectedMemberIds { get; set; } = [];

    [Signal]
    public delegate void TotalPartyMembersSelectedChangedEventHandler(int count);

    public override void _Ready()
    {
        Instance = this;
    }

    public void ToggleMember(string id)
    {
        if (!SelectedMemberIds.Remove(id))
        {
            SelectedMemberIds.Add(id);
        }

        EmitSignalTotalPartyMembersSelectedChanged(SelectedMemberIds.Count);
    }

    public bool IsMemberSelected(string id) => SelectedMemberIds.Contains(id);
}
