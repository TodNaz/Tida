module egl.egl;

import bindbc.loader;

alias EGLDisplay = void*;
alias EGLConfig = void*;
alias EGLSurface = void*;
alias EGLContext = void*;

enum EGL_SUCCESS	=	       0x3000;
enum EGL_NOT_INITIALIZED	=       0x3001;
enum EGL_BAD_ACCESS	=	       0x3002;
enum EGL_BAD_ALLOC	=	       0x3003;
enum EGL_BAD_ATTRIBUTE	=       0x3004;
enum EGL_BAD_CONFIG	=	       0x3005;
enum EGL_BAD_CONTEXT	=	       0x3006;
enum EGL_BAD_CURRENT_SURFACE =       0x3007;
enum EGL_BAD_DISPLAY	=	       0x3008;
enum EGL_BAD_MATCH	=	       0x3009;
enum EGL_BAD_NATIVE_PIXMAP	=       0x300A;
enum EGL_BAD_NATIVE_WINDOW	=       0x300B;
enum EGL_BAD_PARAMETER	=       0x300C;
enum EGL_BAD_SURFACE	=	       0x300D;
enum EGL_CONTEXT_LOST	=       0x300E;
/* 0x300F - 0x301F reserved for additional errors. */

/*
** Config attributes
*/
enum EGL_BUFFER_SIZE	=	       0x3020;
enum EGL_ALPHA_SIZE	=	       0x3021;
enum EGL_BLUE_SIZE	=	       0x3022;
enum EGL_GREEN_SIZE	=	       0x3023;
enum EGL_RED_SIZE	=	       0x3024;
enum EGL_DEPTH_SIZE	=	       0x3025;
enum EGL_STENCIL_SIZE	=       0x3026;
enum EGL_CONFIG_CAVEAT	=       0x3027;
enum EGL_CONFIG_ID	=	       0x3028;
enum EGL_LEVEL	=	       0x3029;
enum EGL_MAX_PBUFFER_HEIGHT	=       0x302A;
enum EGL_MAX_PBUFFER_PIXELS	=       0x302B;
enum EGL_MAX_PBUFFER_WIDTH	=       0x302C;
enum EGL_NATIVE_RENDERABLE	=       0x302D;
enum EGL_NATIVE_VISUAL_ID	=       0x302E;
enum EGL_NATIVE_VISUAL_TYPE	=       0x302F;
/*enum EGL_PRESERVED_RESOURCES	 0x3030*/
enum EGL_SAMPLES	=	       0x3031;
enum EGL_SAMPLE_BUFFERS	=       0x3032;
enum EGL_SURFACE_TYPE	=       0x3033;
enum EGL_TRANSPARENT_TYPE	=       0x3034;
enum EGL_TRANSPARENT_BLUE_VALUE =    0x3035;
enum EGL_TRANSPARENT_GREEN_VALUE =   0x3036;
enum EGL_TRANSPARENT_RED_VALUE =     0x3037;
enum EGL_NONE	=	       0x3038;	/* Also a config value */
enum EGL_BIND_TO_TEXTURE_RGB =       0x3039;
enum EGL_BIND_TO_TEXTURE_RGBA =      0x303A;
enum EGL_MIN_SWAP_INTERVAL	=       0x303B;
enum EGL_MAX_SWAP_INTERVAL	=       0x303C;

/*
** Config values
*/
enum EGL_DONT_CARE	=	       (-1);

enum EGL_SLOW_CONFIG	=	       0x3050;	/* EGL_CONFIG_CAVEAT value */
enum EGL_NON_CONFORMANT_CONFIG =     0x3051;	/* " */
enum EGL_TRANSPARENT_RGB	=       0x3052;	/* EGL_TRANSPARENT_TYPE value */
enum EGL_NO_TEXTURE	=	       0x305C;	/* EGL_TEXTURE_FORMAT/TARGET value */
enum EGL_TEXTURE_RGB	=	       0x305D;	/* EGL_TEXTURE_FORMAT value */
enum EGL_TEXTURE_RGBA	=       0x305E;	/* " */
enum EGL_TEXTURE_2D	=	       0x305F;	/* EGL_TEXTURE_TARGET value */

/*
** Config attribute mask bits
*/
enum EGL_PBUFFER_BIT	=	       0x01;	/* EGL_SURFACE_TYPE mask bit */
enum EGL_PIXMAP_BIT	=	       0x02;	/* " */
enum EGL_WINDOW_BIT	=	       0x04;	/* " */

/*
** String names
*/
enum EGL_VENDOR	=	       0x3053;	/* eglQueryString target */
enum EGL_VERSION	=	       0x3054;	/* " */
enum EGL_EXTENSIONS	=	       0x3055;	/* " */

/*
** Surface attributes
*/
enum EGL_HEIGHT	=	       0x3056;
enum EGL_WIDTH	=	       0x3057;
enum EGL_LARGEST_PBUFFER	=       0x3058;
enum EGL_TEXTURE_FORMAT	=       0x3080;	/* For pbuffers bound as textures */
enum EGL_TEXTURE_TARGET	=       0x3081;	/* " */
enum EGL_MIPMAP_TEXTURE	=       0x3082;	/* " */
enum EGL_MIPMAP_LEVEL	=       0x3083;	/* " */

