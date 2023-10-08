/++
The module describing the unit of the object - Instance.

An instance is an object in a scene with behavior only for itself with the
interaction of other instances, through collisions, any internal events.
Each instance has properties of execution conditions, rendering conditions,
rendering properties, conditions for the execution of some events. All of these
properties describe an instance, however, more behavior can be achieved using
inheritance (see `tida.localevent`). Instance functions are not inherited. but
they are directly written and marked with attributes that give execution
conditions (under what conditions it is necessary to execute, as if it is a
transfer of control between scenes, rendering of a frame, processing user input).

Also, an instance has a hard mask, where, when it touches another mask,
a collision event can be generated and such instances can handle this event,
if, of course, the corresponding functions have been marked with attributes.

---
class MyObject : Instance
{
    this() { ... }

    @event(Init)
    void onInitFunction()
    {
        firstProperty = 0.0f;
        position = vecf(32f, 11.5f);
        ...
    }

    @Collision("OtherInstanceName")
    void onCollsion(Instance other)
    {
        other.posiiton -= vecf(1, 0);
    }
}
---

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.instance;

export:
/++
Checks if an object is an instance.
+/
template isInstance(T)
{
    enum isInstance = is(T : Instance);
}

struct InstanceEvents
{
    import tida.event;
    import tida.render;
    import tida.localevent;

    struct FEEntry
    {
        void delegate() @safe func;
        string[] __types;

        static FEEntry create(T...)(void delegate() @safe func) @trusted
        {
            FEEntry entry;
            entry.func = func;
            entry.appendArguments!T();

            return entry;
        }

        void appendArguments(T...)() @trusted
        {
            static foreach (Arg; T)
            {
                __types ~= Arg.stringof;
            }
        }

        bool validArgs(T...)(T args) @trusted
        {
            import std.traits : AllImplicitConversionTargets;
            import std.algorithm : canFind;

            size_t countConv = 0;
            string[][] newTypes;

            if (__types.length == 0)
                return true;
            else
            {
                static foreach (Arg; T)
                {
                    newTypes.length += 1;
                    newTypes[$ - 1] ~= Arg.stringof;
                    static foreach (Imip; AllImplicitConversionTargets!Arg)
                    {
                        newTypes[$ - 1] ~= Imip.stringof;
                    }
                }

                if (newTypes.length != __types.length)
                    return false;

                foreach (i; 0 .. __types.length)
                {
                    if (newTypes[i].canFind(__types[i]))
                        countConv++;
                }

                return countConv == __types.length;
            }
        }

        void opCall(T...)(T args) @trusted
        {
            /+
            When indicating such a flag, with a discrepancy of the arguments
            submitted during the transition of the stage, an error will
            occur so that the programmer can correct the shortcomings.
            In the absence of such a flag, this function will not be caused,
            thereby, different implementations of the functions will be
            caused depending on the arguments.
            +/
            if (!validArgs(args))
            {
                version (anErrorInCaseOfMismatch)
                    assert(null, "Arguments do not match!");
                else
                    return;
            }

            void delegate(T) @safe callFunction = cast(void delegate(T) @safe) func;
            callFunction(args);
        }
    }

    alias FEInit = FEEntry;
    alias FERestart = FEEntry;

    alias FELeave = void delegate() @safe;
    alias FEStep = void delegate() @safe;
    alias FEGameStart = void delegate() @safe;
    alias FEGameExit = void delegate() @safe;
    alias FEGameRestart = void delegate() @safe;
    alias FEEventHandle = void delegate(EventHandler) @safe;
    alias FEDraw = void delegate(IRenderer) @safe;
    alias FEOnError = void delegate() @safe;
    alias FECollision = void delegate(Instance) @safe;
    alias FETrigger = void delegate() @safe;
    alias FEDestroy = void delegate(Instance) @safe;
    alias FEATrigger = void delegate(string) @safe;

    struct SRCollider
    {
        Collision ev;
        FECollision fun;
    }

