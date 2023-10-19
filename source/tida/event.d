/++
A module for listening to incoming events from the window manager for their 
subsequent processing.

Such a layer does not admit events directly to the data, but whether it can show
what is happening at the moment, which can serve as a cross-plotter tracking 
of events.

Using the IEventHandler.nextEvent function, you can scroll through the queue of 
events that can be processed and at each queue, the programmer needs to track 
the events he needs by the functions of the same interface:
---
while (event.nextEvent()) {
    if (event.keyDown == Key.Space) foo();
}
---
As you can see, we loop through each event and read what happened.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.event;

export:
enum DeprecatedMethodSize = 
"This function is useless. Use the parameters `IWindow.width/IWindow.height`.";

/// Mouse keys.
enum MouseButton
{
    unknown = 0, /// Unknown mouse button
    left = 1, /// Left mouse button
    right = 3, /// Right mouse button
    middle = 2 /// Middle mouse button
}

/++
Interaction interface and receiving information from the joystick.
+/
export interface IJoystick
{
    import tida.vector;
    
    enum maximumAxes = vec!float(32767, 32767);
    
    /++
    A method that returns the value of all axes of the controller. 
    The maximum number of axes can be checked using the `.length` property:
    ---
    writeln("Axless count: ", joystick.axless.length);
    ---
    +/
    @property int[] axless() @safe;
    
    /++
    A method that returns the maximum number of buttons on the controller.
    +/
    @property uint maxButtons() @safe;
    
    /++
    A method that returns the name of the controller.
    +/
    @property string name() @safe;
    
    /++
    Method showing which button was pressed/released in the current event.
    +/
    @property int button() @safe;
    
    /++
    Shows the state when any button was pressed.
    +/
    @property bool isButtonDown() @safe;
    
    /++
    Shows the state when any button was released..
    +/
    @property bool isButtonUp() @safe;
    
    /++
    Shows the state when any one of the axes has changed its state.
    +/
    @property bool isAxisMove() @safe;

    /++
    Shows the value of the first axis on the controller. 
    The value ranges from -1.0 to 1.0.
    +/
    final @property Vector!float xy() @safe
    {
        return vec!float(axless[0], axless[1]) / maximumAxes;
    }
    
    /++
    Shows the value of the second axis on the controller. 
    The value ranges from -1.0 to 1.0.
    +/
    final @property Vector!float zr() @safe
    {
        return vec!float(axless[2], axless[3]) / maximumAxes;
    }
    
    /++
    Shows the value of the third axis on the controller. 
    The value ranges from -1.0 to 1.0.
    +/
    final @property Vector!float uv() @safe
    {
        return vec!float(axless[4], axless[5]) / maximumAxes;
    }
    
    /++
    Shows the currently pressed key.
    +/
    final @property int buttonDown() @safe
    {
        return isButtonDown ? button : -1;
    }
    
    /++
    Shows the currently released key.
    +/
    final @property int buttonUp() @safe
    {
        return isButtonUp ? button : -1;
    }
}

import std.range : InputRange;

/++
Interface for cross-platform listening for events from the window manager.
+/
interface IEventHandler
{
@safe:
    final IEventHandler front() @safe
    {
        return this;
    }

    final bool empty() @safe
    {
        return !this.hasEvent;
    }

    final void popFront() @safe
    {
        nextEvent();
    }

    bool hasEvent() @safe;

    /++
    Moves to the next event. If there are no more events, it returns false, 
    otherwise, it throws true and the programmer can safely check which event 
    s in the current queue.
    +/
    bool nextEvent();

    /++
    Checking if any key is pressed in the current event.
    +/
    bool isKeyDown();

    /++
    Checking if any key is released in the current event.
    +/
    bool isKeyUp();

    /++
    Will return the key that was pressed. Returns zero if no key is pressed 
    in the current event.
    +/
    @property int key();

    /++
    Returns the key at the moment the key was pressed, 
    otherwise it returns zero.
    +/
    @property final int keyDown()
    {
        return isKeyDown ? key : 0;
    }

    /++
    Returns the key at the moment the key was released, 
    otherwise it returns zero.
    +/
    @property final int keyUp()
    {
        return isKeyUp ? key : 0;
    }

    /++
    Check if the mouse button is pressed in the current event.
    +/
    bool isMouseDown();

    /++
    Check if the mouse button is released in the current event.
    +/
    bool isMouseUp();

    /++
    Returns the currently pressed or released mouse button.
    +/
    @property MouseButton mouseButton();

    /++
    Returns the mouse button at the moment the key was pressed; 
    otherwise, it returns zero.
    +/
    @property final MouseButton mouseDownButton()
    {
        return isMouseDown ? mouseButton : MouseButton.unknown;
    }

    /++
    Returns the mouse button at the moment the key was released; 
    otherwise, it returns zero.
    +/
    @property final MouseButton mouseUpButton()
    {
        return isMouseUp ? mouseButton : MouseButton.unknown;
    }

    /++
    Returns the position of the mouse in the window.
    +/
    @property int[2] mousePosition();

