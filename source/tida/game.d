/++
A module for playing and organizing a game cycle with a scene manager.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.game;

export:
import tida.window;
import tida.render;
import tida.fps;
import tida.scenemanager;
import tida.scene;
import tida.event;
import tida.image;
import tida.listener;
import tida.loader;
import std.experimental.logger;

import std.concurrency;

__gshared
{
    IWindow _window;
    IRenderer _renderer;
    FPSManager _fps;
    Listener _listener;
    bool hasFrameTime = false;
    bool hasRenderBeginTime = false;
}

/// Window global object.
@property IWindow window() @trusted
{
    return _window;
}

/// Render global object.
@property IRenderer renderer() @trusted
{
    return _renderer;
}

/// FPS global object
@property FPSManager fps() @trusted
{
    return _fps;
}

/// Listener global object
@property Listener listener() @trusted
{
    return _listener;
}

struct ClosedThreadMessage { }

/++
Game initialization information.
+/
struct GameConfig
{
    import tida.color;

export:
    uint windowWidth = 640; /// Window width.
    uint windowHeight = 480; /// Window height.
    string windowTitle = "Tida"; /// Window title.
    Color!ubyte background = rgb(255, 255, 255); /// Window background.
    int positionWindowX = 100; /// Window position x-axis.
    int positionWindowY = 100; /// Window position y-axis.
    string icon; /// Icon path.
    string mainAssetsFile; // Main assets file
    
    size_t maxThreads = 3;
    size_t functionPerThread = 80;
}

private void workerThread(Tid owner, size_t id)
{
    bool isRun = true;
    bool isPaused = false;
    FPSManager threadFPS = new FPSManager();
    
    while (isRun)
    {
        threadFPS.countDown();
        
        if (id in sceneManager.threadAPI)
        {   
            import std.range : popFront, front, empty;  
            while(!sceneManager.threadAPI[id].empty)
            {
                immutable response = sceneManager.threadAPI[id].front;
                sceneManager.threadAPI[id].popFront();
                
                switch (response.code)
                {
                    case APIType.ThreadClose:
                        isRun = 0;
                        owner.send(APIType.ThreadClosed);
                        return;
                        
                    case APIType.ThreadPause:
                        isPaused = true;
                    break;
                    
                    case APIType.ThreadResume:
                        isPaused = false;
                    break;

                    case APIType.ThreadRebindThreadID:
                        id = response.value;
                    break;
                    
                    default:
                        continue;
                }
            }
        }
        
        if (isPaused)
            continue;
        
        if (!sceneManager.isThereGoto)
        {
            sceneManager.callStep(id, null);
        }
        
        threadFPS.control();
    }
}

class Game
{
export:
    EventHandler event;
    Tid[] threads;
    Tid[] dthreads;
    
    bool isGame = true;

export:
    int result = 0;
    Logger logger;

@trusted:
    this(GameConfig config, Logger logger)
    {
        import std.process;
        import std.conv : to;

        this.logger = logger;

        {
            import tida.text;
            import tida.sound;

            initFontLibrary();
            initSoundlibrary();
        }

        _window = new Window(config.windowWidth, config.windowHeight, config.windowTitle);
        (cast(Window) _window).windowInitialize(config.positionWindowX,config.positionWindowY);

        _renderer = new Render(cast(Window) window);
        _renderer.background = config.background;
        _renderer.reshape();

        if (config.icon != "")
        {
            import tida.def;
            auto imgic = new Image().load(config.icon);
            _window.icon = imgic.iconv;
        }

        _window.title = config.windowTitle;

        initSceneManager(logger);
        event = new EventHandler((cast(Window) window));

        logger.info("Create event handler!");

        _fps = new FPSManager();

        string fs = environment.get("TIDA_MAXFPS_OVERRIDE", null);
        if (fs != null)
        {
            _fps.maxFPS = to!long(fs);
        }

        logger.info("Create framerate control object!");

        _loader = new Loader();

        logger.info("Create resource manager object!");

        _listener = new Listener();

        // if (config.mainAssetsFile.length != 0)
        //     _loader.parseAssetsFromFile(config.mainAssetsFile);
        
        string mts, fpts;
        mts = environment.get("TIDA_MAX_THREADS_OVERRIDE", null);
        fpts = environment.get("TIDA_MAX_FPT_OVERRIDE", null);

        if (mts == null)
            sceneManager.maxThreads = config.maxThreads;
        else
            sceneManager.maxThreads = to!size_t(mts);

        if (fpts == null)
            sceneManager.functionPerThread = config.functionPerThread;
        else
            sceneManager.functionPerThread = to!size_t(fpts);

        // foreach (i; 0 .. sceneManager.maxThreads)
        //     sceneManager.fpt[i] = 0;

        logger.info("Set max threads: ", sceneManager.maxThreads);
        logger.info("Set max function per thread: ", sceneManager.functionPerThread);
        logger.info("Game object created!");
    }

