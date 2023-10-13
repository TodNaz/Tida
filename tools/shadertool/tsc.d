module tools.shadertool.tsc;

import tida;
import commandr;
import tida.graphics.shader;
import tida.graphics.gapi;
import directx.d3dcompiler;

import std.path : extension;

struct CompilerOptions
{
    string input;
    string output;
    StageType stage;
    ShaderSourceType type;
    bool debugCompile;
}

import std.process;
import std.string;
import std.file;
import std.algorithm;
import core.internal.gc.impl.conservative.gc;

string findIt(string path, string programName)
{
    import std.path;

    try {
        foreach (DirEntry ey; dirEntries(path, SpanMode.depth)) {
            if (baseName(ey.name) == programName)
                return ey.name();
        }
    } catch (Exception e)
        return null;

    return null;
}

string __win32_findInstallation(string programName)
{
    string[] paths = environment.get("PATH").split(";") ~ [getcwd()]; 

    foreach (path; paths) {
        auto ff = findIt(path, programName);
        if (ff != null)
            return ff;
    }

    return null;
}

string __posix_findInstallation(string programName)
{
    string[] paths = environment.get("PATH").split(":") ~ [getcwd()];

    foreach (path; paths) {
        auto ff = findIt(path, programName);
        if (ff != null)
            return ff;
    }

    return null;
}

string findInstallation(string programName)
{
    version(Windows)
        return __win32_findInstallation(programName ~ ".exe");
    else
        return __posix_findInstallation(programName);
}

int compileShader(CompilerOptions options)
{
    import std.path;

    import bm = std.bitmanip;
    import io =  std.stdio;
    import std.string;

    if (!exists(options.input))
        throw new Exception("Cannot find input shader file!");

    string glslangValidator = findInstallation("glslang");
    if (glslangValidator is null)
        throw new Exception("Require program: glslangValidator");

    io.writeln("glslangValidator path: ", glslangValidator);

    string dxc = findInstallation("dxc");
    if (dxc is null)
        throw new Exception("Require program: dxc");

    io.writeln("DXC path: ", dxc);

    io.writeln("Source type: ", options.type);
    io.writeln("Source stage: ", options.stage);

    string target;
    if (options.stage == StageType.vertex)
        target = "vs_5_0";
    else
    if (options.stage == StageType.fragment)
        target = "ps_5_0";
    else
        target = "cs_6_0";

    if (options.type == ShaderSourceType.GLSL)
    {
        Pid gvp = spawnProcess([
            glslangValidator, "-G", "--keep-uncalled", options.input, "-o", "__gv_" ~ std.path.baseName(options.input) ~ ".spv"
        ]);
        auto code = wait(gvp);
        if (code != 0)
            throw new Exception("Cannot compile shader!");
    } else
    {
        Pid dxcp = spawnProcess([
            dxc, "-spirv", options.input, "-T", target, "-Fo", "__gv_" ~ std.path.baseName(options.input) ~ ".spv"
        ]);
        auto code = wait(dxcp);
        if (code != 0)
            throw new Exception("Cannot compile shader!");
    }

    void[] spvdat = read("__gv_" ~ std.path.baseName(options.input) ~ ".spv");

    ShaderCompiler compiler = new ShaderCompiler(ShaderSourceType.HLSL);
    auto src = compiler.compile(
        spvdat
    );

    ID3D10Blob code;
    ID3D10Blob error;

    auto dsrc = src ~ "\0";

    auto rcode = D3DCompile(
        &dsrc[0], dsrc.length, null, null, null, "main", target.toStringz, D3DCOMPILE_ENABLE_STRICTNESS, 0, &code, &error
    );
    if (FAILED(rcode))
    {
        io.writeln("SOURCE:");
        import std.string, std.conv;

        size_t i = 1;
        auto sd = split(src, '\n');
        string mn = to!string(sd.length);

        string se(size_t c)
        {
            char[] r = new char[](c);
            return cast(string) (r[] = ' ');
        }

        foreach (e; sd)
        {
            string istr = i.to!string;
            io.writeln(istr, se(mn.length - istr.length), "| ", e);
            i++;
        }
        io.writeln("OPTIONS: ", options);

        io.writeln(
            cast(string) error.GetBufferPointer()[0 .. error.GetBufferSize]
        );
        throw new Exception("Cannot compile DXBC code!");
    }

    version (Windows)
        void[] dxidat = code.GetBufferPointer()[0 .. code.GetBufferSize()]; /+read("__gv" ~ std.path.baseName(options.input) ~ ".dxi");+/
    else
        void[] dxidat = null;

    scope(exit)
    {
        if (exists("__gv" ~ std.path.baseName(options.input) ~ ".dxi"))
            remove("__gv" ~ std.path.baseName(options.input) ~ ".dxi");

        if (exists("__dxi_" ~ std.path.baseName(options.input) ~ ".hlsl"))
            remove("__dxi_" ~ std.path.baseName(options.input) ~ ".hlsl");
        
        if (exists("__gv_" ~ std.path.baseName(options.input) ~ ".spv"))
            remove("__gv_" ~ std.path.baseName(options.input) ~ ".spv");
    }

    void[] unidat = new ubyte[](
        compiler.ubos.length * (6 + 3)
    );
    size_t uoffset;

    foreach (e; compiler.ubos)
    {
        unidat[uoffset .. uoffset += 3] = cast(void[]) "UNI";
        bm.write(cast(ubyte[]) unidat, cast(ushort) e.id, uoffset);
        uoffset += ushort.sizeof;
        bm.write(cast(ubyte[]) unidat, cast(uint) e.sizeBuffer, uoffset);
        uoffset += uint.sizeof;

        io.writeln(e);
    }

    void[] tso = new ubyte[](8 + 4 + 4 + 4 + spvdat.length + dxidat.length + unidat.length);
    size_t offset;

    tso[0 .. 8] = cast(void[]) ".TIDASO\0";
    offset += 8;
    bm.write(cast(ubyte[]) tso, cast(uint) spvdat.length, offset);
    offset += 4;
    bm.write(cast(ubyte[]) tso, cast(uint) dxidat.length, offset);
    offset += 4;
    bm.write(cast(ubyte[]) tso, cast(uint) unidat.length, offset);
    offset += 4;
    tso[offset .. offset += spvdat.length] = spvdat[];
    tso[offset .. offset += dxidat.length] = dxidat[];
    tso[offset .. offset += unidat.length] = unidat[];

    io.writeln("Save in ", options.output, "...");
    write(options.output, tso);

    return 0;
}

