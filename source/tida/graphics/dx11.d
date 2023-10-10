module tida.graphics.dx11;
 import directx.d3d11;

version(DX11Graph):
import directx.d3d11;
import tida.graphics.gapi;
import tida.window;
import core.sys.windows.windows;
import tida.color;

import directx.d3dx11;
import directx.dxgi;
import directx.d3dcompiler;
import core.sys.windows.iphlpapi;
import tida.graphics.shader;
import std.encoding;

class DX11Shader : IShaderManip
{
    ID3D10Blob code;
    ID3D11Device device;
    ID3D11DeviceContext ctx;
    string _src;
    // DX11Buffer[] buffers;
    // UBInfo[] ubos;

    struct Memory
    {
        UBInfo ub;
        DX11Buffer buffer;
    }

    Memory[] memories;

    union Sh
    {
        ID3D11VertexShader _vertex;
        ID3D11PixelShader _pixel;
        ID3D11GeometryShader _geom;
        ID3D11ComputeShader _comp;
    }

    Sh object;
    StageType _stage;

    static string targetFrom(StageType stage) @safe
    {
        final switch (stage)
        {
            case StageType.vertex:
                return "vs_5_0";

            case StageType.fragment:
                return "ps_5_0";

            case StageType.geometry:
                return "gs_5_0";

            case StageType.compute:
                return "cs_5_0";
        }
    } 

    ~this() @trusted
    {
        if (code !is null)
            code.Release();

        if (object._vertex !is null)
            (cast(ID3D11Resource) object._vertex).Release();
    }

    this(StageType s, ID3D11Device device, ID3D11DeviceContext ctx) @safe
    {
        this._stage = s;
        this.device = device;
        this.ctx = ctx;
    }

    /// Loading a shader from its source code.
    void loadFromSource(string code) @safe
    {
        
    }

    debug
    {
        void outputCode() @trusted
        {
            import std.string, std.conv;
            import io = std.stdio;

            size_t i = 1;
            auto sd = split(_src, '\n');
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
        }
    }

    /// Loading a shader from an memory.
    /// Assumes loading an object in Spire-V format.
    void loadFromMemory(void[] b) @trusted
    {
        import std.conv, std.string;

        ShaderCompiler compiler = new ShaderCompiler(ShaderSourceType.HLSL);
        string src = compiler.compile(b);
        debug
        {
            _src = src;
        }

        foreach_reverse (e; compiler.ubos)
        {
            Memory mem;
            DX11Buffer buffer = new DX11Buffer(BufferType.uniform, device, ctx);

            mem.buffer = buffer;
            mem.ub = e;

            memories ~= mem;
        }

        ID3D10Blob error;
        HRESULT rcode;

        rcode = D3DCompile(
            &src[0], src.length, null, null, null, "main", targetFrom(_stage).toStringz, D3DCOMPILE_ENABLE_STRICTNESS, 0, &code, &error
        );

        if (FAILED(rcode) || error)
        {
            char[] message = (cast(char*) error.GetBufferPointer)[0 .. error.GetBufferSize()];
            
            debug
            {
                outputCode();
            }
            throw new Exception("[D3DCompiler] " ~ message.to!string);
        }

        HRESULT csc;
        final switch (_stage)
        {
            case StageType.vertex:
                csc = device.CreateVertexShader(
                    code.GetBufferPointer(),
                    code.GetBufferSize(),
                    null,
                    &object._vertex
                );
                break;
            case StageType.fragment:
                csc = device.CreatePixelShader(
                    code.GetBufferPointer(),
                    code.GetBufferSize(),
                    null,
                    &object._pixel
                );
                break;
            case StageType.geometry:
                csc = device.CreateGeometryShader(
                    code.GetBufferPointer(),
                    code.GetBufferSize(),
                    null,
                    &object._geom
                );
                break;
            case StageType.compute:
                csc = device.CreateComputeShader(
                    code.GetBufferPointer(),
                    code.GetBufferSize(),
                    null,
                    &object._comp
                );
                break;
        }

        if (FAILED(csc))
        {
            debug outputCode();
            throw new Exception("Cannot create shader!");
        }
    }

    /// Shader stage type.
    @property StageType stage() @safe
    {
        return StageType.init;
    }
}

class DX11ShaderProgram : IShaderProgram
{
    DX11Shader vertex;
    DX11Shader fragment;
    DX11Shader geometry;
    DX11Shader compute;
    bool isLink = false;

    void attach(IShaderManip manip) @safe
    {
        DX11Shader shader = cast(DX11Shader) manip;
        final switch (shader._stage)
        {
            case StageType.vertex:
                vertex = shader;
                break;
            case StageType.fragment:
                fragment = shader;
                break;
            case StageType.geometry:
                geometry = shader;
                break;
            case StageType.compute:
                compute = shader;
                break;
        }
    }

    DX11Shader mainShader() @safe
    {
        if (vertex !is null) return vertex; else
        if (fragment !is null) return fragment; else
        if (geometry !is null) return geometry; else
        if (compute !is null) return compute;

        assert(null);
    }

    /// Program link. Assumes that prior to its call, shaders were previously bound.
    void link() @safe
    {
        isLink = true;
    }

    size_t getUniformBlocks() @safe
    {
        return mainShader().memories.length;
    }

    void setUniformData(uint id, void[] data) @safe
    {
        mainShader().memories[id].buffer.bindData(data);
    }

    void setUniformBuffer(uint id, IBuffer buffer) @safe
    {
        mainShader().memories[id].buffer = cast(DX11Buffer) buffer;
    }

    IBuffer getUniformBuffer(uint id) @safe
    {
        return mainShader().memories[id].buffer;
    }

    uint getUniformBufferAlign() @safe
    {
        return 16;
    }
}

class DX11Buffer : IBuffer
{
    ID3D11Buffer id;
    ID3D11Device device;
    ID3D11DeviceContext ctx;
    D3D11_USAGE _usage;
    D3D11_BIND_FLAG _bind;
    BufferType _type;
    uint size;
    void[] cache;
    void[] mapped;

