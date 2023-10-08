/++
This module describes shapes for drawing, 
checking and other things related to the work of shapes.

Forms are of the following types:
* `Unknown` - Forms are of the following types:
* `Point` - Dot. The simplest of the simplest forms. Only origin parameters are valid.
* `line` - More complex form. Has the origin and the end of the coordinates of its two points. 
           By default, this is a line. 
* 'rectangle' - Rectangle shape. By default, such a rectangle is considered to be solid.
* `circle` - Circle shape. By default, it is considered to be solid.
* `triangle` - Triangle shape. It is believed to be solid.
* `multi` - A shape that combines several shapes, which will eventually give a single shape.
    Here you can, for example, create a non-solid polygon:
    ---
    /*
        Such a rectangle can also be created using the function
        `Shape.RectangleLine(begin,end)`.
    */
    auto rectangle_nonSolid = Shape.Multi([
        Shape.Line(Vecf(0,0),Vecf(32,0)),
        Shape.Line(Vecf(32,0),Vecf(32,32)),
        Shape.Line(Vecf(0,0),Vecf(0,32)),
        Shape.Line(Vecf(0,32),Vecf(32,32))
    ], Vecf(0,0));
    ---

All such types are specified in enum `ShapeType`.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.shape;

import std.traits;

/++
Shape type.
+/
enum ShapeType
{
    unknown, /// Unknown
    point, /// Point
    line, /// Line
    rectangle, /// Rectangle
    circle, /// Circle
    triangle, /// Triangle
    roundrect, /// Roundrect
    polygon, /// Polygon
    multi /// Several shapes in one.
}

