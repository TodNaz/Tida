/++
Module for rendering text using the `FreeType` library.
Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>
Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.text;

export:
import bindbc.freetype;
import std.traits;
import tida.drawable;
import tida.color;

import tida.vector;

__gshared FT_Library _FTLibrary;

/++
Loads a library for loading and rendering fonts.
$(PHOBREF object,Exception) if the library was not found on the system.
+/
void initFontLibrary()
{
    import std.exception : enforce;

    enforce!Exception(loadFreeType() != FTSupport.noLibrary, "Not find FreeType library!");
    enforce!Exception(!FT_Init_FreeType(&_FTLibrary), "Not a initialize FreeType Library!");
}

struct FontSymbolInfo
{
    import tida.image;
    import tida.vector;

    int bitmapLeft;
    int bitmapTop;
    Vector!float advance;
    Image image;
}

/++
The object to load and use the font.
+/
class Font
{
    import std.exception : enforce;
    import std.string : toStringz;
    import std.file : exists;
    import tida.image;

private:
    FT_Face _face;
    size_t _size;

export:
    FontSymbolInfo[uint] cache;

@trusted:
    /// Font face object.
    @property FT_Face face() nothrow pure
    {
        return _face;
    }

    /// Font size.
    @property size_t size() nothrow pure
    {
        return _size;
    }

    auto charIndex(T)(T symbol, int flags)
    {
        FT_Load_Char(_face, symbol, flags);
        return FT_Get_Char_Index(_face, symbol);
    }

    FontSymbolInfo renderSymbol(uint index, int fload, int frender)
    {
        import tida.vector;
        import tida.color;

        if (index in cache)
        {
            return cache[index];
        } else
        {
            FontSymbolInfo syinfo;
            Image image;
            FT_GlyphSlot glyph;

            FT_Load_Glyph(_face, index, fload);
            FT_Render_Glyph(_face.glyph, frender);

            glyph = _face.glyph;

            if (glyph.bitmap.width > 0 && glyph.bitmap.rows > 0)
            {
                auto bitmap = glyph.bitmap;

                image = new Image();
                image.allocatePlace(bitmap.width, bitmap.rows);

                auto pixels = image.pixels;

                foreach(j; 0 .. bitmap.width * bitmap.rows)
                {
                    pixels[j] = rgba(255, 255, 255, bitmap.buffer[j]);
                }
            }

            syinfo.bitmapLeft = glyph.bitmap_left;
            syinfo.bitmapTop = glyph.bitmap_top;
            syinfo.advance = vec!float(glyph.advance.x, glyph.advance.y);
            syinfo.image = image;

            cache[index] = syinfo;

            return syinfo;
        }
    }

    /++
    Loads a font.
    Params:
        path = The path to the font.
        size = Font size.
    Throws:
    $(PHOBREF object,Exception) if the font was not found in the file system,
    or if the font is damaged.
    +/
    Font load(string path, size_t size)
    {
        enforce!Exception(exists(path), "Not file file `"~path~"`");

        enforce!Exception(!FT_New_Face(_FTLibrary, path.toStringz, 0, &_face), "Font damaged!");

        FT_CharMap found;

        foreach(i; 0 .. _face.num_charmaps)
        {
            FT_CharMap charmap = _face.charmaps[i];
            if ((charmap.platform_id == 3 && charmap.encoding_id == 1)
             || (charmap.platform_id == 3 && charmap.encoding_id == 0)
             || (charmap.platform_id == 2 && charmap.encoding_id == 1)
             || (charmap.platform_id == 0)) {
                found = charmap;
                break;
            }
        }

        FT_Set_Charmap(_face, found);
        FT_Set_Char_Size(_face, 0, cast(int) size*32, 300, 300);
        FT_Set_Pixel_Sizes(_face, 0, cast(int) size*2);

        this._size = size;

        return this;
    }

    /++
    Changes the font size to the specified parameter.
    Params:
        newSize = Font new size.
    +/
    void resize(size_t newSize) @trusted
    {
        this._size = newSize;

        FT_Set_Char_Size(_face, 0, cast(int) _size*32, 300, 300);
        FT_Set_Pixel_Sizes(_face, 0, cast(int) size*2);

        cache.clear();
    }

    /// Free memory
    void free() @trusted
    {
        FT_Done_Face(_face);
    }

    ~this() @safe
    {
        free();
    }
}

