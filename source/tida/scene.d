/++
Scene description module.

A stage is an object that manages instances, collisions between them and serves
as a place for them (reserves them in a separate array). Such an object can
also be programmable using events (see tida.localevent). It does not have
properties that define behavior without functions, it can only contain
instances that, through it, can refer to other instances.

WARNING:
Don't pass any arguments to the scene constructor.
This breaks the scene restart mechanism.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.scene;

export:

enum
{
    InMemory, /// Delete with memory
    InScene /// Delete with scene
}

/++
A template that checks if the type is a scene.
+/
template isScene(T)
{
    enum isScene = is(T : Scene);
}

struct SceneEvents
{
    import tida.event;
    import tida.render;
    import tida.localevent;
    import tida.instance;

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
            if (!validArgs(args))
            {
                /+
                When indicating such a flag, with a discrepancy of the arguments
                submitted during the transition of the stage, an error will
                occur so that the programmer can correct the shortcomings.
                In the absence of such a flag, this function will not be caused,
                thereby, different implementations of the functions will be
                caused depending on the arguments.
                +/
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

    alias FEStep = void delegate() @safe;
    alias FELeave = void delegate() @safe;
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

    struct SRTrigger
    {
        Trigger ev;
        FETrigger func;

        string[] __types;

        static SRTrigger create(T...)(Trigger ev, void delegate() @safe func) @trusted
        {
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
        in (validArgs(args))
        {
            void delegate(T) @safe callFunction = cast(void delegate(T) @safe) func;
            callFunction(args);
        }
    }

    bool isCreate = false;

    FEInit[] InitFunctions;
    FEStep[] StepFunctions;
    FEStep[][size_t] StepThreadFunctions;
    FEStep[] OnCreateFunctions;
    FERestart[] RestartFunctions;
    FEEntry[] EntryFunctions;
    FELeave[] LeaveFunctions;
    FEGameStart[] GameStartFunctions;
    FEGameExit[] GameExitFunctions;
    FEGameRestart[] GameRestartFunctions;
    FEEventHandle[] EventHandleFunctions;
    FEDraw[] DrawFunctions;
    FEDraw[][size_t] DrawThreadFunctions;
    FEOnError[] OnErrorFunctions;
    SRTrigger[] OnTriggerFunctions;
    FEDestroy[] OnDestroyFunctions;
    FEATrigger[] OnAnyTriggerFunctions;
    FECollision[] OnAnyCollisionFunctions;

    void delegate() @safe OnAssetLoad;
    void delegate() @safe OnShaderLoad;
}

/++
Scene object.
+/
class Scene
{
    import tida.scenemanager;
    import tida.instance;
    import tida.component;
    import tida.render;
    import tida.event;
    import tida.image;

package(tida):
    bool isInit = false;

protected:
    Instance[] instances;
    Instance[] erentInstances;
    Instance[][] bufferThread;

    Image batched;

export:
    Camera camera; /// Camera scene
    string name = ""; /// Scene name
    SceneEvents events;

    size_t[size_t] fpt;

@safe:
    this() nothrow
    {
        bufferThread = [[]];
    }

    /++
    Returns a list of instances.
    +/
    @property final Instance[] list() nothrow
    {
        return instances;
    }

    /++
    Returns a buffer of instances from the thread.

    Params:
        index = Thread id.
    +/
    final Instance[] getThreadList(size_t index) nothrow
    {
        return bufferThread[index];
    }

    /++
    Is there such a thread buffer.

    Params:
        index = Thread id.
    +/
    final bool isThreadExists(size_t index) nothrow
    {
        return index < bufferThread.length;
    }

    /++
    Creates an instance buffer for the thread.
    +/
    final void initThread(size_t count = 1) nothrow
    {
        foreach (i; 0 .. count)
        {
            bufferThread ~= [[]];
            fpt[i] = 0;
        }
    }

    /++
    Adds an instance to the scene for interpreting its actions.

    Params:
        instance = Instance.
        threadID = In which thread to add execution.
    +/
    final void add(T)(T instance, size_t threadID = 0)
    if (isInstance!T)
    in(instance, "Instance is not a create!")
    do
    {
        if (threadID >= bufferThread.length) threadID = 0;

        this.instances ~= instance;
        instance.id = this.instances.length - 1;
        instance.threadid = threadID;

        bufferThread[threadID] ~= instance;

        if (instance.name.length == 0)
            instance.name = T.stringof;

        sceneManager.instanceExplore!T(this, instance);

        if (instance.events.OnAssetLoad !is null)
            instance.events.OnAssetLoad();
        if (instance.events.OnShaderLoad !is null)
            instance.events.OnShaderLoad();

        if (!instance.events.isCreate)
        {
            instance.events.isCreate = true;
            foreach (fun; instance.events.ICreateFunctions)
            {
                fun();
            }
        }

        this.sort();
    }

    /++
    Adds multiple instances at a time.

    Params:
        instances = Instances.
        threadID = In which thread to add execution.
    +/
    final void add(Instance[] instances, size_t threadID = 0)
    {
        foreach (instance; instances)
        {
            add(instance, threadID);
        }
    }

    final void add(T...)(T args)
    {
        foreach (instance; args)
        {
            static if (isInstance!(typeof(instance)))
                add(instance);
            else
                static assert(null, "One of the parameters is not a copy.");
        }
    }

    /++
    Returns a assorted list of instances.
    +/
    final Instance[] getAssortedInstances()
    {
        return erentInstances;
    }

    /++
    Whether this instance is on the list.

    Params:
        instance = Instance.
    +/
    final bool hasInstance(Instance instance) nothrow
    {
        foreach(ins; instances)
        {
            if(instance is ins)
                return true;
        }

        return false;
    }

    /++
    Removes an instance from the list and, if a delete method is
    specified in the template, from memory.

    Params:
        instance = Instance.
        isRemoveHandle = State remove function pointers in scene manager.

    Type:
        `InScene`  - Removes only from the scene, does not free memory.
        `InMemory` - Removes permanently, from the scene and from memory
                     (by the garbage collector).
    +/
    final void instanceDestroy(ubyte type)(Instance instance, bool isRemoveHandle = true) @trusted
    //in(hasInstance(instance))
    //do
    {
        import std.algorithm : each;

        if (!hasInstance(instance))
        {
            return;
        }

        // dont remove, it's succes work.
        void remove(T)(ref T[] obj, size_t index) @trusted nothrow
        {
            auto dump = obj.dup;
            foreach (i; index .. dump.length)
            {
                import core.exception : RangeError;
                try
                {
                    dump[i] = dump[i + 1];
                }
                catch (RangeError e)
                {
                    continue;
                }
            }
            obj = dump[0 .. $-1];
        }

        remove(instances, instance.id);
        fpt[0] -= instance.events.IStepFunctions.length;
        foreach (size_t i; 0 .. bufferThread.length)
        {
            if (i == instance.threadid)
            {
                __dstBT: foreach (j; 0 .. bufferThread[i].length)
                {
                    if (bufferThread[instance.threadid][i] is instance)
                    {
                        remove(bufferThread[instance.threadid],j);
                        break __dstBT;
                    }
                }

                fpt[i] -= instance.events.IStepThreadFunctions[i].length;
            }
        }
        // foreach (size_t i; 0 .. bufferThread[instance.threadid].length)
        // {
            
        // }

        if (this.instances.length != 0)
        {
            this.instances[instance.id .. $].each!((ref e) => e.id--);
        }

        if (sceneManager !is null)
        {
            sceneManager.destroyEventCall(instance);
            sceneManager.destroyEventSceneCall(this, instance);
            sceneManager.manualTrigger(instance, "Destroy", instance);
            sceneManager.manualTrigger(instance, "SelfDestroy", instance);
        }

        if (sceneManager !is null && isRemoveHandle)
            sceneManager.removeHandle(this, instance);

        static if(type == InMemory)
        {
            instance.dissconnectAll();
            destroy(instance);
        }
    }

    /++
    Destroys an instance from the scene or from memory, depending on the template argument, by its class.

    Params:
        type = Type destroy.
        Name = Instance class.

    Type:
        `InScene`  - Removes only from the scene, does not free memory.
        `InMemory` - Removes permanently, from the scene and from memory
                     (by the garbage collector).
    +/
    final void instanceDestroy(ubyte type, Name)() @trusted
    in(isInstance!Name)
    do
    {
        instanceDestroy!type(getInstanceByClass!Name);
    }

    /++
    Returns an instance by name.

    Params:
        name = Instance name.
    +/
    final Instance getInstanceByName(string name) nothrow
    {
        synchronized
        {
            foreach (instance; list())
            {
                if (instance.name == name)
                    return instance;
            }

            return null;
        }
    }

    /++
    Returns an instances by name.

    Params:
        name = Instance name.
    +/
    final Instance[] getInstancesByName(string name) nothrow
    {
        import std.algorithm : find;

        Instance[] finded;

        foreach (e; list())
        {
            if (e.name == name)
            {
                finded ~= e;
            }
        }

        return finded;
    }

    @trusted unittest
    {
        initSceneManager();

        Scene test = new Scene();

        Instance a = new Instance();
        a.name = "bread1";

        Instance b = new Instance();
        b.name = "bread3";

        Instance c = new Instance();
        c.name = "bread1";

        Instance d = new Instance();
        d.name = "bread3";

        Instance e = new Instance();
        e.name = "bread1";

        test.add(a, b, c, d, e);

        assert(test.getInstancesByName("bread1").length == 3);
    }

    /++
    Returns an instance by name and tag.

    Params:
        name = Instance name.
        tag = Instance tag.
    +/
    final Instance getInstanceByNameTag(string name, string tag) nothrow
    {
        synchronized
        {
            foreach (instance; list())
            {
                if (instance.name == name)
                {
                    foreach (tage; instance.tags)
                        if (tag == tage)
                            return instance;
                }
            }

            return null;
        }
    }

    /++
    Returns an object by its instance inheritor.

    Params:
        T = Class name.
    +/
    final T getInstanceByClass(T)() nothrow
    in(isInstance!T)
    do
    {
        synchronized
        {
            foreach (instance; list)
            {
                if ((cast(T) instance) !is null)
                    return cast(T) instance;
            }

            return null;
        }
    }

    import tida.shape, tida.vector;

    /++
    Returns instance(-s) by its mask.

    Params:
        shape = Shape mask.
        position = Instance position.
    +/
    final Instance getInstanceByMask(Shapef shape, Vecf position)
    {
        import tida.collision;

        synchronized
        {
            foreach (instance; list())
            {
                if (instance.solid)
                if (isCollide(shape,instance.mask,position,instance.position))
                {
                    return instance;
                }
            }

            return null;
        }
    }

    /// ditto
    final Instance[] getInstancesByMask(Shapef shape,Vecf position) @safe
    {
        import tida.collision;

        Instance[] result;

        synchronized
        {
            foreach(instance; list())
            {
                if(instance.solid)
                if(isCollide(shape,instance.mask,position,instance.position)) {
                    result ~= instance;
                    continue;
                }
            }
        }

        return result;
    }

    /// Clear sorted list of instances.
    void sortClear() @safe
    {
        this.erentInstances = null;
    }

    /// Sort list of instances.
    void sort() @trusted
    {
        void sortErent(T)(ref T[] data, bool delegate(T a, T b) @safe nothrow func) @trusted nothrow
        {
            T tmp;
            for (size_t i = 0; i < data.length; i++)
            {
                for (size_t j = (data.length-1); j >= (i + 1); j--)
                {
                    if (func(data[j],data[j-1]))
                    {
                        tmp = data[j];
                        data[j] = data[j-1];
                        data[j-1] = tmp;
                    }
                }
            }
        }

        sortClear();

        erentInstances = instances.dup;
        sortErent!Instance(erentInstances,(a, b) @safe nothrow => a.depth > b.depth);
    }
}

unittest
{
    import tida.instance;
    import tida.scenemanager;

    initSceneManager();

    class A : Instance { this() @safe { name = "A"; tags = ["A"]; }}
    class B : Instance { this() @safe { name = "B"; tags = ["B"]; }}

    Scene scene = new Scene();

    auto a = new A();
    auto b = new B();
    scene.add(a, b);

    assert(scene.getInstanceByClass!A is (a));
    assert(scene.getInstanceByClass!B is (b));

    assert(scene.getInstanceByName("A") is (a));
    assert(scene.getInstanceByName("B") is (b));

    assert(scene.getInstanceByNameTag("A", "A") is (a));
    assert(scene.getInstanceByNameTag("B", "B") is (b));
}

unittest
{
    import tida.instance;
    import tida.scenemanager;

    initSceneManager();

    Scene scene = new Scene();

    Instance a = new Instance(),
             b = new Instance();

    a.depth = 3;
    b.depth = 7;

    scene.add([a,b]);

    assert(scene.getAssortedInstances == ([b,a]));
}