/++
Figure description structure.
+/
struct Shape(T : float)
if (isNumeric!T && isMutable!T && isSigned!T)
{
    import tida.vector;

    alias Type = T;

public:
    T _radius;
    Vector!T _trType;
    Vector!T _begin;
    Vector!T _end;

export:
    ShapeType type; /// Shape type
    Shape!T[] shapes; /++ A set of figures. Needed for the type when you need 
                        to make one shape from several. +/
    Vector!T[] data; /// Polygon data

    string toString() @safe
    {
        import std.conv : to;
        import std.algorithm;

        if(type == ShapeType.point) {
            return "Shape.Point("~begin.to!string~")";
        }else
        if(type == ShapeType.line) {
            return "Shape.Line(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.rectangle) {
            return "Shape.Rectangle(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.circle) {
            return "Shape.Circle(position: "~begin.to!string~", radius: "~radius.to!string~")";
        }else 
        if(type == ShapeType.triangle) {
            return "Shape.Triangle(0: "~vertexs[0].to!string~", 1:"~vertexs[1].to!string~
                ", 2:"~vertexs[2].to!string~")";
        }else
        if(type == ShapeType.multi) {
            string strData;

            foreach(e; shapes)
                strData ~= e.toString ~ (e == shapes[$-1] ? "" : ",") ~"\n";

            return "Shape.Multi(position: "~begin.to!string~", shapes: [\n" ~ strData ~ "])";

        }else
        if(type == ShapeType.polygon) {
            string strData;

            foreach(e; data)
                strData ~= e.to!string ~ (e == data[$-1] ? "" : ",") ~ "\n";

            return "Shape.Polygon(position: "~begin.to!string~", points: [\n" ~ strData ~ "])";
        }

        return "Shape.Unknown()";
    }

    /++
    Converting a form to another form of its presentation.

    Params:
        R = What to convention?

    Example:
    ---
    Vecf[][] points = myPolygon.to!Vecf[][];
    ---
    +/
    R to(R)()
    {
        static if (is(R : Vector!T))
        {
            return begin;
        }else
        static if (is(R : Vector!T[]))
        {
            if (type == ShapeType.point || type == ShapeType.circle)
            {
                return [begin];
            }else
            if (type == ShapeType.line || type == ShapeType.rectangle)
            {
                return [begin, end];
            }else
            if (type == ShapeType.triangle)
            {
                return [this.vertex!0,this.vertex!1,this.vertex!2];
            }else
            if (type == ShapeType.multi)
            {
                Vector!(T)[] temp;
                foreach (shape; shapes)
                {
                    temp ~= this.to!R;
                }
                return temp;
            }

            return [];
        }else
        static if (is(R : Vector!T[][]))
        {
            if (type != ShapeType.unknown)
            {
                if (type != ShapeType.multi)
                {
                    return [to!(Vector!T[])];
                }else
                {
                    Vector!T[][] temp;
                    foreach (shape; shapes)
                    {
                        temp ~= this.to!(Vector!T[]);
                    }
                }
            }
        }else
        static if (is(R : string))
        {
            return toString();
        }
    }

@safe nothrow pure:
    /// The beginning of the figure.
    @property Vector!T begin() inout
    {
        return _begin;
    }

    /// The end of the figure.
    @property Vector!T end() inout
    in(type != ShapeType.point && type != ShapeType.circle && type != ShapeType.polygon,
    "This shape does not support end coordinates!")
    do
    {
        return _end;
    }

    /++
    Move shape
    +/
    void move(Vector!T pos)
    {
        _begin = _begin + pos;

        if(type == ShapeType.line || type == ShapeType.rectangle) {
            _end = _end + pos;
        }
    }

    /// The beginning of the figure.
    @property Vector!T begin(Vector!T vec)
    {
        return _begin = vec;
    }

    /// The end of the figure.
    @property Vector!T end(Vector!T vec) @safe nothrow pure
    in(type != ShapeType.point && type != ShapeType.circle && type != ShapeType.polygon,
        "This shape does not support end coordinates!")
    do
    {
        return _end = vec;
    }

    /// The beginning of the figure along the x-axis.
    @property T x() inout
    {
        return begin.x;
    }

    /// The beginning of the figure along the y-axis.
    @property T y() inout
    {
        return begin.y;
    }

    /// The beginning of the figure along the x-axis.
    @property T x(T value)
    {
        return begin.x = value;
    }

    /// The beginning of the figure along the y-axis.
    @property T y(T value)
    {
        return begin.y = value;
    }
    
    /// The end of the figure along the x-axis.
    @property T endX() inout
    {
        return end.x;
    }

    /// The end of the figure along the y-axis.
    @property T endY() inout
    {
        return end.y;
    }

    alias left = x; /// Rectangle left
    alias right = endX; /// Rectangle right
    alias top = y; /// Rectangle top
    alias bottom = endY; /// Rectange bottom

    /// The radius the figure.
    @property T radius() inout
    in(type == ShapeType.circle || type == ShapeType.roundrect,"This is not a circle!")
    do
    {
        return _radius;
    }

    /// ditto
    @property T radius(T value)
    in(type == ShapeType.circle || type == ShapeType.roundrect,"This is not a circle!")
    do
    {
        return _radius = value;
    }

    /// The top of the triangle.
    @property Vector!T vertex(uint num)() inout
    in
    {
        assert(type == ShapeType.triangle,"This is not a triangle!");
    }do
    {
        static assert(num < 3,"The triangle has only three vertices! (0 .. 2)");

        static if(num == 0)
            return begin;
        else
        static if(num == 1)
            return end;
        else
        static if(num == 2)
            return _trType;
    }

    /// Shape width
    @property T width() inout
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        return end.x - begin.x;
    }

    /// Shape height
    @property T height() inout
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        return end.y - begin.y;
    }

    /// Shape width
    @property T width(T value)
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        _end = begin + Vector!T(value,height);
        
        return value;
    }

    /// Shape height
    @property T height(T value)
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        _end = begin + Vector!T(width, value);
        
        return value;
    }

    /// The top of the triangle.
    @property Vector!T[] vertexs() inout
    {
        return [begin, end, _trType];
    }

    /// ditto
    @property void vertex(uint num)(Vector!T value)
    in
    {   
        assert(type == ShapeType.triangle,"This is not a triangle!");
    }do
    {
        static assert(num < 3,"The triangle has only three vertices! (0 .. 2)");

        static if(num == 0)
            begin = value;
        else
        static if(num == 1)
            end = value;
        else
        static if(num == 2)
            _trType = value;
    }

    /// Line length.
    @property T length() inout
    in(type == ShapeType.line,"This is not a line!")
    do
    {
        import std.math : sqrt;

        auto distX = begin.x - end.x;
        auto distY = begin.y - end.y;

        return sqrt((distX * distX) + (distY * distY));
    }

    /// Line length.
    @property void length(T value)
    in(type == ShapeType.line,"This is not a line!")
    do
    {
        import tida.angle;

        auto dir = begin.pointDirection(end);

        end = (vectorDirection(dir) * value);
    }
    
    @property Vector!T calculateSize()
    {
        switch (type)
        {
            case ShapeType.point:
                return vec!T(1, 1);
                
            case ShapeType.line:
                return abs(end - begin);
                
            case ShapeType.rectangle:
                return abs(end - begin);
                
            case ShapeType.circle:
                return (begin + vec!T(radius, radius) * 2) - begin;
                
            case ShapeType.triangle:
            {
                import std.algorithm : minElement, maxElement;
                
                immutable objs = [vertex!0, vertex!1, vertex!2];
                immutable maxObj = objs.maxElement!"a.length";
                immutable minObj = objs.minElement!"a.length";
                
                return maxObj - minObj;
            }
            
            case ShapeType.roundrect:
                return abs(end - begin);
                
            case ShapeType.polygon:
            {
                import std.algorithm : minElement, maxElement;
                
                immutable maxObj = data.maxElement!"a.length";
                immutable minObj = data.minElement!"a.length";
                
                return maxObj - minObj;
            }
            
            case ShapeType.multi:
            {
                import std.algorithm : sort;
                import std.range : array;
                
                Shape!T[] rectangles;
                
                foreach (e; shapes)
                {
                    rectangles ~= Shape!T.Rectangle(e.begin, e.begin + e.calculateSize);
                }
                
                rectangles.sort!((a, b) => a.x > b.x && a.y > b.y).array;
                
                return rectangles[0].end - rectangles[$ - 1].begin;
            }
        
            default:
                return vecZero!T;
        }
    }

    /++
    Resizes as a percentage.

    Params:
        k = Percentage.
    +/
    void scale(T k)
    in(type != ShapeType.point)
    do
    {
        import std.algorithm : each;

        if(type != ShapeType.polygon)
            end = end * k;
        else
            data.each!((ref e) => e = e * k);
    }

    /++
    Returns the shape as a polygon.

    Params:
        points = An array of polygon vertices.
        pos = Polygon position.

    Returns:
        Polygon.

    Example:
    ---
    auto triangle = Shape.Polygon([
        Vecf(64, 32),
        Vecf(32, 64),
        Vecf(96, 64)
    ]);
    ---
    +/
    static Shape!T Polygon( Vector!T[] points,
                            Vector!T pos = vec!T(0,0))
    {
        Shape!T shape;

        shape.type = ShapeType.polygon;
        shape.data = points;
        shape.begin = pos;

        return shape;
    }

    static Shape!T PolygonLine( Vector!T[] points,
                                Vector!T pos = vec!T(0,0))
    {
        Shape!T shape;

        shape.type = ShapeType.multi;
        shape.begin = pos;

        int next = 0;
        for(int current = 0; current < points.length; current++)
        {
            next = current + 1;

            if (next == points.length) next = 0;
            
            shape.shapes ~= Shape!float.Line(
                pos + points[current],
                pos + points[next]
            );
        }

        return shape;
    }

    /++
    Collects several figures into one.

    Params:
        shapes = A collection of figures.
        pos = The relative position of such a figure.

    Returns:
        A shapes assembled from many shapes.

    Example:
    ---
    auto multi = Shape.Mutli([
        Shape.Line(Vecf(0,0), Vecf(32,32)),
        Shape.Rectangle(Vecf(32,0), Vecf(64, 32)),
        ...
    ]);
    ---
    +/
    static Shape!T Multi(   Shape!T[] shapes,
                            Vector!T pos = vec!T(0, 0))
    {
        Shape!T shape;

        shape.type = ShapeType.multi;
        shape.shapes = shapes;
        shape.begin = pos;

        return shape;
    }

    /++
    Creates a point.

    Params:
        point = Point position.

    Returns:
        Point.
    +/
    static Shape!T Point(Vector!T point)
    {
        Shape!T shape;

        shape.type = ShapeType.point;
        shape.begin = point;

        return shape;
    }

    /++
    Creates a line from two points.

    Params:
        begin = Line begin.
        end = Line end. 

    Returns:
        Line.
    +/ 
    static Shape!T Line(Vector!T begin,
                        Vector!T end)
    {
        Shape!T shape;

        shape.type = ShapeType.line;
        shape.begin = begin;
        shape.end = end;

        return shape;
    }

    /++
    Creates a rectangle. 

    Params:
        begin = Rectangle begin.
        end = Rectangle end.

    Returns:
        Rectangle. 
    +/
    static Shape!T Rectangle(   Vector!T begin, 
                                Vector!T end)
    {
        Shape!T shape;

        shape.type = ShapeType.rectangle;
        shape.begin = begin;
        shape.end = end;

        return shape;
    }

    static Shape!T RoundRectangle(  Vector!T begin, 
                                    Vector!T end, 
                                    T radius)
    {
        Shape!T shape;

        shape.type = ShapeType.roundrect;
        shape.begin = begin;
        shape.end = end;
        shape.radius = radius;

        return shape;
    }

    static Shape!T RoundRectangleLine(  Vector!T begin,
                                        Vector!T end,
                                        T radius)
    {
        import std.math : cos, sin;
        import tida.angle;

        Shape!T shape;

        shape.type = ShapeType.multi;

        static if (isFloatingPoint!T)
            immutable factor = 0.01;
        else
            immutable factor = 1;

        immutable size = end - begin;

        void rounded(vec!T c, float b, float e)
        {
            Vector!T currPoint;
            for (T i = b; i <= e; i += factor)
            {
                T j = i.conv!(Degrees, Radians);
                currPoint = begin + c + vec!T(cos(j), sin(j)) * radius;

                i += factor;
                j = i.conv!(Degrees, Radians);
                shape.shapes ~= Shape!T.Line(   currPoint,
                                                begin + c + vec!T(cos(j), sin(j)) * radius);
            }
        }

        rounded(vec!T(radius, radius), 180, 270);
        shape.shapes ~= Shape!T.Line(   begin + vec!T(radius, 0),
                                        begin + vec!T(size.x - radius, 0));

        rounded(vec!T(size.x - radius, radius), 270, 360);
        shape.shapes ~= Shape!T.Line(   begin + vec!T(size.x, radius),
                                        end - vec!T(0, radius));

        rounded(vec!T(size.x - radius, size.y - radius), 0, 90);
        shape.shapes ~= Shape!T.Line(   end - vec!T(radius, 0),
                                        begin + vec!T(radius, size.y));

        rounded(vec!T(radius, size.y - radius), 90, 180);
        shape.shapes ~= Shape!T.Line(   begin + vec!T(0, size.y - radius),
                                        begin + vec!T(0, radius));

        return shape;
    }

    /++
    Create a non-solid rectangle. 

    Params:
        begin = Rectangle begin.
        end = Rectangle end. 

    Returns:
        Non-solid rectangle
    +/
    static Shape!T RectangleLine(   Vector!T begin, 
                                    Vector!T end)
    {
        return Shape!T.Multi([
            Shape!T.Line(begin, vec!T(end.x, begin.y)),
            Shape!T.Line(vec!T(end.x, begin.y), end),
            Shape!T.Line(end, vec!T(begin.x, end.y)),
            Shape!T.Line(vec!T(begin.x, end.y), begin)
        ], vec!T(0, 0));
    }

    /++
    Creates a circle.

    Params:
        pos = Circle position.
        r = Circle radius.  

    Returns:
        Circle. 
    +/
    static Shape!T Circle(Vector!T pos, T r)
    {
        Shape!T shape;

        shape.type = ShapeType.circle;
        shape.begin = pos;
        shape.radius = r;

        return shape;
    }

    static Shape!T CircleLine(Vector!T pos, T r)
    {
        import std.math : cos, sin;

        static if (isFloatingPoint!T)
            immutable factor = 0.25;
        else
            immutable factor = 1;

        Shape!T shape;

        shape.type = ShapeType.multi;
        Vector!T currPoint;

        for (T i = 0; i <= 360;)
        {
            currPoint = pos + vec!T(cos(i), sin(i)) * r;
            i += factor;

            shape.shapes ~= Shape.Line(currPoint, pos + vec!T(cos(i), sin(i)) * r);
            i += factor;
        }

        return shape;
    }

    /++
    Creates a triangle.

    Params:
        vertexs = Triangle vertexs.

    Returns:
        Tringle. 
    +/
    static Shape!T Triangle(Vector!T[3] vertexs)
    {
        Shape!T shape;

        shape.type = ShapeType.triangle;
        shape.vertex!0 = vertexs[0];
        shape.vertex!1 = vertexs[1];
        shape.vertex!2 = vertexs[2];

        return shape;
    }

    /++
    Creates a non-filled triangle.

    Params:
        vertexs = Triangle vertexs.

    Returns:
        Tringle.
    +/
    static Shape!T TriangleLine(Vector!T[3] vertexs)
    {
        Shape!T shape;

        shape.type = ShapeType.multi;
        shape.shapes =  [
                            Shape.Line(vertexs[0], vertexs[1]),
                            Shape.Line(vertexs[1], vertexs[2]),
                            Shape.Line(vertexs[2], vertexs[0])
                        ];

        return shape;
    }

    /++
    Create a square.

    Params:
        pos = Square position.
        len = Square length;

    Returns:
        Square (ShapeType: Rectangle).
    +/
    static Shape!T Square(Vector!T pos, T len)
    {
        return Shape!T.Rectangle(pos,pos + vec!T(len, len));
    }
}

