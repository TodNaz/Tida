/++
Sprite unit description module.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.sprite;

export:
import tida.drawable;

/++
A sprite is any object that can be drawn with the rendering parameters specified
by the programmer, such as position, size, rotation angle, etc. It does not have
to be a set of pictures, but some object, for example, that sets the renderer to
draw lines to represent an object. This object is `IDrawableEx`, where you can
describe the rendering parameters.
+/
class Sprite : IDrawable
{
    import tida.vector;
    import tida.render;
    import tida.color;
    import tida.matrix;
    import tida.graphics.gapi;

export:
    /++
    An object that represents a picture.
    +/
    IDrawableEx draws;

    /++
    Sprite position.
    +/
    Vecf position = vecf(0, 0);

    /++
    Sprite width. (If it is equal to zero, then the size is standard).
    +/
    uint width = 0;

    /++
    Sprite height. (If it is equal to zero, then the size is standard).
    +/
    uint height = 0;

    /++
    The rotation angle of the sprite.
    +/
    float angle = 0.0f;

    /++
    The center rotation angle of the sprite.
    +/
    Vecf center = vecfNaN;

    /++
    The transparency value of the sprite.
    +/
    ubyte alpha = ubyte.max;

    /++
    The shader used for rendering.
    +/
    IShaderPipeline shader;

    /++
    The color used for rendering. 
    +/
    Color!ubyte color = Color!ubyte(255, 255, 255, 255);

    /++
    Sprite transformation matrix.
    +/
    float[4][4] matrix = identity();

    /++
    A set of other sprites to help create a consistent look for the sprite.
    +/
    Sprite[] skelet;

override:
    void draw(IRenderer renderer, Vecf position)
    {
        mat4 mat = identity();

        if (draws !is null)
        {
            mat = mulmat(renderer.currentModelMatrix, matrix);
            renderer.currentModelMatrix = mat;

            if(renderer.currentShader is renderer.mainShader)
                renderer.currentShader = shader;

            draws.drawEx(   renderer,
                            this.position + position,
                            angle,
                            center,
                            !width || !height ? vecfNaN : vecf(width, height),
                            alpha,
                            color);
        }

        if (skelet.length != 0)
        {
            foreach (e; skelet)
            {
                renderer.currentModelMatrix = mat;
                e.draw(renderer, position);
            }
        }
    }
}
