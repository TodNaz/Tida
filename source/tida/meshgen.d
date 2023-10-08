module tida.meshgen;

import  tida.vector,
        tida.shape;

export:

/++
Generates the vertices of shapes to be rendered using hardware acceleration.
Params:
    T = Type.
    shape = Shape information.
    textureSize =   Texture size. If not specified, will not generate texture
                    vertices for vertices.
+/
Vector!T[] generateBuffer(T)(Shape!T shape) @safe nothrow pure
{
    import std.math : cos, sin;

    Vector!T[] vertexs;

    switch (shape.type)
    {
        case ShapeType.point:
            vertexs = [shape.begin];
        break;

        case ShapeType.line:
            vertexs = [shape.begin, shape.end];
        break;

        case ShapeType.rectangle:
            vertexs =   [
                            vec!T(shape.end.x, shape.begin.y),
                            shape.end,
                            vec!T(shape.begin.x, shape.end.y),
                            shape.begin
                        ];
        break;

        case ShapeType.roundrect:
            immutable pos1 = shape.begin + vec!T(shape.radius, 0);
            immutable pos2 = shape.begin + vec!T(0, shape.radius);

            immutable size = vec!T(shape.width, shape.height);

            vertexs =   [
                            // FIRST RECTANGLE
                            pos1,
                            pos1 + vec!T(size.x - shape.radius * 2, 0),
                            pos1 + size - vec!T(shape.radius * 2, 0),

                            pos1,
                            pos1 + vec!T(0, size.y),
                            pos1 + size - vec!T(shape.radius * 2, 0),

                            // SECOND RECTANGLE
                            pos2,
                            pos2 + vec!T(size.x, 0),
                            pos2 + size - vec!T(0, shape.radius * 2),

                            pos2,
                            pos2 + vec!T(0, size.y - shape.radius * 2),
                            pos2 + size - vec!T(0, shape.radius * 2)
                        ];

            void rounded(vec!T pos, T a1, T a2, T iter)
            {
                for (T i = a1; i <= a2;)
                {
                    vertexs ~= pos + vec!T(cos(i), sin(i)) * shape.radius;

                    i += iter;
                    vertexs ~= pos + vec!T(cos(i), sin(i)) * shape.radius;
                    vertexs ~= pos;

                    i += iter;
                }
            }

            rounded(shape.begin + vec!T(shape.radius, shape.radius), 270, 360, 0.25);
            rounded(shape.begin + vec!T(size.x - shape.radius, shape.radius), 0, 90, 0.25);
            rounded(shape.begin + vec!T(shape.radius, size.y - shape.radius), 180, 270, 0.25);
            rounded(shape.begin + vec!T(size.x - shape.radius, size.y - shape.radius), 90, 180, 0.25);
        break;

        case ShapeType.circle:
            for (T i = 0; i <= 360;)
            {
                vertexs ~= shape.begin + vec!T(cos(i), sin(i)) * shape.radius;

                i += 0.25;
                vertexs ~= shape.begin + vec!T(cos(i), sin(i)) * shape.radius;
                vertexs ~= shape.begin;

                i += 0.25;
            }
        break;

        case ShapeType.triangle:
            vertexs = shape.vertexs;
        break;

        case ShapeType.polygon:
            foreach (e; shape.data)
                vertexs ~= shape.begin + e;
            vertexs ~= shape.begin + shape.data[0];
        break;

        case ShapeType.multi:
            foreach (cs; shape.shapes)
            {
                vertexs ~= generateBuffer!T(cs);
            }
        break;

        default:
            return null;
    }

    return vertexs;
}
