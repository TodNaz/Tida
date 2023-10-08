module tida.controller;

import tida.scenemanager;
import tida.event;
import tida.render;
import tida.instance;
import tida.localevent;

export struct ControllerEvents
{
    import tida.event;
    import tida.render;
    import tida.localevent;

export:
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
    alias FETrigger = void delegate() @safe;
    alias FEDestroy = void delegate(Instance) @safe;
    alias FEATrigger = void delegate(string) @safe;
    alias FEEachInstance = void delegate(Instance) @safe;

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

    //alias 

    FEInit[] IInitFunctions;

    FEStep[] IStepFunctions;
    FEEachInstance[] IEachInstance;
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
    SRTrigger[] IOnTriggerFunctions;
    FEDestroy[] IOnDestroyFunctions;
    FEATrigger[] IOnAnyTriggerFunctions;

    void delegate() @safe OnAssetLoad;
}

/++
Enums that can influence behavior:
+/
export class Controller
{
    export
    {
        ControllerEvents events;
    }
}

template isController(T)
{
    import std.traits : TemplateOf;

    enum isController = is(T : Controller);
}

@threadSafe
export final class WorldCollision : Controller
{
    import tida.collision;
export:

    @event(Step) void update() @safe
    {
        foreach (first; sceneManager.context.list())
        {
            if (first.solid && first.active)
            {
                foreach (Instance second; sceneManager.context.list())
                {
                    if (second.solid && second.active && first !is second)
                    {
                        if (isCollide(  first.mask,
                                        second.mask,
                                        first.position,
                                        second.position)
                            )
                        {
                            foreach (tg; second.tags)
                            {
                                sceneManager.manualTrigger(
                                    first,
                                    "Collision:" ~ second.name ~ "." ~ tg,
                                    second
                                );

                                // This is necessary for unnamed collisions
                                // that only need an object with a certain tag.
                                sceneManager.manualTrigger(
                                    first,
                                    "Collision:." ~ tg,
                                    second
                                );
                            }

                            sceneManager.manualTrigger(
                                first,
                                "Collision:" ~ second.name ~ ".",
                                second
                            );
                        }
                    }
                }
            }
        }
    }
}
