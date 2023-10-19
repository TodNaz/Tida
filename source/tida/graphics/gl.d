/++
Module for loading the library of open graphics, as well as some of its
extensions.

Also, the module provides information about which version of the library
is used, provides a list of available extensions, and more.

To load the library, you need the created graphics context. Therefore,
you need to create a window and embed a graphical context,
which is described $(HREF window.html, here). After that,
using the $(LREF loadGraphicsLibrary) function, the functions of
the open graphics library will be available.

Example:
---
import tida.runtime;
import tida.window;
import tida.gl;

int main(string[] args)
{
    ITidaRuntime.initialize(args, AllLibrary);
    Window window = new Window(640, 480, "Example window");
    window.windowInitialize(100, 100);

    loadGraphicsLibrary();

    return 0;
}
---

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.graphics.gl;

version(GraphBackendVulkan) {} else:
export import bindbc.opengl;
import std.experimental.logger;

__gshared int[2] _glVersionSpecifed;
__gshared string _glslVersion;

/++
A function that returns the version of the library in the form of two numbers:
a major version and a minor version.
+/
@property int[2] glVersionSpecifed() @trusted
{
    return _glVersionSpecifed;
}

/++
Indicates whether the use of geometry shaders is supported on this device.
+/
@property bool glGeometrySupport() @trusted
{
    ExtList extensions = glExtensionsList();

    return 	hasExtensions(extensions, Extensions.geometryShaderARB) ||
            hasExtensions(extensions, Extensions.geometryShaderEXT) ||
            hasExtensions(extensions, Extensions.geometryShaderNV);
}

@property bool glSpirvSupport() @trusted
{
    ExtList extensions = glExtensionsList();

    if (hasExtensions(extensions, Extensions.glSpirvARB))
    {
        int param;
        glGetIntegerv(GL_NUM_PROGRAM_BINARY_FORMATS, &param);

        return param != 0;
    } else
        return false;
}

@property bool glDSASupport() @trusted
{
    ExtList extensions = glExtensionsList();

    if (hasExtensions(extensions, Extensions.dsa))
    {
        int param;
        glGetIntegerv(GL_NUM_PROGRAM_BINARY_FORMATS, &param);

        return param != 0;
    } else
        return false;
}

/++
Returns the maximum version of the shaders in the open graphics.
+/
@property string glslVersion() @trusted
{
    return _glslVersion;
}

@property uint glError() @trusted
{
    return glGetError();
}

@property string glErrorMessage(immutable uint err) @trusted
{
    enum GL_STACK_OVERFLOW = 0x0503;
    enum GL_STACK_UNDERFLOW = 0x0407;
    
    string error;

    switch (err)
    {
        case GL_INVALID_ENUM:
            error = "Invalid enum!";
            break;

        case GL_INVALID_VALUE:
            error = "Invalid input value!";
            break;

        case GL_INVALID_OPERATION:
            error = "Invalid operation!";
            break;

        case GL_STACK_OVERFLOW:
            error = "Stack overflow!";
            break;

        case GL_STACK_UNDERFLOW:
            error = "Stack underflow!";
            break;

        case GL_OUT_OF_MEMORY:
            error = "Out of memory!";
            break;

        case GL_INVALID_FRAMEBUFFER_OPERATION:
            error = "Invalid framebuffer operation!";
            break;

        default:
            error = "Unkown error!";
    }

    return error;
}

void checkGLError(
    string file = __FILE__,
    size_t line = __LINE__,
    string func = __FUNCTION__
) @safe
{
    immutable err = glError();
    if (err != GL_NO_ERROR)
    {
        throw new Exception(
            "In function `" ~ func ~ "` discovered error: `" ~ glErrorMessage(err) ~ "`.",
            file,
            line
        );
    }
}

void assertGLError(
    lazy uint checked,
    string file = __FILE__,
    size_t line = __LINE__,
    string func = __FUNCTION__
) @safe
{
    immutable err = checked();
    if (err != GL_NO_ERROR)
    {
        throw new Exception(
            "In function `" ~ func ~ "` discovered error: `" ~ glErrorMessage(err) ~ "`.",
            file,
            line
        );
    }
}

/++
Returns the company responsible for this GL implementation.
This name does not change from release to release.

See_Also:
    $(HREF https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetString.xhtml, OpenGL Reference - glGetString)
+/
@property string glVendor() @trusted
{
    import std.conv : to;

    return glGetString(GL_VENDOR).to!string;
}

/++
Returns the name of the renderer.
This name is typically specific to a particular configuration of a hardware platform.
It does not change from release to release.

See_Also:
    $(HREF https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetString.xhtml, OpenGL Reference - glGetString)
+/
@property string glRenderer() @trusted
{
    import std.conv : to;

    return glGetString(GL_RENDERER).to!string;
}

/++
The function loads the `OpenGL` libraries for hardware graphics acceleration.

Throws:
$(HREF https://dlang.org/library/object.html#Exception, Exception)
if the library was not found or the context was not created to implement
hardware acceleration.
+/
void loadGraphicsLibrary() @trusted
{
    import std.exception : enforce;
    import std.conv : to;

    bool valid(GLSupport value)
    {
        return value != GLSupport.noContext &&
               value != GLSupport.badLibrary &&
               value != GLSupport.noLibrary;
    }

    GLSupport retValue = loadOpenGL();
    enforce!Exception(valid(retValue),
    "The library was not loaded or the context was not created!");

    glGetIntegerv(GL_MAJOR_VERSION, &_glVersionSpecifed[0]);
    glGetIntegerv(GL_MINOR_VERSION, &_glVersionSpecifed[1]);
	string str = glGetString(GL_SHADING_LANGUAGE_VERSION).to!string;
	
	if (str.length != 0)
		_glslVersion = str[0 .. 4];
	else
		_glslVersion = "1.30";
}

alias ExtList = string[];

/++
Available extensions that the framework can load with one function.
+/
enum Extensions : string
{
    /++
    Compressing texture images can reduce texture memory utilization and
    improve performance when rendering textured primitives.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_texture_compression.txt, OpenGL reference "GL_ARB_texture_compression")
    +/
    textureCompression = "GL_ARB_texture_compression",

    /++
    This extension introduces the notion of one- and two-dimensional array
    textures.  An array texture is a collection of one- and two-dimensional
    images of identical size and format, arranged in layers.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/EXT/EXT_texture_array.txt, OpenGL reference "GL_EXT_texture_array")
    +/
    textureArray = "GL_EXT_texture_array",

    /++
    Texture objects are fundamental to the operation of OpenGL. They are
    used as a source for texture sampling and destination for rendering
    as well as being accessed in shaders for image load/store operations
    It is also possible to invalidate the contents of a texture. It is
    currently only possible to set texture image data to known values by
    uploading some or all of a image array from application memory or by
    attaching it to a framebuffer object and using the Clear or ClearBuffer
    commands.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_clear_texture.txt, OpenGL reference "GL_ARB_clear_texture")
    +/
    textureClear = "GL_ARB_clear_texture",

    /++
    ARB_geometry_shader4 defines a new shader type available to be run on the
    GPU, called a geometry shader. Geometry shaders are run after vertices are
    transformed, but prior to color clamping, flat shading and clipping.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_geometry_shader4.txt, OpenGL reference "GL_ARB_geometry_shader4")
    +/
    geometryShaderARB = "GL_ARB_geometry_shader4",

    /// ditto
    geometryShaderEXT = "GL_EXT_geometry_shader4",

    /// ditto
    geometryShaderNV = "GL_NV_geometry_shader4",

    glSpirvARB = "GL_ARB_gl_spirv",

    dsa = "ARB_direct_state_access"
}

/++
Checks if the extension specified in the argument is in the open graphics library.

Params:
    list =  List of extensions. Leave it blank (using the following: '[]')
            for the function to calculate all the extensions by itself.
    name =  The name of the extension you need.

Returns:
    Extension search result. `False` if not found.
+/
bool hasExtensions(ExtList list, string name) @trusted
{
    import std.algorithm : canFind;

    if (list.length == 0)
        list = glExtensionsList();

    return list.canFind(name);
}

