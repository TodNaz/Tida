/++
Object module for tracking some global events like timers,
global event handlers, etc.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.listener;

export:

public import std.datetime;
import tida.event;

private struct Event
{
export:
    void delegate(EventHandler) @safe event;
}

/// Timer structure.
struct Timer
{
export:
    MonoTime start; /// Timer start time
    Duration duration; /// Timer duration
    void delegate() @safe onEnd; /// Timer callback
    bool isRepeat = false; /// Is repeat?

@safe:
    bool tick()
    {
        if (!isActual)
        {
            if (onEnd !is null) onEnd();

            if (isRepeat)
            {
                start = MonoTime.currTime;
                return false;
            }else
                return true;
        }else
            return false;
    }

    /// Indicates whether the timer is in effect.
    bool isActual()
    {
        return MonoTime.currTime - start < duration;
    }

    /// Shows the remaining time.
    Duration remainder()
    {
        return MonoTime.currTime - start;
    }
}

/++
Object module for tracking some global events like timers,
global event handlers, etc.
+/
class Listener
{
    import std.algorithm : remove;

private:
    Event[] events;
    Timer[] timers;

export @safe:
    void clearTimers()
    {
        timers = [];
    }

    /++
    Stop the timer if there is such an instance.

    Params:
        tm = Timer.
    +/
    void timerStop(Timer* tm)
    {
        foreach (i; 0 .. timers.length)
        {
            if (timers[i] == *tm)
            {
                timers = timers.remove(i);
                return;
            }
        }
    }

    /++
    Start a timer.

    Params:
        func = The function to call when the timer expires.
        duration = Timer duration.
        isRepeat = Whether to repeat the timer.

    Example:
    ---
    listener.timer({
        writeln("3 seconds!");
    },dur!"msecs"(3000),true);
    ---

    Returns: A pointer to a timer.
    +/
    Timer* timer(void delegate() @safe func, Duration duration, bool isRepeat = false) @trusted
    {
        timers ~= Timer(MonoTime.currTime, duration, func, isRepeat);

        return &timers[$-1];
    }

    /++
    Supply a function to handle events, no matter what the scene.

    Params:
        func = Function for handler.
    +/
    void globalEvent(void delegate(EventHandler) @safe func) @trusted
    {
        events ~= Event(func);
    }

    void eventHandle(EventHandler event) @trusted
    {
        foreach(ev; events)
        {
            ev.event(event);
        }
    }

    void timerHandle() @safe
    {
        foreach(i; 0 .. timers.length)
        {
            if(timers[i].tick()) {
                timers = timers.remove(i);
                return;
            }
        }
    }
}
