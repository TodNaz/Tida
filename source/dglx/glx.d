module dglx.glx;

version(Posix):
version(Dynamic_GLX):

import bindbc.loader;
import x11.X, x11.Xlib, x11.Xutil;

alias GLXLibrary = SharedLib;

__gshared GLXLibrary glxLib;

struct __GLXFBConfigRec;
struct __GLXcontextRec;

static immutable GLX_X_RENDERABLE = 0x8012;
static immutable GLX_DRAWABLE_TYPE = 0x8010;
static immutable GLX_RENDER_TYPE = 0x8011;
static immutable GLX_X_VISUAL_TYPE = 0x22;
static immutable GLX_RED_SIZE = 8;
static immutable GLX_GREEN_SIZE = 9;
static immutable GLX_BLUE_SIZE = 10;
static immutable GLX_ALPHA_SIZE = 11;
static immutable GLX_DEPTH_SIZE = 12;
static immutable GLX_STENCIL_SIZE = 13;
static immutable GLX_DOUBLEBUFFER = 5;
static immutable GLX_BUFFER_SIZE = 2;
static immutable GLX_RGBA = 4;

static immutable GLX_WINDOW_BIT = 0x00000001;
static immutable GLX_RGBA_BIT = 0x00000001;
static immutable GLX_TRUE_COLOR = 0x8002;
static immutable GLX_RGBA_TYPE = 0x8014;

static immutable GLX_SAMPLE_BUFFERS = 0x186a0;
static immutable GLX_SAMPLES = 0x186a1;

alias GLXDrawable = ulong;
alias GLXFBConfig = __GLXFBConfigRec*;
alias GLXContext = __GLXcontextRec*;

alias FglXQueryVersion = extern(C) bool function(Display *dpy,int *maj,int *min);
alias FglXChooseFBConfig = extern(C) GLXFBConfig* function(Display *dpy,int screen,const int *attribList, int *nitems);;
alias FglXGetVisualFromFBConfig = extern(C) XVisualInfo* function(Display *dpy, GLXFBConfig config);;
alias FglXGetFBConfigAttrib = extern(C) int function(Display *dpy, GLXFBConfig config,  int attribute, int *value);
alias FglXQueryExtensionsString = extern(C) const(char*) function(Display *dpy, int screen);
alias FglXCreateNewContext = extern(C) GLXContext function(Display *dpy, GLXFBConfig config,int renderType, 
                                                 GLXContext shareList, bool direct);

alias FglXMakeCurrent = extern(C) bool function(Display *dpy,GLXDrawable drawable, GLXContext ctx);
alias FglXDestroyContext = extern(C) void function(Display *dpy, GLXContext ctx);
alias FglXSwapBuffers = extern(C) void function(Display *dpy, GLXDrawable drawable);
alias FglXWaitX = extern(C) void function();
alias FglXChooseVisual = extern(C) XVisualInfo* function(Display *dpy,int ds,int* attribs);;
alias FglXCreateContext = extern(C) GLXContext function(Display *dpy,XVisualInfo* vis,GLXContext shareList,bool direct);
alias FglXIsDirect = extern(C) bool function(Display *dpy,GLXContext context);

__gshared
{
    FglXQueryVersion glXQueryVersion;
    FglXChooseFBConfig glXChooseFBConfig;
    FglXGetVisualFromFBConfig glXGetVisualFromFBConfig;
    FglXGetFBConfigAttrib glXGetFBConfigAttrib;
    FglXQueryExtensionsString glXQueryExtensionsString;
    FglXCreateNewContext glXCreateNewContext;
    FglXMakeCurrent glXMakeCurrent;
    FglXDestroyContext glXDestroyContext;
    FglXSwapBuffers glXSwapBuffers;
    FglXWaitX glXWaitX;
    FglXChooseVisual glXChooseVisual;
    FglXCreateContext glXCreateContext;
    FglXIsDirect glXIsDirect;
}

struct LibraryResult {
    public
    {
        string path;
        bool isSucces;
    }
}

/++
    Load GLX library, which should open context in x11 environment.

    Throws: `Exception` if library is not load.
+/
LibraryResult[] GLXLoadLibrary() @trusted
{
    import std.file : exists, dirEntries, SpanMode, DirEntry, isDir, isFile;
    import std.string : toStringz;
    import std.algorithm : reverse, canFind;
    import std.parallelism : parallel;

    string[] pathes;

    string[] recurseFindGLX(string path)
    {
        string[] locateds;

        try
        {
            auto dirs = dirEntries(path, SpanMode.depth);

            foreach(DirEntry e; parallel(dirs, 1))
            {
                if(e.name.isDir) {
                    if(!pathes.canFind(e.name)) {
                        locateds ~= recurseFindGLX(e.name ~ "/");
                        pathes ~= e.name;
                    }
                }

                if(e.name.isFile)
                {
                    if(e.name.canFind("libglx.so")) {
                        locateds ~= e.name;
                    }

                    if(e.name.canFind("libGL.so")) {
                        locateds ~= e.name;
                    }
                }
            }
        }catch(Exception e) {}

        return locateds;
    }

    string[] paths = recurseFindGLX("/usr/lib/");

    LibraryResult[] results;

    bool isSucces = false;
    bool ErrorFind = false;

    void bindOrError(void** ptr,string name) @trusted
    {
        bindSymbol(glxLib, ptr, name.toStringz);

        if(*ptr is null) throw new Exception("Not load library!");
    }

    import std.stdio, std.conv;

    foreach(path; paths)
    {
        if(path.exists)
        {
            glxLib = load(path.toStringz);
            if(glxLib == invalidHandle) {
                results ~= LibraryResult(path, false);
                continue;
            }

            try
            {
                bindOrError(cast(void**) &glXQueryVersion, "glXQueryVersion");
                bindOrError(cast(void**) &glXChooseFBConfig, "glXChooseFBConfig");
                bindOrError(cast(void**) &glXGetVisualFromFBConfig, "glXGetVisualFromFBConfig");
                bindOrError(cast(void**) &glXGetFBConfigAttrib, "glXGetFBConfigAttrib");
                bindOrError(cast(void**) &glXQueryExtensionsString, "glXQueryExtensionsString");
                bindOrError(cast(void**) &glXCreateNewContext, "glXCreateNewContext");
                bindOrError(cast(void**) &glXMakeCurrent, "glXMakeCurrent");
                bindOrError(cast(void**) &glXDestroyContext, "glXDestroyContext");
                bindOrError(cast(void**) &glXSwapBuffers, "glXSwapBuffers");
                bindOrError(cast(void**) &glXWaitX, "glXWaitX");
                bindOrError(cast(void**) &glXChooseVisual, "glXChooseVisual");
                bindOrError(cast(void**) &glXCreateContext, "glXCreateContext");
                bindOrError(cast(void**) &glXIsDirect, "glXIsDirect");

                isSucces = true;
            }catch(Exception e)
            {
                continue;
            }

            results ~= LibraryResult(path, true);
            break;
        }
    }

    if(!isSucces)
        throw new Exception("Library `glx` is not load!");

    return results;
}