/++
A function that provides a list of available extensions to use.
+/
ExtList glExtensionsList() @trusted
{
    import std.conv : to;
    import std.string : split;

    int numExtensions = 0;
    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);

    string[] extensions;

    foreach (i; 0 .. numExtensions)
    {
        extensions ~= glGetStringi(GL_EXTENSIONS, i).to!string;
    }

    return extensions;
}

// Texture compressed
alias FCompressedTexImage2DARB = extern(C) void function(GLenum target,
                                               int level,
                                               GLenum internalformat,
                                               GLsizei width,
                                               GLsizei height,
                                               int border,
                                               GLsizei imagesize,
                                               void* data);

__gshared
{
    FCompressedTexImage2DARB glCompressedTexImage2DARB;
}

alias glCompressedTexImage2D = glCompressedTexImage2DARB;

enum
{
    GL_COMPRESSED_RGBA_ARB = 0x84EE,
    GL_COMPRESSED_RGB_ARB = 0x84ED,
    GL_COMPRESSED_ALPHA_ARB = 0x84E9,

    GL_TEXTURE_COMPRESSION_HINT_ARB = 0x84EF,
    GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB = 0x86A0,
    GL_TEXTURE_COMPRESSED_ARB = 0x86A1,
    GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB = 0x86A2,
    GL_COMPRESSED_TEXTURE_FORMATS_ARB = 0x86A3
}

/++
Loads the extension `GL_ARB_texture_compression`, that is,
extensions for loading compressed textures.

Returns:
    Returns the result of loading. False if the download is not successful.
+/
bool extTextureCompressionLoad() @trusted
{
    import bindbc.opengl.util;

    if (!hasExtensions(null, "GL_ARB_texture_compression"))
        return false;

    if (!loadExtendedGLSymbol(  cast(void**) &glCompressedTexImage2DARB,
                                "glCompressedTexImage2DARB"))
        return false;

    return true;
}

// Texture array ext
alias FFramebufferTextureLayerEXT = extern(C) void function();

__gshared
{
    FFramebufferTextureLayerEXT glFramebufferTextureLayerEXT;
}

enum
{
    GL_TEXTURE_1D_ARRAY_EXT = 0x8C18,
    GL_TEXTURE_2D_ARRAY_EXT = 0x8C1A,

    GL_TEXTURE_BINDING_1D_ARRAY_EXT = 0x8C1C,
    GL_TEXTURE_BINDING_2D_ARRAY_EXT = 0x8C1D,
    GL_MAX_ARRAY_TEXTURE_LAYERS_EXT = 0x88FF,
    GL_COMPARE_REF_DEPTH_TO_TEXTURE_EXT = 0x884E
}

/++
Loads the extension `GL_EXT_texture_array`, that is, extensions for
loading an array of textures.

Returns:
    Returns the result of loading. False if the download is not successful.
+/
bool extTextureArrayLoad() @trusted
{
    import bindbc.opengl.util;

    if (!hasExtensions(null, Extensions.textureArray))
        return false;

    // glFramebufferTextureLayerEXT
    if (!loadExtendedGLSymbol(cast(void**) &glFramebufferTextureLayerEXT,
                              "glFramebufferTextureLayerEXT"))
        return false;

    return true;
}

string formatError(string error) @safe pure
{
    import std.array : replace;

    error = error.replace("error","\x1b[1;91merror\x1b[0m");

    return error;
}

extern(C) void __glLog(
    GLenum source,
    GLenum type,
    GLuint id,
    GLenum severity,
    GLsizei length,
    const(char*) message,
    const(void*) userParam
)
{
    import std.conv : to;

    string sourceID;
    string typeID;
    uint typeLog = 0;

    Logger logger = cast(Logger) userParam;

    switch (source)
    {
        case GL_DEBUG_SOURCE_API:
            sourceID = "API";
        break;

        case GL_DEBUG_SOURCE_APPLICATION:
            sourceID = "Application";
        break;

        case GL_DEBUG_SOURCE_SHADER_COMPILER:
            sourceID = "Shader Program";
        break;

        case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
            sourceID = "Window system";
        break;

        case GL_DEBUG_SOURCE_THIRD_PARTY:
            sourceID = "Third party";
        break;

        default:
            sourceID = "Unknown";
    }

    switch(type)
    {
        case GL_DEBUG_TYPE_ERROR:
            typeID = "Error";
            typeLog = 1;
        break;

        case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
            typeID = "Deprecated";
            typeLog = 2;
        break;

        case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
            typeID = "Undefined behaviour";
            typeLog = 3;
        break;

        default:
            typeID = "Other";
        break;
    }

    final switch(typeLog)
    {
        case 0: break;

        case 1:
            logger.critical("[OpenGL][", sourceID, "](", id, ") ", message.to!string);
        break;

        case 2:
            logger.warning("[OpenGL][", sourceID, "](", id, ") ", message.to!string);
        break;

        case 3:
            logger.critical("[OpenGL][", sourceID, "](", id, ") ", message.to!string);
        break;
    }
}

void glSetupDriverLog(Logger logger) @trusted
{
    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(cast(GLDEBUGPROC) &__glLog, cast(void*) logger);
}

import tida.graphics.gapi;

class GLBuffer : IBuffer
{
    uint id;
    uint glDataUsage = GL_STATIC_DRAW;
    uint glBuff = GL_ARRAY_BUFFER;
    bool isEmpty = true;
    BufferType _type = BufferType.array;
    uint size;

    this(BufferType buffType) @trusted
    {
        glCreateBuffers(1, &id);
        usage(buffType);
    }

    this(BufferType buffType, inout void[] data) @trusted immutable
    {
        glCreateBuffers(1, cast(uint*) &id);

        if (buffType == BufferType.array)
        {
            glBuff = GL_ARRAY_BUFFER;
        } else
        if (buffType == BufferType.element)
        {
            glBuff = GL_ELEMENT_ARRAY_BUFFER;
        } else
        if (buffType == BufferType.uniform)
        {
            glBuff = GL_UNIFORM_BUFFER;
        } else
        if (buffType == BufferType.textureBuffer)
        {
            glBuff = GL_TEXTURE_BUFFER;
        } else
        if (buffType == BufferType.storageBuffer)
        {
            glBuff = GL_SHADER_STORAGE_BUFFER;
        }

        this._type = buffType;

        glNamedBufferData(id, data.length, cast(void*) data.ptr, GL_STATIC_DRAW);
    }

    size_t getSize() @safe
    {
        return size;
    }

    void bind() @trusted
    {
        glBindBuffer(glBuff, id);
    }

    void bind() @trusted immutable
    {
        glBindBuffer(glBuff, id);
    }

    void[] getData(size_t length) @trusted
    {
        void[] data = new void[](length);
        glGetNamedBufferSubData(id, 0, cast(GLsizeiptr) length, data.ptr);

        return data;
    }

    ~this() @trusted
    {
        glDeleteBuffers(1, &id);

        id = 0;
    }

override:
    void usage(BufferType buffType) @trusted
    {
        if (buffType == BufferType.array)
        {
            glBuff = GL_ARRAY_BUFFER;
        } else
        if (buffType == BufferType.element)
        {
            glBuff = GL_ELEMENT_ARRAY_BUFFER;
        } else
        if (buffType == BufferType.uniform)
        {
            glBuff = GL_UNIFORM_BUFFER;
        } else
        if (buffType == BufferType.textureBuffer)
        {
            glBuff = GL_TEXTURE_BUFFER;
        } else
        if (buffType == BufferType.storageBuffer)
        {
            glBuff = GL_SHADER_STORAGE_BUFFER;
        }

        this._type = buffType;
    }

    void[] mapData() @trusted
    {
        ubyte* cdata = cast(ubyte*) glMapNamedBuffer(id, GL_READ_WRITE);

        return cast(void[]) cdata[0 .. size];
    }

    void unmapData() @trusted
    {
        glUnmapNamedBuffer(id);
    }

    @property BufferType type() @trusted inout
    {
        return this._type;
    }

