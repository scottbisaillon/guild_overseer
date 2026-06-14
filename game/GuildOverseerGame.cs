using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Scenes;
using GuildOverseer.Services;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

namespace GuildOverseer;

public class GuildOverseerGame() : Core("GuildOverseer", 1280, 720, false)
{
    protected override void Initialize()
    {
        Services.AddService(new ActiveDungeonService());

        var unitRegistry = new UnitRegistry();
        unitRegistry.Load(Content);
        Services.AddService(unitRegistry);

        base.Initialize();
    }

    protected override void LoadContent()
    {
        base.LoadContent();

        ChangeScene(new TitleScene());
    }

    protected override void Update(GameTime gameTime)
    {
        if (
            GamePad.GetState(PlayerIndex.One).Buttons.Back == ButtonState.Pressed
            || Keyboard.GetState().IsKeyDown(Keys.Escape)
        )
            Exit();

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        base.Draw(gameTime);
    }
}
