/++
Runtime is a fundamental module for building two-dimensional games. It is he 
who connects to the window manager of the operating system, initializes the 
sound device and loads the necessary libraries for the game. Also, it is able 
to store program arguments in itself, in order to pass them later to 
other functions.

How do I create a runtime?:
Creating a runtime is quick and easy. There is a class, it has a static 
method $(HREF ../tida/runtime/ITidaRuntime.initialize.html, initialize), which allocates memory, and then calls the internal 
functions of the object to execute its functions. This is done 
in the following way:
---
import tida;

int main(string[] args)
{
    TidaRuntime.initialize(args);

    return 0;
}
---

As you can see, the program arguments are passed to the function. 
This is necessary in order to later use them outside the main function.

Also, the second parameter can be a list of libraries to load. 
All kinds of libraries that runtime can load are described in $(HREF #OpenAL, here).
---
import tida;

int main(string[] args)
{
    TidaRuntime.initialize(args, [FreeType, OpenAL]);

    return 0;
}
---

Or you can use $(LREF AllLibrary) to say that you need to load everything, 
or $(LREF WithoutLibrary) that you need to load nothing.

Next, to take advantage of the runtime, you can refer to the $(LREF runtime) function, 
which will give the runtime object as long as you can do something. 
All actions are described in $(HREF ../tida/runtime/ITidaRuntime.html, ITidaRuntime).

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    OBJECTREF = <a href="https://dlang.org/library/object.html#$1">$1</a>

Authors: $(HREF https://github.com/TodNaz, TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE, MIT)
+/
module tida.runtime;

__gshared TidaRuntime _runtimeObject;

/++
Global access to runtime. An object can be called from anywhere, 
but cannot be replaced.
+/
@property TidaRuntime runtime() @trusted
{
    return _runtimeObject;
}

enum : int
{
    OpenAL = 0, /// Open Audio Library
    FreeType /// Free Type Library
}

alias LibraryUnite = int; /// 

/++
An array of library indexes. Indicates that all libraries should be loaded, 
when specified in the 
$(HREF ../tida/runtime/ITidaRuntime.initialize.html, initialization) of the runtime.
+/
enum AllLibrary = [OpenAL, FreeType];

/++
An array of only important libraries. Loads only the necessary libraries 
(for connecting to the window manager) when specified in the 
$(HREF ../tida/runtime/ITidaRuntime.initialize.html, initialization) of the runtime.
+/
enum WithoutLibrary  = [];

/++
The interface of interaction between the program and the window manager.
+/
interface ITidaRuntime
{
@safe:
    /++
    Connects to the window manager.

    Throws:
    $(OBJECTREF Exception) If the libraries were not installed on the machine 
    being started or they were damaged. And also if the connection to the 
    window manager was not successful (for example, there is no such component 
    in the OS or the connection to an unknown window manager is not supported).
    +/
    void connectToWndMng();

    /++
    Closes the session with the window manager.
    +/
    void closeWndMngSession();

    /++
    Arguments given to the program.
    +/
    @property string[] mainArguments();

    /++
    Accepts program arguments for subsequent operations with them.
    +/
    void acceptArguments(string[] arguments);

    uint[2] monitorSize();

@trusted:
    /++
    Static function to initialize the runtime. Allocates memory for runtime and 
    executes its functions of accepting arguments, loading the necessary 
    libraries and connecting to the window manager through its 
    interface functions.
    
    An example of how to load individual libraries:
    ---
    import tida.runtime;
    
    int main(string[] args)
    {
        TidaRuntime.initialize(args, [FreeType, OpenAL]);
        
        return 0;
    }
    ---
    
    Params:
        arguments = Arguments that were nested in the main function. They will 
                    be stored in the runtime memory from where they can be read. 
                    Rantheim doesn't read such arguments.
        libs      = List of libraries to download. Please note that this does 
                    not affect libraries that the framework does not use. 
                    Notable libraries are listed 
                    $(HREF ../runtime.html#EGL, here).
                    
    Throws: $(OBJECTREF Exception) if during initialization the libraries 
    were not loaded or the runner could not connect to the window manager.
    +/
    static final void initialize(   string[] arguments  = [], 
                                    LibraryUnite[] libs = AllLibrary)
    {
        _runtimeObject = new TidaRuntime();
        _runtimeObject.acceptArguments(arguments);
        _runtimeObject.connectToWndMng();
    }
}


version(SDL)
{
    public import tida.sdlruntime;
} else:

/++
The interface of interaction between the program and the window manager.
+/
version (Posix)
{
    import x11.Xlib;
    import x11.X;
    import x11.Xlib_xcb;

    version(UseXCB)
    {
        class TidaRuntime : ITidaRuntime
        {
            import xcb.xcb;
            import std.exception : enforce;

            enum SessionType
            {
                unknown,
                x11,
                wayland
            }

            enum SessionWarning =
            "WARNING! The session is not defined. Perhaps she simply does not exist?";

        private:
            XDisplay* _dpy;
            xcb_connection_t* _connection;
            xcb_screen_t* _screen;
            int _displayID;
            string[] arguments;
            SessionType _session;

        export @trusted:
            this()
            {
                import std.process;
                import std.stdio : stderr, writeln;

                auto env = environment.get("XDG_SESSION_TYPE");
                if (env == "x11")
                {
                    _session = SessionType.x11;
                } else
                if (env == "wayland")
                {
                    _session = SessionType.wayland;
                } else
                {
                    _session = SessionType.unknown;
                    stderr.writeln(SessionWarning);
                }

            }

            auto display() @trusted { return this._dpy; }
            auto connection() @trusted { return this._connection; }

            override void connectToWndMng()
            {
                this._dpy = XOpenDisplay(null);
                //this._connection = xcb_connect(null, null);
                this._connection = cast(xcb_connection_t*) XGetXCBConnection(_dpy);
                enforce!Exception(this._connection,
                "Failed to connect to window manager.");

                this._screen = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;
            }

            override void closeWndMngSession()
            {
                xcb_disconnect(this._connection);
                this._connection = null;
                this._screen = null;
            }

            override void acceptArguments(string[] arguments)
            {
                this.arguments = arguments;
            }

            @property override string[] mainArguments()
            {
                return this.arguments;
            }

            @property auto rootWindow()
            {
                return _screen.root;
            }

            uint[2] monitorSize()
            {
                return [0, 0];
            }

        @trusted:

            /// Default screen number
            xcb_screen_t* screen()
            {
                return this._screen;
            }

            ~this()
            {
                closeWndMngSession();
            }
        }
    }
    else
    {
        class TidaRuntime : ITidaRuntime
        {
            import x11.X, x11.Xlib, x11.Xutil;
            import std.exception : enforce;

            enum SessionType
            {
                unknown,
                x11,
                wayland
            }

            enum SessionWarning =
            "WARNING! The session is not defined. Perhaps she simply does not exist?";

        private:
            Display* _display;
            int _displayID;
            string[] arguments;
            SessionType _session;;

        export @trusted:
            this()
            {
                import std.process;
                import std.stdio : stderr, writeln;

                auto env = environment.get("XDG_SESSION_TYPE");
                if (env == "x11")
                {
                    _session = SessionType.x11;
                } else
                if (env == "wayland")
                {
                    _session = SessionType.wayland;
                } else
                {
                    _session = SessionType.unknown;
                    stderr.writeln(SessionWarning);
                }

            }

            override void connectToWndMng()
            {
                this._display = XOpenDisplay(null);
                enforce!Exception(this._display,
                "Failed to connect to window manager.");

                this._displayID = DefaultScreen(this._display);
            }

            override void closeWndMngSession()
            {
                XCloseDisplay(this._display);
                this._display = null;
                this._displayID = 0;
            }

            override void acceptArguments(string[] arguments)
            {
                this.arguments = arguments;
            }

            @property override string[] mainArguments()
            {
                return this.arguments;
            }

            @property Window rootWindow()
            {
                return RootWindow(_display, _displayID);
            }

            uint[2] monitorSize()
            {
                auto screen = ScreenOfDisplay(_display, 0);
                return [screen.width, screen.height];
            }

        @safe:
            /// An instance for contacting the manager's server.
            @property Display* display()
            {
                return this._display;
            }

            /// Default screen number
            @property int displayID()
            {
                return this._displayID;
            }

            ~this()
            {
                closeWndMngSession();
            }
        }
    }
}

/++
Required to enable high performance on devices with nvidia optimus.

If necessary, include the "WitoutHighNvidiaOptimus" version in the flags.

See_Also:
    https://developer.download.nvidia.com/devzone/devcenter/gamegraphics/files/OptimusRenderingPolicies.pdf
+/
// version (Windows)
// {
//     version (WitoutHighNvidiaOptimus)
//     {
//         // Nothing
//     } else
//     {
//         import core.sys.windows.windows;
//         // extern(C) 
//         // {
//         //     export DWORD NvOptimusEnablement = 0x00000001;
//         // }
//     }
// }

version (Windows)
class TidaRuntime : ITidaRuntime
{
    import core.sys.windows.windows;
    import std.exception : enforce;

    pragma(lib, "opengl32.lib");

private:
    HINSTANCE hInstance;
    string[] arguments;

export @trusted:
    override void connectToWndMng()
    {
        this.hInstance = GetModuleHandle(null);
        debug {} else
            ShowWindow(GetConsoleWindow(), SW_HIDE);

        enforce!Exception(this.hInstance, 
        "Failed to connect to window manager.");
    }

    override void closeWndMngSession()
    {
        this.hInstance = null;
    }

    override void acceptArguments(string[] arguments)
    {
        this.arguments = arguments;
    }
    
    override uint[2] monitorSize()
    {
        HDC hScreenDC = GetDC(GetDesktopWindow());
        int width = GetDeviceCaps(hScreenDC, HORZRES);
        int height = GetDeviceCaps(hScreenDC, VERTRES);
        ReleaseDC(GetDesktopWindow(), hScreenDC);
        
        return [width, height];
    }

    @property override string[] mainArguments()
    {
        return this.arguments;
    }

@safe:
    @property HINSTANCE instance()
    {
        return this.hInstance;
    }
}