    this(BufferType type, ID3D11Device device, ID3D11DeviceContext ctx) @safe
    {
        this.device = device;
        this._type = type;
        this._bind = dxBind(this._type);
        this._usage = D3D11_USAGE_DYNAMIC;
        this.ctx = ctx;
    }

    this(BufferType type, ID3D11Device device, ID3D11DeviceContext ctx, inout void[] data) @trusted immutable
    {
        this.device = cast(immutable) device;
        this._type = type;
        this._bind = dxBind(this._type);
        this._usage = D3D11_USAGE_DYNAMIC;
        this.ctx = cast(immutable) ctx;

        D3D11_BUFFER_DESC bd;
        bd.Usage = _usage;
        bd.ByteWidth = cast(uint) data.length;
        bd.BindFlags = _bind;
        bd.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;

        D3D11_SUBRESOURCE_DATA idata;
        idata.pSysMem = cast(void*) data.ptr;

        size = cast(uint) data.length;

        cache = data.dup;

        auto code = device.CreateBuffer(&bd, &idata, cast(ID3D11Buffer*) &id); 
        if (FAILED(code))
        {
            throw new Exception("[DX11] Cannot create buffer!");
        }
    }

    static D3D11_BIND_FLAG dxBind(BufferType type) @safe
    {
        final switch (type)
        {
            case BufferType.array:
                return D3D11_BIND_VERTEX_BUFFER;

            /// Use as buffer for indexing
            case BufferType.element:
                return D3D11_BIND_INDEX_BUFFER;

            /// Use as buffer for uniforms structs
            case BufferType.uniform:
                return D3D11_BIND_CONSTANT_BUFFER;

            /// Use as buffer for texture pixel buffer
            case BufferType.textureBuffer:
                return D3D11_BIND_STREAM_OUTPUT;

            /// Use as buffer for compute buffer
            case BufferType.storageBuffer:
                return D3D11_BIND_STREAM_OUTPUT;
        }
    }

    size_t getSize() @safe
    {
        return size;
    }

    void allocate(size_t size) @trusted
    {
        if(id !is null)
        {
            (cast(ID3D11Buffer) id).Release();
            id = null;
        }

        if (size < 8)
            size = 16;
        else
        if ((size % 16) != 0)
        {
            immutable crt = ((size / 16) + 1) * 16;
            size += crt - size;
        }

        D3D11_BUFFER_DESC bd;
        bd.Usage = _usage;
        bd.ByteWidth = cast(uint) size;
        bd.BindFlags = _bind;
        bd.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;

        this.size = cast(uint) size;

        cache = new ubyte[](this.size);

        auto code = device.CreateBuffer(&bd, null, &id); 
        if (FAILED(code))
        {
            throw new Exception("[DX11] Cannot create buffer!");
        }
    }

    void usage(BufferType type) @safe
    {

    }

    /// Buffer type.
    @property BufferType type() @safe inout
    {
        return _type;
    }

    /// Specifying the buffer how it will be used.
    void dataUsage(BuffUsageType usage) @safe
    {
        this._usage = dxUsage(usage);
    }

    static D3D11_USAGE dxUsage(BuffUsageType usage) @safe
    {
        final switch (usage)
        {
            case BuffUsageType.staticData:
                return D3D11_USAGE_DEFAULT;

            case BuffUsageType.dynamicData:
                return D3D11_USAGE_DYNAMIC;
        }
    }

    void[] mapData() @trusted
    {
        if (id is null) throw new Exception("Cannot map void buffer!");

        D3D11_MAPPED_SUBRESOURCE res;
        ctx.Map(id, 0, D3D11_MAP_WRITE_DISCARD, 0, &res);
        mapped = res.pData[0 .. size];

        if (cache.length != 0)
            mapped[] = cache[];
        return mapped;
    }

    void unmapData() @trusted
    {
        cache = mapped.dup;
        ctx.Unmap(id, 0);
    }

    /// Attach data to buffer. If the data is created as immutable, the data can
    /// only be entered once.
    void bindData(inout void[] data) @trusted
    {
        if (size == data.length)
        {
            void[] tdat = mapData();
            tdat[0 .. data.length] = data[];
            unmapData(); 
        } else
        {
            if(id !is null)
            {
                (cast(ID3D11Buffer) id).Release();
                id = null;
            }
            size = cast(uint) data.length;

            if (size < 8)
                size = 16;
            else
            if ((size % 16) != 0)
            {
                immutable crt = ((size / 16) + 1) * 16;
                size += crt - size;
            } 

            D3D11_BUFFER_DESC bd;
            bd.Usage = _usage;
            bd.ByteWidth = cast(uint) size;
            bd.BindFlags = _bind;
            bd.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;

            D3D11_SUBRESOURCE_DATA idata;
            idata.pSysMem = cast(void*) data.ptr;

            this.size = cast(uint) data.length;

            cache = data.dup;

            auto code = device.CreateBuffer(&bd, &idata, &id); 
            if (FAILED(code))
            {
                throw new Exception("[DX11] Cannot create buffer!");
            }
        }
    }

    /// ditto
    void bindData(inout void[] data) @trusted immutable
    {
        D3D11_BUFFER_DESC bd;
        bd.Usage = _usage;
        bd.ByteWidth = cast(uint) data.length;
        bd.BindFlags = _bind;
        bd.CPUAccessFlags = 0;

        D3D11_SUBRESOURCE_DATA idata;
        idata.pSysMem = cast(void*) data.ptr;

        (cast(ID3D11Device) device).CreateBuffer(&bd, &idata, cast(ID3D11Buffer*) &id);
    }

    void[] getData(size_t size) @safe
    {
        return cache[0 .. size];
    }

    /// Clears data. If the data is immutable, then the method will throw an
    /// exception.
    void clear() @safe
    {

    }

    ~this() @trusted
    {
        if (id !is null)
            id.Release();
    }
}

class DX11VertexInfo : IVertexInfo
{
    DX11Buffer vert;
    DX11Buffer elem;
    ID3D11Device device;
    ID3D11DeviceContext ctx;
    D3D11_INPUT_ELEMENT_DESC[] desc;
    ID3D11InputLayout[ulong] layouts;
    uint stride;