    void dataUsage(BuffUsageType type) @trusted
    {
        if (type == BuffUsageType.staticData)
            glDataUsage =  GL_STATIC_DRAW;
        else
        if (type == BuffUsageType.dynamicData)
        {
            if (this.type() != BufferType.uniform)
                glDataUsage = GL_DYNAMIC_DRAW;
            else
                glDataUsage = GL_DYNAMIC_COPY;
        }
    }

    void bindData(inout void[] data) @trusted
    {
        this.size = cast(uint) data.length;

        if (isEmpty)
        {
            glNamedBufferData(id, data.length, data.ptr, glDataUsage);
            isEmpty = false;
        } else
        {
            glNamedBufferSubData(id, 0, data.length, data.ptr);
        }
    }

    void allocate(size_t size) @trusted
    {
        this.size = cast(uint) size;
        glNamedBufferData(id, size, null, glDataUsage);
    }

    void clear() @trusted
    {
        this.size = 0;
        glNamedBufferData(id, 0, null, glDataUsage);
    }
}

class GLVertexInfo : IVertexInfo
{
    GLBuffer buffer;
    GLBuffer indexBuffer;

    uint id;

    this() @trusted
    {
        glCreateVertexArrays(1, &id);
    }

    ~this() @trusted
    {
        glDeleteVertexArrays(1, &id);
    }

    uint glType(TypeBind tb) @safe
    {
        final switch (tb)
        {
            case TypeBind.Byte:
                return GL_BYTE;

            case TypeBind.UnsignedByte:
                return GL_UNSIGNED_BYTE;

            case TypeBind.Short:
                return GL_SHORT;

            case TypeBind.UnsignedShort:
                return GL_UNSIGNED_SHORT;

            case TypeBind.Int:
                return GL_INT;

            case TypeBind.UnsignedInt:
                return GL_UNSIGNED_INT;

            case TypeBind.Float:
                return GL_FLOAT;

            case TypeBind.Double:
                return GL_DOUBLE;
        }
    }

override:
    void bindBuffer(inout IBuffer buffer) @trusted
    {
        if (buffer.type == BufferType.array)
        {
            this.buffer = cast(GLBuffer) buffer;
        } else
        if (buffer.type == BufferType.element)
        {
            this.indexBuffer = cast(GLBuffer) buffer;
        }
    }

    void vertexAttribPointer(AttribPointerInfo[] attribs) @trusted
    {
        foreach (attrib; attribs)
        {
            uint typeID = glType(attrib.type);

            glVertexArrayVertexBuffer(
                id,
                0,
                buffer.id,
                0,
                attrib.stride
            );

            if(indexBuffer !is null)
                glVertexArrayElementBuffer(id, indexBuffer.id);

            glEnableVertexArrayAttrib(id, attrib.location);

            glVertexArrayAttribFormat(id, attrib.location, attrib.components, typeID, false, attrib.offset);

            glVertexArrayAttribBinding(id, attrib.location, 0);
        }
    }
}

class GLShaderManip : IShaderManip
{
    import tida.graphics.shader;

    StageType _stage;
    uint id;

    Logger logger;

    uint glStage(StageType type) @safe
    {
        if (type == StageType.vertex)
        {
            return GL_VERTEX_SHADER;
        } else
        if (type == StageType.fragment)
        {
            return GL_FRAGMENT_SHADER;
        } else
        if (type == StageType.geometry)
        {
            return GL_GEOMETRY_SHADER;
        } else
        if (type == StageType.compute)
        {
            return GL_COMPUTE_SHADER;
        }

        return 0;
    }

    bool memored = false;
    UBInfo[] prepared;

    this(StageType stage, Logger logger) @trusted
    {
        this._stage = stage;
        this.logger = logger;
        id = glCreateShader(glStage(stage));
    }

    ~this() @trusted
    {
        glDeleteShader(id);
    }

    void tsoMemory(void[] adata)
    {
        ubyte[] data = cast(ubyte[]) adata;
        import bm = std.bitmanip;

        data = data[8 .. $];
        size_t offset;
        void[] spirv;

        uint spvs, dxis, unis;
        ubyte[] cdat;

        cdat = data[offset .. offset += uint.sizeof];
        spvs = bm.read!uint(cdat);
        cdat = data[offset .. offset += uint.sizeof];
        dxis = bm.read!uint(cdat);
        cdat = data[offset .. offset += uint.sizeof];
        unis = bm.read!uint(cdat);

        spirv = data[offset .. offset += spvs];
        offset += dxis;
        immutable range = offset + unis;
        for (; offset < range;)
        {
            char[] type = cast(char[]) data[offset .. offset += 3];
            if (type == "UNI")
            {
                ushort binding;
                uint size;

                cdat = data[offset .. offset += ushort.sizeof];
                binding = bm.read!ushort(cdat);
                cdat = data[offset .. offset += uint.sizeof];
                size = bm.read!uint(cdat);

                prepared ~= UBInfo(binding, [], size);
            } else
            if (type == "SMP")
            {
                offset += 3;
            }
        }

        if (!glSpirvSupport())
        {
            spvMemory(spirv);
            return;
        }

        memored = true;

        glShaderBinary(1, &id, GL_SHADER_BINARY_FORMAT_SPIR_V, spirv.ptr, cast(uint) spirv.length);
        
        if (glSpecializeShader is null)
            throw new Exception("[GL] Specialize shader is not supported");

        glSpecializeShader(id, "main", 0, null, null);

        char[] error;
        int result;
        int lenLog;

        glGetShaderiv(id, GL_COMPILE_STATUS, &result);
        if (!result)
        {
            import std.conv : to;

            debug logger.critical("Shader is not a compile!");

            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(id, lenLog, null, error.ptr);

            debug logger.critical("Shader log error:\n", error.to!string.formatError);

            throw new Exception("Shader compile error:\n" ~ error.to!string.formatError);
        }
    }

    void spvMemory(void[] data)
    {
        import tida.graphics.shader;
        import std.conv : to;

        ShaderCompiler compiler = new ShaderCompiler(ShaderSourceType.GLSL);
        string source = compiler.compile(data);
        
        const int len = cast(const(int)) source.length;
        glShaderSource(id, 1, [source.ptr].ptr, &len);
        glCompileShader(id);

        char[] error;
        int result, lenLog;

        glGetShaderiv(id, GL_COMPILE_STATUS, &result);
        if (!result)
        {
            debug logger.critical("Shader is not a compile!");

            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(id, lenLog, null, error.ptr);

            debug logger.critical("Shader log error:\n", error.to!string);

            throw new Exception("Shader compile error:\n" ~ error.to!string.formatError);
        }
    }

override:
    void loadFromMemory(void[] memory) @trusted
    {
        import std.conv : to;

        string signature = cast(string) memory[0 .. 8];
        if (signature == ".TIDASO\0")
        {
            tsoMemory(memory);
            return;
        }

        if (!glSpirvSupport())
        {
            spvMemory(memory);
            return;
        }

        memored = true;

        glShaderBinary(1, &id, GL_SHADER_BINARY_FORMAT_SPIR_V, memory.ptr, cast(uint) memory.length);
        
        if (glSpecializeShader is null)
            throw new Exception("[GL] Specialize shader is not supported");

        glSpecializeShader(id, "main", 0, null, null);

        char[] error;
        int result;
        int lenLog;

        glGetShaderiv(id, GL_COMPILE_STATUS, &result);
        if (!result)
        {
            debug logger.critical("Shader is not a compile!");

            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(id, lenLog, null, error.ptr);

            debug logger.critical("Shader log error:\n", error.to!string.formatError);

            throw new Exception("Shader compile error:\n" ~ error.to!string.formatError);
        }
    }

    @property StageType stage() @safe
    {
        return _stage;
    }
}

class GLShaderProgram : IShaderProgram
{
    struct MemoryUniform
    {
        uint id;
        GLBuffer buffer;
        uint size;
    }

    public
    {
        uint id;
        GLShaderManip   vertex,
                        fragment,
                        geometry,
                        compute;

        MemoryUniform[] ublocks;      
    }

    Logger logger;

    this(Logger logger) @trusted
    {
        id = glCreateProgram();
        glProgramParameteri(id, GL_PROGRAM_SEPARABLE, GL_TRUE);

        this.logger = logger;
    }

