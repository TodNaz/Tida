module tida.sdlevent;

import tida.window;
import tida.event;
import bindbc.sdl;

export:

version(SDL):
class Joystick : IJoystick
{
    /++
    A method that returns the value of all axes of the controller. 
    The maximum number of axes can be checked using the `.length` property:
    ---
    writeln("Axless count: ", joystick.axless.length);
    ---
    +/
    @property int[] axless() @safe
    {
        return [];
    }
    
    /++
    A method that returns the maximum number of buttons on the controller.
    +/
    @property uint maxButtons() @safe
    {
        return 0;
    }
    
    /++
    A method that returns the name of the controller.
    +/
    @property string name() @safe
    {
        return "NOT SUPPORTED";
    }
    
    /++
    Method showing which button was pressed/released in the current event.
    +/
    @property int button() @safe
    {
        return -1;
    }
    
    /++
    Shows the state when any button was pressed.
    +/
    @property bool isButtonDown() @safe
    {
        return false;
    }
    
    /++
    Shows the state when any button was released..
    +/
    @property bool isButtonUp() @safe
    {
        return false;
    }
    
    /++
    Shows the state when any one of the axes has changed its state.
    +/
    @property bool isAxisMove() @safe
    {
        return false;
    }

}

class EventHandler : IEventHandler
{
    Window window;
    SDL_Event event;

    this(Window window)
    {
        this.window = window;
    }

override @trusted:
    /++
    Moves to the next event. If there are no more events, it returns false, 
    otherwise, it throws true and the programmer can safely check which event 
    s in the current queue.
    +/
    bool nextEvent()
    {
        auto tick = SDL_PollEvent(&event);  

        return tick != 0;
    }

    /++
    Checking if any key is pressed in the current event.
    +/
    bool isKeyDown()
    {
        return event.type == SDL_KEYDOWN;
    }

    /++
    Checking if any key is released in the current event.
    +/
    bool isKeyUp()
    {
        return event.type == SDL_KEYUP;
    }

    /++
    Will return the key that was pressed. Returns zero if no key is pressed 
    in the current event.
    +/
    @property int key()
    {
        return cast(int) event.key.keysym.sym;
    }

    /++
    Check if the mouse button is pressed in the current event.
    +/
    bool isMouseDown()
    {
        return event.type == SDL_MOUSEBUTTONDOWN;
    }

    /++
    Check if the mouse button is released in the current event.
    +/
    bool isMouseUp()
    {
        return event.type == SDL_MOUSEBUTTONUP;
    }

    /++
    Returns the currently pressed or released mouse button.
    +/
    @property MouseButton mouseButton()
    {
        switch (event.button.button)
        {
            case SDL_BUTTON_LEFT:
                return MouseButton.left;

            case SDL_BUTTON_RIGHT:
                return MouseButton.right;

            case SDL_BUTTON_MIDDLE:
                return MouseButton.middle;

            default:
                return MouseButton.unknown;
        }
    }

    /++
    Returns the position of the mouse in the window.
    +/
    @property int[2] mousePosition()
    {
        return [event.motion.x, event.motion.y];
    }

    /++
    Returns in which direction the user is turning the mouse wheel. 
    1 - down, -1 - up, 0 - does not twist. 

    This iteration is convenient for multiplying with some real movement coefficient.
    +/
    @property int mouseWheel()
    {
        if (event.type != SDL_MOUSEWHEEL)
            return 0;

        return event.wheel.y > 0 ? -1 : 1; 
    }

    /++
    Indicates whether the window has been resized in this event.
    +/
    bool isResize()
    {
        return  event.type == SDL_WINDOWEVENT &&
                (event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED ||
                 event.window.event == SDL_WINDOWEVENT_RESIZED);
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
        uint[2] res;
        SDL_GetWindowSize(window.handle, cast(int*) &res[0], cast(int*) &res[1]);

        return res;
    }

    /++
    Indicates whether the user is attempting to exit the program.
    +/
    bool isQuit()
    {
        return event.type == SDL_QUIT;
    }

    /++
    Indicates whether the user has entered text information.
    +/
    bool isInputText()
    {
        return false;
    }

    /++
    User entered data.
    +/
    @property string inputChar() { return ""; }

    @property wstring inputWChar() { return ""w; }
    
    /++
    Returns an array of the interface for controlling joysticks. 
    If its length is zero, no joysticks were found.