    ~this() @trusted
    {
        foreach (ref e; layouts.byValue)
            e.Release();
    }

    this(ID3D11Device device, ID3D11DeviceContext ctx) @safe
    {
        this.device = device;
        this.ctx = ctx;
    }

    void bindBuffer(inout IBuffer buffer) @trusted
    {
        DX11Buffer dbuff = cast(DX11Buffer) buffer;
        if (dbuff.type == BufferType.array)
        {
            this.vert = dbuff;
        } else
        if (dbuff.type == BufferType.element)
        {
            this.elem = dbuff;
        } else
            return;
    }

    ID3D11InputLayout layout(DX11ShaderPipeline pipeline) @trusted
    {
        import std.conv : to;

        if (pipeline is null)
            throw new Exception("Pipeline is null!");
        if (pipeline._vertex is null)
            throw new Exception("Pipeline vertex shader is null!");
        if (pipeline._vertex.vertex.code is null)
            throw new Exception("Pipeline vertex code shader is null!");

        immutable ulong __id = cast(ulong) (cast(void*) pipeline._vertex.vertex.code);

        ID3D11InputLayout il;
        ID3D11InputLayout* dil;

        if (layouts.length != 0)
        {
            dil = (__id in layouts);
            if (dil !is null)
            {
                return *dil;
            }
        }

        auto code = device.CreateInputLayout(
            &desc[0], cast(UINT) desc.length, 
            pipeline._vertex.vertex.code.GetBufferPointer(),
            pipeline._vertex.vertex.code.GetBufferSize(),
            &il
        );
        if (FAILED (code))
        {
            debug pipeline._vertex.vertex.outputCode();
            throw new Exception("[DX11] Cannot create input layout: " ~ to!string(code));
        }

        layouts[__id] = il;

        return il;
    }

    static DXGI_FORMAT format(AttribPointerInfo ab) @safe
    {
        if (ab.components > 4)
            return DXGI_FORMAT_UNKNOWN;

        final switch (ab.type)
        {
            case TypeBind.Byte, TypeBind.UnsignedByte:
                if (ab.components == 1)
                    return DXGI_FORMAT_R8_UINT;
                else if (ab.components == 2)
                    return DXGI_FORMAT_R8G8_SINT;
                else if (ab.components == 3)
                    return DXGI_FORMAT_D24_UNORM_S8_UINT;
                else if (ab.components == 4)
                    return DXGI_FORMAT_R8G8B8A8_UINT;
                break;

            case TypeBind.Short, TypeBind.UnsignedShort:
                if (ab.components == 1)
                    return DXGI_FORMAT_R16_UINT;
                else if (ab.components == 2)
                    return DXGI_FORMAT_R16G16_SINT;
                else if (ab.components == 3)
                    return DXGI_FORMAT_UNKNOWN;
                else if (ab.components == 4)
                    return DXGI_FORMAT_R16G16B16A16_UINT;
                break;

            case TypeBind.Int, TypeBind.UnsignedInt:
                if (ab.components == 1)
                    return DXGI_FORMAT_R32_UINT;
                else if (ab.components == 2)
                    return DXGI_FORMAT_R32G32_SINT;
                else if (ab.components == 3)
                    return DXGI_FORMAT_R32G32B32_UINT;
                else if (ab.components == 4)
                    return DXGI_FORMAT_R32G32B32A32_UINT;
                break;

            case TypeBind.Float, TypeBind.Double:
                if (ab.components == 1)
                    return DXGI_FORMAT_R32_FLOAT;
                else if (ab.components == 2)
                    return DXGI_FORMAT_R32G32_FLOAT;
                else if (ab.components == 3)
                    return DXGI_FORMAT_R32G32B32_FLOAT;
                else if (ab.components == 4)
                    return DXGI_FORMAT_R32G32B32A32_FLOAT;
                break;
        }

        return DXGI_FORMAT_UNKNOWN;
    }

    uint typeSize(TypeBind bind) @safe
    {
        final switch (bind)
        {
            case TypeBind.Byte, TypeBind.UnsignedByte: return byte.sizeof;
            case TypeBind.Short, TypeBind.UnsignedShort: return short.sizeof;
            case TypeBind.Int, TypeBind.UnsignedInt: return int.sizeof;
            case TypeBind.Float, TypeBind.Double: return float.sizeof;
        }
    }

    /// Describe the binding of the buffer to the vertices.
    void vertexAttribPointer(AttribPointerInfo[] attrib) @trusted
    {
        import std.conv : to;
        import std.string;

        foreach (e; attrib)
        {
            D3D11_INPUT_ELEMENT_DESC d;
            d.SemanticName = "TEXCOORD";
            d.SemanticIndex = e.location;
            d.Format = format(e);
            d.InputSlot = 0;
            d.AlignedByteOffset = e.offset;
            d.InputSlotClass = D3D11_INPUT_PER_VERTEX_DATA;
            d.InstanceDataStepRate = 0;

            desc ~= d;

            stride = e.stride;
        }
    }
}

class DX11ShaderPipeline : IShaderPipeline
{
    DX11ShaderProgram _vertex, _fragment, _geometry, _compute;

    override void bindShader(IShaderProgram program) @trusted
    {
        DX11ShaderProgram dprogram = cast(DX11ShaderProgram) program;
        if (dprogram.vertex !is null) _vertex = dprogram; else
        if (dprogram.fragment !is null) _fragment = dprogram; else
        if (dprogram.geometry !is null) _geometry = dprogram; else
        if (dprogram.compute !is null) _compute = dprogram; else
            throw new Exception("Shader unstaged!");
    }

    IShaderProgram vertexProgram() @safe { return _vertex; }
    IShaderProgram fragmentProgram() @safe { return _fragment; }
    IShaderProgram geometryProgram() @safe { return _geometry; }
    IShaderProgram computeProgram() @safe { return _compute; }

