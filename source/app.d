module app;

import tida.runtime;
import tida.window;
import tida.event;
import tida.vector;
import tida.color;
import tida.render;
import tida.shape;
import tida.meshgen;
import tida.image;
import tida.angle;
import tida.each;
import tida.fps;
import tida.sound;
import std.datetime;
import tida.matrix;
import tida.drawable;
import tida.game;
import tida.scene;
import tida.scenemanager;
import tida.instance;
import tida.component;
import tida.text;
import tida.loader;
import tida.listener;
import tida.localevent;
import tida.sprite;
import tida.animation;
import tida.controller;
import tida.def;
import tida.graphics.gapi;

import io = std.stdio;
import file = std.file;

version(unittest) {} else
int main(string[] args)
{
    TidaRuntime.initialize(args);

    Window window = new Window(640, 480, "Tida");
    windowInitialize(window, 640, 480);

    EventHandler event = new EventHandler(window);
    Render render = new Render(window);

    render.background(rgb(128, 128, 128));

    Image image = new Image().load("icon.png");
    image.toTexture(render);

    auto arrayBuffer = render.api.createBuffer(BufferType.array);
    arrayBuffer.bindData([
        0f, 0f,          0f, 0f,
        640, 0f,      1f, 0f,
        640, 480, 1f, 1f,
        0f, 480,     0f, 1f
    ]);

    auto elementBuffer = render.api.createBuffer(BufferType.element);
    elementBuffer.bindData([0, 1, 2, 0, 2, 3]);

    auto vertexInfo = render.api.createVertexInfo();
    vertexInfo.bindBuffer(arrayBuffer);
    vertexInfo.bindBuffer(elementBuffer);
    vertexInfo.vertexAttribPointer([
        AttribPointerInfo(0, 2, TypeBind.Float, 4 * float.sizeof, 0),
        AttribPointerInfo(1, 2, TypeBind.Float, 4 * float.sizeof, 2 * float.sizeof)
    ]);

    bool isQuit = false;
    while (!isQuit)
    {
        while (event.nextEvent)
        {
            if (event.isQuit)
                isQuit = true;
        }

        render.clear();


        render.line([vecf(0, 0), vecf(320, 240)], rgb(255, 0, 0));
        render.line([vecf(320, 240), vecf(640, 0)], rgb(255, 255, 0));
        render.line([vecf(320, 240), vecf(0, 480)], rgb(255, 0, 255));
        render.line([vecf(320, 240), vecf(640, 480)], rgb(0, 255, 0));

        IShaderPipeline shader = Image.initShader(render);

        render.api.bindProgram(shader);
        render.api.bindVertexInfo(vertexInfo);

        uniformBuilder(
            shader.vertexProgram(),
            0,
            (cast(Render) render).projection,
            render.currentModelMatrix()
        );

        uniformBuilder(
            shader.fragmentProgram(),
            0,
            cast(float[4]) [1.0f, 1.0f, 1.0f, 1.0f],
            cast(float[2]) [640, 480]
        );

        render.api.begin();

        render.api.drawIndexed(ModeDraw.triangle, 6);

        render.drawning();
    }

    return 0;
}