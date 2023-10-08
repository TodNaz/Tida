/++
Module for working with mathematical angles. Contains the translation of
measurement systems, work in the form of determining the angle,
vector rotation and more.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.angle;

import std.math : PI;

enum Radians = 0; /// Radians
enum Degrees = 1; /// Degrees
enum Turns = 2; /// Turns
enum Gons = 3; /// Gons

/++
Maximum angle value.

Params:
    Type = Type angle.
    
Example:
---
auto maxRad = max!Radians;
---
+/
template max(ubyte Type)
{
    static if (Type == Radians) 
    {
        enum max = 2 * PI;
    }else
    static if (Type == Degrees)
    {
        enum max = 360.0f;
    }else
    static if (Type == Turns)
    {
        enum max = 1.0f;
    }else
    static if (Type == Gons)
    {
        enum max = 400.0f;
    }
}

alias perigon = max; /// perigon

/++
Returns the right angle.

Params:
    Type = Type angle.
    
Example:
---
auto riaRad = rightAngle!Radians;
---
+/
template rightAngle(ubyte Type)
{
    static if (Type == Radians)
    {
        enum rightAngle = PI / 2;
    }else
    static if (Type == Degrees)
    {
        enum rightAngle = 90.0f;
    }else
    static if (Type == Turns)
    {
        enum rightAngle = 1 / 4;
    }else
    static if (Type == Gons)
    {
        enum rightAngle = 100;
    }else
        static assert(null, "Unknown angle type!");
}

/++
Returns straight angle.

Params:
    Type = Type angle.
    
Example:
---
auto strRad = straight!Radians;
---
+/
template straight(ubyte Type)
{   
    static if (Type == Radians)
    {
        enum straight = PI;
    }else
    static if (Type == Degrees) 
    {
        enum straight =  180;
    }else
    static if (Type == Turns)
    {
        enum straight =  0.5;
    }else
    static if (Type == Gons)
    {
        enum straight =  200;
    }else
        static assert(null,"Unknown angle type!");
}

/++
Translate one system of angles into another.

Params:
    What = What to translate.
    In = What to translate.
    value = Value.

Example:
---
from(Degrees,Radians)(45);
---
+/
float conv(ubyte What,ubyte In)(float value) @safe nothrow pure
{
    import std.math;
    
    static if (What == In) return value;
    else
    static if (In == Turns) return value / max!What;
    else
    static if (What == Turns) return max!In * value;
    else
    static if (What == Radians)
    {
        static if (In == Degrees)
        {
            return value * 180 / PI;
        }else
        static if (In == Gons)
        {
            return value * 200 / PI;
        }
    }else
    static if (What == Degrees)
    {
        static if (In == Radians)
        {
            return value * PI / 180;
        }else
        static if (In == Gons)
        {
            return value * 200 / 180;
        }
    }else
    static if (What == Gons)
    {
        static if (In == Radians)
        {
            return value * PI / 200;
        }else
        static if (In == Degrees)
        {
            return value * 180 / 200;
        }
    }
}

alias from = conv; // old name saved.

/++
Converts degrees to radians.

See_Also:
    $(LREF conv)
+/
alias degToRad = conv!(Degrees, Radians);

/++
Convert radians to degrees.


See_Also:
    $(LREF conv)
+/
alias radToDeg = conv!(Radians, Degrees);

/++
Brings the angle back to normal.

Params:
    Type = Angle type.
    angle = Angle.

Example:
---
assert(375.minimize!Degrees == 15);
    ---
+/
float minimize(ubyte Type)(float angle) @safe nothrow pure
{
    int k = cast(int) (angle / max!Type);
    float sign = angle >= 0 ? 1 : -1;

    return angle - ((max!Type * cast(float) k) * sign);
}

unittest
{
    assert(minimize!Degrees(361) == 1);
    assert(minimize!Degrees(470) == (470 - 360));
    assert(minimize!Degrees(848) == 128);
}

/++
Finds the angle between two angel's. Accepted in any angle change systems.

Params:
    a = First angle.
    b = Second angle.
    
Returns: Angle between two angel's.
+/
float betweenAngle(float a, float b) @safe nothrow pure
{
    return (a + b) / 2;
}

unittest
{
    assert(max!Radians.from!(Radians,Degrees) == (max!Degrees));
    assert(max!Degrees.from!(Degrees,Gons) == (max!Gons));
    assert(max!Gons.from!(Gons,Turns) == (max!Turns));
    
    assert(rightAngle!Radians.from!(Radians,Degrees) == (rightAngle!Degrees));
    assert(rightAngle!Degrees.from!(Degrees,Gons) == (rightAngle!Gons));
}

import tida.vector;

/++
Returns the angle between two vectors in radians.

Params:
    a = First point.
    b = Second point.
    
Returns: Angle in radians.

To convert, for example, to degrees, use the function like this:
---
pointDirection(...).from!(Radians,Degrees);
    ---
+/
T pointDirection(T)(inout Vector!T a, inout Vector!T b) @safe nothrow pure
{
    import std.math : atan2;

    auto result = atan2(b.y - a.y, b.x - a.x);
    return result;
}

/++
Rotates the point by the specified number of degrees.

Params:
    vec = Point.
    angle = Angle of rotation.
    center = Center of rotation.
+/
Vecf rotate(Vecf vec, float angle, Vecf center = vecf(0, 0)) @safe nothrow pure
{
    import std.math : sin, cos;

    float ca = cos(angle);
    float sa = sin(angle);

    Vecf result;

    vec -= center;

    result.x = vec.x * ca - vec.y * sa;
    result.y = vec.x * sa + vec.y * ca;

    return result + center;
}

/++
Convert angle to direction vector. Use when moving an object at a given angle.

Params:
    angle = Angle.

Example:
---
Vecf vecd = vectorDirection(45.from!(Degrees,Radians));
position += vecd * 5; // Move the object 45 degrees at a given speed.
    ---
+/
Vector!T vectorDirection(T)(inout T angle) @safe nothrow pure
{
    import std.math : cos, sin;

    return vec!T(cos(angle), sin(angle));
}
