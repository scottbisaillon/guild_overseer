using Godot;

public partial class PartySelectListItem : PanelContainer
{
    [Export]
    public StyleBoxFlat NormalStyle { get; set; } = null!;

    [Export]
    public StyleBoxFlat HoverStyle { get; set; } = null!;

    [Export]
    public StyleBoxFlat SelectedStyle { get; set; } = null!;

    public Label Label { get; set; } = null!;
    public CheckBox CheckBox { get; set; } = null!;

    private UnitData _data = null!;
    private bool _selected;

    [Signal]
    public delegate void CheckedEventHandler(UnitData data, bool newState);

    // Called when the node enters the scene tree for the first time.
    public override void _Ready()
    {
        Label = GetNode<Label>("%Label");
        CheckBox = GetNode<CheckBox>("%CheckBox");

        AddThemeStyleboxOverride("panel", NormalStyle);

        MouseEntered += () => AddThemeStyleboxOverride("panel", HoverStyle);
        MouseExited += () => AddThemeStyleboxOverride("panel", NormalStyle);
    }

    public override void _GuiInput(InputEvent @event)
    {
        if (@event is InputEventMouseButton { ButtonIndex: MouseButton.Left, Pressed: true })
        {
            _selected = !_selected;
            EmitSignalChecked(_data, _selected);
            CheckBox.ButtonPressed = _selected;
        }
    }

    public void Setup(UnitData data)
    {
        _data = data;
        Label.Text = data.DisplayName;
    }
}