    static ID3D11Buffer[] dxbuffers(DX11Buffer[] bs) @safe
    {
        ID3D11Buffer[] result = new ID3D11Buffer[](bs.length);
        foreach (i; 0 .. bs.length) result[i] = bs[i].id;

        return result;
    }

    void cBeginUpdate(ID3D11DeviceContext context) @trusted
    {
        uint i = 0;

        ID3D11Buffer[] dxbs;

        context.VSSetShader(_vertex.vertex.object._vertex, null, 0);

        foreach (ref e; _vertex.vertex.memories)
        {
            if (e.buffer.getSize() != 0)
                context.VSSetConstantBuffers(e.ub.id, 1, &e.buffer.id);
        }

        context.PSSetShader(_fragment.fragment.object._pixel, null, 0);

        foreach (ref e; _fragment.fragment.memories)
        {
            if (e.buffer.getSize() != 0)
                context.PSSetConstantBuffers(e.ub.id, 1, &e.buffer.id);
        }

        i = 0;
    }
}

class DX11Texture : ITexture
{
    ID3D11Device device;
    ID3D11DeviceContext ctx;
    TextureType type;
    uint w, h, size;
    StorageType stType;
    uint _active = 0;

    ID3D11SamplerState sampler;
    D3D11_SAMPLER_DESC sampDescript;

    ~this() @trusted
    {
        if (id.tex1D !is null)
            (cast(ID3D11Resource) id.tex1D).Release();

        if (sampler !is null)
            sampler.Release();
    }

    union Utex
    {
        ID3D11Texture1D tex1D;
        ID3D11Texture2D tex2D;
        ID3D11Texture3D tex3D;
    }

    ID3D11ShaderResourceView resource;

    Utex id;

    this(TextureType type, ID3D11Device device, ID3D11DeviceContext ctx) @trusted
    {
        this.device = device;
        this.ctx = ctx;
        this.type = type;

        initializeSampler();
    }

    auto format(StorageType storage) @safe
    {
        final switch (storage)
        {
            case StorageType.r32f: return DXGI_FORMAT_R32_FLOAT;
            case StorageType.r32i, StorageType.r32ui: return DXGI_FORMAT_R32_UINT;
            case StorageType.r8i: return DXGI_FORMAT_R8_UINT;
            case StorageType.rg32f: return DXGI_FORMAT_R32G32_FLOAT;
            case StorageType.rgba32f: return DXGI_FORMAT_R32G32B32A32_FLOAT;
            case StorageType.rgba32i, StorageType.rgba32ui: return DXGI_FORMAT_R32G32B32A32_UINT;
            case StorageType.rgba8, StorageType.rgba8i: return DXGI_FORMAT_R8G8B8A8_UNORM;
        }
    }

    void initializeSampler() @trusted
    {
        sampDescript.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
        sampDescript.AddressU = D3D11_TEXTURE_ADDRESS_WRAP;
        sampDescript.AddressV = D3D11_TEXTURE_ADDRESS_WRAP;
        sampDescript.AddressW = D3D11_TEXTURE_ADDRESS_WRAP;
        sampDescript.ComparisonFunc = D3D11_COMPARISON_NEVER;
        sampDescript.MinLOD = 0;
        sampDescript.MaxLOD = D3D11_FLOAT32_MAX;
    }

    void __1dstorage(StorageType storage, uint width, uint height = 1, inout void[] data = null)  @trusted
    {
        w = width; h = height;

        if (id.tex1D !is null)
        {
            id.tex1D.Release();
            id.tex1D = null;
        }

        D3D11_TEXTURE1D_DESC descript;
        descript.Width = width;
        descript.Format = format(storage);
        descript.Usage = D3D11_USAGE_DYNAMIC;
        descript.BindFlags = D3D11_BIND_SHADER_RESOURCE;
        descript.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        descript.MipLevels = 1;
        descript.ArraySize = 1;

        if (data.length != 0)
        {
            D3D11_SUBRESOURCE_DATA _resource;
            _resource.pSysMem = cast(void*) data.ptr;

            device.CreateTexture1D(&descript, &_resource, &id.tex1D);
        } else
        {
            device.CreateTexture1D(&descript, null, &id.tex1D);
        }

        
        if (sampler !is null) sampler.Release();
        device.CreateSamplerState(&sampDescript, &sampler);

        D3D11_SHADER_RESOURCE_VIEW_DESC sdesc;
        sdesc.Format = descript.Format;
        sdesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE1D;
        sdesc.Texture1D.MipLevels = 1;

        device.CreateShaderResourceView(cast(ID3D11Resource) id.tex1D, &sdesc, &resource);
    }

    void __2dstorage(StorageType storage, uint width, uint height = 1, inout void[] data = null)  @trusted
    {
        w = width; h = height;

        if (id.tex2D !is null)
        {
            id.tex2D.Release();
            id.tex2D = null;
        }

        D3D11_TEXTURE2D_DESC descript;
        descript.Width = width;
        descript.Height = height;
        descript.Format = format(storage);
        descript.Usage = D3D11_USAGE_DEFAULT;
        descript.BindFlags = D3D11_BIND_SHADER_RESOURCE | D3D11_BIND_RENDER_TARGET;
        descript.CPUAccessFlags = D3D11_CPU_ACCESS_WRITE;
        descript.MipLevels = 1;
        descript.ArraySize = 1;

        if (data.length != 0)
        {
            D3D11_SUBRESOURCE_DATA _resource;
            _resource.pSysMem = cast(void*) data.ptr;
            _resource.SysMemPitch = width * 4;

            device.CreateTexture2D(&descript, &_resource, &id.tex2D);
        } else
        {
            device.CreateTexture2D(&descript, null, &id.tex2D);
        }

        if (sampler !is null) sampler.Release();
        device.CreateSamplerState(&sampDescript, &sampler);

        D3D11_SHADER_RESOURCE_VIEW_DESC sdesc;
        sdesc.Format = descript.Format;
        sdesc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;
        sdesc.Texture2D.MipLevels = 1;

        device.CreateShaderResourceView(cast(ID3D11Resource) id.tex2D, &sdesc, &resource);
    }