    /++
    Returns in which direction the user is turning the mouse wheel. 
    1 - down, -1 - up, 0 - does not twist. 

    This iteration is convenient for multiplying with some real movement coefficient.
    +/
    @property int mouseWheel();

    /++
    Indicates whether the window has been resized in this event.
    +/
    bool isResize();

    /++
    Returns the new size of the window 
    
    deprecated: 
    although this will already be available directly in the 
    window structure itself.
    +/
    deprecated(DeprecatedMethodSize) 
    uint[2] newSizeWindow();

    /++
    Indicates whether the user is attempting to exit the program.
    +/
    bool isQuit();

    /++
    Indicates whether the user has entered text information.
    +/
    bool isInputText();

    /++
    User entered data.
    +/
    @property string inputChar();

    @property wstring inputWChar();
    
    /++
    Returns an array of the interface for controlling joysticks. 
    If its length is zero, no joysticks were found.

    It is checked once, if one controller has been disabled, then it is recommended 
    to zero the array as shown below and call again to rescan the joysticks.
    ---
    event.joysticks.length = 0;
    ---
    +/
    @property IJoystick[] joysticks();

@trusted:
    final int opApply(scope int delegate(ref int) dg)
    {
        int count = 0;

        while (this.nextEvent()) 
        {
            dg(++count);
        }

        return 0;
    }
}

version(SDL)
{
    export import tida.sdlevent;
} else:

version(Windows)
class Joystick : IJoystick
{
    import core.sys.windows.windows;
    import tida.vector;

private:
    EventHandler event;   

export:
    int id; // identificator
    int numAxes; // Max axes
    int numButtons; // Max buttons
    int[] axisMin; // Minimum axes values
    int[] axisMax; // Maximum axes values
    int[] axisOffset; // Axes offset values
    float[] axisScale; // Axes scale values
    string namely; 
    
    int[] axesState; // Axes state
    int[int] buttons;
    
    int[] _axis;

    static immutable(int[]) jid =
    [
        JOYSTICKID1,
        JOYSTICKID2
    ];
    
    static immutable(int[]) jbuttondown =
    [
        MM_JOY1BUTTONDOWN,
        MM_JOY2BUTTONDOWN 
    ];
    
    static immutable(int[]) jbuttonup = 
    [
        MM_JOY1BUTTONUP,
        MM_JOY2BUTTONUP 
    ];
    
    static immutable(int[]) jmove = 
    [
        MM_JOY1MOVE,
        MM_JOY2MOVE
    ];
    
    static immutable defAxisMin = -32768;
    static immutable defAxisMax = 32767;
    static immutable defAxisThreshold = (defAxisMax - defAxisMin) / 256;

@safe:
    this(int id, EventHandler event)
    {
        this.event = event;
        this.id = id;
    }
    
override:
    @property int[] axless()
    {
        return axesState;
    }
    
    @property uint maxButtons()
    {
        return numButtons;
    }
    
    @property string name()
    {
        return namely;
    }

    @property bool isButtonDown()
    {
        if (event.currJEvent !is null)
            return event.currJEvent.type == EventHandler.JoystickEventType.buttonPressed;
        else
            return false;
    }
    
    @property bool isButtonUp()
    {
        if (event.currJEvent !is null)
            return event.currJEvent.type == EventHandler.JoystickEventType.buttonReleased;
        else
            return false;
    }
    
    @property bool isAxisMove()
    {
        if (event.currJEvent !is null)
            return event.currJEvent.type == EventHandler.JoystickEventType.axisMove;
        else
            return false;
    }
    
    @property int button()
    {
        if (event.currJEvent !is null)
            return event.currJEvent.value;
        else
            return -1;
    }
}

version(Posix)
class Joystick : IJoystick
{
    import std.stdio : File;
    import core.sys.posix.sys.ioctl;
    import tida.vector;

private:
    int descriptor;

export:
    int id; // identificator
    string namely;
    
    int numAxes; // Max axes
    int numButtons; // Max buttons
    
    int[] _axis;

    // linux/joystick.h
    enum JSIOCGAXES = _IOR!ubyte('j', 0x11);
    enum JSIOCGBUTTONS = _IOR!ubyte('j', 0x12);
    enum JSIOCGNAME(T) = _IOC!T(_IOC_READ, 'j', 0x13); 

    enum JS_EVENT_BUTTON = 0x01;    /* button pressed/released */
    enum JS_EVENT_AXIS = 0x02;    /* joystick moved */
    enum JS_EVENT_INIT = 0x80;    /* initial state of device */

    struct js_event
    {
        uint time; /* event timestamp in milliseconds */
        short value;    /* value */
        ubyte type;  /* event type */
        ubyte number;    /* axis/button number */

        ubyte trueType() @safe nothrow pure
        {
            return type & ~JS_EVENT_INIT;
        }
    }

    js_event* currJEvent;

@safe:
    package(tida) @property int fd()
    {
        return descriptor;
    }

