/++
$(TOOLS
    <a href="https://github.com/TodNaz/Tida/issues/new/choose" class="bugraf" title="Submit a bug to the list of problems in the official repository.">Report bug</a>
)

Tida is a library for building 2D games in D language with an OOP system in 
the form of Scene-Instance-Component (where Instance is equivalent to Entity).

This page lists some modules according to the categories to which the modules 
belong. Please note that addons are not included in the default documentation.
$(TABLE
    $(TSTR
        $(TNAM Modules),
        $(TNAM Description)
    )

    $(STRNAME Technical modules.)
    $(TSTR
        $(ITEM 
            $(HREF tida/runtime.html, tida.runtime)<br/>
            $(HREF tida/gl.html, tida.gl)<br/>
        )
        $(ITEM Technical modules are intended as fundamental tools in building 
        the logic for creating a window and other interfaced devices, which will
        depend on an object that needs to be transferred to access or obtain 
        important properties during their operation. Also, if such modules are 
        necessary for important operations, they are also marked as technical. 
        Runtime creates an object for addressing the window manager and creates 
        a device for sound, and the open graphics module loads such a library 
        and auxiliary extensions that may not be useful.)
    )

    $(STRNAME Mathematical module.)
    $(TSTR
        $(ITEM 
            $(HREF tida/vector.html, tida.vector)<br/>
            $(HREF tida/angle.html, tida.angle)<br/>
            $(HREF tida/shape.html, tida.shape)<br/>
            $(HREF tida/matrix.html, tida.matrix)
        )
        $(ITEM Math modules are essential for 2D calculations. The emphasis is 
        on two-dimensionality, the framework does not assume that functions 
        will be needed to calculate three-dimensional objects (excluding matrices). 
        A vector, functions for operating with angles, a structure for 
        describing a shape are implemented.)
    )   

    $(STRNAME Renderers module.)
    $(TSTR
        $(ITEM
            $(HREF tida/render.html, tida.render)<br/>
            $(HREF tida/drawable.html, tida.drawable)<br/>
            $(HREF tida/sprite.html, tida.sprite)<br/>
            $(HREF tida/shader.html, tida.shader)<br/>
            $(HREF tida/gl.html, tida.gl)<br/>
            $(HREF tida/vertgen.html, tida.html)
        )
        $(ITEM Such modules implement and help in rendering of primitives and 
        objects, as well as their filling. The renderer is a direct participant 
        in the rendering of objects, controls the camera, is responsible for 
        rendering primitives, indicates the visible part of the port of the 
        rendering plane. Sprite is a structure for specifying rendering parameters. 
        Those. defines a transformation. Analogue of matrices.)
    )

    $(STRNAME Image & color processing modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/color.html, tida.color)<br/>
            $(HREF tida/image.html, tida.image)<br/>
            $(HREF tida/each.html, tida.each)<br/>
            $(HREF tida/softimage.html, tida.softimage)<br/>
            $(HREF tida/texture.html, tida.texture)
        )
        $(ITEM Such modules are responsible for creating, loading and 
        processing textures. Pixel is the basis of textures. Therefore, 
        in the color manipulation module, some functions have been made for 
        color manipulation, their creation and other operations. The images 
        module processes the image plane itself. Like color correction, 
        resizing, or even rendering of any objects on the image. 
        This can be helped by the software rendering 
        for pictures $(B tida.softimage))
    )

    $(STRNAME Sound manipulation modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/sound.html, tida.sound)
        )
        $(ITEM
            Such modules implement loading of sounds and their playback.
        )
    )

    $(STRNAME Behavior manipulation modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/component.html, tida.component)<br/>
            $(HREF tida/instance.html, tida.instance)<br/>
            $(HREF tida/scene.html, tida.scene)<br/>
            $(HREF tida/scenemanager.html, tida.scenemanager)<br/>
            $(HREF tida/localevent.html, tida.localevent)<br/>
            $(HREF tida/game.html, tida.game)<br/>
            $(HREF tida/listener.html, tida.listener)
        )
        $(ITEM Such modules serve the purpose of providing a way to make the 
        game feel comfortable and well-behaved. With the help of scene modules, 
        you can create separate sections of the game, and with the help of the 
        scene manager, you can move between scenes. Scenes have objects - instances, 
        which are assigned certain behavior, which also assumes communication 
        between instances. An instance can have components to reduce common 
        behavior code between different instances. Also, the game module is 
        responsible for distributing the game life cycle and limiting 
        frames per second.)
    )
    $(STRNAME Game auxiliary modules.)
    $(TSTR
        $(ITEM
            $(HREF tida/algorithm.html, tida.algorithm)<br/>
            $(HREF tida/animation.html, tida.animation)<br/>
            $(HREF tida/collision.html, tida.collision)<br/>
            $(HREF tida/loader.html, tida.loader)<br/>
            $(HREF tida/text.html, tida.text)
        )
        $(ITEM Such modules help in building a two-dimensional game, such as 
        collision detection, animation, pathfinding algorithms, 
        resource allocation object and others.)
    )

    $(STRNAME Fundamental elements.)
    $(TSTR
        $(ITEM
            $(HREF tida/window.html, tida.window)<br/>
            $(HREF tida/event.html, tida.event)
        )
        $(ITEM Such modules are necessary when building a two-dimensional game, 
        such as creating and managing a window and an object to track events 
        such as input from devices.)
    )
)


