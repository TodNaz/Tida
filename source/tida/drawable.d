/++
A module for rendering your own objects on the canvas.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.drawable;

export:

/++
The interface for normal rendering by coordinates.
All properties are specified in the constructor at best.

Example:
---
class Rectangle : IDrawable
{
    export
    {
        uint width, height;
        Color!ubyte color;
    }

    this(uint width,uint height,Color!ubyte color);

    override void draw(IRenderer renderer,Vecf position) @safe
    {
        renderer.rectangle(position,width,height,color,true);
    }
}
---
+/
interface IDrawable
{
    import tida.vector;
    import tida.render;

    /// draw object implemetation
    void draw(IRenderer renderer, Vecf position) @trusted;
}

/++
Interface for advanced object rendering.
It contains both the rotation of the object and such a property as size.
+/
interface IDrawableEx
{
    import tida.vector;
    import tida.render;
    import tida.color;

    /// draw object implemetation
    void drawEx(IRenderer renderer, Vecf position, float angle, Vecf center,
                Vecf size, ubyte alpha, Color!ubyte color) @trusted;
}