    this(int descriptor, int id) @trusted
    {
        import std.conv : to;
    
        this.descriptor = descriptor;
        this.id = id;

        char[80] __name;
 
        ioctl(descriptor, JSIOCGAXES, &numAxes);
        ioctl(descriptor, JSIOCGBUTTONS, &numButtons);
        ioctl(descriptor, JSIOCGNAME!(char[80]), &__name);
        
        namely = __name.to!string;
        
        _axis = new int[](numAxes);
    }

    ~this() @trusted
    {
        import core.sys.posix.unistd;

        close(descriptor);
        descriptor = -2;
    }

override:
    @property int[] axless()
    {
        return _axis;
    }

    @property uint maxButtons()
    {
        return numButtons;
    }
    
    @property string name()
    {
        return namely;
    }

    @property int button()
    {
        if (currJEvent !is null)
            return currJEvent.number;
        else
            return -1;
    }
    
    @property bool isButtonDown()
    {
        if (currJEvent !is null)
            return currJEvent.trueType == JS_EVENT_BUTTON && currJEvent.value == 1;
        else
            return false;
    }
    
    @property bool isButtonUp()
    {
        if (currJEvent !is null)
            return currJEvent.trueType == JS_EVENT_BUTTON && currJEvent.value == 0;
        else
            return false;
    }
    
    @property bool isAxisMove()
    {
        if (currJEvent !is null)
            return currJEvent.trueType == JS_EVENT_AXIS;
        else
            return false;
    }
}

