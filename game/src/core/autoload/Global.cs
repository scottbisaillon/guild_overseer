using Godot;

namespace GuildOverseer.Core.Autoload;

public partial class Global : Node
{
    public static Global Instance { get; private set; } = null!;

    public override void _Ready()
    {
        Instance = this;
    }

    public void ExitApplication()
    {
        GetTree().Quit();
    }
}
