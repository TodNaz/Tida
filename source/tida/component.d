/++
Component module. Components extend the functionality of instances, but
independently of a specific one (at least so. Or only one group of instances).

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.component;

export:
/++
Checks if an object is a component for an instance.
+/
template isComponent(T)
{
    enum isComponent = is(T : Component);
}

struct ComponentEvents
{
    import tida.event;
    import tida.render;
    import tida.localevent;
    import tida.instance;

    struct FEInit
    {
        Instance instance;
        void delegate(Instance) @safe fun;
    }

    struct SRTrigger
    {
        Trigger ev;
        FETrigger fun;
    }

    alias FEStep = void delegate() @safe;
    alias FERestart = void delegate() @safe;
    alias FEEntry = void delegate() @safe;
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

    FEInit[] CInitFunctions;
    FEStep[] CStepFunctions;
    FEStep[][size_t] CStepThreadFunctions;
    FELeave[] CLeaveFunctions;
    FEEventHandle[] CEventHandleFunctions;
    FEDraw[] CDrawFunctions;
    FEOnError[] COnErrorFunctions;
    SRTrigger[] COnTriggerFunctions;
    FEATrigger[] COnAnyTriggerFunctions;
    FECollision[] COnAnyCollisionFunctions;
}

/++
A component object that extends some functionality to an entire
or group of instances.
+/
export class Component
{
export:
    string name; /// Component
    string[] tags; /// Component tags.

    ComponentEvents events;
}