version(Posix)
{
    version(UseXCB)
    {
        import tida.window;
        import tida.runtime;
        import core.stdc.stdlib;

        class EventHandler : IEventHandler
        {
            import xcb.xcb;

            struct JoystickEvent
            {
                int id;
                Joystick.js_event data;
            }

            tida.window.Window window;
            xcb_generic_event_t* last;
            xcb_atom_t destroyAtom;
            Joystick[] _joysticks;
            JoystickEvent[] jevents;

            this(tida.window.Window window) @safe
            {
                this.window = window;

                destroyAtom = window.getAtom("WM_DELETE_WINDOW");
            }

            int joyHandle()
            {
                import core.sys.posix.unistd;

                int count = 0;
                foreach (ref e; _joysticks)
                {
                    Joystick.js_event eEvent;
                    immutable bytes = read(e.fd(), &eEvent, Joystick.js_event.sizeof);

                    if (eEvent.type != 0 &&
                        ((eEvent.type & Joystick.JS_EVENT_INIT) != Joystick.JS_EVENT_INIT))
                    {
                        jevents ~= JoystickEvent(e.id, eEvent);
                        count++;
                    }
                }

                return count;
            }

            void validateJoysticks()
            {
                import std.algorithm : remove;
                import core.sys.posix.fcntl;

                foreach (size_t i, ref e; _joysticks)
                {
                    if (fcntl(e.fd(), F_GETFD) == -1)
                    {
                        _joysticks = _joysticks.remove(i);
                    }
                }
            }

        override @trusted:
            bool hasEvent() @safe
            {
                return  last !is null ||
                        jevents.length != 0;
            }

            /++
            Moves to the next event. If there are no more events, it returns false,
            otherwise, it throws true and the programmer can safely check which event
            s in the current queue.
            +/
            bool nextEvent()
            {
                if (last !is null)
                {
                    free(last);
                    last = null;
                }

                joyHandle();

                last = xcb_poll_for_event(runtime.connection);

                if (last is null)
                {
                    if (jevents.length != 0)
                    {
                        auto currEvent = &jevents[0];
                        jevents = jevents[1 .. $];

                        foreach (ref e; _joysticks)
                        {
                            if (e.id == currEvent.id)
                            {
                                e.currJEvent = &currEvent.data;
                                if (currEvent.data.trueType == Joystick.JS_EVENT_AXIS)
                                {
                                    e._axis[currEvent.data.number] = e.currJEvent.value;
                                }
                            } else
                            {
                                e.currJEvent = null;
                            }
                        }

                        return true;
                    } else
                    {
                        foreach (ref e; _joysticks)
                        {
                            e.currJEvent = null;
                        }

                        return false;
                    }
                }

                return last !is null;
            }

            /++
            Checking if any key is pressed in the current event.
            +/
            bool isKeyDown()
            {
                if (last is null)
                    return false;

                return (last.response_type & ~0x80) == XCB_KEY_PRESS;
            }

            /++
            Checking if any key is released in the current event.
            +/
            bool isKeyUp()
            {
                if (last is null)
                    return false;

                return (last.response_type & ~0x80) == XCB_KEY_RELEASE;
            }

            /++
            Will return the key that was pressed. Returns zero if no key is pressed
            in the current event.
            +/
            @property int key()
            {
                if (isKeyDown)
                {
                    xcb_key_press_event_t* pe = cast(xcb_key_press_event_t*) last;

                    return pe.detail;
                } else
                if (isKeyUp)
                {
                    xcb_key_release_event_t* re = cast(xcb_key_release_event_t*) last;

                    return re.detail;
                } else
                    return 0;
            }

            /++
            Check if the mouse button is pressed in the current event.
            +/
            bool isMouseDown()
            {
                if (last is null)
                    return false;

                return (last.response_type & ~0x80) == XCB_BUTTON_PRESS;
            }

            /++
            Check if the mouse button is released in the current event.
            +/
            bool isMouseUp()
            {
                if (last is null)
                    return false;

                return (last.response_type & ~0x80) == XCB_BUTTON_RELEASE;
            }

            /++
            Returns the currently pressed or released mouse button.
            +/
            @property MouseButton mouseButton()
            {
                if (isMouseDown)
                {
                    xcb_button_press_event_t* pb = cast(xcb_button_press_event_t*) last;

                    return cast(MouseButton) pb.detail;
                } else
                if (isMouseUp)
                {
                    xcb_button_release_event_t* rb = cast(xcb_button_release_event_t*) last;

                    return cast(MouseButton) rb.detail;
                } else
                    return MouseButton.init;
            }

            /++
            Returns the position of the mouse in the window.
            +/
            @property int[2] mousePosition()
            {
                auto c = xcb_query_pointer(runtime.connection, window.handle);
                xcb_flush(runtime.connection);
                auto reply = xcb_query_pointer_reply(runtime.connection, c, null);

                auto x = reply.win_x;
                auto y = reply.win_y;

                free(reply);

                return [x, y];
            }

            /++
            Returns in which direction the user is turning the mouse wheel.
            1 - down, -1 - up, 0 - does not twist.

            This iteration is convenient for multiplying with some real movement coefficient.
            +/
            @property int mouseWheel()
            {
                if (isMouseDown || isMouseUp)
                {
                    if (mouseButton == 4)
                        return -1;
                    else
                    if (mouseButton == 5)
                        return 1;
                }

                return 0;
            }

            /++
            Indicates whether the window has been resized in this event.
            +/
            bool isResize()
            {
                if (last is null)
                {
                    return false;
                }

                if ((last.response_type  & ~0x80) == XCB_CONFIGURE_NOTIFY)
                {
                    xcb_configure_notify_event_t* cne = cast(xcb_configure_notify_event_t*) last;

                    return cne.response_type == 22;
                }

                return false;
            }

            /++
            Returns the new size of the window

            deprecated:
            although this will already be available directly in the
            window structure itself.
            +/
            deprecated(DeprecatedMethodSize)
            uint[2] newSizeWindow()
            {
                return [window.width, window.height];
            }

            /++
            Indicates whether the user is attempting to exit the program.
            +/
            bool isQuit()
            {
                if (last is null)
                    return false;

                if ((last.response_type & 0x7f) == XCB_CLIENT_MESSAGE)
                {
                    xcb_client_message_event_t* cme = cast(xcb_client_message_event_t*) last;
                    return cme.data.data32[0] == destroyAtom;
                }

                return false;
            }

            /++
            Indicates whether the user has entered text information.
            +/
            bool isInputText()
            {
                return isKeyDown;
            }

            /++
            User entered data.
            +/
            @property string inputChar()
            {
                return [];
            }

            @property wstring inputWChar()
            {
                return [];
            }

            @property IJoystick[] joysticks()
            {
                import core.sys.posix.fcntl;
                import std.conv : to;

                IJoystick[] togo() @safe {
                    IJoystick[] tojo; foreach (e; _joysticks) tojo ~= e;

                    return tojo;
                }

                if (_joysticks.length != 0)
                {
                    validateJoysticks();
                    return togo();
                }

                foreach (i; 0 .. 2)
                {
                    int fd = open(("/dev/input/js" ~ i.to!string).ptr, 0);
                    if (fd == -1)
                        continue;

                    immutable flags = fcntl(fd, F_GETFL, 0);
                    fcntl(fd, F_SETFL, flags | O_NONBLOCK);

                    _joysticks ~= new Joystick(fd, i);
                }

                return togo();
            }
        }
    } else
    {
        class EventHandler : IEventHandler
        {
            import x11.X, x11.Xlib, x11.Xutil;
            import tida.window, tida.runtime;

        private:
            struct JoystickEvent
            {
                int id;
                Joystick.js_event data;
            }

            tida.window.Window[] windows;
            Atom destroyWindowEvent;
            _XIC* ic;
            Joystick[] _joysticks;
            JoystickEvent[] jevents;

        export:
            XEvent event;

        @trusted:
            this(tida.window.Window window)
            {
                this.windows ~= window;

                this.destroyWindowEvent = XInternAtom(runtime.display, "WM_DELETE_WINDOW", 0);

                ic = XCreateIC( XOpenIM(runtime.display, null, null, null),
                                XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
                                XNClientWindow, this.windows[0].handle, null);
                XSetICFocus(ic);
                XSetLocaleModifiers("@im=none");
            }

            void appendWindow(tida.window.Window window)
            {
                this.windows ~= window;
            }

            @property tida.window.IWindow windowEvent()
            {
                foreach (window; windows)
                {
                    if (window.handle == this.event.xany.window)
                        return window;
                }

                return null;
            }

            int joyHandle()
            {
                import core.sys.posix.unistd;

                int count = 0;
                foreach (ref e; _joysticks)
                {
                    Joystick.js_event eEvent;
                    immutable bytes = read(e.fd(), &eEvent, Joystick.js_event.sizeof);

                    if (eEvent.type != 0 &&
                        ((eEvent.type & Joystick.JS_EVENT_INIT) != Joystick.JS_EVENT_INIT))
                    {
                        jevents ~= JoystickEvent(e.id, eEvent);
                        count++;
                    }
                }

                return count;
            }

            void validateJoysticks()
            {
                import std.algorithm : remove;
                import core.sys.posix.fcntl;

                foreach (size_t i, ref e; _joysticks)
                {
                    if (fcntl(e.fd(), F_GETFD) == -1)
                    {
                        _joysticks = _joysticks.remove(i);
                    }
                }
            }

            IJoystick[] aJoy()
            {
                IJoystick[] res;
                foreach (e; _joysticks)
                {
                    res ~= cast(IJoystick) e;
                }

                return res;
            }

        override:
            bool hasEvent()
            {
                return  XPending(runtime.display) != 0 ||
                        jevents.length != 0;
            }

            bool nextEvent()
            {
                joyHandle();
                immutable pen = XPending(runtime.display);

                if (pen != 0)
                {
                    XNextEvent(runtime.display, &this.event);

                    return pen != 0;
                } else
                {
                    if (jevents.length != 0)
                    {
                        auto currEvent = &jevents[0];
                        jevents = jevents[1 .. $];

                        foreach (ref e; _joysticks)
                        {
                            if (e.id == currEvent.id)
                            {
                                e.currJEvent = &currEvent.data;
                                if (currEvent.data.trueType == Joystick.JS_EVENT_AXIS)
                                {
                                    e._axis[currEvent.data.number] = e.currJEvent.value;
                                }
                            } else
                            {
                                e.currJEvent = null;
                            }
                        }

                        return true;
                    } else
                    {
                        foreach (ref e; _joysticks)
                        {
                            e.currJEvent = null;
                        }

                        return false;
                    }
                }
            }

            bool isKeyDown()
            {
                return  this.event.type == KeyPress;
            }

            bool isKeyUp()
            {
                return  this.event.type == KeyRelease;
            }

            @property int key()
            {
                return this.event.xkey.keycode;
            }

            bool isMouseDown()
            {
                return  this.event.type == ButtonPress;
            }

            bool isMouseUp()
            {
                return  this.event.type == ButtonRelease;
            }

            @property MouseButton mouseButton()
            {
                return cast(MouseButton) this.event.xbutton.button;
            }

            @property int[2] mousePosition() @trusted
            {
                return [this.event.xmotion.x, this.event.xmotion.y];
            }

            @property int mouseWheel()
            {
                return this.isMouseDown ?
                    (this.mouseButton == 4 ? -1 : (this.mouseButton == 5 ? 1 : 0)) : 0;
            }

            bool isResize()
            {
                return 	this.event.type == ConfigureNotify &&
        		        this.event.xconfigure.type == 22 &&
        		        !this.event.xconfigure.send_event;
            }

            uint[2] newSizeWindow()
            {
                XWindowAttributes attr;
                XGetWindowAttributes(   runtime.display,
                                        (cast(tida.window.Window) this.windows[0]).handle, &attr);

                return [attr.width, attr.height];
            }

            bool isQuit()
            {
                return  this.event.xclient.data.l[0] == this.destroyWindowEvent;
            }

            bool isInputText()
            {
                return this.isKeyDown;
            }

            @property string inputChar()
            {
                int count;
                string buf = new string(20);
                KeySym ks;
                Status status = 0;

                count = Xutf8LookupString(  this.ic, cast(XKeyPressedEvent*) &this.event.xkey,
                                            cast(char*) buf.ptr, 20, &ks, &status);

                return buf[0 .. count];
            }

            @property wstring inputWChar()
            {
                import std.utf : toUTF16;

                int count;
                string buf = new string(20);
                KeySym ks;
                Status status = 0;

                count = Xutf8LookupString(  this.ic, cast(XKeyPressedEvent*) &this.event.xkey,
                                            cast(char*) buf.ptr, 20, &ks, &status);

                return buf[0 .. count].toUTF16;
            }

            @property IJoystick[] joysticks()
            {
                import core.sys.posix.fcntl;
                import std.conv : to;

                if (_joysticks.length != 0)
                {
                    validateJoysticks();
                    return aJoy();
                }

                foreach (i; 0 .. 2)
                {
                    int fd = open(("/dev/input/js" ~ i.to!string).ptr, 0);
                    if (fd == -1)
                        continue;

                    immutable flags = fcntl(fd, F_GETFL, 0);
                    fcntl(fd, F_SETFL, flags | O_NONBLOCK);

                    _joysticks ~= new Joystick(fd, i);
                }

                return aJoy();
            }
        }
    }
}

