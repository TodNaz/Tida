/++
Resource loader module

Using the loader, you can load various resources that
will be kept in memory. They can be accessed by their
name or path, they can also be unloaded from memory.

Please note that it is unnecessary to reload `download` since it does
not exist, it is implemented using the download-upload method. It will
load the resource from the .temp folder.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.loader;

export:
import std.path : baseName, stripExtension;
import std.file : exists,mkdir;

import tida.rc;

__gshared Loader _loader;

template isLoadable(T)
{
    static if (isRefCounted!T)
    {
        enum isLoadable = false;
    } else
    {
        enum isLoadable = __traits(compiles, (T r) => r.load("test"));
    }
}

/// Loader instance.
Loader loader() @trusted
{
    return _loader;
}

alias RC(T) = RefCounted!(T);
//alias refCounted(T) = refCounted!(T);

/// Resource descriptor
struct Resource
{
export:
    RC!(Object) object; /// Object
    string type; /// Type name object
    string path; /// Releative path object
    string name; /// Local name object
    bool isFont = false;
    bool collect = true;

@trusted:
    /++
    Initializes a resource. For this, he saves the name of the type and later,
    according to this type, he can determine further calls to it.

    Params:
        resource = Object resource.
    +/
    void init(T)(RC!T resource)
    {
        this.object = cast(RC!Object) resource;
        type = typeid(T).toString;
    }

    void init(T)(T resource)
    {
        this.object = refCounted!T(resource);
        type = typeid(T).toString;
    }

    /++
    The method to get the object.
    If the object turns out to be the wrong one, the contract will work.
    +/
    RC!T get(T)()
    in(typeid(T).toString == type)
    do
    {
        return object.opCast!(RC!T)();
    }

    void free()
    {
        destroy(object);
    }
}

interface LoaderProdriver
{
    Resource get(string name) @safe;
    Resource load(string path, string name) @safe;
}

/++
Resource loader. Loads resources, fonts and more
and keeps it in memory.
+/
class Loader
{
    import std.path;
    import std.exception : enforce;
    import core.memory;
    import core.internal.gc.proxy;
    import core.gc.gcinterface;
    import core.internal.gc.impl.conservative.gc;
    import core.gc.config;

private:
    core.gc.gcinterface.GC instance;
    core.internal.gc.impl.conservative.gc.ConservativeGC cgc;

export:
    Resource[] resources;
    LoaderProdriver[] prodrivers;

@safe:
    void collect() @trusted
    {
        import std.algorithm;

        foreach (size_t i, ref e; resources)
        {
            if (e.object.refCount() == 1)
            {
                e.object.__dtor();
                resources = resources[0 .. i] ~ resources[i + 1 .. $];
            }
        }
    }

    /++
    Will load the resource, having only its path as
    input. The entire loading implementation lies with
    the resource itself. The manager will simply keep
    this resource in memory.

    Params:
        T = Data type.
        path = Path to the file.
        name = Name.

    Retunrs:
        T

    Throws: `LoadException` if the loader determines
        that the file does not exist. There may be other
        errors while loading, see their documentation,
        for example `Image`.

    Example:
    ---
    Image img = loader.load!Image("a.png");
    ---
    +/
    RC!T load(T)(immutable string path, string name = "null", bool collect = true) @trusted
    if (isLoadable!T)
    {
        RC!T rtn = this.get!T(path);
        if (rtn != RC!T.init)
            return rtn;

        RC!T obj = RC!T(new T());
        Resource res;

        synchronized
        {
            foreach (p; prodrivers)
            {
                Resource ress = p.load(path, name);
                if (ress != Resource())
                {
                    return ress.get!T;
                }
            }

            enforce!Exception(path.exists, "Not find file `" ~ path ~ "`!");

            if(name == "null")
                name = path.baseName.stripExtension;

            obj.load(path);

            //import tida.image;
            //static if (is(T : Image))
            //{
            //    import tida.game : renderer;
            //    obj.toTexture(renderer);
            //}

            res.path = path;
            res.name = name;
            res.collect = collect;
            res.init!T(obj);

            this.resources ~= (res);
        }

        return obj;
    }

    /++
    Loads multiple resources in one fell swoop using an associated array.

    Params:
        T = Data type.
        paths = Paths and names for loading resources.

    Throws: `LoadException` if the loader determines
        that the file does not exist. There may be other
        errors while loading, see their documentation,
        for example `Image`.

    Example:
    ---
    loader.load!Image([
        "op1" : "image.png",
        "op2" : "image2.png"
    ]);
    ---
    +/
    void load(T)(immutable string[string] paths)
    if(isLoadable!T)
    {
        foreach (key; paths.keys)
        {
            this.load!T(paths[key],key);
        }
    }

    private size_t pos(T)(T res)
    {
        foreach (size_t i; 0 .. resources.length)
        {
            if (resources[i].object is res)
            {
                return i;
            }
        }

        throw new Exception("Unknown resource");
    }

    /++
    Frees the resource from memory by calling the `free`
    construct on the resource if it has unreleased pointers
    and so on, and later removes the resource from the array,
    letting the garbage collector destroy this object.

    Params:
        T = Resource class
        path = Name or Path to file resource

    Example:
    ---
    loader.free!Image("myImage");
    ---
    +/
    void free(T)(immutable string path) @trusted
    {
        auto obj = get!T(path);

        if (obj is null)
            return;

        resources.remove(pos(obj));
        synchronized destroy(obj);
    }

    /++
    Frees the resource from memory by calling the `free`
    construct on the resource if it has unreleased pointers
    and so on, and later removes the resource from the array,
    letting the garbage collector destroy this object.

    Params:
        T = Resource class
        obj = Resource object

    Example:
    ---
    auto myImage = loader.load!Image(...);
    loader.free(myImage);
        ---
    +/
    void free(T)(T obj) @trusted
    {
        if (obj is null)
            return;

        resources.remove(pos!T(obj));
        synchronized destroy(obj);
    }

    /++
    Returns a resource by name or path.

    Params:
        name = name resource(or path)

    Returns:
        `null` if the resource is not found.
        If found, will return a `T` of the
        appropriate size.
    +/
    RC!T get(T)(immutable string name) @trusted
    {
        foreach (p; prodrivers)
        {
            Resource res = p.get(name);
            if (res != Resource())
            {
                return res.get!T;
            }
        }

        foreach (e; this.resources)
        {
            if (e.path == name)
                return e.get!T;

            if (e.name == name)
                return e.get!T;
        }

        return RC!T.init;
    }

    /++
    Will add a resource that was not loaded through the manager.
    Please note that it must have a path and a name.

    Params:
        res = Resource.
    +/
    void add(Resource res)
    {
        this.resources ~= (res);
    }

    void add(T)(T object, string path = "", string name = "", bool collect = true)
    {
        name = T.stringof;
        Resource res;
        res.init!T(object);
        res.path = path;
        res.name = name;
        res.collect = collect;
        add(res);
    }

    ~this() @safe
    {
        foreach (res; resources)
        {
            res.free();
        }
    }
}

unittest
{
    import tida.image;
    import tida.sprite;

    _loader = new Loader();
    RC!Image image = loader.load!(Image)("icon.png");

    assert(image);

    RC!Image dimage = loader.get!Image("icon.png");
    
    assert(dimage);

    Sprite sprite = new Sprite();
    sprite.draws = dimage;

    assert(sprite.draws);

    destroy(dimage);

    assert(image.refCount() == 2);
}