    void threadClose(uint value) @trusted
    {
        import std.algorithm : remove;

        threads[value].send(APIType.ThreadClose, 0);

        foreach(i; value .. threads.length) 
        {
            threads[i].send(APIType.ThreadRebindThreadID, i - 1);
            dthreads[i].send(APIType.ThreadRebindThreadID, i - 1);
        }
        
        threads.remove(value);
        dthreads.remove(value);

        logger.info("Closed the thread ", value);
    }

    private void qclose() @trusted
    {
        isGame = false;
        
        foreach (size_t i, ref e; threads)
        {
            sceneManager.threadAPI[i + 1] ~= APIResponse(APIType.ThreadClose, cast(uint) i);
            sceneManager.threadAPIDraw[i + 1] ~= APIResponse(APIType.ThreadClose, cast(uint) i);
        
        // __rcwaitop:
        //     auto ef = receiveOnly!APIType;
        //     if (ef != APIType.ThreadClosed)
        //         goto __rcwaitop;
        }
        
        sceneManager.callGameExit();

        logger.info("The game is completed");
    }

    /++
    Starts the game loop of the game.
    +/
    void run() @trusted
    {
        logger.info("We start the game ...");

        sceneManager.callGameStart();

        version (manualThreadControl)
        {
            // Manual support thread...
            logger.info("Thread manual management is chosen.");
        } else
        {
            logger.info("Automatic thread control has been selected.");

            size_t countThreads = sceneManager.maxThreads;
            if (sceneManager.countStartThreads > countThreads)
            {
                logger.info("The automatic thread control mechanism has changed the value of the maximum threads: ", sceneManager.countStartThreads);

                countThreads = sceneManager.countStartThreads;
            }
        
            foreach (i; 0 .. countThreads)
            {
                immutable id = i + 1;
                threads ~= spawn(&workerThread, thisTid, id);
            }

            foreach (e; sceneManager.scenes)
            {
                e.initThread(countThreads);
            }

            sceneManager.countStartThreads = 0;
        }

        while (isGame)
        {
            _fps.countDown();

            scope (failure)
            {
                sceneManager.callOnError();
                qclose();
            }

            while (event.nextEvent)
            {
                if (event.isQuit)
                {
                    qclose();
                    return;
                }

                sceneManager.callEvent(event);
                if (listener !is null) listener.eventHandle(event);
            }

            if (listener !is null) listener.timerHandle();

            foreach (response; sceneManager.api)
            {
                switch (response.code)
                {
                    case APIType.ThreadCreate:
                    {
                        foreach (i; 0 .. response.value)
                        {
                            immutable id = i + 1;
                            threads ~= spawn(&workerThread, thisTid, id);
                        }
                    }
                    break;
                    
                    case APIType.ThreadPause, APIType.ThreadResume:
                    {
                        if (response.value > threads.length)
                        {
                            sceneManager.apiError[response.code] = APIError.ThreadIsNotExists;
                            continue;
                        }
                        
                        sceneManager.threadAPI[response.value] ~= response;
                        sceneManager.threadAPIDraw[response.value] ~= response;
                    }
                    break;
                    
                    case APIType.ThreadClose:
                    {
                        if (response.value > threads.length)
                        {
                            sceneManager.apiError[response.code] = APIError.ThreadIsNotExists;
                            continue;
                        }
                        
                        if (response.value == 0)
                            qclose();
                        else
                        {
                            sceneManager.threadAPI[response.value] ~= response;
                            sceneManager.threadAPIDraw[response.value] ~= response;
                        }
                    }
                    break;
                    
                    case APIType.GameClose:
                    {
                    	result = response.value;
                    	qclose();
                    }
                    break;
                    
                    default:
                        sceneManager.apiError[response.code] = APIError.UnkownResponse;
                        break;
                }
            }

            sceneManager.api = []; // GC, please, clear this

            sceneManager.callStep(0, renderer);

            renderer.clear();

            sceneManager.callDraw(renderer);

            renderer.drawning();

            _fps.control();
        }
    }
}

