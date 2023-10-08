module wgl.wgl;

version(Windows):
import bindbc.loader;
import core.sys.windows.windows;

pragma(lib, "opengl32.lib");
pragma(lib, "winmm.lib");

enum
{
    WGL_DRAW_TO_WINDOW_ARB = 0x2001,
    WGL_RED_BITS_ARB = 0x2015,
    WGL_GREEN_BITS_ARB = 0x2017,
    WGL_BLUE_BITS_ARB = 0x2019,
    WGL_ALPHA_BITS_ARB = 0x201B,
    WGL_DOUBLE_BUFFER_ARB = 0x2011,
    WGL_DEPTH_BITS_ARB = 0x2022,
    WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091,
    WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092,
    WGL_CONTEXT_FLAGS_ARB = 0x2094,
    WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x0002,
    WGL_CONTEXT_COMPATIBILITY_PROFILE_BIT_ARB = 0x00000002,
    WGL_SUPPORT_OPENGL_ARB = 0x2010,
    WGL_COLOR_BITS_ARB = 0x2014,
    WGL_STENCIL_BITS_ARB = 0x2023,
    WGL_ACCELERATION_ARB = 0x2003,
    WGL_FULL_ACCELERATION_ARB = 0x2027,
    WGL_PIXEL_TYPE_ARB = 0x2013, 
    WGL_TYPE_RGBA_ARB = 0x202B,
    WGL_CONTEXT_PROFILE_MASK_ARB = 0x9126,
    WGL_CONTEXT_CORE_PROFILE_BIT_ARB = 0x00000001,

    WGL_NUMBER_PIXEL_FORMATS_ARB = 0x2000
}

alias FwglGetExtensionsStringARB = extern(C) char* function(HDC hdc);
alias FwglGetPixelFormatAttribivEXT = extern(C) bool function(HDC hdc, int iPixelFormat, int iLayerPlane, uint nAttributes, int* piAttribs, int* piVals);
alias FwglChoosePixelFormatARB = extern(C) bool function( HDC hdc,
                                                    int *piAttribIList,
                                                    float *pfAttribFList,
                                                    uint nMaxFormats,
                                                    int *piFormats,
                                                    uint *nNumFormats);
alias FwglGetPixelFormatAttribivARB  = extern(C) bool function( HDC hdc,
                                                                int iPixelFormat,
                                                                int iLayerPlane,
                                                                UINT nAttributes,
                                                                const int *piAttributes,
                                                                int *piValues);


alias FwglCreateContextAttribsARB = extern(C) HGLRC function(HDC, HGLRC, int*);

__gshared
{
    FwglGetExtensionsStringARB wglGetExtensionsStringARB;
    FwglGetPixelFormatAttribivEXT wglGetPixelFormatAttribivEXT;
    FwglChoosePixelFormatARB wglChoosePixelFormatARB;
    FwglCreateContextAttribsARB wglCreateContextAttribsARB;
    FwglGetPixelFormatAttribivARB wglGetPixelFormatAttribivARB;
}

struct WGLResult
{
    bool hasEnumExts = true;
    bool hasGetPixfAttrib = true;
}

export WGLResult initWGL() @trusted
{
    import std.string : toStringz;

    WGLResult result;
    // bool hasEnumExts = true;
    // bool hasGetPixfAttrib = true;
    wglGetExtensionsStringARB = cast(FwglGetExtensionsStringARB) wglGetProcAddress("wglGetExtensionsStringARB".toStringz);
    if (wglGetExtensionsStringARB is null)
        result.hasEnumExts = false;

    wglGetPixelFormatAttribivEXT = cast(FwglGetPixelFormatAttribivEXT) wglGetProcAddress("wglGetPixelFormatAttribivEXT");
    if (wglGetPixelFormatAttribivEXT is null)
    {
        // how push it? Logger?
        result.hasGetPixfAttrib = false;
    }

    wglChoosePixelFormatARB = cast(FwglChoosePixelFormatARB) wglGetProcAddress("wglChoosePixelFormatARB");
    if (wglChoosePixelFormatARB is null)
        throw new Exception("Terminate!");

    wglCreateContextAttribsARB = cast(FwglCreateContextAttribsARB) wglGetProcAddress("wglCreateContextAttribsARB");
    if (wglCreateContextAttribsARB is null)
        throw new Exception("Terminate!");

    wglGetPixelFormatAttribivARB = cast(FwglGetPixelFormatAttribivARB) wglGetProcAddress("wglGetPixelFormatAttribivARB");
    if (wglGetPixelFormatAttribivARB is null)
        throw new Exception("Terminate!");

    return result;
}