    struct SRTrigger
    {
        Trigger ev;
        FETrigger func;

        string[] __types;

        static SRTrigger create(T...)(Trigger ev, void delegate() @safe func) @trusted
        {
            if (ev == Trigger.init)
                throw new Exception("Trigger is not must equal empty.");

            SRTrigger trigg;
            trigg.func = func;
            trigg.appendArguments!T();
            trigg.ev = ev;

            return trigg;
        }

        void appendArguments(T...)() @trusted
        {
            static foreach (Arg; T)
            {
                __types ~= Arg.stringof;
            }
        }

        bool validArgs(T...)(T args) @trusted
        {
            import std.traits : AllImplicitConversionTargets;
            import std.algorithm : canFind;

            size_t countConv = 0;
            string[][] newTypes;

            static foreach (Arg; T)
            {
                newTypes.length += 1;
                newTypes[$ - 1] ~= Arg.stringof;
                static foreach (Imip; AllImplicitConversionTargets!Arg)
                {
                    newTypes[$ - 1] ~= Imip.stringof;
                }
            }

            if (newTypes.length != __types.length)
                return false;

            foreach (i; 0 .. __types.length)
            {
                if (newTypes[i].canFind(__types[i]))
                    countConv++;
            }

            return countConv == __types.length;
        }

        void opCall(T...)(T args) @trusted
        //in (validArgs(args))
        {
            void delegate(T) @safe callFunction = cast(void delegate(T) @safe) func;
            callFunction(args);
        }
    }

    bool isCreate = false;

    void delegate() @safe[] ICreateFunctions;
    FEInit[] IInitFunctions;

    FEStep[] IStepFunctions;
    FEStep[][size_t] IStepThreadFunctions;
    FERestart[] IRestartFunctions;
    FEEntry[] IEntryFunctions;
    FELeave[] ILeaveFunctions;
    FEGameStart[] IGameStartFunctions;
    FEGameExit[] IGameExitFunctions;
    FEGameRestart[] IGameRestartFunctions;
    FEEventHandle[] IEventHandleFunctions;
    FEDraw[] IDrawFunctions;
    FEOnError[] IOnErrorFunctions;
    SRCollider[] IColliderStructs;
    FECollision[] ICollisionFunctions;
    SRTrigger[] IOnTriggerFunctions;
    FEDestroy[] IOnDestroyFunctions;
    FEATrigger[] IOnAnyTriggerFunctions;

    void delegate() @safe OnAssetLoad;
    void delegate() @safe OnShaderLoad;
}

struct RegComponent
{
    string aliasName;
    void[] structInfo;

    template tSizeof(T...)
    {
        static if (T.length == 0) 
            enum tSizeof = 0;
        else
            enum tSizeof = T[0].sizeof + tSizeof!(T[1 .. $]);
    }

    void opCall(T...)(T args)
    {
        // if (tSizeof!T != structInfo.sizeof)
        //     throw new Exception("Removable!");

        size_t offset;
        foreach (arg; args)
        {
            auto a = arg;
            structInfo[offset .. offset += arg.sizeof] = (cast(void*) &a)[0 .. arg.sizeof];
        }

        import std.stdio;
        writeln (structInfo);
    }

    T opCast(T)()
    {
        if (T.sizeof != structInfo.length)
            return T.init;

        T* tcast = cast(T*) structInfo.ptr; 

        return *tcast;
    }
}

/++
Instance object. Can be created for a render unit as well as for legacy
with a programmable model.
+/
class Instance
{
    import tida.vector;
    import tida.sprite;
    import tida.shape;
    import tida.component;

protected:
    /++
    Components of an instance, complementing its functionality.
    +/
    Component[] components;

    //RegComponent[] reqComponents;

    /// only for call.
    bool _destroy = false;

export:
    /++
    Instance sprite. Will be output at the position of the instance.
    +/
    Sprite sprite;

    InstanceEvents events;

