module tida.rc;

import std.typecons : RefCountedAutoInitialize;
import std.traits;

version (D_Exceptions)
{
    import core.exception : onOutOfMemoryError;
    private enum allocationFailed = `onOutOfMemoryError();`;
}
else
{
    private enum allocationFailed = `assert(0, "Memory allocation failed");`;
}

// (below comments are non-DDOC, but are written in similar style)

/+
Mnemonic for `enforce!OutOfMemoryError(malloc(size))` that (unlike malloc)
can be considered pure because it causes the program to abort if the result
of the allocation is null, with the consequence that errno will not be
visibly changed by calling this function. Note that `malloc` can also
return `null` in non-failure situations if given an argument of 0. Hence,
it is a programmer error to use this function if the requested allocation
size is logically permitted to be zero. `enforceCalloc` and `enforceRealloc`
work analogously.

All these functions are usable in `betterC`.
+/
void* enforceMalloc()(size_t size) @nogc nothrow pure @safe
{
    auto result = fakePureMalloc(size);
    if (!result) mixin(allocationFailed);
    return result;
}

// ditto
void* enforceCalloc()(size_t nmemb, size_t size) @nogc nothrow pure @safe
{
    auto result = fakePureCalloc(nmemb, size);
    if (!result) mixin(allocationFailed);
    return result;
}

// ditto
void* enforceRealloc()(return scope void* ptr, size_t size) @nogc nothrow pure @system
{
    auto result = fakePureRealloc(ptr, size);
    if (!result) mixin(allocationFailed);
    return result;
}

// Purified for local use only.
extern (C) @nogc nothrow pure private
{
    pragma(mangle, "malloc") void* fakePureMalloc(size_t) @safe;
    pragma(mangle, "calloc") void* fakePureCalloc(size_t nmemb, size_t size) @safe;
    pragma(mangle, "realloc") void* fakePureRealloc(return scope void* ptr, size_t size) @system;
}

template isRefCounted(T)
{
    import std.traits : TemplateOf;

    enum isRefCounted = __traits(isSame, TemplateOf!(T), RefCounted);
}

struct Impl
{
    object.Object _payload;
    size_t _count;
}

struct RefCounted(T, RefCountedAutoInitialize autoInit =
    RefCountedAutoInitialize.yes)
