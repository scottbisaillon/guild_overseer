using Godot;

namespace GuildOverseer.Levels;

public abstract partial class BaseLevel : Node2D
{
    public abstract Vector2 GetPartySpawnLocation();
}