version(Windows)
class EventHandler : IEventHandler
{
    import tida.window, tida.runtime;
    import core.sys.windows.windows;

private:
    tida.window.Window window;
    Joystick[] _joysticks;

export:
    MSG msg;
    
    enum JoystickEventType
    {
        axisMove,
        buttonPressed,
        buttonReleased
    }
    
    enum JoystickAxis
    {
        X = JOY_RETURNX,
        Y = JOY_RETURNY,
        Z = JOY_RETURNZ,
        R = JOY_RETURNR,
        U = JOY_RETURNU,
        V = JOY_RETURNV
    }
    
    struct JoystickEvent
    {
        int id;
        JoystickEventType type;
        int value;
        
        JoystickAxis axis;
    }
    
    JoystickEvent[] jEvents;
    JoystickEvent* currJEvent = null;
    bool _isResize = false;

@safe:
    this(tida.window.Window window)
    {
        this.window = window;
    }

@trusted:
    void joyPeek()
    {
        immutable flagsAxis = [
            JOY_RETURNX,
            JOY_RETURNY,
            JOY_RETURNZ,
            JOY_RETURNR,
            JOY_RETURNU,
            JOY_RETURNV
        ];
        
        foreach (ref e; _joysticks)
        {
            JOYINFOEX joyInfo;
            joyInfo.dwSize = joyInfo.sizeof;
            joyInfo.dwFlags = JOY_RETURNALL;
            
            joyGetPosEx(Joystick.jid[e.id], &joyInfo);
            
            immutable axisPos = [
                joyInfo.dwXpos,
                joyInfo.dwYpos,
                joyInfo.dwZpos,
                joyInfo.dwRpos,
                joyInfo.dwUpos,
                joyInfo.dwVpos
            ];
            
            foreach (i; 0 .. e.numAxes)
            {
                if (!(joyInfo.dwFlags & flagsAxis[i]))
                    continue;
                    
                immutable int value = cast(int) (cast(float) (axisPos[i]) + e.axisOffset[i] * e.axisScale[i]);
                immutable change = (value - e._axis[i]);
                
                if (change > -Joystick.defAxisThreshold &&
                    change < Joystick.defAxisThreshold)
                    continue;
                
                e._axis[i] = value;
                e.axesState[i] = !(value < 300 && value > -300) ? value : 0;
                
                JoystickEvent jevent;
                jevent.id = e.id;
                jevent.type = JoystickEventType.axisMove;
                jevent.axis = cast(JoystickAxis) flagsAxis[i];
                jevent.value = !(value < 300 && value > -300) ? value : 0;
                jEvents ~= jevent;
            }
            
            if (joyInfo.dwFlags & JOY_RETURNBUTTONS)
            {
                foreach (i; 0 .. e.numButtons)
                {
                    int pressed = joyInfo.dwButtons & (1 << i);
                
                    if (pressed == 0)
                    {
                        if (1 << i in e.buttons)
                        if (e.buttons[1 << i] != 0)
                        {
                            JoystickEvent jevent;
                            jevent.id = e.id;
                            jevent.type = JoystickEventType.buttonReleased;
                            jevent.value = 1 << i;
                            jEvents ~= jevent;
                            e.buttons[1 << i] = 0;
                        }
                        
                        continue;
                    }
                    
                    if (1 << i in e.buttons)
                    {
                        if(e.buttons[1 << i] != 0)
                            continue;
                    }
                     
                    e.buttons[1 << i] = 1;   
                    JoystickEvent jevent;
                    jevent.id = e.id;
                    jevent.type = JoystickEventType.buttonPressed;
                    jevent.value = 1 << i;
                    jEvents ~= jevent;
                }
            }
        }
    }

