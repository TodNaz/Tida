/++
Color manipulation module. Mixing, converting, parsing colors.

For mixing use implementations: $(LREF BlendImpl), using 
$(HREF #BlendFactor, factors) you will get the desired mixing result as 
a function. An example would be the simplest blending by alpha value: 
---
BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, Type).
---

If you need to convert a set of bytes to a set of colors, 
use the $(LREF fromColors) function.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.color;

import std.traits;

enum CannotDetectAuto = 
"The format cannot be detected automatically!";

/// Pixel representation format.
enum PixelFormat : int
{
    None, /// None format
    Auto, /// Automatic detection
    RGB, /// Red-Green-Blue
    RGBA, /// Red-Green-Blue-Alpha
    ARGB, /// Alpha-Red-Green-Blue
    BGRA, /// Blue-Green-Red-Alpha
    BGR /// Blur-Green-Red
}

/++
Whether the pixel format is valid for the job.
+/
template isValidFormat(int pixelformat)
{
    enum isValidFormat =    pixelformat != PixelFormat.None &&
                            pixelformat != PixelFormat.Auto &&
                            pixelformat <= PixelFormat.max;
}

unittest
{
    assert(isValidFormat!(PixelFormat.BGRA));
    assert(!isValidFormat!(30));
}

/++
Shows how many bytes are contained in a color unit.
+/
template bytesPerColor(int pixelformat, T = ubyte)
{
    static assert(isValidFormat!pixelformat, "Invalid or unknown pixel format!");

    static if ( pixelformat == PixelFormat.RGBA ||
                pixelformat == PixelFormat.ARGB ||
                pixelformat == PixelFormat.BGRA)
    {
        enum bytesPerColor = 4 * T.sizeof;
    }else
    {
        enum bytesPerColor = 3 * T.sizeof;
    }
}

unittest
{
    assert(bytesPerColor!(PixelFormat.RGBA) == 4);
    assert(bytesPerColor!(PixelFormat.RGBA, int) == 4 * int.sizeof);
    assert(bytesPerColor!(PixelFormat.BGR, int) == 3 * int.sizeof);
    assert(bytesPerColor!(PixelFormat.ARGB, long) == 4 * long.sizeof);
    assert(bytesPerColor!(PixelFormat.RGB, float) == 3 * float.sizeof);
}

T hexTo(T, R)(R hexData) @safe nothrow pure
if (isSomeString!R)
{
    import std.math : pow;

    enum hexNumer = "0123456789";
    enum hexWord = "ABCDEF";
    enum hexSmallWord = "abcdef";

    T result = T.init;
    int index = -1;

    hexDataEach: foreach_reverse (e; hexData)
    {
        index++;
        immutable rindex = (cast(int) hexData.length) - index;
        immutable ai = pow(16, index);

        foreach (el; hexNumer)
        {
            if (e == el)
            {
                result += (e - 48) * (ai == 0 ? 1 : ai);
                continue hexDataEach;
            }
        }

        foreach (el; hexWord)
        {
            if (e == el)
            {
                result += (e - 55) * (ai == 0 ? 1 : ai);
                continue hexDataEach;
            }
        }

        foreach (el; hexSmallWord)
        {
            if (e == el)
            {
                result += (e - 87) * (ai == 0 ? 1 : ai);
                continue hexDataEach;
            }
        }
    }

    return result;
}

unittest
{
    assert(hexTo!long("FF0000") == (0xFF0000));
    assert(hexTo!long("0A0A1F") == (0x0A0A1f));
    assert(hexTo!int("3AF124") == (0x3AF124));
    assert(hexTo!int("f1aB11") == (0xf1aB11));
    assert(hexTo!int("fffff3a") == (0xfffff3a));
}

/++
Creates an RGB color.

Params:
    red = Red.
    green = Green.
    blue = Blue. 

Returns: RGBA
+/
Color!ubyte rgb(ubyte red, ubyte green, ubyte blue) @safe nothrow pure
{
    return Color!ubyte(red, green, blue, ubyte.max);
}

