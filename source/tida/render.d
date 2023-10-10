module tida.render;

import tida.graphics.gapi;

export:

/++
Camera control object in render,
+/
class Camera
{
    import  tida.vector,
            tida.shape;

    struct CameraObject
    {
        Vector!float* position;
        Vector!float size;
    }

private:
    Shape!float _port;
    Shape!float _shape;
    CameraObject object;
    Vector!float _trackDistance = vec!float(4.0f, 4.0f);
    Vector!float _sizeRoom = vecNaN!float;


export @safe nothrow pure:
    /// The allowed room size for camera scrolling.
    @property Vector!float sizeRoom()
    {
        return _sizeRoom;
    }

    /// The allowed room size for camera scrolling.
    @property Vector!float sizeRoom(Vector!float value)
    {
        return _sizeRoom = value;
    }

    /// A method to change the allowed size of a scrolling room for a camera.
    void resizeRoom(Vector!float value)
    {
        _sizeRoom = value;
    }

    /++
    A method for binding a specific object to a camera to track it.

    Params:
        position =  The reference to the variable for which the tracking
                    will be performed. We need a variable that will be
                    alive during the camera's tracking cycle.
        size     =  The size of the object. (Each object is represented as a rectangle.)
    +/
    void bindObject(    ref Vector!float position,
                        Vector!float size = vecNaN!float)  @trusted
    {
        object.position = &position;
        object.size = size.isVectorNaN ? vec!float(1, 1) : size;
    }

    /++
    A method for binding a specific object to a camera to track it.

    Params:
        position =  The reference to the variable for which the tracking
                    will be performed. We need a variable that will be
                    alive during the camera's tracking cycle.
        size     =  The size of the object. (Each object is represented as a rectangle.)
    +/
    void bindObject(    Vector!float* position,
                        Vector!float size = vecNaN!float)
    {
        object.position = position;
        object.size = size.isVectorNaN ? vec!float(1, 1) : size;
    }

    /++
    A method that reproduces the process of tracking an object.
    +/
    void followObject()
    {
        Vector!float velocity = vecZero!float;

        if (object.position.x < port.begin.x + _trackDistance.x)
        {
            velocity.x = (port.begin.x + _trackDistance.x) - object.position.x;
        } else
        if (object.position.x + object.size.x> port.begin.x + port.end.x - _trackDistance.x)
        {
            velocity.x = (port.begin.x + port.end.x - _trackDistance.x) - (object.position.x + object.size.x);
        }

        if (object.position.y < port.begin.y + _trackDistance.y)
        {
            velocity.y = (port.begin.y + _trackDistance.y) - object.position.y;
        } else
        if (object.position.y + object.size.y > port.begin.y + port.end.y - _trackDistance.y)
        {
            velocity.y = (port.begin.y + port.end.y - _trackDistance.y) - (object.position.y + object.size.y);
        }

        immutable preBegin = port.begin - velocity;

        if (!_sizeRoom.isVectorNaN)
        {
            if (preBegin.x > 0 &&
                preBegin.x + port.end.x < _sizeRoom.x)
            {
                port = Shapef.Rectangle(vec!float(preBegin.x, port.begin.y), port.end);
            } else
            {
            	if (preBegin.x > 0)
            		port = port = Shapef.Rectangle(vec!float(_sizeRoom.x - port.end.x, port.begin.y), port.end);
            	else
            		port = Shapef.Rectangle(vec!float(0, port.begin.y), port.end);
            }

            if (preBegin.y > 0 &&
                preBegin.y + port.end.y < _sizeRoom.y)
            {
                port = Shapef.Rectangle(vec!float(port.begin.x, preBegin.y), port.end);
            } else
            {
            	if (preBegin.y > 0)
            		port = port = Shapef.Rectangle(vec!float(port.begin.x, _sizeRoom.y - port.end.y), port.end);
            	else
			port = Shapef.Rectangle(vec!float(port.begin.x, 0), port.end);            		
            }
        } else
            port = Shapef.Rectangle(preBegin, port.end);
    }