    bool hasEvent()
    {
        return  jEvents.length != 0 ||
                PeekMessage(&this.msg, this.window.handle, 0, 0, PM_NOREMOVE) != 0 ||
                window.isResize;
    }

    bool nextEvent()
    {
        TranslateMessage(&this.msg); 
        DispatchMessage(&this.msg);
        
        joyPeek();
        if (PeekMessage(&this.msg, this.window.handle, 0, 0, PM_REMOVE) == 0)
        {
            if (jEvents.length == 0)
            {
                currJEvent = null;
                if (window.isResize)
                {
                    _isResize = true;
                    window.isResize = false;
                    return true;
                }

                return false;
            }
            else
            {
                currJEvent = &jEvents[0];
                jEvents = jEvents[1 .. $];
                _isResize = false;
                
                return true;
            }
        } else
        {
            _isResize = false;
            return true;
        }
    }

    bool isKeyDown()
    {
        return this.msg.message == WM_KEYDOWN;
    }

    bool isKeyUp()
    {
        return this.msg.message == WM_KEYUP;
    }

    @property int key()
    {
        return cast(int) this.msg.wParam;
    }

    bool isMouseDown()
    {
        return this.msg.message == WM_LBUTTONDOWN ||
               this.msg.message == WM_RBUTTONDOWN ||
               this.msg.message == WM_MBUTTONDOWN;
    }

