namespace GuildOverseer.Gameplay;

using System.Collections.Generic;
using Friflo.Engine.ECS;
using GuildOverseer.Data;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

public struct UnitTag : ITag { }

public enum UnitType
{
    [MapTag<Ally>]
    Ally,

    [MapTag<Enemy>]
    Enemy,
}

public struct Ally : ITag { }

public struct Enemy : ITag { }

[ComponentKey("sprite-component")]
public struct Sprite : IComponent
{
    public Texture2D Texture;
    public Color Color;
    public int Size;
}

[ComponentKey("pos2d")]
public struct Position2D : IComponent
{
    public Vector2 Value = Vector2.Zero;

    public Position2D() { }
}

public struct Target : ILinkComponent
{
    public Entity Value;

    public readonly Entity GetIndexedValue() => Value;
}

public struct GlobalCooldown : IComponent
{
    public const float GCD = 1.0f;
    public float Remaining;
}

public struct CombatStats : IComponent
{
    public float MoveSpeed;
    public float AttackRangeSq;
}

public struct Health : IComponent
{
    public float Current;
}

public struct SkillLoadout : IComponent
{
    public Skill BasicAttack;
    public List<Skill> Skills;
}

public struct DamageNumber : IComponent
{
    public string Text;
    public Vector2 Drift;
    public float Lifetime;
    public float Elapsed;
}