    GLShaderManip mainShader() @safe
    {
        if (vertex !is null) return vertex; else
        if (fragment !is null) return fragment; else
        if (compute !is null) return compute; else
        return geometry;
    }

    GLBuffer fromBind(uint id) @safe
    {
        import std.algorithm;

        return ublocks.find!(a => a.id == id)[0].buffer;
    }

override:
    void attach(IShaderManip shader) @trusted
    {
        GLShaderManip gshader = cast(GLShaderManip) shader;
        glAttachShader (id, gshader.id);
        final switch (gshader.stage())
        {
            case StageType.vertex:
                vertex = gshader;
                break;
            case StageType.fragment:
                fragment = gshader;
                break;
            case StageType.geometry:
                geometry = gshader;
                break;
            case StageType.compute:
                compute = gshader;
                break;
        }
    }

    /// Program link. Assumes that prior to its call, shaders were previously bound.
    void link() @trusted
    {
        int status;

        glLinkProgram(id);
        glGetProgramiv(id, GL_LINK_STATUS, &status);
        if (!status)
        {
            char[] message;
            int messageLength;
            glGetProgramiv(id, GL_INFO_LOG_LENGTH, &messageLength);

            message = new char[](messageLength);
            glGetProgramInfoLog(id, messageLength, &messageLength, &message[0]);

            immutable msg = "Shader link error: " ~ (cast(string) message);
            logger.error(msg);
            throw new Exception(msg);
        }

        // BUG: GL драйвер что-то не хочет принимать такие данные, только свои.
        // if (mainShader().prepared.length != 0)
        // {
        //     import tida.graphics.shader;

        //     foreach (i; 0 .. mainShader().prepared.length)
        //     {
        //         UBInfo e = mainShader().prepared[i];

        //         uint usize = cast(uint) e.sizeBuffer;

        //         MemoryUniform mu;
        //         mu.id = e.id;
        //         mu.buffer = new GLBuffer(BufferType.uniform);
        //         mu.buffer.dataUsage(BuffUsageType.dynamicData);
        //         mu.buffer.allocate(usize);
        //         mu.size = usize;

        //         ublocks ~= mu;
        //     }
        //     return;
        // }

        int uniformBlocks;
        glGetProgramiv(id, GL_ACTIVE_UNIFORM_BLOCKS, &uniformBlocks);
        foreach (i; 0 .. uniformBlocks)
        {
            int namelen;
            glGetActiveUniformBlockiv(id, i, GL_UNIFORM_BLOCK_NAME_LENGTH, &namelen); 
            char[] name = new char[](namelen);
            glGetActiveUniformBlockName(id, i, namelen, null, &name[0]);
            int block = 0;
            glGetActiveUniformBlockiv(id, i, GL_UNIFORM_BLOCK_BINDING, &block);

            int usize;
            glGetActiveUniformBlockiv(id, i, GL_UNIFORM_BLOCK_DATA_SIZE, &usize);

            MemoryUniform mu;
            mu.id = block;
            mu.buffer = new GLBuffer(BufferType.uniform);
            mu.buffer.dataUsage(BuffUsageType.dynamicData);
            mu.buffer.allocate(usize);
            mu.size = usize;

            ublocks ~= mu;
        }
    }

    bool hasUniformBinding(uint id) @safe
    {
        foreach (e; ublocks)
        {
            if (e.id == id) return true;
        }

        return false;
    }

    size_t getUniformBlocks() @safe
    {
        return ublocks.length;
    }

    void setUniformData(uint id, void[] data) @safe
    {
        fromBind(id).bindData(data);
    }

    IBuffer getUniformBuffer(uint id) @safe
    {
        return fromBind(id);
    }

    uint getUniformBufferAlign() @trusted
    {
        return 0;
    }
}

class GLPipeline : IShaderPipeline
{
    uint id;
    GLShaderProgram _vertex, _fragment, _geometry, _compute;

    this() @trusted
    {
        glGenProgramPipelines(1, &id);
    }

    uint stageBit(StageType type) @trusted
    {
        final switch (type)
        {
            case StageType.vertex: return GL_VERTEX_SHADER_BIT;
            case StageType.fragment: return GL_FRAGMENT_SHADER_BIT;
            case StageType.geometry: return  GL_GEOMETRY_SHADER_BIT;
            case StageType.compute: return GL_COMPUTE_SHADER_BIT;
        }
    }

    void bindShader(IShaderProgram program) @trusted
    {
        GLShaderProgram gprogram = cast(GLShaderProgram) program;

        uint sb;
        if (gprogram.vertex !is null) { sb |= GL_VERTEX_SHADER_BIT; _vertex = gprogram; }
        if (gprogram.fragment !is null) { sb |= GL_FRAGMENT_SHADER_BIT; _fragment = gprogram; }
        if (gprogram.geometry !is null) { sb |= GL_GEOMETRY_SHADER_BIT; _geometry = gprogram; }
        if (gprogram.compute !is null) { sb |= GL_COMPUTE_SHADER_BIT; _compute = gprogram; }

        glUseProgramStages(id, sb, gprogram.id);
    }

    IShaderProgram vertexProgram() @safe { return _vertex; }
    IShaderProgram fragmentProgram() @safe { return _fragment; }
    IShaderProgram geometryProgram() @safe { return _geometry; }
    IShaderProgram computeProgram() @safe { return _compute; }
}

class GLTexture : ITexture
{
    uint id;
    uint glType;
    TextureType _type;
    uint activeID = 0;

    uint width = 0;
    uint height = 0;

    Logger logger;

    this(TextureType _type, Logger logger) @trusted
    {
        this._type = _type;
        this.logger = logger;

        if (_type == TextureType.oneDimensional)
            glType = GL_TEXTURE_1D;
        else
        if (_type == TextureType.twoDimensional)
            glType = GL_TEXTURE_2D;
        else
        if (_type == TextureType.threeDimensional)
            glType = GL_TEXTURE_3D;

        glCreateTextures(glType, 1, &id);
    }

    ~this() @trusted
    {
        glDeleteTextures(1, &id);
    }

    uint toGLWrap(TextureWrap wrap) @safe
    {
        if (wrap == TextureWrap.wrapR)
            return GL_TEXTURE_WRAP_R;
        else
        if (wrap == TextureWrap.wrapS)
            return GL_TEXTURE_WRAP_S;
        else
            return GL_TEXTURE_WRAP_T;
    }

    uint tpGLWrapValue(TextureWrapValue value) @safe
    {
        if (value == TextureWrapValue.clampToEdge)
            return GL_CLAMP_TO_EDGE;
        else
        if (value == TextureWrapValue.mirroredRepeat)
            return GL_MIRRORED_REPEAT;
        else
            return GL_REPEAT;
    }

    uint toGLFilter(TextureFilter filter) @safe
    {
        if (filter == TextureFilter.minFilter)
            return GL_TEXTURE_MIN_FILTER;
        else
            return GL_TEXTURE_MAG_FILTER;
    }

    uint toGLFilterValue(TextureFilterValue value) @safe
    {
        if (value == TextureFilterValue.nearest)
            return GL_NEAREST;
        else
            return GL_LINEAR;
    }

    uint dataType;

override:
    void active(uint value) @trusted
    {
        activeID = value;
    }

    void storage(StorageType storage, uint width, uint height) @trusted
    {
        debug
        {
            if (width == 0 || height == 0)
                logger.critical("The sizes of the image are set incorrectly (they are zero)");
        }

        if (_type == TextureType.oneDimensional)
        {
            glTextureStorage1D(id, 1, GLGraphManip.glStorageType(storage), width);

            this.width = width;
            this.height = 1;
        } else
        {
            glTextureStorage2D(id, 1, GLGraphManip.glStorageType(storage), width, height);

            this.width = width;
            this.height = height;
        }
    }