    void storage(StorageType storage, uint width, uint height = 1) @safe
    {
        this.stType = storage;

        final switch (type)
        {
            case TextureType.oneDimensional: __1dstorage(stType, width, height, null); break;
            case TextureType.twoDimensional: __2dstorage(stType, width, height, null); break;
            case TextureType.threeDimensional: throw new Exception("GAPI not implement 3d texture.");
        }
    }

    void subImage(inout void[] data, uint width, uint height = 1) @trusted
    {
        if (id != Utex.init)
        {
            if (width != w || height != height)
            {
                final switch (type)
                {
                    case TextureType.oneDimensional: __1dstorage(stType, width, height, data); break;
                    case TextureType.twoDimensional: __2dstorage(stType, width, height, data); break;
                    case TextureType.threeDimensional: throw new Exception("GAPI not implement 3d texture.");
                }
            } else
            {
                ctx.UpdateSubresource(id.tex1D, 0, null, cast(void*) data.ptr, w * 4, 0);
            }
        } else
        final switch (type)
        {
            case TextureType.oneDimensional: __1dstorage(stType, width, height, data); break;
            case TextureType.twoDimensional: __2dstorage(stType, width, height, data); break;
            case TextureType.threeDimensional: throw new Exception("GAPI not implement 3d texture.");
        }
    }

    void subData(inout void[] data, uint width, uint height = 1) @trusted
    {
        if (id != Utex.init)
        {
            if (width != w || height != height)
            {
                final switch (type)
                {
                    case TextureType.oneDimensional: __1dstorage(stType, width, height, data); break;
                    case TextureType.twoDimensional: __2dstorage(stType, width, height, data); break;
                    case TextureType.threeDimensional: throw new Exception("GAPI not implement 3d texture.");
                }
            } else
            {
                ctx.UpdateSubresource(id.tex1D, 0, null, cast(void*) data.ptr, w * 4, 0);
            }
        } else
        final switch (type)
        {
            case TextureType.oneDimensional: __1dstorage(stType, width, height, data); break;
            case TextureType.twoDimensional: __2dstorage(stType, width, height, data); break;
            case TextureType.threeDimensional: throw new Exception("GAPI not implement 3d texture.");
        }
    }

    void[] getData() @safe
    {
        return null;
    }

    auto wrapValue(TextureWrapValue value) @safe
    {
        final switch (value)
        {
            case TextureWrapValue.repeat, TextureWrapValue.mirroredRepeat: return D3D11_TEXTURE_ADDRESS_MIRROR;
            case TextureWrapValue.clampToEdge: return D3D11_TEXTURE_ADDRESS_CLAMP;
        }
    }

    /// Type of deployment of texture on the canvas
    void wrap(TextureWrap wrap, TextureWrapValue value) @trusted
    {
        D3D11_TEXTURE_ADDRESS_MODE* mode;
        final switch (wrap)
        {
            case TextureWrap.wrapR: mode = &sampDescript.AddressU; break;
            case TextureWrap.wrapS: mode = &sampDescript.AddressV; break;
            case TextureWrap.wrapT: mode = &sampDescript.AddressW; break;
        }

        *mode = wrapValue(value);

        if (sampler !is null) sampler.Release();
        device.CreateSamplerState(&sampDescript, &sampler);
    }

    auto filterType(TextureFilterValue value) @safe
    {
        // D3D11_FILTER_MIN_MAG_MIP_LINEAR
        final switch (value)
        {
            case TextureFilterValue.linear: return D3D11_FILTER_MIN_MAG_LINEAR_MIP_POINT;
            case TextureFilterValue.nearest: return D3D11_FILTER_MIN_MAG_MIP_POINT;
        }
    }

    /// Type of the texture processing filter.
    void filter(TextureFilter filter, TextureFilterValue value) @trusted
    {
        sampDescript.Filter = filterType(value);

        if (sampler !is null) sampler.Release();
        device.CreateSamplerState(&sampDescript, &sampler);
    }

    /// Indicate the parameters of the texture.
    void params(uint[] parameters) @trusted
    {
        import std.range : chunks;

        foreach (kv; chunks(parameters, 2))
        {
            if (kv[0] >= TextureFilter.min &&
                kv[0] <= TextureFilter.max)
            {
                sampDescript.Filter = filterType(cast(TextureFilterValue) kv[1]);
            } else
            if (kv[0] >= TextureWrap.min &&
                kv[0] <= TextureWrap.max)
            {
                D3D11_TEXTURE_ADDRESS_MODE* mode;
                final switch (cast(TextureWrap) kv[0])
                {
                    case TextureWrap.wrapR: mode = &sampDescript.AddressU; break;
                    case TextureWrap.wrapS: mode = &sampDescript.AddressV; break;
                    case TextureWrap.wrapT: mode = &sampDescript.AddressW; break;
                }

                *mode = wrapValue(cast(TextureWrapValue) kv[1]);
            } else
            {
                // ...
            }
        }

        if (sampler !is null) sampler.Release();
        device.CreateSamplerState(&sampDescript, &sampler);
    }

    /// Insert the texture identifier.
    void active(uint value) @safe
    {
        this._active = value;
    }
}

class DX11Framebuffer : IFrameBuffer
{
    ID3D11Device device;
    ID3D11DeviceContext ctx;
    DX11Texture texture;
    ID3D11RenderTargetView id;

    ~this() @trusted
    {
        if (id !is null)
            id.Release();
    }

    this(ID3D11Device device, ID3D11DeviceContext ctx) @safe
    {
        this.device = device;
        this.ctx = ctx;
    }

    this(ID3D11Device device, ID3D11DeviceContext ctx, ID3D11RenderTargetView target) @safe
    {
        this.device = device;
        this.ctx = ctx;
        this.id = target;
    }

    void attach(ITexture texture) @trusted
    {
        this.texture = cast(DX11Texture) texture;

        if (this.texture.type != TextureType.twoDimensional)
            throw new Exception("Cannot create framebuffer for one/third dimensial texture!");

        D3D11_RENDER_TARGET_VIEW_DESC desc;
        desc.Format = this.texture.format(this.texture.stType);
        desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;

        device.CreateRenderTargetView(this.texture.id.tex2D, &desc, &id);
    }