if (is(T == class) || is(T == interface))
{
@trusted:
    version (D_BetterC)
    {
        private enum enableGCScan = false;
    }
    else
    {
        private enum enableGCScan = hasIndirections!T;
    }

    extern(C) private pure nothrow @nogc static
    {
        pragma(mangle, "free") void pureFree( void *ptr );
        static if (enableGCScan)
            import core.memory : GC;
    }

    struct RefCountedStore
    {
        private Impl* _store;

        private void initialize(A...)(auto ref A args)
        {
            import core.lifetime : emplace, forward;

            allocateStore();
            version (D_Exceptions) scope(failure) deallocateStore();
            emplace(&_store._payload, forward!args);
            _store._count = 1;
        }

        private void move(ref T source) nothrow pure
        {
            import std.algorithm.mutation : moveEmplace;

            allocateStore();
            Object obj = cast(Object) source;
            moveEmplace(obj, _store._payload);
            _store._count = 1;
        }

        // 'nothrow': can only generate an Error
        private void allocateStore() nothrow pure
        {
            static if (enableGCScan)
            {
                _store = cast(Impl*) enforceCalloc(cast(size_t) 1, Impl.sizeof);
                GC.addRange(&_store._payload, T.sizeof);
            }
            else
            {
                _store = cast(Impl*) enforceMalloc(Impl.sizeof);
            }
        }

        private void deallocateStore() nothrow pure
        {
            static if (enableGCScan)
            {
                GC.removeRange(&this._store._payload);
            }
            pureFree(_store);
            _store = null;
        }

        @property nothrow @safe pure @nogc
        bool isInitialized() const
        {
            return _store !is null;
        }

        @property nothrow @safe pure @nogc
        size_t refCount() const
        {
            return isInitialized ? _store._count : 0;
        }

        void ensureInitialized()()
        {
            // By checking for `@disable this()` and failing early we can
            // produce a clearer error message.
            static assert(__traits(compiles, { static T t; }),
                "Cannot automatically initialize `" ~ fullyQualifiedName!T ~
                "` because `" ~ fullyQualifiedName!T ~
                ".this()` is annotated with `@disable`.");
            if (!isInitialized) initialize();
        }

    }
    RefCountedStore _refCounted;

    auto ref size_t refCount() @safe nothrow pure
    {
        return _refCounted.refCount();
    }

    @property nothrow @safe
    ref inout(RefCountedStore) refCountedStore() inout
    {
        return _refCounted;
    }

    this(A...)(auto ref A args) if (A.length > 0)
    out
    {
        assert(refCountedStore.isInitialized);
    }
    do
    {
        import core.lifetime : forward;
        _refCounted.initialize(forward!args);
    }

    this(T val)
    {
        _refCounted.move(val);
    }

    this(this) @safe pure nothrow @nogc
    {
        if (!_refCounted.isInitialized) return;
        ++_refCounted._store._count;
    }

    ~this()
    {
        if (!_refCounted.isInitialized) return;
        assert(_refCounted._store._count > 0);
        if (--_refCounted._store._count)
            return;
        // Done, destroy and deallocate

        _refCounted._store._payload = null;
        //.destroy(_refCounted._store._payload);
        _refCounted.deallocateStore();
    }

    void opAssign(typeof(this) rhs)
    {
        import std.algorithm.mutation : swap;

        //_refCounted._store = rhs._refCounted._store;
        swap(_refCounted._store, rhs._refCounted._store);
    }

    void opAssign(T rhs)
    {
        import std.algorithm.mutation : move;

        static if (autoInit == RefCountedAutoInitialize.yes)
        {
            _refCounted.ensureInitialized();
        }
        else
        {
            assert(_refCounted.isInitialized);
        }

        //Object obj = cast(Object) rhs;
        _refCounted._store._payload = cast(Object) rhs;
    }

    T1 opCast(T1)()
    {
        import std.algorithm.mutation : swap;

        static if(is(T1 == bool))
        {
            return _refCounted._store._payload !is null;
        } else
        {
            static if(!isRefCounted!T1)
            {
                static assert(null,
                    T1.stringof ~ " is not a ref counted!"
                );
            }

            alias R = TemplateArgsOf!(T1)[0];
            static if (isImplicitlyConvertible!(R, T) || (is(R : Object) && is(R == class)))
            {
                T1 ret;
                ret._refCounted._store = _refCounted._store;
                _refCounted._store._count++;
                
                return ret;
            } else
            {
                static assert(null, "Non cast object " ~ R.stringof ~ " to " ~ T.stringof);
            }
        }
    }

    static if (autoInit == RefCountedAutoInitialize.yes)
    {
        //Can't use inout here because of potential mutation
        @property
        T refCountedPayload() return
        {
            _refCounted.ensureInitialized();
            return cast(T) _refCounted._store._payload;
        }
    }

    @property nothrow @trusted pure @nogc
    T refCountedPayload() inout return
    {
        assert(_refCounted.isInitialized, "Attempted to access an uninitialized payload.");
        return cast(T) _refCounted._store._payload;
    }

    alias refCountedPayload this;

    static if (is(T == struct) && !is(typeof((ref T t) => t.toString())))
    {
        string toString(this This)()
        {
            import std.conv : to;

            static if (autoInit)
                return to!string(refCountedPayload);
            else
            {
                if (!_refCounted.isInitialized)
                    return This.stringof ~ "(RefCountedStore(null))";
                else
                    return to!string(_refCounted._store._payload);
            }
        }
    }
}

RefCounted!(T, RefCountedAutoInitialize.no) refCounted(T)(T val)
{
    typeof(return) res;
    res._refCounted.move(val);
    return res;
}