    /// Distance between camera boundaries and subject for the scene to move the camera's view.
    @property Vector!float trackDistance()
    {
        return _trackDistance;
    }

    /// Distance between camera boundaries and subject for the scene to move the camera's view.
    @property Vector!float trackDistance(Vector!float value)
    {
        return _trackDistance = value;
    }

    /++
    The port is the immediate visible part in the "room". The entire area in
    the world that must be covered in the field of view.
    +/
    @property Shape!float port()
    {
        return _port;
    }

    /// ditto
    @property Shape!float port(Shape!float value)
    {
        return _port = value;
    }

    /++
    The size of the visible part in the plane of the window.
    +/
    @property Shape!float shape()
    {
        return _shape;
    }

    /// ditto
    @property Shape!float shape(Shape!float value)
    {
        return _shape = value;
    }

    /++
    Moves the visible field.
    Params:
        value = Factor movement.
    +/
    void moveView(Vecf value)
    {
        _port = Shape!float.Rectangle(_port.begin + value, _port.end);
    }
}

/++
An interface for rendering objects to a display or other storehouse of pixels.
+/
interface IRenderer
{
    import  tida.color,
            tida.vector,
            tida.drawable,
            tida.matrix;

@safe:
    /// Updates the rendering surface if, for example, the window is resized.
    void reshape();

    ///Camera for rendering.
    @property void camera(Camera camera);

    /// Camera for rendering.
    @property Camera camera();

    @property IGraphManip api();

    /++
    Drawing a point.
    Params:
        vec = Point position.
        color = Point color.
    +/
    void point(Vecf vec, Color!ubyte color) @safe;

    /++
    Line drawing.
    Params:
        points = Tops of lines.
        color = Line color.
    +/
    void line(Vecf[2] points, Color!ubyte color) @safe;

    /++
    Drawing a rectangle.
    Params:
        position = Rectangle position.
        width = Rectangle width.
        height = Rectangle height.
        color = Rectangle color.
        isFill = Whether to fill the rectangle with color.
    +/
    void rectangle( Vecf position,
                    uint width,
                    uint height,
                    Color!ubyte color,
                    bool isFill) @safe;

    /++
    Drawning a circle.
    Params:
        position = Circle position.
        radius = Circle radius.
        color = Circle color.
        isFill = Whether to fill the circle with color.
    +/
    void circle(Vecf position,
                float radius,
                Color!ubyte color,
                bool isFill) @safe;

    /++
    Drawing a triangle by its three vertices.
    Params:
        points = Triangle vertices
        color = Triangle color.
        isFill = Whether it is necessary to fill the triangle with color.
    +/
    void triangle(Vecf[3] points, Color!ubyte color, bool isFill) @safe;

    /++
    Draws a rectangle with rounded edges.
    (Rendering is available only through hardware acceleration).
    Params:
        position = Position roundrectangle.
        width = Width roundrectangle.
        height = Height roundrectangle.
        radius = Radius rounded edges.
        color = Color roundrect.
        isFill = Roundrect is filled color?
    +/
    void roundrect( Vecf position,
                    uint width,
                    uint height,
                    float radius,
                    Color!ubyte color,
                    bool isFill) @safe;

    /// Cleans the surface by filling it with color.
    void clear() @safe;

    /// Outputs the buffer to the window.
    void drawning() @safe;

    /// Set factor blend
    void blendOperation(BlendFactor sfactor, BlendFactor dfactor) @safe;

    /// The color to fill when clearing.
    void background(Color!ubyte background) @safe @property;

    /// ditto
    Color!ubyte background() @safe @property;

    /++
    Memorize the shader for future reference.
    Params:
        name =  The name of the shader by which it will be possible to pick up
                the shader in the future.
        program = Shader program.
    +/
    void setShader(string name, IShaderPipeline program) @safe;

