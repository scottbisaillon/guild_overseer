namespace GuildOverseer.Globals;

using System.Collections.Generic;

public sealed record LevelOption(string Id, string Name)
{
    public override string ToString() => Name;
}

public class ActiveDungeonService
{
    public const int MAX_PARTY_SIZE = 4;
    public LevelOption SelectedRun { get; private set; } = default!;

    public readonly List<string> Party = [];

    public int SelectedMembersCount => Party.Count;

    public bool CanStart => Party.Count > 0;

    public void SelectLevel(LevelOption level) => SelectedRun = level;

    public bool IsMemberSelected(string memberId) => Party.Contains(memberId);

    public void SetParty(List<string> ids)
    {
        Party.Clear();
        Party.AddRange(ids);
    }

    public void ToggleMemberSelection(string memberId)
    {
        if (Party.Remove(memberId))
        {
            return;
        }

        if (Party.Count < MAX_PARTY_SIZE)
        {
            Party.Add(memberId);
        }
    }
}
