module tida.def;

import tida.window;
import tida.image;
import tida.color;
import tida.render;
import tida.instance;

export:
IWindow.Image iconv(Image image) @trusted
{
    return IWindow.Image(image.bytes!(PixelFormat.RGBA), image.width, image.height);
}

/++
    A method for binding a specific object to a camera to track it.

    Params:
        instance =  An object in the scene that will be monitored by the camera.
                    The size is calculated from the object's touch mask.
+/
void bindObject(T)(Camera camera, T instance)
if (isInstance!T)
{
    camera.bindObject(instance.position, instance.mask.calculateSize());
}