/*
** BindTexImage / ReleaseTexImage buffer target
*/
enum EGL_BACK_BUFFER	=	       0x3084;

/*
** Current surfaces
*/
enum EGL_DRAW	=	       0x3059;
enum EGL_READ	=	       0x305A;

/*
** Engines
*/
enum EGL_CORE_NATIVE_ENGINE	=       0x305B;

version(Windows)
{
    alias NativeDpyType = void*;
    alias NativeWndType = void*;
}
else
version(Posix)
{
    alias NativeDpyType = void*;
    alias NativeWndType = ulong;
}

extern(C) 
{
    alias eglGetDisplayf = EGLDisplay function(NativeDpyType);

    alias eglInitializef = bool function(EGLDisplay, int* major, int* minor);
    alias eglTerminatef = bool function(EGLDisplay);
    alias eglGetConfigsf = bool function(EGLDisplay, EGLDisplay*, int configSize, int* numConfigs);
    alias eglGetConfigAttribf = bool function(EGLDisplay, EGLConfig, int attrib, int* value);
    alias eglChooseConfigf = bool function(EGLDisplay, int* attriblist, EGLConfig*, int configSize, int* num_config);
    alias eglCreateWindowSurfacef = EGLSurface function(EGLDisplay, EGLConfig, NativeWndType, int* attrib_list);
    alias eglDestroySurfacef = bool function(EGLDisplay, EGLSurface);
    alias eglSwapIntervalf = bool function(EGLDisplay, int interval);
    alias eglCreateContextf = EGLContext function(EGLDisplay, EGLConfig, EGLContext share, int* attribs);
    alias eglDestroyContextf = bool function(EGLDisplay, EGLContext);
    alias eglMakeCurrentf = bool function(EGLDisplay, EGLSurface draw, EGLSurface read, EGLContext ctx);
    alias eglSwapBuffersf = bool function(EGLDisplay, EGLSurface draw);
}

__gshared
{
    eglGetDisplayf eglGetDisplay;
    eglInitializef eglInitialize;
    eglTerminatef eglTerminate;
    eglGetConfigsf eglGetConfigs;
    eglGetConfigAttribf eglGetConfigAttrib;
    eglChooseConfigf eglChooseConfig;
    eglCreateWindowSurfacef eglCreateWindowSurface;
    eglDestroySurfacef eglDestroySurface;
    eglSwapIntervalf eglSwapInterval;
    eglCreateContextf eglCreateContext;
    eglDestroyContextf eglDestroyContext;
    eglMakeCurrentf eglMakeCurrent;
    eglSwapBuffersf eglSwapBuffers;
    SharedLib egllib;
}

void loadEGLLibrary() @trusted
{
    import std.process : environment;
    import std.string : split;
    import std.file;
    import std.algorithm;

    version(Windows)
        immutable splitPoint = ";";
    else
        immutable splitPoint = ":";

    string[] paths = environment.get("PATH").split(splitPoint) ~ [getcwd()];

    bool loadLib(string path)
    {
        import std.string : toStringz;

        egllib = load(path.toStringz);
        if (egllib == invalidHandle)
            return false;

        egllib.bindSymbol(cast(void**) &eglGetDisplay, "eglGetDisplay");
        egllib.bindSymbol(cast(void**) &eglInitialize, "eglInitialize");
        egllib.bindSymbol(cast(void**) &eglTerminate, "eglTerminate");
        egllib.bindSymbol(cast(void**) &eglGetConfigs, "eglGetConfigs");
        egllib.bindSymbol(cast(void**) &eglGetConfigAttrib, "eglGetConfigAttrib");
        egllib.bindSymbol(cast(void**) &eglChooseConfig, "eglChooseConfig");
        egllib.bindSymbol(cast(void**) &eglCreateWindowSurface, "eglCreateWindowSurface");
        egllib.bindSymbol(cast(void**) &eglDestroySurface, "eglDestroySurface");
        egllib.bindSymbol(cast(void**) &eglSwapInterval, "eglSwapInterval");
        egllib.bindSymbol(cast(void**) &eglCreateContext, "eglCreateContext");
        egllib.bindSymbol(cast(void**) &eglDestroyContext, "eglDestroyContext");
        egllib.bindSymbol(cast(void**) &eglMakeCurrent, "eglMakeCurrent");
        egllib.bindSymbol(cast(void**) &eglSwapBuffers, "eglSwapBuffer");

        return true;
    }

    foreach (e; paths)
    {
        try
        {
            foreach (DirEntry je; dirEntries(e, SpanMode.depth))
            {
                if (je.isFile() && (je.name.canFind("libEGL")))
                {
                    auto __rate = loadLib(je.name);
                    if (__rate)
                        return;
                }
            }
        }
        catch (Exception e) {continue;}
    }

    debug
    {
        import std.stdio, std.conv;
        for (size_t i = 0; i < errorCount(); i++)
            writeln(errors[i].error.to!string, " -> ", errors[i].message.to!string);
    }
    throw new Exception("Cannot load EGL lib!");
}