    /++
    Pulls a shader from memory, getting it by name. Returns a null pointer
    if no shader is found.
    Params:
        name = Shader name.
    +/
    IShaderPipeline getShader(string name) @safe;

    /// The current shader for the next object rendering.
    void currentShader(IShaderPipeline program) @safe @property;

    /// The current shader for the next object rendering.
    IShaderPipeline currentShader() @safe @property;

    IShaderPipeline mainShader() @safe @property;

    /// Reset the shader to main.
    void resetShader() @safe;

    /// Current model matrix.
    float[4][4] currentModelMatrix() @safe @property;

    /// ditto
    void currentModelMatrix(float[4][4] matrix) @safe @property;

    /// Reset current model matrix.
    final void resetModelMatrix() @safe
    {
        this.currentModelMatrix = identity();
    }

    /++
    Renders an object.
    See_Also: `tida.graph.drawable`.
    +/
    void draw(IDrawable drawable, Vecf position) @safe;

    /// ditto
    void drawEx(    IDrawableEx drawable,
                    Vecf position,
                    float angle,
                    Vecf center,
                    Vecf size,
                    ubyte alpha,
                    Color!ubyte color = rgb(255, 255, 255)) @safe;
}

class Render : IRenderer
{
    import tida.window;
    import  tida.color,
            tida.vector,
            tida.drawable,
            tida.matrix,
            tida.shape,
            tida.meshgen;

    enum vertexShaderSource = import("color.vert.spv");

    enum fragmentShaderSource = import("color.frag.spv");

    IGraphManip gapi;
    IShaderPipeline defaultShader;
    mat4 projection;

    Camera _camera;
    Color!ubyte _background;

    IShaderPipeline[string] shaders;

    IShaderPipeline _currentShader;
    mat4 _currentModel = identity();
    Window window;

    this(Window window) @trusted
    {
        import std.process : environment;

        this.window = window;
        gapi = createGraphManip(GraphBackend.autofind);

        bool isDiscrete = environment.get("TIDA_RENDER_DISCRETE_USE", "true") == "true";

        gapi.initialize(isDiscrete);
        gapi.createAndBindSurface(
            window,
            GraphicsAttributes(8, 8, 8, 8, 24, BufferMode.doubleBuffer)
        );

        gapi.viewport(0, 0, window.width, window.height);

        // auto vertex = gapi.createShader(StageType.vertex);
        // vertex.loadFromSource(vertexShaderSource);

        // auto fragment = gapi.createShader(StageType.fragment);
        // fragment.loadFromSource(fragmentShaderSource);

        // defaultShader = gapi.createShaderProgram();
        // defaultShader.attach(vertex);
        // defaultShader.attach(fragment);
        // defaultShader.link();

        auto vertex = createProgramFromMemory(gapi, StageType.vertex, cast(void[]) vertexShaderSource);
        auto fragment = createProgramFromMemory(gapi, StageType.fragment, cast(void[]) fragmentShaderSource);
    
        defaultShader = gapi.createShaderPipeline();
        defaultShader.bindShader(vertex);
        defaultShader.bindShader(fragment);

        _currentShader = defaultShader;

        shaders["Default"] = defaultShader;

        _camera = new Camera();
        _camera.port = Shapef.Rectangle(vecf(0, 0), vecf(window.width, window.height));
        _camera.shape = _camera.port;

        gapi.blendFactor(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, true);
        reshape();
    }

    void setDefaultUniform(Color!ubyte color, float[] size = [0.0f, 0.0f]) @safe
    {
        uniformBuilder(
            _currentShader.vertexProgram(),
            0,
            projection,
            _currentModel
        );

        float[4] cc = [color.rf, color.gf, color.bf, color.af];

        uniformBuilder(
            _currentShader.fragmentProgram(),
            0,
            cc,
            cast(float[2]) size[0 .. 2]
        );
    }

override:
    IGraphManip api()
    {
        return gapi;
    }