    bool isMouseUp()
    {
        return this.msg.message == WM_LBUTTONUP ||
               this.msg.message == WM_RBUTTONUP ||
               this.msg.message == WM_MBUTTONUP;
    }

    @property MouseButton mouseButton()
    {
        if (this.msg.message == WM_LBUTTONUP || this.msg.message == WM_LBUTTONDOWN)
            return MouseButton.left;

        if (this.msg.message == WM_RBUTTONUP || this.msg.message == WM_RBUTTONDOWN)
            return MouseButton.right;

        if (this.msg.message == WM_MBUTTONUP || this.msg.message == WM_MBUTTONDOWN)
            return MouseButton.middle;

        return MouseButton.unknown;
    }

    @property int[2] mousePosition()
    {
        POINT p;
        GetCursorPos(&p);
        ScreenToClient((cast(Window) this.window).handle, &p);

        return [p.x, p.y];
    }

    @property int mouseWheel()
    {
        if (this.msg.message != WM_MOUSEWHEEL) return 0;

        return (cast(int) this.msg.wParam) > 0 ? -1 : 1;
    }

    bool isResize()
    {
        return _isResize;
    }

    uint[2] newSizeWindow()
    {
        RECT rect;
        // DwmGetWindowAttribute((
        //     cast(Window) this.window).handle, 
        //     DWMWINDOWATTRIBUTE.DWMWA_EXTENDED_FRAME_BOUNDS, cast(LONG64) &rect, rect.sizeof
        // );

        GetClientRect((cast(Window) this.window).handle, &rect);
        //GetWindowRect((cast(Window) this.window).handle, &rect);

        return [rect.right, rect.bottom];
    }

    bool isQuit()
    {
        return window.isClose;
    }

    bool isInputText()
    {
        return this.msg.message == WM_CHAR;
    }

    string inputChar()
    {
        import std.utf : toUTF8;

        wstring text = [];
        text = [cast(wchar) msg.wParam];

        string utftext = text.toUTF8;

        return [utftext[0]];
    }

    wstring inputWChar()
    {
        return [cast(wchar) msg.wParam];
    }
    
    @property IJoystick[] joysticks() @trusted
    {
        import std.conv : to;

        IJoystick[] js;
    
        if (_joysticks.length != 0)
        {
            foreach (e; _joysticks)
                js ~= cast(IJoystick) e;
            return js;
        }
            
        immutable numDevs = joyGetNumDevs();
        if (numDevs == 0)
            return [];
        
        foreach (i; 0 .. 2)
        {
            JOYINFOEX jInfo;
            JOYCAPS jCaps;
            
            if (joyGetPosEx(Joystick.jid[i], &jInfo) == JOYERR_UNPLUGGED)
            {
                continue;   
            }
            
            if (joySetCapture(window.handle, Joystick.jid[i], 0, true))
            {
                continue;
            }
            
            joyGetDevCaps(Joystick.jid[i], &jCaps, jCaps.sizeof);
            
            auto jj =  new Joystick(i, this);
            jj.numAxes = jCaps.wNumAxes;
            jj.numButtons = jCaps.wNumButtons;
            jj.axesState = new int[](jj.numAxes);
            jj.namely = jCaps.szPname.to!string;
            
            immutable wAxisMin = [
                jCaps.wXmin,
                jCaps.wYmin,
                jCaps.wZmin,
                jCaps.wRmin,
                jCaps.wUmin,
                jCaps.wVmin
            ];
            
            immutable wAxisMax = [
                jCaps.wXmax,
                jCaps.wYmax,
                jCaps.wZmax,
                jCaps.wRmax,
                jCaps.wUmax,
                jCaps.wVmax
            ];
                        
            foreach (j; 0 .. jj.numAxes)
            {
                jj._axis ~= 0;
                jj.axisMin ~= wAxisMin[i];
                jj.axisMax ~= wAxisMax[i];
                jj.axisOffset ~= Joystick.defAxisMin - wAxisMin[i];
                jj.axisScale ~= (cast(float) Joystick.defAxisMax - cast(float) (Joystick.defAxisMin)) / (cast(float) wAxisMax[i] - cast(float) wAxisMin[i]);
            }
            
            _joysticks ~= jj;
            js ~= cast(IJoystick) jj;
        }

        return js;
    }
}

version(Posix)///
static enum Key
{
    Escape = 9,
    F1 = 67,
    F2 = 68,
    F3 = 69,
    F4 = 70,
    F5 = 71,
    F6 = 72,
    F7 = 73,
    F8 = 74,
    F9 = 75,
    F10 = 76,
    F11 = 95,
    F12 = 96,
    PrintScrn = 111,
    ScrollLock = 78,
    Pause = 110,
    Backtick = 49,
    K1 = 10,
    K2 = 11,
    K3 = 12,
    K4 = 13,
    K5 = 14,
    K6 = 15,
    K7 = 16,
    K8 = 17,
    K9 = 18,
    K0 = 19,
    Minus = 20,
    Equal = 21,
    Backspace = 22,
    Insert = 106,
    Home = 97,
    PageUp = 99,
    NumLock = 77,
    KPSlash = 112,
    KPStar = 63,
    KPMinus = 82,
    Tab = 23,
    Q = 24,
    W = 25,
    E = 26,
    R = 27,
    T = 28,
    Y = 29,
    U = 30,
    I = 31,
    O = 32,
    P = 33,