Color!ubyte rgb(ubyte[] data) @safe nothrow pure
{
    return Color!ubyte(data[0], data[1], data[2]);
}

Color!ubyte rgba(ubyte[] data) @safe nothrow pure
{
    return Color!ubyte(data);
}

Color!ubyte grayscale(ubyte value) @safe nothrow pure
{
    return Color!ubyte(value, value, value, Color!ubyte.Max);
}

/++
Creates an RGBA color.

Params:
    red = Red.
    green = Green.
    blue = Blue. 
    alpha = Alpha.

Returns: RGBA
+/
Color!ubyte rgba(ubyte red, ubyte green, ubyte blue, ubyte alpha) @safe nothrow pure
{
    return Color!ubyte(red, green, blue, alpha);
}

/++
Recognizes a hex format string, converting it to RGBA representation as a 
`Color!ubyte` structure.

Params:
    hex = The same performance. The following formats can be used:
          * `0xRRGGBBAA` / `0xRRGGBB`
          * `#RRGGBBAA` / `#RRGGBB`
    format = Pixel format.

Returns: `Color!ubyte`
+/
Color!C parseColor(int format = PixelFormat.Auto, C = ubyte, T)(T hex) 
@safe nothrow pure
{
    static if (isSomeString!T)
    {
        import std.conv : to;
        import std.bigint;

        size_t cv = 0;
        if (hex[0] == '#') 
            cv++;
        else 
        if (hex[0 .. 2] == "0x") 
            cv += 2;

        static if (format == PixelFormat.Auto) 
        {
            const alpha = hex[cv .. $].length > 6;

            return Color!C(
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C,
                alpha ? hex[cv + 6 .. cv + 8].hexTo!C : Color!C.Max
            );
        }else
        static if (format == PixelFormat.RGB) 
        {
            return Color!C(
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C
            );
        }else
        static if (format == PixelFormat.RGBA) 
        {
            assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

            return Color!C(
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C,
                hex[cv + 6 .. cv + 8].hexTo!C
            );
        }else
        static if (format == PixelFormat.ARGB) 
        {
            assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

            return Color!C(
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv + 4 .. cv + 6].hexTo!C,
                hex[cv + 6 .. cv + 8].hexTo!C,
                hex[cv .. cv + 2].hexTo!C
            ); 
        }else
        static if (format == PixelFormat.BGRA) 
        {
            assert(hex[cv .. $].length > 6,"This is not alpha-channel hex color!");

            return Color!C(
                hex[cv + 4 .. cv + 6].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv .. cv + 2].hexTo!C,
                hex[cv + 6 .. cv + 8].hexTo!C
            );
        }else
        static if (format == PixelFormat.BGR) 
        {
            return Color!C(
                hex[cv + 6 .. cv + 8].hexTo!C,
                hex[cv + 2 .. cv + 4].hexTo!C,
                hex[cv .. cv + 2].hexTo!C);
        }else
            static assert(null,"Unknown pixel format");
    }else
    static if (isIntegral!T)
    {
        Color!C result;
    
        static if (format == PixelFormat.RGBA)
        {
            result.r = (hex & 0xFF000000) >> 24;
            result.g = (hex & 0x00FF0000) >> 16;
            result.b = (hex & 0x0000FF00) >> 8;
            result.a = (hex & 0x000000FF);
            
            return result;
        }else
        static if (format == PixelFormat.RGB)
        {
            result.r = (hex & 0xFF0000) >> 16;
            result.g = (hex & 0x00FF00) >> 8;
            result.b = (hex & 0x0000FF);
            result.a = 255;

            return result;
        }else
        static if (format == PixelFormat.ARGB)
        {
            result.a = (hex & 0xFF000000) >> 24;
            result.r = (hex & 0x00FF0000) >> 16;
            result.g = (hex & 0x0000FF00) >> 8;
            result.b = (hex & 0x000000FF);

            return result;
        }else
        static if (format == PixelFormat.BGRA)
        {
            result.b = (hex & 0xFF000000) >> 24;
            result.g = (hex & 0x00FF0000) >> 16;
            result.r = (hex & 0x0000FF00) >> 8;
            result.a = (hex & 0x000000FF);

            return result;
        }else
        static if (format == PixelFormat.BGR)
        {
            result.b = (hex & 0XFF0000) >> 16;
            result.g = (hex & 0x00FF00) >> 8;
            result.r = (hex & 0x0000FF);
            result.a = Color!C.Max;

            return result;
        }else
        static if (format == PixelFormat.Auto) {
            return parseColor!(PixelFormat.RGB, C, T)(hex);
        }else
            static assert(null, "Unknown pixel format!");
    }else
        static assert(null, "Unknown type hex!");
}

