namespace GuildOverseer.Data;

public class MemberData
{
    public required string Id;
    public required string Name;
    public required Stats Stats;

    public override string ToString() => Name;
}

public class Stats
{
    public required double MaxHealth;
    public required float MovementSpeed;
    public required float AttackRange;

    public float AttackRangeSq => AttackRange * AttackRange;
}