    void subImage(inout void[] data, uint width, uint height) @trusted
    {
        debug
        {
            if (data.length == 0)
                logger.critical("There can be no empty data! For cleaning, use `ITexture.clear`.");

            if (width == 0 || height == 0)
                logger.critical("The sizes of the image are set incorrectly (they are zero)");
        }

        if (_type == TextureType.oneDimensional)
        {
            glTextureSubImage1D(id, 0, 0, width, GL_RGBA, GL_UNSIGNED_BYTE, data.ptr);
        } else
        {
            glTextureSubImage2D(id, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data.ptr);
        }

        this.dataType = GL_RGBA;
    }

    void subData(inout void[] data, uint width, uint height) @trusted
    {
        debug
        {
            if (data.length == 0)
                logger.critical("There can be no empty data! For cleaning, use `ITexture.clear`.");

            if (width == 0 || height == 0)
                logger.critical("The sizes of the image are set incorrectly (they are zero)");
        }

        if (_type == TextureType.oneDimensional)
        {
            glTextureSubImage1D(id, 0, 0, width, GL_RED, GL_FLOAT, data.ptr);
        } else
        {
            glTextureSubImage2D(id, 0, 0, 0, width, height, GL_RED, GL_FLOAT, data.ptr);
        }

        this.dataType = GL_RED;
    }

    void[] getData() @trusted
    {
        immutable dt = this.dataType == GL_RGBA ? GL_UNSIGNED_BYTE : GL_FLOAT;
        void[] data = new void[](width * height * (dt == GL_UNSIGNED_BYTE ? 4 : float.sizeof));

        glGetTextureImage(id, 0, this.dataType, dt, cast(int) data.length, data.ptr);

        return data;
    }

    void wrap(TextureWrap wrap, TextureWrapValue value) @trusted
    {
        uint    glWrap = toGLWrap(wrap),
                glWrapValue = tpGLWrapValue(value);

        glTextureParameteri(id, glWrap, glWrapValue);
    }

    void filter(TextureFilter filter, TextureFilterValue value) @trusted
    {
        uint    glFilter = toGLFilter(filter),
                glFilterValue = toGLFilterValue(value);

        glTextureParameteri(id, glFilter, glFilterValue);
    }

    void params(uint[] parameters) @trusted
    {
        import std.range : chunks;

        foreach (kv; chunks(parameters, 2))
        {
            if (kv[0] >= TextureFilter.min &&
                kv[0] <= TextureFilter.max)
            {
                filter(
                    cast(TextureFilter) kv[0],
                    cast(TextureFilterValue) kv[1]
                );
            } else
            if (kv[0] >= TextureWrap.min &&
                kv[0] <= TextureWrap.max)
            {
                wrap(
                    cast(TextureWrap) kv[0],
                    cast(TextureWrapValue) kv[1]
                );
            } else
            {
                debug
                {
                    logger.warning("Unknown parameters for the texture.");
                }
            }
        }
    }
}

class GLFrameBuffer : IFrameBuffer
{
    uint id = 0;
    uint rid = 0;

    uint width = 0;
    uint height = 0;

    this() @trusted
    {
        glCreateFramebuffers(1, &id);
    }

    this(uint index) @safe
    {
        id = index;
    }

    ~this() @trusted
    {
        if (id != 0)
        {
            glDeleteFramebuffers(1, &id);
        }

        if (rid != 0)
        {
            glDeleteRenderbuffers(1, &rid);
        }
    }

override:
    void generateBuffer(uint width, uint height) @trusted
    {
        this.width = width;
        this.height = height;

        if (rid != 0)
        {
            glDeleteRenderbuffers(1, &rid);
        }

        glCreateRenderbuffers(1, &rid);

        glNamedRenderbufferStorage(rid, GL_RGBA8, width, height);
        glNamedFramebufferRenderbuffer(id, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rid);
    }

    void attach(ITexture texture) @trusted
    {
        GLTexture tex = cast(GLTexture) texture;

        //glBindFramebuffer(GL_FRAMEBUFFER, id);
        glNamedFramebufferTexture(id, GL_COLOR_ATTACHMENT0, tex.id, 0);
        //glFramebufferTexture2D(
        //    GL_FRAMEBUFFER,
        //    GL_COLOR_ATTACHMENT0,
        //    GL_TEXTURE_2D,
        //    tex.id,
        //    0
        //);
        //
        //glBindFramebuffer(GL_FRAMEBUFFER, 0);

        width = tex.width;
        height = tex.height;
    }

    void clear(Color!ubyte color) @trusted
    {
        glClearNamedFramebufferfv(id, GL_COLOR, 0, [color.rf, color.gf, color.bf, color.af].ptr);
    }
}

class GLGraphManip : IGraphManip
{
    import tdw = tida.window;
    import egl.egl;

    GraphBackend backend() @safe { return GraphBackend.opengl; }