unittest
{
    assert(parseColor(0xFFFFFF) == (Color!ubyte(255, 255, 255)));
    assert(parseColor("#f9004c") == (Color!ubyte(249, 0, 76)));
    assert(parseColor("#f9004cf9") == (Color!ubyte(249, 0, 76, 249)));

    assert(parseColor!(PixelFormat.RGBA)(0xc1f4a1b4) == (Color!ubyte(193, 244, 161, 180)));
    assert(parseColor!(PixelFormat.BGRA)("FF0000FF") == (Color!ubyte(0, 0, 255, 255)));
    assert(parseColor!(PixelFormat.ARGB)("f9ff00ff") == (Color!ubyte(255, 0, 255, 249)));
    assert(parseColor!(PixelFormat.BGR)(0xf900ff) == (Color!ubyte(255, 0, 249, 255)));
}

/++
Color description structure.
+/
struct Color(T)
if (isIntegral!T || isFloatingPoint!T)
{
    alias Type = T;

    static if (isIntegral!T)
    {
        enum Max = T.max;
        enum Min = 0;
    }
    else
    static if (isFloatingPoint!T)
    {
        enum Max = 1.0f;
        enum Min = 0.0f;
    }

export:
    T red; /// Red component
    T green; /// Green component
    T blue; /// Blue component
    T alpha = Max; /// Alpha component

    alias r = red;
    alias g = green;
    alias b = blue;
    alias a = alpha;

@safe nothrow pure:
    /++
    Color constructor for four components, the latter which is optional.
    +/
    this(T red, T green, T blue, T alpha = Max)
    {
        this.red = red;
        this.green = green;
        this.blue = blue;
        this.alpha = alpha;
    }

    /++
    Parses a color from the input.
    +/
    this(R)(R value)
    if (isIntegral!R || isSomeString!R || isArray!R)
    {
        static if (isArray!R && !isSomeString!R)
        {
            this.red = cast(T) value[0];
            this.green = cast(T) value[1];
            this.blue = cast(T) value[2];
            this.alpha = cast(T) (value.length > 3 ? value[3] : Max);
        }
        else
            this = parseColor!(PixelFormat.Auto, T, R)(value);
    }

    void opAssign(R)(R value)
    if (isIntegral!R || isSomeString!R || isArray!R)
    {
        static if (isArray!R && !isSomeString!R)
        {
            this.red = value[0];
            this.green = value[1];
            this.blue = value[2];
            this.alpha = value.length > 3 ? value[3] : Max;
        }
        else
            this = parseColor!(PixelFormat.Auto, T, R)(value);
    }

    R to(R, int format = PixelFormat.RGBA)() inout
    {
        static if (isIntegral!R && !isFloatingPoint!T)
        {
            static if(format == PixelFormat.RGBA)
                return cast(R) (((r & 0xff) << 24) + ((g & 0xff) << 16) + ((b & 0xff) << 8) + (a & 0xff));
            else
            static if(format == PixelFormat.RGB)
                return cast(R) ((r & 0xff) << 16) + ((g & 0xff) << 8) + ((b & 0xff));
            else
            static if(format == PixelFormat.ARGB)
                return cast(R) (((a & 0xff) << 24) + ((r & 0xff) << 16) + ((g & 0xff) << 8) + (b & 0xff));
            else
            static if(format == PixelFormat.BGRA)
                return cast(R) (((b & 0xff) << 24) + ((g & 0xff) << 16) + ((r & 0xff) << 8) + (a & 0xff));
            else
            static if(format == PixelFormat.BGR)
                return cast(R) (((b & 0xff) << 16) + ((g & 0xff) << 8) + ((r & 0xff)));
            else
                return 0;
        }else
        static if (isSomeString!R)
        {
            static if (isFloatingPoint!T)
                return "";
            else
            {
                import std.digest : toHexString;

                return cast(R) toBytes!(format).toHexString;
            }
        }
    }

    /++
    Returns an array of components.

    Params:
        format = Pixel format.
    +/
    T[] toBytes(int format)() inout
    {
        static assert(isValidFormat!format, CannotDetectAuto);

        static if (format == PixelFormat.RGBA)
            return [r,g,b,a];
        else
        static if (format == PixelFormat.RGB)
            return [r,g,b];
        else
        static if (format == PixelFormat.ARGB)
            return [a,r,g,b];
        else
        static if (format == PixelFormat.BGRA)
            return [b,g,r,a];
        else
        static if (format == PixelFormat.BGR)
            return [b,g,r];
    }

    Color!T opBinary(string op)(T koe) inout
    {
        import std.conv : to;

        static if (op == "+")
            return Color!T( cast(T) (r + koe),
                            cast(T) (g + koe),
                            cast(T) (b + koe),
                            cast(T) (a + koe));
        else
        static if (op == "-")
            return Color!T( cast(T) (r - koe),
                            cast(T) (g - koe),
                            cast(T) (b - koe),
                            cast(T) (a - koe));
        else
        static if (op == "*")
            return Color!T( cast(T) (r * koe),
                            cast(T) (g * koe),
                            cast(T) (b * koe),
                            cast(T) (a * koe));
        else
        static if (op == "/")
            return Color!T( cast(T) (r / koe),
                            cast(T) (g / koe),
                            cast(T) (b / koe),
                            cast(T) (a / koe));
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    Color!T opBinary(string op)(float koe) inout
    {
        import std.conv : to;

        static if (op == "+")
            return Color!T( cast(T) (r + koe),
                            cast(T) (g + koe),
                            cast(T) (b + koe),
                            cast(T) (a + koe));
        else
        static if (op == "-")
            return Color!T( cast(T) (r - koe),
                            cast(T) (g - koe),
                            cast(T) (b - koe),
                            cast(T) (a - koe));
        else
        static if (op == "*")
            return Color!T( cast(T) (r * koe),
                            cast(T) (g * koe),
                            cast(T) (b * koe),
                            cast(T) (a * koe));
        else
        static if (op == "/")
            return Color!T( cast(T) (r / koe),
                            cast(T) (g / koe),
                            cast(T) (b / koe),
                            cast(T) (a / koe));
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    Color!T opBinary(string op)(Color!T color) inout
    {
        static if (op == "+") {
            return Color!T( cast(T) (r + color.r),
                            cast(T) (g + color.g),
                            cast(T) (b + color.b),
                            cast(T) (a + color.a));
        }
        else
        static if (op == "-")
            return Color!T( cast(T) (r - color.r),
                            cast(T) (g - color.g),
                            cast(T) (b - color.b),
                            cast(T) (a - color.a));
        else
        static if (op == "*")
            return Color!T( cast(T) r * color.r,
                                    g * color.g,
                                    b * color.b,
                                    a * color.a);
        else
        static if (op == "/")
            return Color!T( cast(T) r / color.r,
                                    g / color.g,
                                    b / color.b,
                                    a / color.a);
        else
            static assert(0, "Operator `" ~ op ~ "` not implemented.");
    }

    /// Converts the color to black and white.
    float toGrayscaleFloat() inout
    {
        return (rf * 0.299 + gf * 0.587 + bf * 0.144);
    }

    /// Whether the color is dark.
    bool isDark() inout
    {
        return toGrayscaleFloat < 0.5f;
    }

    /// Whether the color is light.
    bool isLight() inout
    {
        return toGrayscaleFloat > 0.5f;
    }

    /// Converts the color to black and white.
    T toGrayscaleNumber() inout
    {
        return cast(T) (Max * toGrayscaleFloat());
    }

    /// Converts the color to black and white.
    Color!T toGrayscale() inout
    {
        auto graycolor = toGrayscaleNumber();

        return Color!T(graycolor, graycolor, graycolor, alpha);
    }

    /// Will return the color opposite to itself.
    @property Color!T inverted() inout
    {
        return Color!T(Max - r, Max - g, Max - b, a);
    }

    /// Invert alpha value
    @property T invertAlpha() inout
    {
        return Max - alpha;
    }

    /// Red value in the form of a range from 0 to 1.
    @property float rf()  inout
    {
        return cast(float) r / cast(float) Max;
    }

    /// ditto
    @property float rf(float value)
    {
        this.r = cast(T) (Max * value);
        
        return value;
    }

    /// Green value in the form of a range from 0 to 1.
    @property float gf() inout
    {
        return cast(float) g / cast(float) Max;
    }

    /// ditto
    @property float gf(float value)
    {
        this.g = cast(T) (Max * value);
        
        return value;
    }

    /// Alpha value in the form of a range from 0 to 1.
    @property float bf() inout
    {
        return cast(float) b / cast(float) Max;
    }

    /// ditto
    @property float bf(float value)
    {
        this.b = cast(T) (Max * value);
        
        return value;
    }

    /// Returns a alpha value in the form of a range from 0 to 1.
    @property float af() inout
    {
        return cast(float) a / cast(float) Max;
    }
    /// ditto
    @property float af(float value)
    {
        this.a = cast(T) (Max * value);
        
        return value;
    }
}

unittest
{
    Color!ubyte color = "#f9004c";
    assert(color == (Color!ubyte(249, 0, 76)));

    color = 0xf9004c;
    assert(color == (Color!ubyte(249, 0, 76)));

    color = Color!ubyte([249, 0, 76]);
    assert(color == (Color!ubyte(249, 0, 76)));

}

/++
Will change the byte sequence to color.

Params:
    format = Pixel format.
    bytes = byte sequence.
+/
Color!ubyte fromColor(int format)(ubyte[] bytes) @safe nothrow pure
{
    bytes = bytes.fromFormat!(format,PixelFormat.RGBA);

    return Color!ubyte(bytes[0],bytes[1],bytes[2],bytes[3]);
}

/++
Will change the sequence of bytes into a collection of colors.

Params:
    format = Pixel format.
    bytes = byte sequence.
+/
Color!ubyte[] fromColors(int format)(ubyte[] bytes) @safe nothrow pure
{
    Color!ubyte[] result;

    for(size_t i = 0; i < bytes.length; i += bytesPerColor!format)
    {
        result ~= bytes[i .. i + bytesPerColor!format].fromColor!(format);
    }

    return result;
}

unittest
{
    assert([54, 13, 85, 255].fromColor!(PixelFormat.RGBA) == (rgb(54, 13, 85)));

    assert([54, 13, 85, 255, 128, 54, 9, 255].fromColors!(PixelFormat.RGBA) == ([rgb(54, 13, 85), rgb(128, 54, 9)]));
}

/++
Checks if the structure is a color.
+/
template isColor(T)
{
    enum isColor =  __traits(hasMember, T, "r") &&
                    __traits(hasMember, T, "g") &&
                    __traits(hasMember, T, "b") &&
                    __traits(hasMember, T, "a");
}

/++
Converts one sample color to another.

Params:
    From = From color.
    To = To color.
    color = color structre.

Returns:
    Converted color.
+/
Color!To convert(From, To)(Color!From color) @safe nothrow pure
{
    static if (isFloatingPoint!From) 
    {
        static if (isFloatingPoint!To)
        {
            return Color!To(
                cast(To) color.red,
                cast(To) color.green,
                cast(To) color.blue,
                cast(To) color.alpha
            );
        }else
        static if (isIntegral!To)
        {
            return Color!To(
                cast(To) (color.red * Color!To.Max),
                cast(To) (color.green * Color!To.Max),
                cast(To) (color.blue * Color!To.Max),
                cast(To) (color.alpha * Color!To.Max)
            );
        }
    }else
    static if (isIntegral!From)
    {
        static if (isFloatingPoint!To)
        {
            return Color!To(
                cast(To) (color.rf),
                cast(To) (color.gf),
                cast(To) (color.bf),
                cast(To) (color.af)
            );
        }else
        static if (isIntegral!From)
        {
            return Color!To(
                cast(To) color.red,
                cast(To) color.green,
                cast(To) color.blue,
                cast(To) color.alpha
            );
        }
    }
}

unittest
{
    assert(Color!ubyte(255, 255, 255, 255)
        .convert!(ubyte, float) == (Color!float(1.0f, 1.0f, 1.0f, 1.0f)));

    assert(Color!float(1.0f, 1.0f, 1.0f, 1.0f)
        .convert!(float, ubyte) == (Color!ubyte(255, 255, 255, 255)));
}

/++
Checks if the byte array is valid for the color description.
+/
bool validateBytes(int format)(inout(ubyte[]) pixels) @safe nothrow pure
{
    return (pixels.length % bytesPerColor!format) == 0;
}

/// Mixing factor of two colors.
enum BlendFactor
{
    Zero,
    One,
    SrcColor,
    OneMinusSrcColor,
    DstColor,
    OneMinusDstColor,
    SrcAlpha,
    OneMinusSrcAlpha,
    DstAlpha,
    OneMinusDstAlpha,
    ConstantColor,
    OneMinusConstantColor,
    ConstantAlpha,
    OneMinusConstanceAlpha
}

/++
Color mixing implementations.

Params:
    fac1 = First factor mixing.
    fac2 = Second factor mixing.
    T = Two colors type.
    orig = Original color mixing.
    color = Second color mixing.
+/
Color!T BlendImpl(int fac1, int fac2, T)(Color!T orig, Color!T color) @safe nothrow pure
{
    Color!float origf = convert!(T, float)(orig);
    Color!float colorf = convert!(T, float)(color);

    Color!float srcf, drtf;

    // Factory 1
    static if(fac1 == BlendFactor.Zero)
        srcf = Color!float(0.0f, 0.0f, 0.0f, 0.0f);
    else
    static if(fac1 == BlendFactor.One)
        srcf = Color!float(1.0f, 1.0f, 1.0f, 1.0f);
    else
    static if(fac1 == BlendFactor.SrcColor)
        srcf = Color!float(origf.r, origf.g, origf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.OneMinusSrcAlpha)
        srcf = Color!float(1.0f - origf.r, 1.0f - origf.g, 1.0f - origf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.DstColor)
        srcf = Color!float(colorf.r, colorf.g, colorf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.OneMinusDstColor)
        srcf = Color!float(1.0f - colorf.r, 1.0f - colorf.g, 1.0f - colorf.b, 1.0f);
    else
    static if(fac1 == BlendFactor.SrcAlpha)
        srcf = Color!float(origf.a, origf.a, origf.a, origf.a);
    else
    static if(fac1 == BlendFactor.OneMinusSrcAlpha)
        srcf = Color!float(1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a);
    else
    static if(fac1 == BlendFactor.DstAlpha)
        srcf = Color!float(colorf.a, colorf.a, colorf.a, colorf.a);
    else
    static if(fac1 == BlendFactor.OneMinusDstAlpha)
        srcf = Color!float(1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a);

    // Factory 2
    static if(fac2 == BlendFactor.Zero)
        drtf = Color!float(0.0f, 0.0f, 0.0f, 0.0f);
    else
    static if(fac2 == BlendFactor.One)
        drtf = Color!float(1.0f, 1.0f, 1.0f, 1.0f);
    else
    static if(fac2 == BlendFactor.SrcColor)
        drtf = Color!float(origf.r, origf.g, origf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.OneMinusSrcAlpha)
        drtf = Color!float(1.0f - origf.r, 1.0f - origf.g, 1.0f - origf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.DstColor)
        drtf = Color!float(colorf.r, colorf.g, colorf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.OneMinusDstColor)
        drtf = Color!float(1.0f - colorf.r, 1.0f - colorf.g, 1.0f - colorf.b, 1.0f);
    else
    static if(fac2 == BlendFactor.SrcAlpha)
        drtf = Color!float(origf.a, origf.a, origf.a, origf.a);
    else
    static if(fac2 == BlendFactor.OneMinusSrcAlpha)
        drtf = Color!float(1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a, 1.0f - origf.a);
    else
    static if(fac2 == BlendFactor.DstAlpha)
        drtf = Color!float(colorf.a, colorf.a, colorf.a, colorf.a);
    else
    static if(fac2 == BlendFactor.OneMinusDstAlpha)
        drtf = Color!float(1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a, 1.0f - colorf.a);

    Color!float trace = (origf * srcf) + (colorf * drtf);
    return convert!(float, T)(trace);
}

alias mix(T) = BlendMultiply!T;
alias BlendAlpha(T) = BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, T);
alias BlendAdd(T) = BlendImpl!(BlendFactor.One, BlendFactor.One, T);
alias BlendMultiply(T) = BlendImpl!(BlendFactor.DstColor, BlendFactor.Zero, T);
alias BlendSrc2DST(T) = BlendImpl!(BlendFactor.SrcColor, BlendFactor.One, T);
alias BlendAddMul(T) = BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.One, T);
alias BlendAddAlpha(T) = BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.One, T);