/++
Determining the type of character depending on the type of the string.
+/
template TypeChar(T)
{
    static if (is(T : string))
        alias TypeChar = char;
    else
    static if (is(T : wstring))
        alias TypeChar = wchar;
    else
    static if (is(T : dstring))
        alias Typechar = dchar;
}

/// The unit for rendering the text.
class Symbol
{
    import tida.image;
    import tida.color;
    import tida.vector;
    import tida.game : renderer;

export:
    Image image; /// Symbol image.
    Vecf position; /// Symbol releative position.
    Color!ubyte color; /// Symbol color.
    Vecf advance; /// Symbol releative position.
    size_t size; /// Symbol size.
    float offsetY = 0.0f; /// Offset symbol

@safe:
    this(   Image image,
            Vecf position,
            Vecf rel,
            size_t size,
            Color!ubyte color = rgb(255,255,255))
    {
        this.image = image;
        this.position = position;
        this.color = color;
        this.advance = rel;
        this.size = size;

        if (this.image !is null)
        if (this.image.texture is null)
        {
            image.toTexture(renderer);
        }
    }
}

/++
Cuts off formatting blocks.
Params:
    symbols = Symbols.
+/
inout(T) cutFormat(T)(inout T symbols) @safe /*nothrow*/ /*pure*/
if (isSomeString!T)
{
    T result;
    int previous = 0;

    for(int i = 0; i < symbols.length; i++)
    {
        if(symbols[i] == '$')
        {
            if(symbols[i+1] == '<')
            {
                __symEachCutter: for(int j = i; j < symbols.length; j++)
                {
                    if(symbols[j] == '>')
                    {
                        result = result ~ symbols[previous .. i];
                        previous = j + 1;
                        break __symEachCutter;
                    }
                }
            }
        }
    }

    result ~= symbols[previous .. $];

    return result;
}

unittest
{
    assert("Hello, $<FF0000>World!".cutFormat == ("Hello, World!"));
}

/++
Returns the size of the rendered text for the given font.
Params:
    T = String type.
    text = Text.
    font = Font.
+/
inout(int) widthText(T)(T text, Font font, Vecf sc = vecf(1.0f, 1.0f)) @safe
{
    import std.algorithm : reduce;
    static assert(isSomeString!T, T.stringof ~ " is not a string!");

    return new Text(font)
        .toSymbols!T(cutFormat!T(text))
        .widthSymbols;
}

/++
Shows the width of the displayed characters.
Params:
    text = Displayed characters.
+/
inout(int) widthSymbols(inout Symbol[] text, Vecf sc = vecf(1.0f, 1.0f)) @safe
{
    import std.algorithm : fold;
    import std.conv : to;

    int width = int.init;

    foreach(s; text)
    {
        width += (cast(int) (s.advance.x * sc.x)) >> 6;
    }

    return width;
}

/++
Draw text object. An array of letters and offset attributes already rendered
into the image is fed into the constructor, and the text is output
from these data.
+/
class SymbolRender : IDrawable, IDrawableEx
{
    import tida.render;
    import tida.vector;
    import tida.color;
    import tida.graphics.gapi;
    import std.conv : to;

private:
    Symbol[] symbols;

export @safe:

    /++
    Constructor of the text rendering object.
    Params:
        symbols =   Already drawn ready-made in image text with offset
                    parameters for correct presentation.
    +/
    this(Symbol[] symbols)
    {
        this.symbols = symbols;
    }

    override void draw(IRenderer render, Vecf position)
    {
        IShaderPipeline currShader = render.currentShader;
        float[4][4] cmodel = render.currentModelMatrix;

        position.y += (symbols[0].size + (symbols[0].size / 2));

        foreach (s; symbols)
        {
            immutable sm = vecf(cmodel[0][0], cmodel[1][1]);
            immutable d = s.position * sm;
            immutable dv = s.advance * sm;

            if (s.image !is null)
            {
                render.currentShader = currShader;
                render.currentModelMatrix = cmodel;

                s.image.drawEx(render, position - vecf(0, d.y), 0.0f,
                vecfNaN, vecfNaN, s.color.a, s.color);
            }

            position = position + vecf(dv.x.to!int >> 6, s.offsetY * sm.y);
        }
    }

