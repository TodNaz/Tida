/++

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.each;

export:
import tida.vector;

enum WithoutParallel = 0; /// Without parallel operation.
enum WithParallel = 1; /// With parallel operation.

/++
The operation of traversing a rectangle.

Params:
    Type = Type operation.
    width = Width rectangle.
    height = Height rectangle.
    beginX = Begin x-axis position.
    beginY = Begin y-axis position. 
+/
auto Coord(int Type = WithoutParallel)(uint width,uint height,int beginX = 0,int beginY = 0) @safe
{
    import std.range : iota;
    import std.parallelism : parallel;

    static if (Type == WithoutParallel)
    {
        return (int delegate(ref int x, ref int y) @safe dg) @safe 
        {
            for(int ix = beginX; ix < width; ix++)
            {
                for(int iy = beginY; iy < height; iy++)
                {
                    dg(ix,iy);
                }
            }

            return 0;
        };
    }else
    static if (Type == WithParallel)
    {
        return (int delegate(ref int x,ref int y) @safe dg) @trusted 
        {
            import std.parallelism, std.range;

            foreach(ix; parallel(iota(beginX, width)))
            {
                foreach(iy; parallel(iota(beginY, height)))
                {
                    int dx = ix;
                    int dy = iy;

                    dg(dx,dy);
                }
            }

            return 0;
        };
    }
}

auto Line(Vecf begin, Vecf end) @safe
{
    import std.math : abs;

    return (int delegate(ref int x,ref int y) @safe dh) @safe {
        int x1 = cast(int) begin.x;
        int y1 = cast(int) begin.y;
        const x2 = cast(int) end.x;
        const y2 = cast(int) end.y;

        const deltaX = abs(x2 - x1);
        const deltaY = abs(y2 - y1);
        const signX = x1 < x2 ? 1 : -1;
        const signY = y1 < y2 ? 1 : -1;

        int error = deltaX - deltaY;

        while (x1 != x2 || y1 != y2) {
            dh(x1,y1);

            const error2 = error * 2;

            if (error2 > -deltaY) {
                error -= deltaY;
                x1 += signX;
            }

            if (error2 < deltaX) {
                error += deltaX;
                y1 += signY;
            }
        }

        return 0;
    };
}

auto LineNoThrowImpl(Vecf begin,Vecf end) @safe nothrow pure
{
    import std.math : abs;

    return (int delegate(ref int x,ref int y) @safe nothrow pure dh) @safe nothrow pure {
        int x1 = cast(int) begin.x;
        int y1 = cast(int) begin.y;
        const x2 = cast(int) end.x;
        const y2 = cast(int) end.y;

        const deltaX = abs(x2 - x1);
        const deltaY = abs(y2 - y1);
        const signX = x1 < x2 ? 1 : -1;
        const signY = y1 < y2 ? 1 : -1;

        int error = deltaX - deltaY;

        while(x1 != x2 || y1 != y2) {
            dh(x1,y1);

            const error2 = error * 2;

            if(error2 > -deltaY) {
                error -= deltaY;
                x1 += signX;
            }

            if(error2 < deltaX) {
                error += deltaX;
                y1 += signY;
            }
        }

        return 0;
    };
}