alias FuncBlend(T) = Color!T function(Color!T,Color!T) @safe nothrow pure;

/++
Returns a reference to a function that implements mixing two colors 
by mixing factors.
+/
FuncBlend!T BlendFunc(T)(int fac1, int fac2) @trusted nothrow pure
{
    if (fac1 == BlendFactor.Zero)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.Zero, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.One)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.One, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.One, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.One, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.SrcColor)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.SrcColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.OneMinusSrcColor)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if(fac1 == BlendFactor.DstColor)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.DstColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.OneMinusDstColor)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstColor, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.SrcAlpha)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.SrcAlpha, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.OneMinusSrcAlpha)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusSrcAlpha, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.DstAlpha)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.DstAlpha, BlendFactor.OneMinusDstAlpha, T);
    }else
    if (fac1 == BlendFactor.OneMinusDstAlpha)
    {
        if (fac2 == BlendFactor.Zero)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.Zero, T);
        else
        if (fac2 == BlendFactor.One)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.One, T);
        else
        if (fac2 == BlendFactor.SrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.SrcColor, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusSrcColor, T);
        else
        if (fac2 == BlendFactor.DstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.DstColor, T);
        else
        if (fac2 == BlendFactor.OneMinusDstColor)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusDstColor, T);
        else
        if (fac2 == BlendFactor.SrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.SrcAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusSrcAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusSrcAlpha, T);
        else
        if (fac2 == BlendFactor.DstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.DstAlpha, T);
        else
        if (fac2 == BlendFactor.OneMinusDstAlpha)
            return &BlendImpl!(BlendFactor.OneMinusDstAlpha, BlendFactor.OneMinusDstAlpha, T);
    }

    assert(null, "Unknown blend factor's!");
}