    void generateBuffer(uint w, uint h) @trusted
    {
        void[] data = new ubyte[](w * h * 4);
        texture = new DX11Texture(TextureType.twoDimensional, device, ctx);
        texture.append(data, w, h);

        D3D11_RENDER_TARGET_VIEW_DESC desc;
        desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        desc.ViewDimension = D3D11_SRV_DIMENSION_TEXTURE2D;

        device.CreateRenderTargetView(texture.id.tex2D, &desc, &id);
    }

    void clear(Color!ubyte color) @trusted
    {
        float[4] clr = [color.rf, color.gf, color.bf, color.af];
        ctx.ClearRenderTargetView(id, &clr[0]);
    }
}

class DX11GraphManip : IGraphManip
{
    // "d3dcompiler", "d3d11", "dxgi"
    pragma(lib, "d3d11");
    pragma(lib, "dxgi");
    pragma(lib, "d3dcompiler");

    private
    {
        IDXGIFactory factor;
        IDXGIAdapter adapter;
        ID3D11Device device;
        IDXGISwapChain swapChain;
        D3D_FEATURE_LEVEL level;
        ID3D11DeviceContext context;
        ID3D11RasterizerState rstate;

        ID3D11Texture2D backBuffer;
        DX11Framebuffer mainTarget;
        DX11Framebuffer currentTarget;
        Color!ubyte clr;

        DX11ShaderPipeline currPip;
        DX11VertexInfo currVi;

        DX11Texture[] currTex;
        ID3D11BlendState bstate;

        Window window;

        bool __discrete = false;
    }

    auto dxBlend(BlendFactor factor) @safe
    {
        final switch (factor)
        {
            case BlendFactor.Zero: return D3D11_BLEND_ZERO;
            case BlendFactor.One: return D3D11_BLEND_ONE;
            case BlendFactor.SrcColor: return D3D11_BLEND_SRC_COLOR;
            case BlendFactor.DstColor: return D3D11_BLEND_DEST_COLOR;
            case BlendFactor.SrcAlpha: return D3D11_BLEND_SRC_ALPHA;
            case BlendFactor.DstAlpha: return D3D11_BLEND_DEST_ALPHA;
            case BlendFactor.OneMinusDstAlpha: return D3D11_BLEND_INV_DEST_ALPHA;
            case BlendFactor.OneMinusSrcAlpha: return D3D11_BLEND_INV_SRC_ALPHA;
            case BlendFactor.OneMinusDstColor: return D3D11_BLEND_INV_DEST_COLOR;
            case BlendFactor.OneMinusSrcColor: return D3D11_BLEND_INV_SRC_COLOR;
            case BlendFactor.ConstantAlpha: return D3D11_BLEND_BLEND_FACTOR;
            case BlendFactor.ConstantColor: return D3D11_BLEND_BLEND_FACTOR;
            case BlendFactor.OneMinusConstanceAlpha: return D3D11_BLEND_INV_BLEND_FACTOR;
            case BlendFactor.OneMinusConstantColor: return D3D11_BLEND_INV_BLEND_FACTOR;
        }
    }

    auto topology(ModeDraw mode) @safe
    {
        final switch (mode)
        {
            case ModeDraw.triangle:
                return D3D_PRIMITIVE_TOPOLOGY_TRIANGLELIST;
            case ModeDraw.triangleStrip:
                return D3D_PRIMITIVE_TOPOLOGY_TRIANGLESTRIP;
            case ModeDraw.line:
                return D3D_PRIMITIVE_TOPOLOGY_LINELIST;
            case ModeDraw.lineStrip:
                return D3D_PRIMITIVE_TOPOLOGY_LINESTRIP;
            case ModeDraw.points:
                return D3D_PRIMITIVE_TOPOLOGY_POINTLIST;
        }
    }

override:
    string[2] rendererInfo() @trusted
    {
        import std.conv : to;
        import std.utf : toUTF8;

        string gpu, vendor;

        DXGI_ADAPTER_DESC adesc;
        adapter.GetDesc(&adesc);
        uint i = 0;
        while (adesc.Description[i++] != '\0') {}
        gpu = adesc.Description[0 .. i - 1].toUTF8;

        immutable vid = adesc.VendorId;
        switch (vid)
        {
            case 0x10DE: vendor = "NVIDIA"; break;
            case 0x1002, 0x1022: vendor = "AMD"; break;
            case 0x163C, 0x8086, 0x8087: vendor = "INTEL"; break;
            default: vendor = "UNDEFINED";  break;
        }

        return [vendor, gpu];
    }

    void pointSize(float size) @safe
    {

    }

    /// Initializes an abstraction object for loading a library.
    void initialize(bool discrete) @safe
    {
        this.__discrete = discrete;
    }

