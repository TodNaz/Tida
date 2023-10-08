/++
Module for limiting the release of frames per second.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.fps;

import std.datetime;
export:

/++
The object that will keep track of the cycle time, counts and
limits the executable frames.
+/
class FPSManager
{
    import core.thread;

private:
    MonoTime controlTime;
    Duration _deltatime;
    
    MonoTime startProgramTime;
    bool isFirstControl = true;
    
    MonoTime lastRenderTime;
    long countFPS = 0;
    long resultFPS = 0;

export:
    /++
    Sets the maximum number of frames per second.
    +/
    long maxFPS = 60;

    /++
    Shows how many frames were formed in a second.
    Please note that the counter is updated once per second.
    +/
    @property long fps() @safe
    {
        return resultFPS;
    }

    /++
    Shows the running time of the program.
    +/
    @property Duration timeJobProgram() @safe
    {
        return MonoTime.currTime - startProgramTime;
    }

    /++
    Delta time.
    +/
    @property Duration deltatime() @safe
    {
        return _deltatime;
    }

@trusted:
    /++
    The origin of the frame unit. Measures time and also changes the
    state of the frame counter.
    +/
    void countDown()
    {
        if (isFirstControl)
        {
            isFirstControl = false;
            startProgramTime = MonoTime.currTime;
        }
        
        if (MonoTime.currTime - lastRenderTime > dur!"msecs"(1000))
        {
            resultFPS = countFPS;
            countFPS = 0;
            lastRenderTime = MonoTime.currTime;
        }
        
        controlTime = MonoTime.currTime;
    }

    /++
    Frame limiting function. Also, it counts frames per second.
    +/
    void control()
    {
        countFPS++;
        
        immutable timePerFrame = dur!"msecs"(1000) / maxFPS;
        _deltatime = MonoTime.currTime - controlTime;
        
        if (_deltatime < timePerFrame)
        {
            Thread.sleep(timePerFrame - _deltatime);
        }
    }
}
