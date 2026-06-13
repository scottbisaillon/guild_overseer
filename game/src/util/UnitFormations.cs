using System;
using System.Collections.Generic;
using Godot;

namespace GuildOverseer.Util;

public static class UnitFormations
{
    public static List<Vector2> Circle(Vector2 center, int total)
    {
        var positions = new List<Vector2>();

        for (int i = 0; i < total; i++)
        {
            var angle = i * (Math.Tau / total);
            positions.Add(center + Vector2.Up.Rotated((float)angle) * 50);
        }

        return positions;
    }
}