template Lazy (T)
if (isScene!T)
{
    struct Lazy
    {
        T scene;
    }
}

template isLazy (T)
{
    import std.traits : TemplateOf;
    
    enum isLazy = __traits(isSame, TemplateOf!(T), Lazy);
}

template lazyScene (T)
if (isLazy!T)
{
    alias lazyScene = typeof(T.scene);
}

template LazyGroup(T...)
{
    struct LazyGroup
    {
        alias Groups = T;
    }
}

template isLazyGroup (T)
{
    import std.traits : TemplateOf;

    enum isLazyGroup = __traits(isSame, TemplateOf!(T), LazyGroup);
}

template lazyGroupScenes (T)
if (isLazyGroup!T)
{
    import std.traits : TemplateArgsOf;

    alias lazyGroupScenes = TemplateArgsOf!T;
}

template isInspectActive()
{
    debug(inspectApp)
    {
        enum isInspectActive = true;
    } else
        enum isInspectActive = false;
}

Game runGame(T...)(GameConfig config, Logger logger = stdThreadLocalLog) @trusted
{
    Game game = new Game(config, logger);

    static foreach (e; T)
    {
        static if (isScene!e)
        {
            sceneManager.add(new e());
        } else
        static if (isLazy!e)
        {
            sceneManager.lazyAdd!(lazyScene!e);
        } else
        static if (isLazyGroup!e)
        {
            sceneManager.lazyGroupAdd!(lazyGroupScenes!e);
        }
    }

    debug(single)
    {
        static foreach (e; T)
        {
        mixin("
        debug(single_" ~ e.stringof ~ ")
        {
            sceneManager.gotoin!(" ~ e.stringof ~ ");
        }
        ");
        }
    }

    static if (isInspectActive!())
    {
        // TODO: implement inspector (debugger for framework)
        /++
        ```
        inspect>echo $
        ```
        +/
        void __inspectSpawn()
        {
            import std.stdio : writeln, write, readln;
            import std.array : replace;
            import std.string : split;
            import std.range : array;
            import std.conv : to;
            import std.algorithm : canFind, joiner, map;
            import tida.instance;

            string line;
            string[] args;
            string mergeArgs;

            string replaceEcho(string info)
            {
                // constants
                // L %sceneManager.list.length%
                // L %sceneManager.context.list.length%
                info = info
                    .replace("%currentScene%", sceneManager.context.name)
                    .replace("%previousScene%", sceneManager.previous !is null ? sceneManager.previous.name : "");

                return info;
            }

            string replaceArg(string arg)
            {
                if (arg[0] == '#')
                {
                    string[] commands = (arg[1 .. $] ~ '|').split('|')[0 .. $-1];
                    string result = "@Null";

                    static struct tScene
                    {
                        string name;
                        Scene scene;

                        this(string input)
                        {
                            name = (input ~ ",").split(",")[1];
                            scene = sceneManager.scenes[name];
                        }

                        string toString()
                        {
                            return "@Scene," ~ name;
                        }
                    }

                    static struct tInstance
                    {
                        string name;
                        Scene scene;
                        size_t id;
                        Instance instance;

                        this(string input)
                        {
                            string[] values = (input ~ ",").split(",")[0 .. $-1];
                            scene = sceneManager.scenes[values[1]];
                            id = values[2].to!size_t;
                            instance = scene.list[id];
                        }

                        string toString()
                        {
                            return "@Instance," ~ scene.name ~ "," ~ id.to!string;
                        }
                    }

                    // @Array!Type,[Values...],...
                    static struct tArray
                    {
                        string type;
                        string[] values;

                        this(string type, string[] values)
                        {
                            this.type = type;
                            this.values = values;
                        }

                        this(string input)
                        {
                            string[] vlv = (input ~ ",").split(",")[0 .. $-1];
                            this.type = (vlv[0] ~ "!").split("!")[1];

                            string naming = "Array!" ~ this.type ~ ",";
                            size_t sqLevel = 0;
                            size_t begin = 0;

                            for (size_t i = naming.length; i < input.length; i++)
                            {
                                immutable e = input[i];
                                if (e == '[')
                                {
                                    if (sqLevel == 0)
                                    {
                                        begin = i + 1;
                                    }

                                    sqLevel++;
                                }

                                if (e == ']')
                                {
                                    sqLevel--;
                                    if (sqLevel == 0)
                                    {
                                        this.values ~= input[begin .. i];
                                    }
                                }
                            }
                        }

                        string element(size_t i) @safe
                        {
                            return "@" ~ type ~ "," ~ values[i];
                        }

                        string toString()
                        {
                            string result = "@Array!" ~ type;
                            foreach (v; values)
                            {
                                result ~= ",[" ~ v ~ "]";
                            }

                            return result;
                        }
                    }

                    // @Pointer,0x0
                    static struct tRef
                    {
                        void* refValue = null;

                        this(string input)
                        {
                            string[] values = (input ~ ",").split(",")[0 .. $-1];
                            refValue = cast(void*) (values[1].to!ptrdiff_t);
                        }

                        string toString()
                        {
                            return "@Pointer," ~ refValue.to!string;
                        }
                    }

                    // sceneByName
                    // Args: Name,any...
                    // Input: any
                    // Output: @Scene,Name
                    static string _smByName(string input, string[] args)
                    {
                        if (!sceneManager.hasScene(args[0]))
                            return "@Exception,No find scene";

                        return "@Scene," ~ sceneManager.scenes[args[0]].name;
                    }

                    // instanceByName
                    // Args: Name,any...
                    // Input: @Scene,Name
                    // Output: @Instance,SceneName,ID
                    static string _iByName(string input, string[] args)
                    {
                        auto scene = tScene(input).scene;
                        Instance[] instances;

                        foreach (e; scene.list)
                        {
                            if (e.name == args[0])
                                instances ~= e;
                        }

                        if (instances.length == 0)
                            return "@Exception,Not find instance by name!";
                        else
                        if (instances.length == 1)
                            return "@Instance," ~ scene.name ~ "," ~ instances[0].id.to!string;
                        else
                        {
                            return tArray("Instance", instances.map!(e => e.name ~ "," ~ e.id.to!string).array).toString;
                        }
                    }

                    // length
                    // Args: any...
                    // Input: @Array!Any,elements... or @Tuple,[@Scene,Name],,...
                    // Output: @Integer,Length
                    static string _aLength(string input, string[] args)
                    {
                        return "@Integer," ~ tArray(input).values.length.to!string;
                    }

                    // indexOf
                    // Args: index
                    // Input: @Array!Any,elements...
                    // Output: @Any,element
                    static string _iOf(string input, string[] args)
                    {
                        auto arr = tArray(input);

                        return arr.element(args[0].to!size_t);
                    }

                    // instanceInfo
                    // Args: any...
                    // Input: @Instance,SceneName,ID
                    // Output: @InstanceInfo,JSON
                    static string _iInfo(string input, string[] args)
                    {
                        import std.json;

                        auto instance = tInstance(input).instance;
                        JSONValue info;
                        info["name"] = JSONValue(instance.name);
                        info["position"] = JSONValue([
                            instance.position.x,
                            instance.position.y
                        ]);
                        info["id"] = JSONValue(instance.id);
                        info["tags"] = JSONValue(instance.tags);
                        info["mask"] = JSONValue(instance.mask.toString);
                        info["threadid"] = JSONValue(instance.threadid);
                        info["active"] = JSONValue(instance.active);
                        info["visible"] = JSONValue(instance.visible);
                        info["onlyDraw"] = JSONValue(instance.onlyDraw);
                        info["persistent"] = JSONValue(instance.persistent);
                        info["depth"] = JSONValue(instance.depth);

                        return "@InstanceInfo," ~ info.toString;
                    }

                    static string _slist(string input, string[] args)
                    {
                        auto scenes = sceneManager.scenes.keys;

                        return tArray("Scene", scenes).toString;
                    }

                    static string _ilist(string input, string[] args)
                    {
                        import std.algorithm : map;
                        import std.range : array;

                        auto instances = sceneManager.scenes[args[0]].list();

                        return tArray("Instance", instances.map!(e => args[0] ~ "," ~ e.id.to!string).array).toString;
                    }

                    static string _aFind(string input, string[] args)
                    {
                        auto arr = tArray(input);
                        if (arr.type == "Instance")
                        {
                            foreach (i; 0 .. arr.values.length)
                            {
                                auto instance = tInstance(arr.element(i));
                                if (instance.instance.name == args[0])
                                {
                                    return instance.toString;
                                }
                            }

                            return "@Null";
                        } else
                        if (arr.type == "Scene")
                        {
                            foreach (i; 0 .. arr.values.length)
                            {
                                auto scene = tScene(arr.element(i));
                                if (scene.scene.name == args[0])
                                {
                                    return scene.toString;
                                }
                            }

                            return "@Null";
                        }

                        return "@Exception,Element is not a legal!";
                    }

                    foreach (cmd; commands)
                    {
                        string function(string, string[]) cmdFunc;

                        string input = result;
                        string[] args = ((cmd ~ "!").split("!")[1] ~ ",").split(",")[0 .. $-1];

                        switch((cmd ~ "!").split("!")[0])
                        {
                            case "scenes":
                            {
                                cmdFunc = &_slist;
                            }
                            break;

                            case "instances":
                            {
                                cmdFunc = &_ilist;
                            }
                            break;

                            case "sceneByName":
                            {
                                cmdFunc = &_smByName;
                            }
                            break;

                            case "instanceByName":
                            {
                                cmdFunc = &_iByName;
                            }
                            break;

                            case "length":
                            {
                                cmdFunc = &_aLength;
                            }
                            break;

                            case "indexOf":
                            {
                                cmdFunc = &_iOf;
                            }
                            break;

                            case "instanceInfo":
                            {
                                cmdFunc = &_iInfo;
                            }
                            break;

                            case "find":
                            {
                                cmdFunc = &_aFind;
                            }
                            break;

                            default:
                            {
                                result = "@Exception,Unknown command!";
                                return result;
                            }
                        }

                        result = cmdFunc(result, args);
                        if (canFind(result, "@Exception"))
                        {
                            writeln(result);
                            break;
                        }
                    }
                    arg = result;
                }

                return arg;
            }

            bool isInspectClose = false;
            while(!isInspectClose)
            {
                import std.range : array;

                write("inspect>");
                line = readln()[0 .. $-1] ~ ' ';

                if (line.length == 0)
                    continue;

                line = replaceEcho(line);
                args = line.split(' ')[0 .. $-1];

                if (args.length == 0)
                {
                    args = [line];
                }

                foreach (ref e; args)
                {
                    e = replaceArg(e);
                }

                mergeArgs = cast(string) args.joiner(" ").array;

                switch (args[0])
                {
                    case "echo":
                    {
                        writeln(mergeArgs);
                    }
                    break;

                    case "close", "exit", "quit":
                    {
                        sceneManager.close(0);
                        isInspectClose = true;
                    }
                    break;

                    default:
                    {
                        writeln("Unknown command!");
                    }
                    break;
                }

                line.length = 0;
                args.length = 0;
                mergeArgs.length = 0;
            }

            writeln("Inspector close.");
        }

        import core.thread;

        auto tid = new Thread(&__inspectSpawn);
        tid.start();
    }

    return game;
}

/++
Game entry point template.

After the configuration indicates the list of scenes that do share in the game.
If you need to designate the scene on the list, but not to highlight the memory
of it first, it is possible to designate it, as lazy to load resources only
when moving to it.

Params:
    config =    The input configuration describes what needs to be loaded,
                what initial parameters should be.
+/
template GameRun(GameConfig config, T...)
{
    import tida.runtime;
    import tida.scenemanager;

    version(unittest) {} else
    int main(string[] args)
    {
        TidaRuntime.initialize(args, AllLibrary);

        Game game = runGame!T(config);
        sceneManager.inbegin();
        game.run();

        return game.result;
    }
}