    // auto opDispatch(string name, T...)(T args)
    // {
    //     foreach (rc; reqComponents)
    //     {
    //         if (rc.aliasName == name)
    //         {
    //             static if (T.length != 0)
    //                 rc(args);

    //             return rc;
    //         }
    //     }

    //     return RegComponent.init;
    // }

    // void bind(string name, T)() @safe
    // {
    //     RegComponent cmp;
    //     cmp.aliasName = name;
    //     cmp.structInfo = new void[](T.sizeof);

    //     reqComponents ~= cmp;
    // }

    @property auto colliders() @safe
    {
        return events.IColliderStructs;
    }

    @property auto collisionFunctions() @safe
    {
        return events.ICollisionFunctions;
    }

    /++
    The name of the instance, by which you can later identify
    the collided or other events.
    +/
    string name;

    /++
    Instance tags. By this parameter, it is possible to distribute an instance
    about groups, for example, instances that should not let the player in upon
    collision will be marked with the "solid" tag, but not necessarily only
    non-living creatures should be used, and others who should not squeeze
    through are marked with such a tag.
    (This is an example, there is no such implementation in the framework).
    +/
    string[] tags;

    /++
    The position of the instance. Serves for collision, rendering, and
    other instance services.
    +/
    Vector!float position = vec!float(0.0f, 0.0f);

    /++
    An auxiliary variable that remembers the position in the previous
    pass of the game loop.
    +/
    Vector!float previous = vec!float(0.0f, 0.0f);

    /++
    Collision mask. A mask is a kind of geometric shape (or several shapes)
    that sets the collision boundary between other instances.
    +/
    Shape!float mask;

    /++
    A property that determines whether an instance can collide with
    other instances.
    +/
    bool solid = false;

    /++
    Instance identifier (often means storage location in an instances array).
    +/
    size_t id;

    /++
    The identifier for the instance in the stream. Shows which thread the
    instance is running on (changing the property does not affect thread selection).
    +/
    size_t threadid;

    /++
    A property indicating whether to handle all events for such an instance.
    If false, no event will be processed for this instance, however,
    it will exist. It is necessary if you do not need to delete the instance,
    but you also do not need to process its events.
    +/
    bool active = true;

    /++
    A property that indicates whether to render the instance and perform
    rendering functions.
    +/
    bool visible = true;

    /++
    A property that indicates whether it is only necessary to draw the object
    without handling other events in it.
    +/
    bool onlyDraw = false;

    /++
    A property that indicates whether to transition to a new scene when
    transferring control to another scene.
    +/
    bool persistent = false;

    /++
    The identifier of the layer in which the instance is placed.
    The render queue is affected, the larger the number, the later the
    instance will be rendered.
    +/
    int depth = 0;

@safe:
    this()
    {
        sprite = new Sprite();
    }

    /++
    Removes an instance. However, not immediately, this will only happen on
    the next iteration of the game loop for thread safety.
    +/
    final void destroy()
    {
        _destroy = true;
    }

    /++
    A method for adding an instance to an instance to expand functionality.

    Params:
        component = Component object.
    +/
    final void add(T)(T component)
    {
        import tida.scenemanager;
        
        static if (is(T : Instance))
            static assert(null, T.stringof ~ " is not a component! Maybe you meant `sceneManager.context.add`?");
        else
            static assert(isComponent!T, T.stringof ~ " is not a component!");

        components ~= component;
        if (component.name == "")
            component.name = T.stringof;

        sceneManager.componentExplore!T(this, component);
    }

    /++
    A method for adding an instance to an instance to expand functionality.

    Params:
        T = Component type.
    +/
    final void add(T)()
    {
        add(new T());
    }

    /++
    A function that returns a component based on its class.

    Params:
        T = Component type.
    +/
    final T cmp(T)()
    {
        static assert(isComponent!T, T.stringof ~ " is not a component!");

        foreach (e; components)
        {
            if ((cast(T) e) !is null)
            {
                return cast(T) e;
            }
        }

        return null;
    }