    version (SDL)
    {
        import bindbc.sdl;

        SDL_GLContext sdl_ctx;
        //tdw.Window window;

        void initializeSDLImpl() @trusted
        {
            // none
        }

        void createSDLImpl(tdw.Window window, GraphicsAttributes attribs) @trusted
        {
            this.window = window;
            sdl_ctx = SDL_GL_CreateContext(window.handle);
            if (sdl_ctx is null)
                throw new Exception("SDL context not created!");
				
			GLSupport sp;
			if ((sp = loadOpenGL()) < GLSupport.gl42)
			{
				import std.conv: to;
				
				debug
				{
					import std.stdio;
					writeln("GL VERSION: ", glGetString(GL_VERSION).to!string);
					writeln(glGetString(GL_RENDERER).to!string);
					writeln(glGetString(GL_VENDOR).to!string);
				}

                if (sp < GLSupport.gl33)
				    throw new Exception("interfaceOutdated: need gl42 or gl33, well your version is " ~ to!string(sp));
			} else
			{
				import std.stdio, std.conv;
				writeln("GL VERSION: ", glGetString(GL_VERSION).to!string);
				writeln(glGetString(GL_RENDERER).to!string);
				writeln(glGetString(GL_VENDOR).to!string);
			}


            //SDL_GL_MakeCurrent(window.handle, sdl_ctx);
        }
    } else
    {
        version(Posix)
        {
            import x11.X;
            import x11.Xlib;
            import x11.Xutil;
            import tida.runtime;
            import dglx.glx;
            import egl.egl;

            version(UseXCB)
            {
                import xcb.xcb;

                enum GLX_VISUAL_ID = 0x800b;
                xcb_visualid_t visualID;
            }

            tdw.Window window;
            Display* display;
            uint displayID;
            XVisualInfo* visualInfo;
            GLXContext _context;
            GLXFBConfig bestFbcs;

            void initializePosixImpl() @trusted
            {
                version(UseXCB)
                {
                    display = XOpenDisplay(null);
                    displayID = DefaultScreen(display);
                } else
                {
                    display = runtime.display;
                    displayID = runtime.displayID;
                }

                version(WithEGL)
                {
                    loadEGLLibrary();
                } else
                    loadGLXLibrary();

                debug
                {
                    scope(failure)
                        logger.critical("GLX/EGL library is not a loaded!");
                }
            }

            void createGLXPosixImpl(tdw.Window window, GraphicsAttributes attribs) @trusted
            {
                import dglx.glx;
                version(UseXCB) import xcb.xcb;
                import std.exception : enforce;
                import std.conv : to;

                this.window = window;

                int[] glxAttributes =
                [
                    GLX_X_RENDERABLE    , True,
                    GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
                    GLX_RENDER_TYPE     , GLX_RGBA_BIT,
                    GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR,
                    GLX_RED_SIZE        , attribs.redSize,
                    GLX_GREEN_SIZE      , attribs.greenSize,
                    GLX_BLUE_SIZE       , attribs.blueSize,
                    GLX_ALPHA_SIZE      , attribs.alphaSize,
                    GLX_DOUBLEBUFFER    , attribs.bufferMode == BufferMode.doubleBuffer ? 1 : 0,
                    None
                ];

                int fbcount = 0;
                scope fbc = glXChooseFBConfig(  display, displayID,
                                                glxAttributes.ptr, &fbcount);
                scope(success) XFree(fbc);
                enforce!Exception(fbc);

                int bestFbc = -1, bestNum = -1;
                foreach (int i; 0 .. fbcount)
                {
                    int sampBuff, samples;
                    glXGetFBConfigAttrib(   display, fbc[i],
                                            GLX_SAMPLE_BUFFERS, &sampBuff);
                    glXGetFBConfigAttrib(   display, fbc[i],
                                            GLX_SAMPLES, &samples);

                    if (bestFbc < 0 || (sampBuff && samples > bestNum))
                    {
                        bestFbc = i;
                        bestNum = samples;
                    }
                }

                this.bestFbcs = fbc[bestFbc];
                enforce!Exception(bestFbcs);

                version(UseXCB)
                {
                    glXGetFBConfigAttrib(display, bestFbcs, GLX_VISUAL_ID , cast(int*) &visualID);
                } else
                {
                    this.visualInfo = glXGetVisualFromFBConfig(runtime.display, bestFbcs);
                    enforce!Exception(visualInfo);
                }

                version(UnsupportNewFeature)
                {
                    _context = glXCreateNewContext( display, this.bestFbcs,
                                                    GLX_RGBA_TYPE, null, true);
                } else
                {
                    int[] ctxAttrib = [
                        GLX_CONTEXT_MAJOR_VERSION_ARB, 3,
                        GLX_CONTEXT_MINOR_VERSION_ARB, 3,
                        None
                    ];
                    _context = glXCreateContextAttribsARB(display, this.bestFbcs, null, true, ctxAttrib.ptr);
                    enforce!Exception(_context);
                }

                window.destroy();

                version(UseXCB)
                {
                    window.createFromVisual(visualID, 100, 100);
                    glXMakeCurrent(display, window.handle, _context);
                } else
                {
                    window.createFromXVisual(visualInfo, 100, 100);
                    glXMakeCurrent(display, window.handle, _context);
                }

                window.show();

                debug
                {
                    scope(failure)
                        logger.critical("Window or/and context is not a created!");
                }
            }
        }

        version(Windows)
        {
            import tida.runtime;
            import core.sys.windows.windows;

            pragma(lib, "opengl32.lib");
            pragma(lib, "winmm.lib");

            HWND handle;
            HDC dc;

            void initializeWinInpl() @trusted
            {
            // none
            }

            void createWinImpl(tdw.Window window, GraphicsAttributes attribs) @trusted
            {
                import wgl.wgl;

                handle = window.handle;

                auto hInstance = runtime.instance;

                auto deviceHandle = GetDC(handle);

                immutable colorBits =   attribs.redSize + 
                                        attribs.greenSize +
                                        attribs.blueSize +
                                        attribs.alphaSize;
                
                immutable stencilSize = 0;

                immutable pfdFlags = attribs.bufferMode == BufferMode.singleBuffer ?
                    (PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL) :
                    (PFD_DOUBLEBUFFER | PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL);

                PIXELFORMATDESCRIPTOR pfd;
                pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
                pfd.nVersion = 1;
                pfd.dwFlags = pfdFlags;
                pfd.iPixelType = PFD_TYPE_RGBA;
                pfd.cRedBits = cast(ubyte) attribs.redSize;
                pfd.cGreenBits = cast(ubyte) attribs.greenSize;
                pfd.cBlueBits = cast(ubyte) attribs.blueSize;
                pfd.cAlphaBits = cast(ubyte) attribs.alphaSize;
                pfd.cDepthBits = cast(ubyte) 24;
                pfd.cStencilBits = cast(ubyte) stencilSize;
                pfd.cColorBits = cast(ubyte) colorBits;
                pfd.iLayerType = PFD_MAIN_PLANE;

                WINDOWINFO winfo;
                RECT wsize;

                GetWindowInfo(window.handle, &winfo);
                GetWindowRect(window.handle, &wsize);

                import std.utf;

                auto fakewindow_handle = CreateWindow(window._title.toUTFz!(wchar*), 
                                            window._title.toUTFz!(wchar*),
                                            WS_CAPTION | WS_SYSMENU | WS_CLIPSIBLINGS | 
                                            WS_CLIPCHILDREN | WS_THICKFRAME,
                                            wsize.left, wsize.top, wsize.right, 
                                            wsize.bottom, null, null, 
                                            runtime.instance, null);

                //this.handle = window.handle;
                        
                if (fakewindow_handle is null)
                    throw new Exception("OpenGL window context failed created!");

                auto fake_deviceHandle = GetDC(fakewindow_handle);
                //window.dc = deviceHandle;       
                //window.resize(wsize.right, wsize.bottom);

                auto chsPixel = ChoosePixelFormat(fake_deviceHandle, &pfd);
                if (chsPixel == 0)
                {
                    import std.conv : to;
                    LPSTR messageBuffer = null;

                    size_t size = FormatMessageA(
                        FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                        null, 
                        cast(uint) GetLastError(), 
                        MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US), 
                        cast(LPSTR) &messageBuffer, 
                        0, 
                        null
                    );
                    throw new Exception(messageBuffer.to!string);
                }

                if (!SetPixelFormat(fake_deviceHandle, chsPixel, &pfd))
                {
                    throw new Exception("interfaceOutdated");
                }

                auto ctx = wglCreateContext(fake_deviceHandle);
                if (!wglMakeCurrent(fake_deviceHandle, ctx))
                {
                    throw new Exception("interfaceOutdated");
                }

                wgl.wgl.initWGL();

                //PIXELFORMATDESCRIPTOR pfd;
                pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
                pfd.nVersion = 1;
                pfd.dwFlags = pfdFlags;
                pfd.iPixelType = PFD_TYPE_RGBA;
                pfd.cRedBits = cast(ubyte) attribs.redSize;
                pfd.cGreenBits = cast(ubyte) attribs.greenSize;
                pfd.cBlueBits = cast(ubyte) attribs.blueSize;
                pfd.cAlphaBits = cast(ubyte) attribs.alphaSize;
                pfd.cDepthBits = cast(ubyte) 24;
                pfd.cStencilBits = cast(ubyte) stencilSize;
                pfd.cColorBits = cast(ubyte) colorBits;
                pfd.iLayerType = PFD_MAIN_PLANE;

                // chsPixel = ChoosePixelFormat(deviceHandle, &pfd);
                // if (chsPixel == 0)
                // {
                //     import std.conv : to;
                //     LPSTR messageBuffer = null;

                //     size_t size = FormatMessageA(
                //         FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                //         null, 
                //         cast(uint) GetLastError(), 
                //         MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US), 
                //         cast(LPSTR) &messageBuffer, 
                //         0, 
                //         null
                //     );
                //     throw new Exception(messageBuffer.to!string);
                // }

                // if (!SetPixelFormat(deviceHandle, chsPixel, &pfd))
                // {
                //     throw new Exception("interfaceOutdated");
                // }

                int[] iattrib =  
                [
                    WGL_SUPPORT_OPENGL_ARB, true,
                    WGL_DRAW_TO_WINDOW_ARB, true,
                    WGL_DOUBLE_BUFFER_ARB, attribs.bufferMode == BufferMode.singleBuffer ? false : true,
                    WGL_RED_BITS_ARB, attribs.redSize,
                    WGL_GREEN_BITS_ARB, attribs.greenSize,
                    WGL_BLUE_BITS_ARB, attribs.blueSize,
                    WGL_ALPHA_BITS_ARB, attribs.alphaSize,
                    WGL_DEPTH_BITS_ARB, 24,
                    WGL_COLOR_BITS_ARB, colorBits,
                    WGL_STENCIL_BITS_ARB, stencilSize,
                    WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
                    0
                ];

                uint nNumFormats;
                int[20] nPixelFormat;
                if (!wglChoosePixelFormatARB(
                    deviceHandle,   
                    iattrib.ptr, 
                    null,
                    20, nPixelFormat.ptr,
                    &nNumFormats
                ))
                {
                    throw new Exception("interfaceOutdated");
                }

                bool isSuccess = false;
                foreach (i; 0 .. nNumFormats)
                {
                    DescribePixelFormat(deviceHandle, nPixelFormat[i], pfd.sizeof, &pfd);
                    if (SetPixelFormat(deviceHandle, nPixelFormat[i], &pfd) == true)
                    {
                        isSuccess = true;
                        break;
                    }
                }

                if (!isSuccess)
                {
                    throw new Exception("interfaceOutdated");
                }

                // Use deprecated functional
                int[] attrib =  
                [
                    WGL_CONTEXT_MAJOR_VERSION_ARB, 4,
                    WGL_CONTEXT_MINOR_VERSION_ARB, 2,
                    WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
                    0
                ];

                auto mctx = wglCreateContextAttribsARB(     deviceHandle, 
                                                            null, 
                                                            attrib.ptr);

                if (mctx is null)
                {
                    attrib =  
                    [
                        WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
                        WGL_CONTEXT_MINOR_VERSION_ARB, 3,
                        WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
                        WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB,
                        0
                    ];

                    mctx = wglCreateContextAttribsARB(      deviceHandle, 
                                                            null, 
                                                            attrib.ptr);

                    if (mctx is null)
                    {
                        throw new Exception("interfaceOutdated");
                    }
                }

                wglMakeCurrent(fake_deviceHandle, null);
                wglDeleteContext(ctx);
                ReleaseDC(fakewindow_handle, fake_deviceHandle);
                DestroyWindow(fakewindow_handle);
                wglMakeCurrent(null, null);

                if (!wglMakeCurrent(deviceHandle, mctx))
                {
                    throw new Exception("interfaceOutdated");
                }
                
                GLSupport sp;
                if ((sp = loadOpenGL()) < GLSupport.gl42)
                {
                    import std.conv: to;
                    
                    debug
                    {
                        import std.stdio;
                        writeln("GL VERSION: ", glGetString(GL_VERSION).to!string);
                    }

                    throw new Exception("interfaceOutdated: need gl42, well your version is " ~ to!string(sp));
                }

                this.dc = deviceHandle;
            }
        }