    SqBrackLeft = 34,
    SqBrackRight = 35,
    SquareBracketLeft = 34,
    SquareBracketRight = 35,

    Return = 36,
    Delete = 107,
    End = 103,
    PageDown = 105,

    KP7 = 79,
    KP8 = 80,
    KP9 = 81,

    CapsLock = 66,
    A = 38,
    S = 39,
    D = 40,
    F = 41,
    G = 42,
    H = 43,
    J = 44,
    K = 45,
    L = 46,
    Semicolons = 47,
    Apostrophe = 48,

    KP4 = 83,
    KP5 = 84,
    KP6 = 85,

    ShiftLeft = 50,
    International = 94,

    Z = 52,
    X = 53,
    C = 54,
    V = 55,
    B = 56,
    N = 57,
    M = 58,
    Comma = 59,
    Point = 60,
    Slash = 61,

    ShiftRight = 62,

    BackSlash = 51,
    Up = 111,

    KP1 = 87,
    KP2 = 88,
    KP3 = 89,

    KPEnter = 108,
    CtrlLeft = 37,
    SuperLeft = 115,
    AltLeft = 64,
    Space = 65,
    AltRight = 113,
    LogoRight = 116,
    Menu = 117,
    CtrlRight = 109,
    Left = 113,
    Down = 116,
    Right = 114,
    KP0 = 90,
    KPPoint = 91
}

version(Windows)///
static enum Key
{
    Escape = 0x1B,
    F1 = 0x70,
    F2 = 0x71,
    F3 = 0x72,
    F4 = 0x73,
    F5 = 0x74,
    F6 = 0x75,
    F7 = 0x76,
    F8 = 0x77,
    F9 = 0x78,
    F10 = 0x79,
    F11 = 0x7A,
    F12 = 0x7B,
    PrintScrn = 0x2A,
    ScrollLock = 0x91,
    Pause = 0x13,
    Backtick = 0xC0,
    K1 = 0x31,
    K2 = 0x32,
    K3 = 0x33,
    K4 = 0x34,
    K5 = 0x35,
    K6 = 0x36,
    K7 = 0x37,
    K8 = 0x38,
    K9 = 0x39,
    K0 = 0x30,
    Minus = 0xBD,
    Equal = 0xBB,
    Backspace = 0x08,
    Insert = 0x2D,
    Home = 0x24,
    PageUp = 0x21,
    NumLock = 0x90,
    KPSlash = 0x6F,
    KPStar = 0xBB,
    KPMinus = 0xBD,
    Tab = 0x09,
    Q = 0x51,
    W = 0x57,
    E = 0x45,
    R = 0x52,
    T = 0x54,
    Y = 0x59,
    U = 0x55,
    I = 0x49,
    O = 0x4F,
    P = 0x50,

    SqBrackLeft = 0xDB,
    SqBrackRight = 0xDD,
    SquareBracketLeft = 0x30,
    SquareBracketRight = 0xBD,

    Return = 0x0D,
    Delete = 0x2E,
    End = 0x23,
    PageDown = 0x22,

    KP7 = 0x67,
    KP8 = 0x68,
    KP9 = 0x69,

    CapsLock = 0x14,
    A = 0x41,
    S = 0x53,
    D = 0x44,
    F = 0x46,
    G = 0x47,
    H = 0x48,
    J = 0x4A,
    K = 0x4B,
    L = 0x4C,
    Semicolons = 0xBA,
    Apostrophe = 0xBF,

    KP4 = 0x64,
    KP5 = 0x65,
    KP6 = 0x66,

    ShiftLeft = 0xA0,
    International = 0xA4,

    Z = 0x5A,
    X = 0x58,
    C = 0x43,
    V = 0x56,
    B = 0x42,
    N = 0x4E,
    M = 0x4D,
    Comma = 0xBC,
    Point = 0xBE,
    Slash = 0xBF,

    ShiftRight = 0xA1,

    BackSlash = 0xE2,
    Up = 0x26,

    KP1 = 0x61,
    KP2 = 0x62,
    KP3 = 0x63,

    KPEnter = 0x6A,
    CtrlLeft = 0xA2,
    SuperLeft = 0xA4,
    AltLeft = 0xA4,
    Space = 0x20,
    AltRight = 0xA5,
    SuperRight = 0xA5,
    Menu = 0,
    CtrlRight = 0xA3,
    Left = 0x25,
    Down = 0x28,
    Right = 0x27,
    KP0 = 0x60,
    KPPoint = 0x6F
}