    void reshape() @safe
    {
        version(SDL)
        {
            gapi.viewport(
                -_camera.shape.x,
                -_camera.shape.y,
                _camera.shape.width,
                _camera.shape.height
            );
        } else
        {
            version (Windows)
            {
                gapi.viewport(
                    -_camera.shape.x,
                    -_camera.shape.y,
                    _camera.shape.width,
                    _camera.shape.height
                );
            } else
            version (Posix)
            {
                gapi.viewport(
                    -_camera.shape.x,
                    -_camera.shape.y,
                    _camera.shape.width,
                    _camera.shape.height
                );
            }
        }

        if (gapi.backend == GraphBackend.dx11)
        {
            projection = ortho(0.0, _camera.port.end.x, _camera.port.end.y, 0.0, -1.0, 1.0);
        } else
        {
            projection = ortho(0.0, _camera.port.end.x, _camera.port.end.y, 0.0, -1.0, 1.0);
        }
    }

    void camera(Camera value) @safe
    {
        this._camera = value;
    }

    Camera camera() @safe
    {
        return _camera;
    }

    void point(Vecf vec, Color!ubyte color) @trusted
    {
        immutable buffer = gapi.createImmutableBuffer(BufferType.array, [
            vec - camera.port.begin
        ]);

        auto vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindProgram(_currentShader);
        gapi.bindVertexInfo(vertInfo);
        setDefaultUniform(color, [1, 1]);

        gapi.begin();
        gapi.draw(ModeDraw.points, 0, 1);

        resetShader();
        resetModelMatrix();
    }

    void line(Vecf[2] points, Color!ubyte color) @trusted
    {
        points[0] -= camera.port.begin;
        points[1] -= camera.port.begin;

        immutable buffer = gapi.createImmutableBuffer(BufferType.array, [
            points[0], points[1]
        ]);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);
        setDefaultUniform(color, [points[1].x - points[0].x, points[1].y - points[0].y]);

        gapi.begin();
        gapi.draw(ModeDraw.line, 0, 2);

