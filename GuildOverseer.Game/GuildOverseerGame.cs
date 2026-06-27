namespace GuildOverseer;

using GuildOverseer.Globals;
using GuildOverseer.Library;
using GuildOverseer.Scenes;
using GuildOverseer.Services;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Input;

public class GuildOverseerGame() : Core("GuildOverseer.Game", 1280, 720, false)
{
    protected override void Initialize()
    {
        Services.AddService(new ActiveDungeonService());

        var unitRegistry = new UnitRegistry();
        unitRegistry.Load(Content);
        Services.AddService(unitRegistry);

        var enemyRegistry = new EnemyRegistry();
        enemyRegistry.Load(Content);
        Services.AddService(enemyRegistry);

        var skillRegistry = new SkillRegistry();
        skillRegistry.Load(Content);
        Services.AddService(skillRegistry);

        Services.AddService(new CombatEvents());

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
        {
            Exit();
        }

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime) => base.Draw(gameTime);
}
