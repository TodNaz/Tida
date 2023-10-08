module tida.sdlwindow;

version(SDL):
import bindbc.sdl;
import sdl;
import tida.window;

class Window : IWindow
{
    uint _widthInit, _heightInit;
    SDL_Window* handle;
    bool _fullscreen = false;
    bool _border = true;
    bool _aot = false;
    bool _resizable = true;
    string _title;

    this(uint width, uint height, string title) @trusted
    {
        this._widthInit = width;
        this._heightInit = height;
        this._title = title;
    }

    void create(uint posX, uint posY) @trusted
    {
        import std.string : toStringz;

        handle = SDL_CreateWindow(
            _title.toStringz, 
            posX, posY, 
            _widthInit, _heightInit, 
            SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
        );
        if (handle is null)
            throw new Exception("[SDL] Failed create window!");
    }

override @trusted:
    /// The position of the window in the plane of the desktop.
    @property int x()
    {
        int _x;
        SDL_GetWindowPosition(handle, &_x, null);

        return _x;
    }

    /// The position of the window in the plane of the desktop.
    @property int y()
    {
        int _y;
        SDL_GetWindowPosition(handle, null, &_y);

        return _y;
    }

    /// Window width
    @property uint width()
    {
        int _w;
        SDL_GetWindowSize(handle, &_w, null);

        return cast(uint) _w;
    }

    /// Window height
    @property uint height()
    {
        int _h;
        SDL_GetWindowSize(handle, null, &_h);

        return _h;
    }

    /// Window mode, namely whether windowed or full screen
    @property void fullscreen(bool value)
    {
        SDL_SetWindowFullscreen(handle, value ? SDL_WINDOW_FULLSCREEN : 0);
        _fullscreen = value;
    }

    /// Window mode, namely whether windowed or full screen
    @property bool fullscreen()
    {
        return _fullscreen;
    }

    /// Whether the window can be resized by the user.
    @property void resizable(bool value)
    {
        SDL_SetWindowResizable(handle, value);
        _resizable = value;
    }

    /// Whether the window can be resized by the user.
    @property bool resizable()
    {
        return _resizable;
    }

    /// Frames around the window.
    @property void border(bool value)
    {
        SDL_SetWindowBordered(handle, value);
        _border = value;
    }

    /// Frames around the window.
    @property bool border()
    {
        return _border;
    }

    /// Window title.
    @property void title(string value)
    {
        import std.string : toStringz;
        SDL_SetWindowTitle(handle, value.toStringz);
        _title = value;
    }

    /// Window title.
    @property string title()
    {
        return _title;
    }

    /// Whether the window is always on top of the others.
    @property void alwaysOnTop(bool value)
    {
        SDL_SetWindowAlwaysOnTop(handle, value);
        _aot = value;
    }

    /// Whether the window is always on top of the others.
    @property bool alwaysOnTop()
    {
        return _aot;
    }

    /// Dynamic window icon.
    @property void icon(IWindow.Image iconimage)
    {
        SDL_Surface* surface = SDL_CreateRGBSurfaceFrom(
            cast(void*) iconimage.pixels.ptr,
            iconimage.width,
            iconimage.height,
            32,
            iconimage.width * 4,
            0xFF000000, 0x00FF0000, 0x0000FF00, 0x000000FF
        );

        SDL_SetWindowIcon(handle, surface);

        SDL_FreeSurface(surface);
    }

    /++
    Window resizing function.

    Params:
        w = Window width.
        h = Window height.
    +/
    void resize(uint w, uint h)
    {
        SDL_SetWindowSize(handle, w, h);
    }

    /++
    Changes the position of the window in the plane of the desktop.

    Params:
        xposition = Position x-axis.
        yposition = Position y-axis.
    +/
    void move(int xposition, int yposition)
    {
        SDL_SetWindowPosition(handle, xposition, yposition);
    }

    /++
    Shows a window in the plane of the desktop.
    +/
    void show()
    {
        SDL_ShowWindow(handle);
    }

    /++
    Hide a window in the plane of the desktop. 
    (Can be tracked in the task manager.)
    +/
    void hide()
    {
        SDL_HideWindow(handle);
    }

    /++
    Destroys the window and its associated data (not the structure itself, all values are reset to zero).
    +/
    void destroy()
    {
        SDL_DestroyWindow(handle);
        handle = null;
    }
}

/++
Creating a window in the window manager. When setting a parameter in a template, 
it can create both its regular version and with hardware graphics acceleration.

Params:
    type =  Method of creation. 
            `WithoutContext` -  Only the window is created. 
                                The context is created after.
            `WithContext` - Creates both a window and a graphics context for 
                            using hardware graphics acceleration.
    window = Window pointer.
    posX = Position in the plane of the desktop along the x-axis.
    posY = Position in the plane of the desktop along the y-axis.

Throws:
`Exception` If a window has not been created in the process 
(and this also applies to the creation of a graphical context).

Examples:
---
windowInitialize!WithoutContext(window, 100, 100); /// Without context
...
windowInitialize!WithContext(window, 100, 100); /// With context
---
+/
void windowInitialize(  Window window,
                        int posX,
                        int posY) @trusted
{
    window.create(posX, posY);
}