    /// Create and bind a framebuffer surface to display in a window.
    ///
    /// Params:
    ///     window  = The window to bind the display to.
    ///     attribs = Graphics attributes.
    void createAndBindSurface(Window window, GraphicsAttributes attribs) @trusted
    {
        immutable   w = window.width,
                    h = window.height;

        this.window = window;

        HWND windowHandle;
        version(SDL)
        {
            import bindbc.sdl;

            SDL_SysWMinfo wmInfo;
            SDL_VERSION(&wmInfo.version_);
            SDL_GetWindowWMInfo(window.handle, &wmInfo);
            windowHandle = wmInfo.info.win.window;
        } else
        {
            windowHandle = window.handle;
        }

        if (windowHandle is null)
        {
            throw new Exception("[DX11] Not extract window handle!");
        }

        if (__discrete)
        {
            version(Windows)
            {
                auto cuda = LoadLibraryA("nvcuda.dll");
                if (cuda !is null) {}
            }
        }

        CreateDXGIFactory(&uuidof!(IDXGIFactory), &factor);
        
        if (factor.EnumAdapters(0, &adapter) == DXGI_ERROR_NOT_FOUND)
        {
            throw new Exception("[D3DX11] Not enum first adapter!");
        }

        DXGI_SWAP_CHAIN_DESC sd;
        sd.BufferCount = 1;
        sd.BufferDesc.Width = w;
        sd.BufferDesc.Height = h;
        sd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
        sd.BufferDesc.RefreshRate.Numerator = 60;
        sd.BufferDesc.RefreshRate.Denominator = 1;
        sd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
        sd.OutputWindow = windowHandle;
        sd.SampleDesc.Count = 1;
        sd.SampleDesc.Quality = 0;
        sd.Windowed = true;

        D3D_FEATURE_LEVEL[] featureLevels =
        [
            D3D_FEATURE_LEVEL_11_0,
            D3D_FEATURE_LEVEL_10_1,
            D3D_FEATURE_LEVEL_10_0
        ];
        immutable numFeatureLevels = featureLevels.length;

        D3D_DRIVER_TYPE[] drivers = [
            D3D_DRIVER_TYPE_HARDWARE,
            D3D_DRIVER_TYPE_WARP,
            D3D_DRIVER_TYPE_REFERENCE
        ];
        HRESULT code;

        UINT flags;
        debug
        {
            flags |= D3D11_CREATE_DEVICE_DEBUG;
        }

        foreach (ref e; drivers)
        {
            code = D3D11CreateDeviceAndSwapChain(
                /+adapter+/ null, e, null, flags, &featureLevels[0], cast(UINT) numFeatureLevels, D3D11_SDK_VERSION, 
                &sd, &swapChain, &device, &level, &context
            );

            if (SUCCEEDED (code))
            {
                break;
            }
        }
        if (FAILED (code))
        {
            throw new Exception("[D3DX11] Error create device context!");
        }

        ID3D11RenderTargetView _mainTarget;

        swapChain.GetBuffer(0, &uuidof!(ID3D11Texture2D), cast(void**) &backBuffer);
        device.CreateRenderTargetView(backBuffer, null, &_mainTarget);

        mainTarget = new DX11Framebuffer(device, context, _mainTarget);

        currentTarget = mainTarget;

        D3D11_RASTERIZER_DESC rasterState;
        rasterState.FillMode = D3D11_FILL_SOLID;
        rasterState.CullMode = D3D11_CULL_NONE;
        rasterState.FrontCounterClockwise = false;
        rasterState.DepthBias = 0;
        rasterState.DepthBiasClamp = 0.0f;
        rasterState.SlopeScaledDepthBias = 0.0f;
        rasterState.DepthClipEnable = true;
        rasterState.ScissorEnable = false;
        rasterState.MultisampleEnable = false;
        rasterState.AntialiasedLineEnable = false;

        device.CreateRasterizerState(&rasterState, &rstate);
        context.RSSetState(rstate);

        blendFactor(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, true);
    }

    /// Updating the surface when the window is resized.
    void update() @safe
    {

    }

    /// Settings for visible borders on the surface.
    ///
    /// Params:
    ///     x = Viewport offset x-axis.
    ///     y = Viewport offset y-axis.
    ///     w = Viewport width.
    ///     h = Viewport height.
    void viewport(float x, float y, float w, float h) @trusted
    {
        D3D11_VIEWPORT viewport;
        viewport.Width = w;
        viewport.Height = h + window.windowBorderSize;
        viewport.MinDepth = 0.0f;
        viewport.MaxDepth = 1.0f;
        viewport.TopLeftX = x;
        viewport.TopLeftY = y;

        context.RSSetViewports(1, &viewport);
    }

    /// Color mixing options.
    ///
    /// Params:
    ///     src     = Src factor.
    ///     dst     = Dst factor.
    ///     state   = Do I need to mix colors?
    void blendFactor(BlendFactor src, BlendFactor dst, bool state) @trusted
    {
        D3D11_BLEND_DESC bdesc;
        bdesc.RenderTarget[0].BlendEnable = state;
        if (!state)
        {
            goto __gapi_blend_create;
        }

        bdesc.AlphaToCoverageEnable = false;
        bdesc.IndependentBlendEnable = false;
        bdesc.RenderTarget[0].SrcBlend = dxBlend(src);
        bdesc.RenderTarget[0].DestBlend = dxBlend(dst);
        bdesc.RenderTarget[0].SrcBlendAlpha = dxBlend(src);
        bdesc.RenderTarget[0].DestBlendAlpha = dxBlend(dst);
        bdesc.RenderTarget[0].BlendOp = D3D11_BLEND_OP_ADD;
        bdesc.RenderTarget[0].BlendOpAlpha = D3D11_BLEND_OP_ADD;
        bdesc.RenderTarget[0].RenderTargetWriteMask = D3D11_COLOR_WRITE_ENABLE_ALL;

__gapi_blend_create:
        auto blendFactor = [ 0.0f, 0.0f, 0.0f, 0.0f ];

        device.CreateBlendState(&bdesc, &bstate);
        context.OMSetBlendState(bstate, blendFactor.ptr, 0xffffffff);
    }

    GraphBackend backend() @safe { return GraphBackend.dx11; }

    /// Color clearing screen.
    void clearColor(Color!ubyte clr) @safe
    {
        this.clr = clr;
    }

    void clear() @trusted
    {
        float[4] color = [clr.rf, clr.gf, clr.bf, clr.af];
        context.ClearRenderTargetView(currentTarget.id, &color[0]);
    }

    /// Drawing start.
    void begin() @trusted
    {
        context.OMSetRenderTargets(1, &currentTarget.id, null);
    }

    void compute(ComputeDataType[] cmp) @safe
    {

    }

    ID3D11SamplerState[] states;
    ID3D11ShaderResourceView[] views;