    override void drawEx(   IRenderer render,
                            Vecf position,
                            float angle,
                            Vecf center,
                            Vecf size,
                            ubyte alpha,
                            Color!ubyte color)
    {
        IShaderPipeline currShader = render.currentShader;
        float[4][4] cmodel = render.currentModelMatrix;

        position.y += (symbols[0].size + (symbols[0].size / 2));

        foreach (s; symbols)
        {
            immutable sm = vecf(cmodel[0][0], cmodel[1][1]);
            immutable d = s.position * sm;
            immutable dv = s.advance * sm;

            if (s.image !is null)
            {
                render.currentShader = currShader;
                render.currentModelMatrix = cmodel;

                s.image.drawEx(render, position, angle, center, vecfNaN, alpha,
                s.color);
            }

            position = position + vecf(dv.x.to!int >> 6, 0);
        }
    }
}

Symbol fromSymInfo(Font font, FontSymbolInfo syInfo, Color!ubyte color) @safe
{
    import tida.vector;

    return new Symbol(syInfo.image,
        vec!float(syInfo.bitmapLeft, syInfo.bitmapTop),
        vec!float(syInfo.advance.x, 0),
        font.size,
        color);
}

/++
An object for rendering drawing symbols.
+/
class Text
{
    import tida.color;
    import tida.image;
    import tida.vector;

private:
    Font font;

export @trusted:
    this(Font font)
    {
        this.font = font;
    }

    /++
    Draws each character and gives them a relative position to position
    them correctly in the text.
    Params:
        T = String type.
        text = Text.
        color = Color text.
    +/
    Symbol[] toSymbols(T)(T text, Color!ubyte color = rgb(0, 0, 0))
    {
        import std.algorithm : map;
        import std.range : array;

        static assert(isSomeString!T, T.stringof ~ " is not a string!");

        Symbol[] symbols;

        symbols = text
            .map!(a => font.charIndex(a, FT_LOAD_RENDER | FT_LOAD_TARGET_NORMAL))
            .map!(a => font.renderSymbol(a, FT_LOAD_DEFAULT, FT_RENDER_MODE_NORMAL))
            .map!(a => font.fromSymInfo(a, color))
            .array;

        return symbols;
    }

    /++
    Outputs text with color and positional formatting.
    Using the special block `$ <...>`, you can highlight text with color,
    for example:
    ---
    new Text(font).toSymbolsFormat("Black text! $<ffffff> white text!\nNew line!");
    ---
    There must be a hex color inside the special block, which will be used later.
    Also, line wrapping is supported.
    Params:
        T = string type.
        symbols = Text.
        defaultColor = Default color.
    +/
    Symbol[] toSymbolsFormat(T)(T symbols,
                                Color!ubyte defaultColor = rgba(255,255,255,255))
    {
        static assert(isSomeString!T, T.stringof ~ " is not a string!");

        Symbol[] result;
        int previous = 0;
        int j = 0;

        Color!ubyte color = defaultColor;

        for (int i = 0; i < symbols.length; i++)
        {
            if (symbols[i] == '$')
            {
                if (symbols[i+1] == '<') {
                    T colorText;

                    __symEach: for (j = i; j < symbols.length; j++)
                    {
                        if (symbols[j] == '>')
                        {
                            colorText = symbols[i+2 .. j];
                            break __symEach;
                        }
                    }

                    if (colorText != "")
                    {
                        result ~= this.toSymbols(symbols[previous .. i], color);

                        color = Color!ubyte(colorText);
                        i = j + 1;
                        previous = i;
                    }
                }
            } else
            if (symbols[i] == '\n')
            {
                Symbol[] temp = this.toSymbols(symbols[previous .. i], color);
                Symbol last = temp[$ - 1];
                last.offsetY += last.size * 2;
                float tc = -(result.widthSymbols + widthSymbols(temp));
                int ic = cast(int) tc;
                last.advance = vecf((ic << 6) + last.advance.x , 0);

                previous = i + 1;

                result ~= temp;
            }
        }

        result ~= this.toSymbols(symbols[previous .. $], color);

        return result;
    }

    /++
    Creates symbols for rendering and immediately returns the object of
    their renderer.
    Params:
        T = String type.
        text = Text.
        color = Color text.
    +/
    SymbolRender renderSymbols(T)(T text, Color!ubyte color = rgb(0, 0, 0))
    {
        static assert(isSomeString!T, T.stringof ~ " is not a string!");
        return new SymbolRender(toSymbols(text, color));
    }

    /++
    Outputs characters with color formatting and sequel, renders such text.
    Params:
        T = String type.
        text = Text.
        color = Color text.
    +/
    SymbolRender renderFormat(T)(T text, Color!ubyte color = rgb(0, 0, 0))
    {
        static assert(isSomeString!T, T.stringof ~ " is not a string!");
        return new SymbolRender(toSymbolsFormat(text, color));
    }
}