    /++
    Finds a component by its name.

    Params:
        name = Component name.
    +/
    final Component cmp(string name)
    {
        foreach (e; components)
        {
            if (e.name == name)
                return e;
        }

        return null;
    }

    /++
    Detaches a component from an instance by finding it by class.

    Params:
        T = Component type.
    +/
    final void dissconnect(T)()
    {
        import std.algorithm : remove;
        import tida.scenemanager;
        static assert(isComponent!T, "`" ~ T.stringof ~ "` is not a component!");

        Component cmp;

        foreach (i; 0 .. components.length)
        {
            if ((cast(T) components[i]) !is null)
            {
                cmp = components[i];

                foreach(fun; cmp.events.CLeaveFunctions) fun();

                components = components.remove(i);
                break;
            }
        }
    }

    /++
    Detaches a component from an instance by finding it by name.

    Params:
        name = Instance name.
    +/
    final void dissconnect(string name)
    {
        import std.algorithm : remove;
        import tida.scenemanager;

        foreach (i; 0 .. components.length)
        {
            if (components[i].name == name)
            {
                foreach(fun; components[i].events.CLeaveFunctions) fun();

                components = components.remove(i);
                break;
            }
        }
    }

    /++
    Detaches absolutely all components in this instance.
    +/
    final void dissconnectAll() @trusted
    {
        import tida.scenemanager;
        import std.algorithm : remove;

        foreach (i; 0 .. components.length)
        {
            if (sceneManager !is null)
            {
                foreach(fun; components[i].events.CLeaveFunctions)
                    fun();
            }
        }
        
        components = [];
    }

package(tida):
    bool isDestroy()
    {
        return _destroy;
    }

    Component[] getComponents()
    {
        return components;
    }
}

unittest
{
    import tida.scenemanager;
    import tida.component;

    initSceneManager();

    class CComponent : Component { }

    CComponent cmp = new CComponent();
    cmp.name = "Cmp";

    Instance instance = new Instance();
    instance.add(cmp);

    assert(instance.cmp("Cmp") is (cmp));
    assert(instance.cmp!(CComponent) is (cmp));
}

debug import tida.color;

debug template debugCollisionMask(Color!ubyte color = Color!ubyte(255, 0, 0))
{
    import tida.render;
    import std.conv : to;

    void __drawShapeConture(Vecf releative, Shapef shape, IRenderer render) @safe
    {
        switch (shape.type)
        {
            case ShapeType.point:
                render.point(shape.begin + releative, color);
            break;

            case ShapeType.line:
                render.line([   shape.begin + releative,
                                shape.end + releative], color);
            break;

            case ShapeType.rectangle:
                render.rectangle(   shape.begin + releative, 
                                    shape.width.to!uint, 
                                    shape.height.to!uint,
                                    color,
                                    false);
            break;

            case ShapeType.circle:
                render.circle(shape.begin + releative, shape.radius, color, false);
            break;

            case ShapeType.triangle:
                render.triangle([   shape.vertex!0 + releative, 
                                    shape.vertex!1 + releative, 
                                    shape.vertex!2 + releative], color, false);
            break;

            case ShapeType.multi:
                foreach (sh; shape.shapes)
                {
                    __drawShapeConture(releative + shape.begin, sh, render);
                }
            break;

            default:
                return;
        }   
    }

    @event(Draw)
    void __debug_drawMask(IRenderer render) @safe
    {
        __drawShapeConture(position, mask, render);
    }
}

unittest
{
    import tida.component;
    import tida.scenemanager;
    import tida.localevent;

    initSceneManager();

    static class A : Component
    {
        int trace = 0;

        @event(Init)
        void onInit(Instance instance) @safe
        {
            trace++;
        }
    }

    Instance instance = new Instance();
    A a;
    instance.add(a = new A());

    assert(a.trace == 1);
}