        resetShader();
        resetModelMatrix();
    }

    void rectangle( Vecf position,
                    uint width,
                    uint height,
                    Color!ubyte color,
                    bool isFill) @trusted
    {
        position -= camera.port.begin;

        auto buffer = gapi.createBuffer();
        buffer.bindData([
            position,
            position + vecf(width, 0),
            position + vecf(width, height),
            position + vecf(0, height)
        ]);

        // immutable buffer = gapi.createImmutableBuffer(BufferType.array, [
        //     position,
        //     position + vecf(width, 0),
        //     position + vecf(width, height),
        //     position + vecf(0, height)
        // ]);

        uint[] index = isFill ?
            [0, 1, 2, 0, 3, 2] :
            [0, 1, 1, 2, 2, 3, 3, 0];
        auto indexBuffer = gapi.createBuffer(BufferType.element);
        indexBuffer.bindData(index);
        // immutable indexBuffer = gapi.createImmutableBuffer(BufferType.element,
        //     index
        // );

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.bindBuffer(indexBuffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(indexBuffer);
            destroy(vertInfo);
        }

        gapi.bindProgram(_currentShader);
        gapi.bindVertexInfo(vertInfo);

        setDefaultUniform(color, [width, height]);

        gapi.begin();
        gapi.drawIndexed(
            isFill ? ModeDraw.triangle : ModeDraw.line,
            cast(uint) index.length
        );

        resetShader();
        resetModelMatrix();
    }

    void circle(Vecf position,
                float radius,
                Color!ubyte color,
                bool isFill) @trusted
    {
        immutable meshData = generateBuffer(
            isFill ?
                Shapef.Circle(position - camera.port.begin, radius) :
                Shapef.CircleLine(position - camera.port.begin, radius)
        );

        immutable buffer = gapi.createImmutableBuffer(BufferType.array, meshData);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);

        setDefaultUniform(color, [radius * 2, radius * 2]);

        gapi.begin();
        gapi.draw(
            isFill ? ModeDraw.triangleStrip : ModeDraw.lineStrip,
            0,
            cast(uint) meshData.length * 2 / 4
        );

        resetShader();
        resetModelMatrix();
    }

    void triangle(Vecf[3] points, Color!ubyte color, bool isFill) @trusted
    {
        points[0] -= camera.port.begin;
        points[1] -= camera.port.begin;
        points[2] -= camera.port.begin;

        immutable buffer = gapi.createImmutableBuffer(BufferType.array, [
            points[0], points[1], points[2]
        ]);

        immutable indexBuffer = gapi.createImmutableBuffer(BufferType.element, [0, 1, 1, 2, 2, 0]);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);

        if (!isFill)
        {
            vertInfo.bindBuffer(indexBuffer);
        }

        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(indexBuffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);
        setDefaultUniform(color, [0.0f, 0.0f]);

        gapi.begin();

        if (isFill)
            gapi.draw(ModeDraw.triangle, 0, 3);
        else
            gapi.drawIndexed(ModeDraw.line, 6);

        resetShader();
        resetModelMatrix();
    }

    void roundrect( Vecf position,
                    uint width,
                    uint height,
                    float radius,
                    Color!ubyte color,
                    bool isFill) @trusted
    {
        position -= camera.port.begin;

        immutable meshData = generateBuffer(
            isFill ?
                Shapef.RoundRectangle(position, position + vecf(width, height), radius) :
                Shapef.RoundRectangleLine(position, position + vecf(width, height), radius)
        );

        immutable buffer = gapi.createImmutableBuffer(BufferType.array, meshData);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);

        setDefaultUniform(color, [width, height]);

        gapi.begin();
        gapi.draw(
            isFill ? ModeDraw.triangleStrip : ModeDraw.lineStrip,
            0,
            cast(uint) meshData.length * 2 / 2
        );

        resetShader();
        resetModelMatrix();
    }

    void clear() @safe
    {
        gapi.clear();
    }

    void drawning() @safe
    {
        gapi.drawning();
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor) @safe
    {
        gapi.blendFactor(sfactor, dfactor, true);
    }

    void background(Color!ubyte value) @safe @property
    {
        _background = value;

        gapi.clearColor(value);
    }

    /// ditto
    Color!ubyte background() @safe @property
    {
        return _background;
    }

    void setShader(string name, IShaderPipeline program) @safe
    {
        shaders[name] = program;
    }

    IShaderPipeline getShader(string name) @safe
    {
        if (name in shaders)
            return shaders[name];
        else
            return null;
    }

    IShaderPipeline mainShader() @safe @property
    {
        return defaultShader;
    }

    void currentShader(IShaderPipeline program) @safe @property
    {
        _currentShader = program;
        if (_currentShader is null)
            _currentShader = defaultShader;
    }

    IShaderPipeline currentShader() @safe @property
    {
        return _currentShader;
    }

    void resetShader() @safe
    {
        _currentShader = defaultShader;
    }

    float[4][4] currentModelMatrix() @safe @property
    {
        return _currentModel;
    }

    void currentModelMatrix(float[4][4] matrix) @safe @property
    {
        _currentModel = matrix;
    }

    void draw(IDrawable drawable, Vecf position) @safe
    {
        drawable.draw(this, position - camera.port.begin);
    }

    void drawEx(    IDrawableEx drawable,
                    Vecf position,
                    float angle,
                    Vecf center,
                    Vecf size,
                    ubyte alpha,
                    Color!ubyte color = rgb(255, 255, 255)) @safe
    {
        drawable.drawEx(this, position - camera.port.begin, angle, center, size, alpha, color);
    }
}
