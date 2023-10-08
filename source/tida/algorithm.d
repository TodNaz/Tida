/++
Assembly module for some game algorithms.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.algorithm;

export:
import tida.vector;
import std.algorithm : find, canFind, remove, reverse;
import std.math : pow;

/++
Finds a path at given coordinates in a grid using the A* algorithm.

Params:
    grid = Grid.
    begin = The point is where you need to start looking for a way.
    from = The point where you need to find the path.

Returns: An array of points, i.e. consistent path to the end of the path.
If the last point is not equal to the last point, then the path was not
found and only the closest path to the point was found.
+/
Vector!int[] findPath(inout bool[][] grid, Vector!int begin, Vector!int from)
@safe nothrow pure
{
    immutable gridWidth = grid[0].length;
    immutable gridHeight = grid.length;

    struct Node
    {
        Node* parent;
        Vector!int position;
        float g = 0.0f;
        float h = 0.0f;
        float f = 0.0f;
    }

    Vector!int[] getPath(Node* node) @safe nothrow pure
    {
        Vector!int[] result;
        Node* current = node;
        while(current !is null)
        {
            result ~= current.position;
            current = current.parent;
        }

        result.reverse;

        return result;
    }

    Node* startNode = new Node(null, begin);
    Node* endNode = new Node(null, from);

    Node*[] yetVisitList = [startNode];
    Node*[] visitList = [];
    Node* currentNode = null;
    size_t currentIndex = 0;

    immutable move = 	[
                            Vector!int(-1,0),
                            Vector!int(0,-1),
                            Vector!int(1, 0),
                            Vector!int(0, 1)
                        ];

    size_t currIter = 0;
    const maxIter = (grid.length * grid[0].length) ^^ 2;
    const cost = 1;
    while (yetVisitList.length > 0)
    {
        currIter++;

        currentNode = yetVisitList[0];
        currentIndex = 0;
        foreach (size_t index, Node* item; yetVisitList)
        {
            if (item.f < currentNode.f)
            {
                currentNode = item;
                currentIndex = index;
            }
        }

        if (currIter > maxIter) return getPath(currentNode);

        yetVisitList.remove(currentIndex);
        visitList ~= currentNode;

        if (currentNode.position == endNode.position) return getPath(currentNode);

        Node*[] children = [];
        foreach (newPos; move)
        {
            Vector!int nodePos = currentNode.position + newPos;

            if (nodePos.x > gridWidth - 1 ||
                nodePos.x < 0 ||
                nodePos.y > gridHeight - 1 ||
                nodePos.y < 0)
                continue;

            if (grid[nodePos.y][nodePos.x] != 0)
                continue;

            children ~= new Node(currentNode, nodePos);
        }

        foreach (child; children)
        {
            if (visitList.canFind!(a => child.position == a.position)) continue;

            child.g = currentNode.g + cost;
            child.h = ((sqr(child.position.x - endNode.position.x)) +
                       (sqr(child.position.y - endNode.position.y)));
            child.f = child.g + child.h;

            if (yetVisitList.canFind!(a => child.position == a.position && child.g > a.g))
                continue;

            yetVisitList ~= child;
        }
    }

    return getPath(currentNode);
}

unittest
{
    immutable bool[][]
            grid =
                        [
                            [1, 1, 1, 1, 1, 1, 1],
                            [1, 0, 0, 0, 0, 0, 1],
                            [1, 1, 1, 1, 1, 0, 1],
                            [1, 0, 0, 0, 0, 0, 0],
                            [1, 0, 1, 1, 1, 1, 0],
                            [1, 0, 0, 0, 1, 0, 0],
                            [1, 1, 1, 0, 0, 0, 1],
                            [1, 1, 1, 1, 0, 1, 1]
                        ];
    auto result = findPath(grid, Vector!int(1, 1), Vector!int(5, 6));
    //result[$ - 1].should.equal(Vector!int(5, 6));
    assert(result[$ - 1] == Vector!int(5, 6));
}