    It is checked once, if one controller has been disabled, then it is recommended 
    to zero the array as shown below and call again to rescan the joysticks.
    ---
    event.joysticks.length = 0;
    ---
    +/
    @property IJoystick[] joysticks() @safe
    {
        return [];
    }
}

static enum Key
{
    Escape = SDLK_ESCAPE,
    F1 = SDLK_F1,
    F2 = SDLK_F2,
    F3 = SDLK_F3,
    F4 = SDLK_F4,
    F5 = SDLK_F5,
    F6 = SDLK_F6,
    F7 = SDLK_F7,
    F8 = SDLK_F8,
    F9 = SDLK_F9,
    F10 = SDLK_F10,
    F11 = SDLK_F11,
    F12 = SDLK_F11,
    PrintScrn = SDLK_PRINTSCREEN,
    ScrollLock = SDLK_SCROLLLOCK,
    Pause = SDLK_PAUSE,
    Backtick = SDLK_BACKQUOTE,
    K1 = SDLK_1,
    K2 = SDLK_2,
    K3 = SDLK_3,
    K4 = SDLK_4,
    K5 = SDLK_5,
    K6 = SDLK_6,
    K7 = SDLK_7,
    K8 = SDLK_8,
    K9 = SDLK_9,
    K0 = SDLK_0,
    Minus = SDLK_MINUS,
    Equal = SDLK_EQUALS,
    Backspace = SDLK_BACKSPACE,
    Insert = SDLK_INSERT,
    Home = SDLK_HOME,
    PageUp = SDLK_PAGEUP,
    NumLock = SDLK_NUMLOCKCLEAR,
    KPSlash = SDLK_KP_DIVIDE,
    KPStar = SDLK_KP_MULTIPLY,
    KPMinus = SDLK_KP_PLUSMINUS,
    Tab = SDLK_TAB,
    Q = SDLK_q,
    W = SDLK_w,
    E = SDLK_e,
    R = SDLK_r,
    T = SDLK_t,
    Y = SDLK_y,
    U = SDLK_u,
    I = SDLK_i,
    O = SDLK_o,
    P = SDLK_p,

    SqBrackLeft = SDLK_LEFTBRACKET,
    SqBrackRight = SDLK_RIGHTBRACKET,
    SquareBracketLeft = 0,
    SquareBracketRight = 0,

    Return = SDLK_RETURN,
    Delete = SDLK_DELETE,
    End = SDLK_END,
    PageDown = SDLK_PAGEDOWN,

    KP7 = SDLK_KP_7,
    KP8 = SDLK_KP_8,
    KP9 = SDLK_KP_9,

    CapsLock = SDLK_CAPSLOCK,
    A = SDLK_a,
    S = SDLK_s,
    D = SDLK_d,
    F = SDLK_f,
    G = SDLK_g,
    H = SDLK_h,
    J = SDLK_j,
    K = SDLK_k,
    L = SDLK_l,
    Semicolons = SDLK_SEMICOLON,
    Apostrophe = SDLK_QUOTE,

    KP4 = SDLK_KP_4,
    KP5 = SDLK_KP_5,
    KP6 = SDLK_KP_6,

    ShiftLeft = SDLK_LSHIFT,
    International = 0,

    Z = SDLK_z,
    X = SDLK_x,
    C = SDLK_c,
    V = SDLK_v,
    B = SDLK_b,
    N = SDLK_n,
    M = SDLK_m,
    Comma = SDLK_COMMA,
    Point = SDLK_PERIOD,
    Slash = SDLK_SLASH,

    ShiftRight = SDLK_RSHIFT,

    BackSlash = SDLK_BACKSLASH,
    Up = SDLK_UP,

    KP1 = SDLK_KP_1,
    KP2 = SDLK_KP_2,
    KP3 = SDLK_KP_3,

    KPEnter = SDLK_KP_ENTER,
    CtrlLeft = SDLK_LCTRL,
    SuperLeft = SDLK_LGUI,
    AltLeft = SDLK_LALT,
    Space = SDLK_SPACE,
    AltRight = SDLK_RALT,
    LogoRight = SDLK_RGUI,
    Menu = SDLK_MENU,
    CtrlRight = SDLK_RCTRL,
    Left = SDLK_LEFT,
    Down = SDLK_DOWN,
    Right = SDLK_RIGHT,
    KP0 = SDLK_KP_0,
    KPPoint = SDLK_KP_PERIOD
}