# Beginning of work.

## Installing the necessary dependencies.

Before starting work, you need to establish the requirements for the
library framework. To begin with, the most important thing is to install the
DUB language compiler and the DUB package manager for the project assembly.
You can install them from the [official site](https://dlang.org/download.html).
The framework was tested on DMD and LDC compilers. Package manager must also be
installed with the compiler.

Also, for the framework, you need installed in the
[OpenAL](https://www.openal.org/downloads/) and
[FreeType](https://github.com/ubawurinna/freetype-windows-binaries)
library system. The FreeType Dynamic Library in the Windows operating system
must be in the same folder, together with the project. The remaining
dependencies will be loaded when assembling or receiving a framework.

## Project initialization.

The project based on framework can be easily done with the following commands:
$(CONSOLE
    $ mkdir <project_dir_name> && cd <project_dir_name>
    $ dub run tida:init
)

And the project initialization tool will be called and also creates a first file template:
---
module app;

import tida;

class Main : Scene
{
    this() @safe
    {
        name = "Main";
    }
}

mixin GameRun!(GameConfig(640, 480, "window"), Main);
---

# How does the framework work?

```
                     +----------------------------+
                  /- |           Runtime          |--\
               /--   +----------------------------+   ---\
             --                    |                      --
 +----------------------------+    |      +---------------------------------+
 | Sound system (with OpenAL) |    |      | Connect to Window Manager       |
 +----------------------------+    |      +---------------------------------+
                                   |
             +-----------------------+    +---------------------------------+
             | Create game instance  |----| - Create window                 |
             +-----------------------+    |   L Set window attributes       |
                                   |      |   L Signal Create a window      |
 +----------------------------+    |      |   L Create OpenGL context       |
 |    Create service for      |    |      |     To access hardware          |
 |    conducting timers       | ---+      |     acceleration.               |
 +----------------------------+    |      | - Create graphics renderer      |
                                   |      +---------------------------------+
 +----------------------------+    |
 |    Create service for      |    |      +---------------------------------+
 |    restrictions frames     |----+      |                                 |
 +----------------------------+    |      |   A convenient environment for  |
                                   |      |   creating behavior by a simple |
 +----------------------------+    |      |   two -dimensional game.        |
 |     Create scene manager.  |----+------|                                 |
 +----------------------------+           +---------------------------------+
  |   +---------------------------------+                         |
  +-- |Creation of the necessary threads|                         |
  |   +---------------------------------+                         |
  |   +--------------------------------------------------------+  |
  +-- |Creation of scenes and copies and management named after|  |
  |   +--------------------------------------------------------+  |
  |   +-------------------------------------+                     |
  +-- |Creating the ability to be restrained|                     |
  |   +-------------------------------------+                     |
  |                                                               |
  +---------------------------------------------------------------+
```

# Scene and instances. How to write them.

## What are the scenes from themselves.

The scene is an object for creating behavior at a certain stage of the game
and the place of execution of instances functions. We will analyze its
meaning on the example: there are two stages of the game - the menu and
directly the playing field. The menu has an entry button in the playing field
and its design itself. When you press a button, instead of the menu there
should be a playing field, and not to prescribe all behavior in one pile,
you can divide them into the scene.

The scene must provide:
$(LIST
    * Collect objects in the scenes to the list, sort it along the layers of
    drawing (to refunning objects), process their behavior.
    * Processing your overall behavior, respond to an input event and events.
    * Draw primitives.
    * Follow the collision and physics of objects.
)

To create a scene, it is enough to inherit the properties of the scene itself,
for example, as follows:
---
class MyCoolScene : Scene
{
    this() @safe
    {
        name = "MyCoolScene";
    }
}
---

It is important to give scenes the name where in the constructor we see his
definition so that later it was possible to go to it for this name. Also,
you can move to the scene by its class prengetention.

Note that all functions within a scene must be marked with the `@safe`
attribute to ensure execution safety from both the compiler and the programmer.

And so, it's one thing to create a scene, another thing is to give him
behavior. To, for example, respond to a mouse click, it is enough to create
such a function, the argument of which will be the event handling object.
However, this is not enough, also, the function must be marked with the
`@event(Input)` attribute in order for the scene manager to accurately set
this function to handle events.

Example:
---
class MyCoolScene : Scene
{
    this() @safe
    {
        name = "MyCoolScene";
    }

    @event(Input) void onInputMouse(EventHandler event) @safe
    {
        ... // Listen for any input events.
    }
}
---

Also, you can distribute several of these functions, for example,
for grouping by case. Those. yes, such functions in one scene that will
follow the input can produce a whole bunch.

This attribute can be used to indicate that other events can be monitored,
such as a simple step that will be executed on every frame of the game or
every frame render, game exit event, etc. The list of valid events are
listed below:

$(SMALL_TABLE
    +-------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
    | Events      | Description                                                                                                                                                                                                               |
    +=============+===========================================================================================================================================================================================================================+
    | Init        | This event will be fired when the scene first passes control. The rest of the time the scene is jumped, this function will not be called until the program is overloaded with the `gameRestart` function.                 |
    | Restart     | An event that will be called when the scene is transitioned again. It is not called the first time, but when the scene is accessed a second or more times, this function will be called.                                  |
    | Entry       | The function will be called always when control passes to the scene.                                                                                                                                                      |
    | Leave       | The function under this attribute will be called when control is lost.                                                                                                                                                    |
    | Step        | Called every step of the game when the scene has a control.                                                                                                                                                               |
    | Input       | The function will be called when the user enters any data from devices or manipulates the window. An object is passed to the function to retrieve data from the event.                                                    |
    | Draw        | The function to be called when preparing the frame. Outside of such an event, it is impossible to draw. An object containing drawing methods and functions with its manipulation is passed to the function.               |
    | AnyTrigger  | The function will respond to any in-game event called through the `sceneManager.trigger` manager function. The name of such an event is attached to the function.                                                         |
    | Destroy     | The function will react to any destruction of the instance inside the scene. Attached to the function is a pointer to an object that has not yet been destroyed.                                                          |
    | GameStart   | The function called when the game starts.                                                                                                                                                                                 |
    | GameRestart | The function will be called when the game is reloaded. Necessary for garbage collection and other operations. Needed to load resources. Lazy scenes will not have this function called, except when the game is reloaded. |
    | GameExit    | Will be called when the game ends. Also called on reboot to simulate an exit.                                                                                                                                             |
    | GameError   | Will be called on an unhandled exception inside the game loop.                                                                                                                                                            |
    +-------------+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
)

## What are instances?

An instance is an object with its characteristic behavior and generalized
properties. Executed in the scene environment and can be transferred
between scenes.

Instances also have the same properties of the scene: have functions that
will be twitched by events, have a name, however, this is not enough to
describe the object. It also has a position in the scene, tags for easier
finding and grouping of objects, has depth properties and a mask for contact.
Yes, instances, for now, can only feel contact between each other (in the future,
it will be possible to expand this).

Another thing that can be said briefly about the possibilities is the
components of the instance. A component is an object for a general description
of an instance, for example, some balls must have elasticity, thereby adding a
component of elasticity, there will be an appropriate behavior, and another,
solid, is assigned a separate hardness component, thus avoiding code copy-paste
between instances, describing only the component.

To create an instance, it is enough to also inherit its properties:
---
class MyBallInstance : Instance
{
    this() @safe
    {
        name = "MyBall";
        tags = ["elastic"];
        ...
    }

    @event(Step) void onStep() @safe
    {
        ...
    }
}
---

It is the same with components, however, they must have one cherished event
that must happen. We implement an object with the following function:
---
class Elasticity : Component
{
    Instance self;

    /+
    In a function with an initialization event,
    a reference to the instance that the component
    installed is also brought in the arguments.
    +/
    @event(Init) void onInit(Instance instance) @safe
    {
        self = instance;
    }

    ...
}
---

In other events, the component works the same, however, not all events in it
are needed, therefore, there are no many events, like scene context change
events.

Now the need is created: how to add scenes to the game, copies to the stage,
and components... All this is done using the `add` method in the corresponding
volume, with the exception of scenes. Let's add a copy to the stage for example:
---
class TestInstance : Instance
{
    this() @safe
    {
        add (new ManyComponent());  // Here the component is random,
                                    //add it to an instance to generalize behavior.
    }
}

class Test : Scene
{
    this() @safe
    {
        Instance instance = new Instance();
        add (instance); // Here we add a copy to the stage.
        // or
        add (new TestInstance());
    }
}

// Here we add a scene to SPSU executions.
// It can be indicated further so that other scenes can be moved
//                                              VVVV
mixin GameRun!(GameConfig(640, 480, "Example"), Test);
---

$(NOTE
    This method also has another parameter responsible for which thread to place,
    but more on that later.
)

You can also add several copies with one call:
---
add (
    new FirstInstance(),
    new SecondInstance()
);
---

If you can add, then you can remove it too. To delete the copy, use its internal
method `destroy`. Such a function sends a signal to the scene to delete an
instance in the next step. This is necessary for the safety of interaction
between specimens.

Example:
---
instance.destroy(); // We send a signal that in the next step you need
                    // to destroy the copy.

instance.interact(args...); // ok, the copy did not immediately leave,
                            // but in the next step it will be a mistake.
---

But if you need to directly destroy the copy in place, then use the function
in the corresponding scene:
---
scene.instanceDestroy!InScene(instance);    // We remove only from the list in
                                            // the stage. The memory of the copy
                                            // will be alive while there are
                                            // links to it, otherwise,

scene.instanceDestroy!InMemory(instance);   // Remove the copy from the memory.
---

Macros:
    LREF = [$1][#$1]
    HREF = [$2]($1)
    B = <b>$0</b>
    TABLE = <table class="def">$0</ table>
    TABLENAME = <caption class="defcap">$0</ caption>
    STRNAME = <tr class="leadingrow"><td colspan="2"><b><em>$(NBSP)$(NBSP)$(NBSP)$(NBSP)$0</em></b></td></tr>
    TSTR = <tr class="deftr">$0</tr>
    TNAM = <th class="defth">$0</th>
    ITEM = <td class="deftd">$0</td>
    TOOLS = <div class="tools">$0</div>
    
Authors: TodNaz
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: MIT
+/
module tida;

export:
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