import tida.vector;

Shape!T rectVertexs(T)(Vector!T[] vertexArray) @safe nothrow pure
{
    import std.algorithm : maxElement, minElement;

    Shape!T shape = Shape!T.Rectangle(vecNaN!T, vecNaN!T);

    shape.begin = vec!T(vertexArray.minElement!"a.x".x, shape.begin.y);
    shape.end = vec!T(vertexArray.maxElement!"a.x".x, shape.end.y);
    shape.begin = vec!T(shape.begin.x, vertexArray.minElement!"a.y".y);
    shape.end = vec!T(shape.end.x, vertexArray.maxElement!"a.y".y);

    return shape;
}

/++
Checks if the given type is a shape
+/
template isShape(T)
{
    enum isShape =  __traits(hasMember, T, "type") && 
                    __traits(hasMember, T, "shape") &&
                    __traits(hasMember, T, "data");
}

/++
Checks if the shape is integers.
+/
template isShapeIntegral(T)
if (isShape!T)
{
    enum isShapeIntegral = isIntegral!(T.Type);
}

/++
Checks if the shape is float.
+/
template isShapeFloatingPoint(T)
if (isShape!T)
{
    enum isShapeFloatingPoint = isFloatingPoint!(T.Type);
}

alias Shapef = Shape!float;