    /// Drawing a primitive to the screen.
    ///
    /// Params:
    ///     mode    = The type of the rendered primitive.
    ///     first   = The amount of clipping of the initial vertices.
    ///     count   = The number of vertices to draw.
    void draw(ModeDraw mode, uint first, uint count) @trusted
    {
        if (currVi is null)
            throw new Exception("Vertex info is null!");
        if (currPip is null)
            throw new Exception("Shader pipeline is null!");

        context.IASetPrimitiveTopology(
            topology(mode)
        );

        currPip.cBeginUpdate(context);
        
        auto il = currVi.layout(currPip);
        context.IASetInputLayout(il);

        context.RSSetState(rstate);

        foreach (DX11Texture e; currTex)
        {
            context.PSSetSamplers(e._active, 1, &e.sampler);
            context.PSSetShaderResources(e._active, 1, &e.resource);
        }

        // if (states.length != 0)
        // {
        //     context.PSSetSamplers(0, cast(UINT) states.length, &states[0]);
        //     context.PSSetShaderResources(0, cast(UINT) views.length, &views[0]);
        // }

        context.Draw(count, first);

        currPip = null;
        currTex = null;
        states = null;
        views = null;
        currVi = null;
    }

    void drawIndexed(ModeDraw mode, uint icount) @trusted
    {
        if (currVi is null)
            throw new Exception("Vertex info is null!");
        if (currPip is null)
            throw new Exception("Shader pipeline is null!");

        context.IASetPrimitiveTopology(
            topology(mode)
        );

        currPip.cBeginUpdate(context);
        
        auto il = currVi.layout(currPip);
        context.IASetInputLayout(il);

        context.RSSetState(rstate);
        
        foreach (DX11Texture e; currTex)
        {
            context.PSSetSamplers(e._active, 1, &e.sampler);
            context.PSSetShaderResources(e._active, 1, &e.resource);
        }

        // if (states.length != 0)
        // {
        //     context.PSSetSamplers(0, cast(UINT) states.length, &states[0]);
        //     context.PSSetShaderResources(0, cast(UINT) views.length, &views[0]);
        // }

        context.DrawIndexed(icount, 0, 0);

        currPip = null;
        currTex = null;
        states = null;
        views = null;
        currVi = null;
    }

    /// Shader program binding to use rendering.
    void bindProgram(IShaderPipeline shader) @trusted
    {
        this.currPip = cast(DX11ShaderPipeline) shader;
    }

    /// Vertex info binding to use rendering.
    void bindVertexInfo(IVertexInfo vertInfo) @trusted
    {
        DX11VertexInfo vi = cast(DX11VertexInfo) vertInfo;
        UINT stride = vi.stride;
        UINT offset = 0;
        
        context.IASetVertexBuffers(
            0, 1, &vi.vert.id, &stride, &offset
        );
        if (vi.elem !is null)
        {
            context.IASetIndexBuffer(vi.elem.id, DXGI_FORMAT_R32_UINT, 0);
        }

        currVi = vi;
    }

    /// Texture binding to use rendering.
    void bindTexture(ITexture texture) @safe
    {
        DX11Texture dtex = cast(DX11Texture) texture;

        // if (dtex._active > states.length)
        // {
        //     auto dstates = states.dup;
        //     auto dviews = views.dup;
        //     states = new ID3D11SamplerState[](dtex._active + 1);
        //     views = new ID3D11ShaderResourceView[](dtex._active + 1);
        //     states[0 .. dstates.length] = dstates[];
        //     views[0 .. dviews.length] = dviews[];
        // } else
        // if (dtex._active == 0 && states.length == 0)
        // {
        //     states = new ID3D11SamplerState[](1);
        //     views = new ID3D11ShaderResourceView[](1);
        // }

        // states[dtex._active] = dtex.sampler;
        // views[dtex._active] = dtex.resource;

        currTex ~= dtex;
    }

    void bindBuffer(IBuffer buffer) @safe
    {

    }

    /// Framebuffer output to the window surface.
    void drawning() @trusted
    {
        context.OMSetRenderTargets(0, null, null);
        swapChain.Present(0, 0);
    }

    void setFrameBuffer(IFrameBuffer fb) @safe
    {
        this.currentTarget = cast(DX11Framebuffer) fb;
    }

    IFrameBuffer cmainFrameBuffer() @safe
    {
        return mainTarget;
    }

    void setCMainFrameBuffer(IFrameBuffer fb) @trusted
    {
        if (fb is null)
        {
            ID3D11RenderTargetView _mainTarget;

            swapChain.GetBuffer(0, &uuidof!(ID3D11Texture2D), cast(void**) &backBuffer);
            device.CreateRenderTargetView(backBuffer, null, &_mainTarget);

            mainTarget = new DX11Framebuffer(device, context, _mainTarget);
        }
        else
            mainTarget = cast(DX11Framebuffer) fb;
    }

    /// Creates a shader.
    IShaderManip createShader(StageType stage) @safe
    {
        return new DX11Shader(stage, device, context);
    }

    /// Create a shader program.
    IShaderProgram createShaderProgram() @safe
    {
        return new DX11ShaderProgram();
    }

    IShaderPipeline createShaderPipeline() @safe
    {
        return new DX11ShaderPipeline();
    }

    /// Buffer creation.
    IBuffer createBuffer(BufferType buffType = BufferType.array) @safe
    {
        return new DX11Buffer(buffType, device, context);
    }

    /// Create an immutable buffer.
    immutable(IBuffer) createImmutableBuffer(BufferType buffType = BufferType.array, inout void[] data = null) @safe
    {
        return new immutable DX11Buffer(buffType, device, context, data);
    }

    /// Generates information about buffer binding to vertices.
    IVertexInfo createVertexInfo() @safe
    {
        return new DX11VertexInfo(device, context);
    }

    /// Create a texture.
    ITexture createTexture(TextureType tt) @safe
    {
        return new DX11Texture(tt, device, context);
    }

    IFrameBuffer createFrameBuffer() @safe
    {
        return new DX11Framebuffer(device, context);
    }

    IFrameBuffer mainFrameBuffer() @safe
    {
        return mainTarget;
    }

    // Debug tools ----------------------------------------------------------+

    debug
    {
        import std.experimental.logger.core;

        // Log tools --------------------------------------------------------+

        void setupLogger(Logger = stdThreadLocalLog) @safe
        {
            
        }

        // -------------------------------------------------------------------
    }

    // --
}