        version(WithEGL)
        {
            import egl.egl;
            EGLDisplay dpy;
            EGLSurface surf;
            EGLContext ctx;

            void createEGLAny(tdw.Window window, GraphicsAttributes attribs) @trusted
            {
                int major, minor;
                version(Windows)
                    dpy = eglGetDisplay(runtime.instance);
                else
                version(Posix)
                    dpy = eglGetDisplay(runtime.display);

                eglInitialize(dpy, &major, &minor);
                int[] configAttributes =
                [
                    EGL_BUFFER_SIZE, 0,
                    EGL_RED_SIZE, attribs.redSize,
                    EGL_GREEN_SIZE, attribs.greenSize,
                    EGL_BLUE_SIZE, attribs.blueSize,
                    EGL_ALPHA_SIZE, attribs.alphaSize,
                    0x303F, 12_430,
                    EGL_DEPTH_SIZE, 24,
                    0x3040, 0x0008, // opengl flag
                    EGL_SURFACE_TYPE, EGL_WINDOW_BIT,
                    0
                ];

                int numConfigs;
                EGLConfig windowConfig;
                eglChooseConfig(dpy, &configAttributes[0], &windowConfig, 1, &numConfigs);

                int[] attribList = [0];
                surf = eglCreateWindowSurface(dpy, windowConfig, window.handle, &attribList[0]);

                int[] ctxAttribList = [0x3098, 4, 0x30FB, 2, 0x30FD, 0x00000001, 0];
                ctx = eglCreateContext(dpy, windowConfig, null, &ctxAttribList[0]);
                eglMakeCurrent(dpy, surf, surf, ctx);
            }
        }
    }

    GLPipeline currentProgram;
    GLVertexInfo currentVertex;
    GLTexture[] currentTexture;
    GLFrameBuffer mainFB;
    GLFrameBuffer rmainFB; // РЕальный
    GLFrameBuffer currentFB;
    GLBuffer[] buffers;

    Color!ubyte _clearColor = Color!ubyte.init;

    Logger logger;

    this() @trusted
    {
        debug
        {
            logger = stdThreadLocalLog;
        }
    }

    int glMode(ModeDraw mode)
    {
        if (mode == ModeDraw.points)
            return GL_POINTS;
        else
        if (mode == ModeDraw.line)
            return GL_LINES;
        else
        if (mode == ModeDraw.lineStrip)
            return GL_LINE_STRIP;
        else
        if (mode == ModeDraw.triangle)
            return GL_TRIANGLES;
        else
        if (mode == ModeDraw.triangleStrip)
            return GL_TRIANGLE_FAN;

        return 0;
    }

    alias glComputeType = glStorageType;

    static uint glStorageType(StorageType type)
    {
        final switch(type)
        {
            case ComputeDataType.r32f:
                return GL_R32F;

            case ComputeDataType.rgba32f:
                return GL_RGBA32F;

            case ComputeDataType.rg32f:
                return GL_RG32F;

            case ComputeDataType.rgba32ui:
                return GL_RGBA32UI;

            case ComputeDataType.rgba32i:
                return GL_RGBA32I;

            case ComputeDataType.r32ui:
                return GL_R32UI;

            case ComputeDataType.r32i:
                return GL_R32I;

            case ComputeDataType.rgba8i:
                return GL_RGBA8I;

            case ComputeDataType.rgba8:
                return GL_RGBA8;

            case ComputeDataType.r8i:
                return GL_R8I;
        }
    }

    // В общем здесь беда.
    // Они не применяются. Смотрю в renderdoc - вообще там нули, у вершинного шейдера всё.
    // Думаю, что не надо было применять separated shaders но теперь фигли)))
    void uniformUse(ref uint index) @trusted
    {
        size_t numBlocks;

        foreach (e; [currentProgram._vertex, currentProgram._geometry, currentProgram._fragment])
        {
            if (e is null)
                continue;
            
            foreach (i; 0 .. e.getUniformBlocks)
            {
                GLShaderProgram.MemoryUniform mu = e.ublocks[i];
                glBindBufferBase(GL_UNIFORM_BUFFER, index, mu.buffer.id);
                index++;    
            }
        }
    }
    
    bool __capture = true;
    float _vx, _vy, _vw, _vh;
    tdw.Window window;
    uint clipMode = GL_LOWER_LEFT;