/++
Converts the format of a sequence of color bytes.

Params:
    format1 = What is the original format.
    format2 = What format should be converted.
    pixels = Sequence of color bytes.

Returns:
    An array of bytes in the order specified in the pattern according to 
    the pixel format.
+/
ubyte[] fromFormat(int format1, int format2)(ubyte[] pixels) @safe nothrow pure
in
{
    assert(validateBytes!format1(pixels), "The input pixels data is incorrect!");
}
out(r; validateBytes!format2(r), "The out pixels data is incorrect!")
do
{
    static assert(isValidFormat!format1, CannotDetectAuto);
    static assert(isValidFormat!format2, CannotDetectAuto);

    static if (format1 == format2)
        return pixels;

    static if (format1 == PixelFormat.RGB)
    {
        static if (format2 == PixelFormat.RGBA)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 3)
            {
                result ~= pixels[i .. i + 3] ~ 255;
            }

            return result;
        }else
        static if (format2 == PixelFormat.ARGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 3)
            {
                result ~= 255 ~ pixels[i .. i + 3];
            }

            return result;
        }else
        static if (format2 == PixelFormat.BGRA)
        {
            import std.algorithm : reverse;

            size_t count = 0;
            ubyte[] result;

            for (size_t i = 3; i <= pixels.length; i += 3)
            {
                result ~= pixels[i - 3 .. i].reverse ~ 255;
            }

            return result;
        }
    }else
    static if (format1 == PixelFormat.RGBA)
    {
        static if (format2 == PixelFormat.RGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3];
            }

            return result;
        }else
        static if (format2 == PixelFormat.ARGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 3] ~ pixels[i .. i + 3];
            }

            return result;
        }else
        static if (format2 == PixelFormat.BGRA)
        {
            import std.algorithm : reverse;

            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3].reverse ~ pixels[i + 3];
            }

            return result;
        }else
        static if (format2 == PixelFormat.BGR)
        {
            import std.algorithm : reverse;

            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3].reverse;
            }

            return result;
        }
    }else
    static if (format1 == PixelFormat.ARGB)
    {
        static if (format2 == PixelFormat.RGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 1 .. i + 4];
            }

            return result;
        }else
        static if (format2 == PixelFormat.RGBA)
        {
            ubyte[] result;

            for(size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 3] ~ pixels[i .. i + 3];
            }

            return result;
        }else
        static if (format2 == PixelFormat.BGRA)
        {
            import std.algorithm : reverse;

            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result = pixels[i + 3] ~ pixels[i .. i + 3].reverse;
            }

            return result;
        }else
        static if (format2 == PixelFormat.BGR)
        {
            import std.algorithm : reverse;

            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 1 .. i + 4].reverse;
            }

            return result;
        }
    }else
    static if (format1 == PixelFormat.BGRA)
    {
        import std.algorithm : reverse;

        static if (format2 == PixelFormat.RGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3].reverse;
            }

            return result;
        }else
        static if (format2 == PixelFormat.RGBA)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i .. i + 3].reverse ~ pixels[i + 3];
            }

            return result;
        }else
        static if (format2 == PixelFormat.ARGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 4)
            {
                result ~= pixels[i + 1 .. i + 4].reverse ~ pixels[i];
            }

            return result;
        }
    }else
    static if (format1 == PixelFormat.BGR)
    {
        import std.algorithm : reverse;

        static if (format2 == PixelFormat.RGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 3)
            {
                result ~= pixels[i .. i + 3].reverse;
            }

            return result;
        }else
        static if (format2 == PixelFormat.RGBA)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 3)
            {
                result ~= pixels[i .. i + 3].reverse ~ 255;
            }

            return result;
        }else
        static if (format2 == PixelFormat.ARGB)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 3)
            {
                result ~= 255 ~ pixels[i .. i + 3].reverse;
            }

            return result;
        }else
        static if (format2 == PixelFormat.BGRA)
        {
            ubyte[] result;

            for (size_t i = 0; i < pixels.length; i += 3)
            {
                result ~= pixels[i .. i + 3] ~ 255;
            }

            return result;
        }
    }
}

unittest
{
    assert([255, 0, 0, 255].fromFormat!(PixelFormat.RGBA, PixelFormat.BGRA) == ([0, 0, 255, 255]));

    assert([255, 0, 0, 255, 128, 0, 0, 255].fromFormat!(PixelFormat.RGBA, PixelFormat.BGR) == ([0, 0, 255, 0, 0, 128]));

    assert([128, 32, 32].fromFormat!(PixelFormat.BGR, PixelFormat.RGBA) == ([32, 32, 128, 255]));

    assert([128, 32, 32, 96].fromFormat!(PixelFormat.BGRA, PixelFormat.RGB) == ([32, 32, 128]));

    assert([128, 32, 32].fromFormat!(PixelFormat.BGR, PixelFormat.RGB) == ([32, 32, 128]));

    assert([128, 32, 32, 96].fromFormat!(PixelFormat.ARGB, PixelFormat.BGR) == ([96, 32, 32]));
}
