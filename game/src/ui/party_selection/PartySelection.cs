using Godot;
using GuildOverseer.Core;
using GuildOverseer.Core.Autoload;
using GuildOverseer.Core.Constants;

namespace GuildOverseer.Ui;

public partial class PartySelection : Control
{
    [Export]
    public PackedScene PartySelectListItem = default!;

    public VBoxContainer PartyMemberList = default!;
    public Label TotalSelectedLabel = default!;
    public Button StartButton = default!;

    public override void _Ready()
    {
        PartyMemberList = GetNode<VBoxContainer>("%PartyMemberList");
        TotalSelectedLabel = GetNode<Label>("%TotalSelectedLabel");
        StartButton = GetNode<Button>("%Button");

        ActiveDungeonManager.Instance.TotalPartyMembersSelectedChanged +=
            OnTotalPartyMembersSelectedChanged;

        StartButton.Pressed += OnStartClicked;

        foreach (var (id, member) in UnitRegistry.Instance.PartyMembers)
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
        MainGame.Instance.ClearScreen();
        MainGame.Instance.LoadLevel(Scenes.Levels.TestLevel);
    }
}