override:
    void initialize(bool discrete) @trusted
    {
        logger.info("Load shared libs...");

        if (discrete)
        {
            version(Windows)
            {
                auto cuda = LoadLibraryA("nvcuda.dll");
                if (cuda !is null) {}
            }
        }

        version(SDL)
        {
            initializeSDLImpl();
        } else
        {
            version(Posix)
            {
                initializePosixImpl();
            } else
            version(Windows)
            {
                version(WithEGL)
                {
                    import egl.egl;
                    loadEGLLibrary();
                } else
                    initializeWinInpl();
            }
        }
        logger.info("Success!");
    }

    void createAndBindSurface(tdw.Window window, GraphicsAttributes attribs) @trusted
    {
        import bindbc.opengl.util;

        this.window = window;

        version(SDL)
        {
			if (window.handle is null || window is null) throw new Exception("Not valid handle!");
			
            createSDLImpl(window, attribs);
        } else
        {
            version(Posix)
            {
                version(WithEGL)
                {
                    createEGLAny(window, attribs);
                } else
                    createGLXPosixImpl(window, attribs);
            } else
            version(Windows)
            {
                version(WithEGL)
                {
                    createEGLAny(window, attribs);
                } else
                    createWinImpl(window, attribs);
            }
        }

        loadGraphicsLibrary();

        mainFB = new GLFrameBuffer(0);
        rmainFB = mainFB;
        currentFB = mainFB;

        if (glSpirvSupport())
        {
            loadExtendedGLSymbol(cast(void**) &glSpecializeShader, "glSpecializeShader");
        }
    }

    void update() @trusted
    {

    }

    void pointSize(float size) @trusted
    {
        glPointSize(size);
    }

    void viewport(float x, float y, float w, float h) @trusted
    {
        debug
        {
            if (w < 0 || h < 0)
                logger.warning("The port size is incorrectly set!");
        }

        if (this.__capture)
        {
            this._vx = x;
            this._vy = y;
            this._vw = w;
            this._vh = h;
        }

        glViewport(
            cast(uint) x,
            cast(uint) y,
            cast(uint) w,
            cast(uint) h
        );

        currentFB.width = cast(uint) w;
        currentFB.height = cast(uint) h;
    }

    void blendFactor(BlendFactor src, BlendFactor dst, bool state) @trusted
    {
        int glBlendFactor(BlendFactor factor)
        {
            if (factor == BlendFactor.Zero)
                return GL_ZERO;
            else
            if (factor == BlendFactor.One)
                return GL_ONE;
            else
            if (factor == BlendFactor.SrcColor)
                return GL_SRC_COLOR;
            else
            if (factor == BlendFactor.DstColor)
                return GL_DST_COLOR;
            else
            if (factor == BlendFactor.OneMinusSrcColor)
                return GL_ONE_MINUS_SRC_COLOR;
            else
            if (factor == BlendFactor.OneMinusDstColor)
                return GL_ONE_MINUS_DST_COLOR;
            else
            if (factor == BlendFactor.SrcAlpha)
                return GL_SRC_ALPHA;
            else
            if (factor == BlendFactor.DstAlpha)
                return GL_DST_ALPHA;
            else
            if (factor == BlendFactor.OneMinusSrcAlpha)
                return GL_ONE_MINUS_SRC_ALPHA;
            else
            if (factor == BlendFactor.OneMinusDstAlpha)
                return GL_ONE_MINUS_DST_ALPHA;

            return 0;
        }

        glBlendFunc(glBlendFactor(src), glBlendFactor(dst));

        if (state)
            glEnable(GL_BLEND);
        else
            glDisable(GL_BLEND);
    }

    void clearColor(Color!ubyte color) @trusted
    {
        _clearColor = color;
    }

    void clear() @trusted
    {
        currentFB.clear(_clearColor);
    }

    void begin() @trusted
    {
        debug
        {
            if (currentVertex is null)
                logger.warning("The peaks for drawing are not set!");

            if (currentProgram is null)
                logger.warning("A shader program for drawing are not set!");
        }

        glBindFramebuffer(GL_FRAMEBUFFER, currentFB.id);

        if (currentVertex !is null)
        {
            glBindVertexArray(currentVertex.id);
        }

        if (currentProgram !is null)
        {
            glBindProgramPipeline(currentProgram.id);
        }

        if (currentProgram !is null)
        {
            foreach (e; currentTexture)
            {
                glBindTextureUnit(e.activeID, e.id);
            }
        }
    }

    void compute(ComputeDataType[] type) @trusted
    {
        import std.algorithm : map;
        import std.range : array;

        if (currentProgram !is null)
        {
            glBindProgramPipeline(currentProgram.id);
        }

        foreach (size_t i, GLTexture e; currentTexture)
        {
            glBindImageTexture(e.activeID, e.id, 0, false, 0, GL_WRITE_ONLY, glComputeType(type[i]));
        }

        if (buffers.length > 0)
        {
            uint[] ids = buffers.map!(e => e.id).array;
            glBindBuffersBase(GL_SHADER_STORAGE_BUFFER, 0, cast(int) ids.length, ids.ptr);
        }

        if (currentTexture.length == 0)
        {
            glDispatchCompute(1, 1, 1);
        } else
        {
            glDispatchCompute(currentTexture[0].width, currentTexture[0].height, 1);
        }

        glMemoryBarrier(GL_ALL_BARRIER_BITS);

        buffers = [];
        currentTexture = [];
    }

    void draw(ModeDraw mode, uint first, uint count) @trusted
    {
        uint gmode = glMode(mode);

        uint index = 0;
        uniformUse(index);

        glDrawArrays(gmode, first, count);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);

        currentProgram = null;
        currentVertex = null;
        currentTexture.length = 0;
    }

    void drawIndexed(ModeDraw mode, uint icount) @trusted
    {
        uint gmode = glMode(mode);

        uint index = 0;
        uniformUse(index);

        glDrawElements(gmode, icount, GL_UNSIGNED_INT, null);

        currentProgram = null;
        currentVertex = null;
        currentTexture.length = 0;
    }

    void bindProgram(IShaderPipeline program) @trusted
    {
        currentProgram = cast(GLPipeline) program;
    }

    void bindVertexInfo(IVertexInfo vertInfo) @trusted
    {
        currentVertex = cast(GLVertexInfo) vertInfo;
    }

    void bindTexture(ITexture texture) @trusted
    {
        if (texture is null)
        {
            debug
            {
                logger.warning("The zero pointer is sent to the function, which may be an error.");
            }

            return;
        }

        currentTexture ~= cast(GLTexture) texture;
    }

    void bindBuffer(IBuffer buffer) @trusted
    {
        if (buffer is null)
        {
            debug
            {
                logger.warning("The zero pointer is sent to the function, which may be an error.");
            }

            return;
        }

        GLBuffer bf = cast(GLBuffer) buffer;

        debug
        {
            if (bf._type != BufferType.storageBuffer)
            {
                logger.warning("A buffer is introduced that cannot serve for calculations. In other situations, it will not be used.");
            }
        }

        this.buffers ~= bf;
    }

    void drawning() @trusted
    {
        // if (currentFB !is rmainFB)
        // {
        //     glBlitNamedFramebuffer(
        //         currentFB.id,
        //         rmainFB.id,
        //         0, 0,
        //         currentFB.width, currentFB.height,
        //         0, 0,
        //         rmainFB.width, rmainFB.height,
        //         GL_COLOR_BUFFER_BIT,
        //         GL_LINEAR
        //     );
        // }

        version(SDL)
        {
            SDL_GL_SwapWindow(window.handle);
        } else
        {
            version(Posix)
            {
                glXSwapBuffers(display, window.handle);
            } else
            version (Windows)
            {
                SwapBuffers(dc);
            }
        }
    }

    void setFrameBuffer(IFrameBuffer ifb) @trusted
    {
        if (ifb is null)
        {
            currentFB = mainFB;
        } else
        {
            currentFB = cast(GLFrameBuffer) ifb;
        }

        if (currentFB is rmainFB)
        {
            version(Windows)
                immutable bs = window.windowBorderSize;
            else
                immutable bs = 0;

            this.__capture = false;
            viewport(
                _vx, _vy + bs, _vw, _vh
            );
            this.__capture = true;
            glClipControl(GL_LOWER_LEFT, GL_ZERO_TO_ONE);
            clipMode = GL_LOWER_LEFT;
        } else
        {
            viewport(
                _vx, _vy, _vw, _vh
            );
            glClipControl(GL_UPPER_LEFT, GL_ZERO_TO_ONE);
            clipMode = GL_UPPER_LEFT;
        }
    }

    IFrameBuffer cmainFrameBuffer() @safe
    {
        return mainFB;
    }

    void setCMainFrameBuffer(IFrameBuffer fb) @safe
    {
        if (fb is null)
            mainFB = rmainFB;
        else
            mainFB = cast(GLFrameBuffer) fb;
    }
    
    string[2] rendererInfo() @safe
    {
    	return [glVendor(), glRenderer()];
    }

    IShaderManip createShader(StageType stage) @trusted
    {
        return new GLShaderManip(stage, logger);
    }

    IShaderProgram createShaderProgram() @trusted
    {
        return new GLShaderProgram(logger);
    }

    IShaderPipeline createShaderPipeline() @safe
    {
        return new GLPipeline();
    }

    IBuffer createBuffer(BufferType buffType = BufferType.array) @trusted
    {
        return new GLBuffer(buffType);
    }

    immutable(IBuffer) createImmutableBuffer(BufferType buffType = BufferType.array, inout void[] data = null) @trusted
    {
        return new immutable GLBuffer(buffType, data);
    }

    IVertexInfo createVertexInfo() @trusted
    {
        return new GLVertexInfo();
    }

    ITexture createTexture(TextureType type) @trusted
    {
        return new GLTexture(type, logger);
    }

    IFrameBuffer createFrameBuffer() @trusted
    {
        return new GLFrameBuffer();
    }

    IFrameBuffer mainFrameBuffer() @trusted
    {
        return mainFB;
    }

    debug
    {
        void setupLogger(Logger logger = stdThreadLocalLog) @safe
        {
            glSetupDriverLog(logger);
            this.logger = logger;
        }
    }
}
