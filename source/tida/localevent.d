/++
A module for describing some local events by means of function attributes.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.localevent;

export:

enum
{
    /++

    +/
    Create,

    /++
    Object initialization flag. Will be called when the very first scene
    initialization occurs. When control is transferred to the scene again,
    such functions will no longer be called.
    +/
    Init,

    /++
    A function with such a flag will be called only when the scene has already
    been initialized and control is transferred to it again, and so on every time.
    +/
    Restart,

    /++
    A function with such a flag will be called when control is transferred to
    the scene, regardless of whether it was initialized or not.
    +/
    Entry,

    /++
    A function with such a flag will be called only when the scene control is lost.
    +/
    Leave,

    /++
    This flag is called every unit of the game loop pass in the current scene.
    +/
    Step,

    /++
    This function with a flag will be called when the user has entered something.
    Like a mouse, keyboard, joystick, etc.
    +/
    Input,

    /++
    This function will be called to draw an object to form a frame.
    +/
    Draw,

    /++
    A function with this flag will respond to all triggers that were
    called in the current scene.
    +/
    AnyTrigger,

    /++
    A function with this flag will react to all collisions of two objects
    (only applicable to an instance).
    +/
    AnyCollision,

    /++
    A function with this flag will react when the scene destroys the
    owner of the function.
    +/
    deprecated("Use instead `@Trigger(Destroy)`")
    Destroy,

    /++
    A function with such a flag will be called at the very beginning of the game
    (if such an object was previously added to the constructor).
    +/
    GameStart,

    /++
    A function with this flag will be called when the game is restarted.
    +/
    GameRestart,

    /++
    A function with this flag will be called when the game ends.
    It is not necessary to implement garbage cleaning here, it is enough to
    implement it in destructors, here they usually implement the storage
    of some data.
    +/
    GameExit,

    /++
    A function with this flag will be called when an unhandled error occurs.
    +/
    GameError,

    /++
    TODO: desript here
    +/
    EachInstance
}

struct event
{
    int type;
}

deprecated("Use instead `@event(type)`")
{
    template FunEvent(int ev)
    {
        enum FunEvent = event(ev);
    }
    
    alias Event = FunEvent;
}

/++
Trigger flag. It is hung on a function where triggers with the selected
name will be listened to.

Example:
---
@Trigger("Attack")
void onAttack() { ... }
---
+/
struct Trigger
{
export:
    string name;
}

/++
Event flag. Functions with this attribute will listen for collision events
only for the instance selected in the arguments (by name and / or tag).

Example:
---
@Collision("Wolf")
void onWolfCollision(Instance wolf) { ... }
---
+/
enum collisionEvent(string name, string tag = "") = Trigger(name ~ "." ~ tag);

enum collisionTagEvent(string tag) = Trigger("." ~ tag);

struct Collision
{
    Trigger trigger;

    this(string name, string tag = "")
    {
        this.trigger = Trigger("Collision:" ~ name ~ "." ~ tag);
    }
}

enum anyCollision = Trigger("AnyCollision");
enum destroyEvent = Trigger("Destroy");
enum selfDestroyEvent = Trigger("SelfDestroy");

/++
Attribute indicating in which thread you need to make an object step.

Example:
---
@StepThread(2) void threadStep() @safe
{
    ...
}
---
+/
struct StepThread
{
export:
    size_t id;
}

/++
Attribute indicating that the flow function function
(guarantees the programmer himself) and can be transferred to another
stream to accelerate. Do not combine with the  @event(step).
+/
struct threadSafe {}

deprecated("This is not used now, the parameters are read through the traits.")
struct args(T...)
{
    alias members = T;
}

/++
Example:
---
class MyInstance : Instance
{
    @asset("path/image.png") // path or name
    Image image;
}
---
+/
struct asset
{
    string name;
}

struct noncollect {}

struct inSpriteDefault { }

struct animationCut
{
    uint    x,
            y,
            w,
            h;
    float speed = 0.75f;
    bool isRepeat = false;
}

import tida.graphics.gapi : StageType;

struct ShaderModule
{
    string path;
    StageType stage;
}

struct ShaderBuild
{
    string name;
    ShaderModule[] modules;

    this(string name, ShaderModule[] modules)
    {
        this.name = name;
        this.modules = modules;
    }

    this(T...)(string name, T modules)
    {
        this.name = name;
        this.modules = [modules];
    }
}