int main(string[] args)
{
    import std.path;

    ProgramArgs program = new Program("tsc", "1.0")
        .summary("tida shader compiler")
        .author("TodNaz <mrnazar44@gmail.com>")
        .add(new Argument("file", "input shader file"))
        .add(new Option("o", "output", "Output blob"))
        .add(new Option("ss", "shaderstage", "shader stage").validate(new EnumValidator(
            ["vertex", "fragment", "compute"]
        )))
        .add(new Option("st", "shadertype", "shader type").validate(new EnumValidator(
            ["GLSL", "HLSL"]
        )))
        .add(new Flag("g", "genDebug", "Set Debug instr in shader"))
        .parse(args);

    CompilerOptions options;
    options.input = program.arg("file", "null");
    options.output = program.option(
        "output", 
        std.path.dirName(options.input) ~ "/" ~ baseName(options.input) ~ ".tso"
    );
    string sname = program.option("shaderstage", extension(options.input));
    switch (sname)
    {
        case ".vert", ".hvert", "vertex": options.stage = StageType.vertex; break;
        case ".frag", ".hfrag", "fragment": options.stage = StageType.fragment; break;
        case ".comp", ".hcomp", "compute": options.stage = StageType.compute; break;
        default: throw new Exception("Cannot automation find shader stage!");
    }

    sname = program.option("shadertype", extension(options.input));
    switch (sname)
    {
        case ".vert", ".glsl", ".frag", ".comp", "GLSL": options.type = ShaderSourceType.GLSL; break;
        case ".hvert", "hlsl", ".hfrag", ".hcomp", "HLSL": options.type = ShaderSourceType.HLSL; break;
        default: throw new Exception("Cannot automation find shader type!");
    }

    options.debugCompile = cast(bool) program.occurencesOf("genDebug");
    
    return compileShader(options);
}