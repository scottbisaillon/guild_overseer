using System;
using Game;
using Godot;

public partial class PartySelection : Control
{
    [Export]
    public PackedScene PartySelectListItem = null!;

    public VBoxContainer PartyMemberList = null!;
    public Label TotalSelectedLabel = null!;
    public Button StartButton = null!;

    public override void _Ready()
    {
        PartyMemberList = GetNode<VBoxContainer>("%PartyMemberList");
        TotalSelectedLabel = GetNode<Label>("%TotalSelectedLabel");
        StartButton = GetNode<Button>("%Button");

        ActiveDungeonManager.Instance.TotalPartyMembersSelectedChanged +=
            OnTotalPartyMembersSelectedChanged;

        StartButton.Pressed += OnStartClicked;

        foreach (var (id, member) in UnitLibrary.Instance.PartyMembers)
        {
            var item = PartySelectListItem.Instantiate<PartySelectListItem>();
            PartyMemberList.AddChild(item);
            item.Setup(member);
            item.Checked += (data, state) =>
            {
                ActiveDungeonManager.Instance.ToggleMember(data.Id);
            };
        }
    }

    public void OnTotalPartyMembersSelectedChanged(int newTotal)
    {
        TotalSelectedLabel.Text = $"{newTotal} / 4 Party Members Selected";
        StartButton.Disabled = newTotal == 0;
    }

    public void OnStartClicked()
    {
        GetTree().ChangeSceneToFile("res://src/levels/test_level/TestLevel.tscn");
    }
}
