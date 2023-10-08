/++
An module for describing animation
(frame-by-frame, by changing rendering objects among themselves).

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.animation;

export:
import tida.drawable;

/++
An object for describing animation
(frame-by-frame, by changing rendering objects among themselves).

The work of such animation takes place not only with images, but with
drawn objects, implemented through IDrawableEx.
+/
class Animation : IDrawable, IDrawableEx
{
    import tida.vector;
    import tida.color;
    import tida.render;

private:
    float _current = 0.0f;

export:
    /// Animation speed.
    float speed = 0.0f;

    /// Animation frames.
    IDrawableEx[] frames = [];

    /// When the animation ends, whether the animation needs to be re-run.
    bool isRepeat = false;

@safe:
    /++
    Animation object constructor.

    Params:
        speed = Animation speed. How many ticks to skip for the next frame.
        isRepeat = Whether to repeat the animation.
    +/
    this(float speed = 0.0f, bool isRepeat = false)
    {
        this.speed = speed;
        this.isRepeat = isRepeat;
    }

    /++
    The current frame of the animation.
    +/
    @property IDrawableEx currentFrame() nothrow pure
    {
        return frames[cast(size_t) _current > $ - 1 ? $ - 1 : cast(size_t) _current];
    }

    /++
    The current position of the animation.
    +/
    @property float numFrame() nothrow pure
    {
        return _current;
    }

    /++
    The current position of the animation.
    +/
    @property float numFrame(float currFrame) nothrow pure
    {
        return _current = currFrame;
    }

    /++
    Starts the animation from the beginning.
    +/
    void reset() nothrow pure
    {
        _current = 0.0f;
    }

    /++
    Carries out animation of objects by frame-by-frame change.

    Returns:
        The current frame of animation.
    +/
    IDrawableEx step() nothrow pure
    {
        if (cast(int) _current >= frames.length)
        {
            if (isRepeat)
            {
                _current = -speed;
            }
        } else
        {
            _current += speed;
        }

        return currentFrame();
    }

override:
    void draw(IRenderer renderer, Vecf position) @trusted
    {
        IDrawableEx draws = step();

        draws.drawEx(renderer, position, 0.0, vecfNaN, vecfNaN, 255, rgb(255, 255, 255));
    }

    void drawEx(IRenderer renderer,
                Vecf position,
                float angle,
                Vecf center,
                Vecf size,
                ubyte alpha,
                Color!ubyte color = rgb(255, 255, 255))
    {
        IDrawableEx draws = step();

        draws.drawEx(renderer, position, angle, center, size, alpha, color);
    }
}
