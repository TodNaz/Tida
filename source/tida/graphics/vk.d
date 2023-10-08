module tida.graphics.vk;

import erupted.platform_extensions;

version(VulkanGraph):
import tida.graphics.gapi;
import tida.window;
import erupted;
import bindbc.loader;

version(SDL) {} else {
    version(Windows)
    {
        import core.sys.windows.windows;
        mixin Platform_Extensions!(KHR_win32_surface);
    } else
    version(Posix)
    {
        mixin Platform_Extensions!(KHR_xlib_surface);
        mixin Platform_Extensions!(KHR_xcb_surface);
    }
}

final class VkGBuffer : IBuffer
{
    VkBuffer id;
    VkDeviceMemory mem;
    VkGraphManip gapi;
    BufferType _type;
    size_t size;

    this(VkGraphManip gapi, BufferType type) @trusted
    {
        this.gapi = gapi;
        this._type = type;
    }

    size_t getSize() @safe
    {
        return size;
    }

    /// How to use buffer.
    void usage(BufferType) @safe
    {

    }

    /// Buffer type.
    @property BufferType type() @safe inout
    {
        return this._type;
    }

    auto vkUsage(BufferType t) @safe
    {
        final switch (t)
        {
            case BufferType.array:
                return VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
            case BufferType.element:
                return VK_BUFFER_USAGE_INDEX_BUFFER_BIT;
            case BufferType.uniform:
                return VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT;
            case BufferType.textureBuffer:
                return VK_BUFFER_USAGE_TRANSFER_SRC_BIT;
            case BufferType.storageBuffer:
                return VK_BUFFER_USAGE_STORAGE_BUFFER_BIT;
        }
    }

    uint findMemIndex() @trusted
    in(id)
    {
        VkMemoryRequirements mq;
        vkGetBufferMemoryRequirements(gapi.device, id, &mq);

        immutable typeFilter = mq.memoryTypeBits;
        immutable properties = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT;

        uint memIndex = 0;
        for (uint i = 0; i < gapi.memProperties.memoryTypeCount; i++)
        {
            if ((typeFilter & (1 << i)) && (gapi.memProperties.memoryTypes[i].propertyFlags & properties) == properties)
            {
                return i;
            }
        }

        return 0;
    }

    void allocate(size_t size) @trusted
    {
        if (id !is null)
        {
            vkFreeMemory(gapi.device, mem, null);

            VkMemoryAllocateInfo allocateInfo;
            allocateInfo.allocationSize = size;
            allocateInfo.memoryTypeIndex = findMemIndex();

            vkAllocateMemory(gapi.device, &allocateInfo, null, &mem);
            vkBindBufferMemory(gapi.device, id, mem, 0);

            this.size = size;
        }

        VkBufferCreateInfo createInfo;
        createInfo.size = cast(VkDeviceSize) size;
        createInfo.usage = vkUsage(_type);
        createInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

        vkCreateBuffer(gapi.device, &createInfo, null, &id);

        VkMemoryAllocateInfo allocateInfo;
        allocateInfo.allocationSize = size;
        allocateInfo.memoryTypeIndex = findMemIndex();

        vkAllocateMemory(gapi.device, &allocateInfo, null, &mem);
        vkBindBufferMemory(gapi.device, id, mem, 0);
    }

    /// Specifying the buffer how it will be used.
    void dataUsage(BuffUsageType usage) @safe
    {

    }

    /// Attach data to buffer. If the data is created as immutable, the data can
    /// only be entered once.
    void bindData(inout void[] data) @trusted
    {
        if (id !is null)
        {
            vkFreeMemory(gapi.device, mem, null);

            VkMemoryAllocateInfo allocateInfo;
            allocateInfo.allocationSize = size;
            allocateInfo.memoryTypeIndex = findMemIndex();

            vkAllocateMemory(gapi.device, &allocateInfo, null, &mem);
            vkBindBufferMemory(gapi.device, id, mem, 0);

            this.size = data.length;
        } else
        {
            VkBufferCreateInfo createInfo;
            createInfo.size = cast(VkDeviceSize) size;
            createInfo.usage = vkUsage(_type);
            createInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

            vkCreateBuffer(gapi.device, &createInfo, null, &id);

            VkMemoryAllocateInfo allocateInfo;
            allocateInfo.allocationSize = size;
            allocateInfo.memoryTypeIndex = findMemIndex();

            vkAllocateMemory(gapi.device, &allocateInfo, null, &mem);
            vkBindBufferMemory(gapi.device, id, mem, 0);

            this.size = data.length;
        }

        void* ptr;
        vkMapMemory(gapi.device, mem, 0, this.size, 0, &ptr);

        void[] mapped = ptr[0 .. this.size];
        mapped[] = data;

        vkUnmapMemory(gapi.device, mem);
    }

    /// ditto
    void bindData(inout void[] data) @safe immutable
    {
        // TODO: implement immutable obj
    }

    void[] getData(size_t size) @trusted
    {
        return null;
    }

    void[] mapData() @trusted
    {
        void* ptr;
        vkMapMemory(gapi.device, mem, 0, this.size, 0, &ptr);

        return ptr[0 .. this.size];
    }

    void unmapData() @trusted
    {
        vkUnmapMemory(gapi.device, mem);
    }

    /// Clears data. If the data is immutable, then the method will throw an
    /// exception.
    void clear() @trusted
    {
        vkFreeMemory(gapi.device, mem, null);
    }

    ~this() @trusted
    {
        if (id !is null)
        {
            vkFreeMemory(gapi.device, mem, null);
            vkDestroyBuffer(gapi.device, id, null);
        }
    }
}

final class VkShader : IShaderManip
{
    StageType _stage;
    VkGraphManip gapi;
    VkShaderModule shModule;
    void[] code;

    this(VkGraphManip gapi, StageType stage) @trusted
    {
        this.gapi = gapi;
        this._stage = stage;
    }

    void loadFromMemory(void[] data) @trusted
    {
        VkShaderModuleCreateInfo createinfo;
        createinfo.codeSize = data.length;
        createinfo.pCode = cast(uint*) data.ptr;

        this.code = data;

        if (vkCreateShaderModule(gapi.device, &createinfo, null, &shModule) != VkResult.VK_SUCCESS)
        {
            throw new Exception("[VK] Cannot create shader module!");
        }
    }

    /// Shader stage type.
    @property StageType stage() @safe
    {
        return _stage;
    }
}

final class VkShaderProgram : IShaderProgram
{
    import tida.graphics.shader;

    VkShader _vertex;
    VkShader _fragment;
    VkShader _geometry;
    VkShader _compute;

    VkGraphManip gapi;
    UBInfo[] ubos;
    VkGBuffer[] buffers;

    this(VkGraphManip gapi) @trusted
    {
        this.gapi = gapi;
    }

    void attach(IShaderManip shader) @safe
    {
        VkShader s = cast(VkShader) shader;
        final switch (s._stage)
        {
            case StageType.vertex: _vertex = s; break;
            case StageType.fragment: _fragment = s; break;
            case StageType.geometry: _geometry = s; break;
            case StageType.compute: _compute = s; break;
        }
    }

    VkShader main() @safe
    {
        if (_vertex !is null) return _vertex; else
        if (_fragment !is null) return _fragment; else
        if (_geometry !is null) return _geometry; else
            return _compute;
    }

    /// Program link. Assumes that prior to its call, shaders were previously bound.
    void link() @trusted
    {
        if (main is null)
            throw new Exception("[VK] Shader Program link error!");

        ShaderCompiler sc = new ShaderCompiler(ShaderSourceType.GLSL);
        sc.uboSetup(main().code);

        this.ubos = sc.ubos;

        foreach (e; this.ubos)
        {
            VkGBuffer gbuffer = new VkGBuffer(gapi, BufferType.uniform);
            gbuffer.allocate(e.sizeBuffer());

            buffers ~= gbuffer;
        }
    }

    size_t getUniformBlocks() @safe
    {
        return ubos.length;
    }

    void setUniformData(uint id, void[] data) @safe
    {
        buffers[id].bindData(data);
    }

    void setUniformBuffer(uint id, IBuffer buffer) @safe
    {
        buffers[id] = cast(VkGBuffer) buffer;
    }

    IBuffer getUniformBuffer(uint id) @safe
    {
        return buffers[id];
    }

    uint getUniformBufferAlign() @safe
    {
        return 16;
    }
}

final class VkVertexIn : IVertexInfo
{
    VkGraphManip gapi;
    VkGBuffer array, elem;
    VkVertexInputBindingDescription inputDescript;
    VkVertexInputAttributeDescription[] iad;

    this(VkGraphManip gapi) @safe
    {
        this.gapi = gapi;
    }

    void bindBuffer(inout IBuffer buffer) @trusted
    {
        VkGBuffer gbuff = cast(VkGBuffer) buffer;
        switch (gbuff.type)
        {
            case BufferType.array: array = gbuff; break;
            case BufferType.element: elem = gbuff; break;
            default: break;
        }
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

    auto vkFormat(AttribPointerInfo attrib) @safe
    {
        final switch ( attrib.type )
        {
            case TypeBind.Byte, TypeBind.UnsignedByte:
                if (attrib.components == 1)
                    return VK_FORMAT_R8_SINT;
                else if (attrib.components == 2)
                    return VK_FORMAT_R8G8_SINT;
                else if (attrib.components == 3)
                    return VK_FORMAT_R8G8B8_SINT;
                else if (attrib.components == 4)
                    return VK_FORMAT_R8G8B8A8_SINT;
                break;
            case TypeBind.Short, TypeBind.UnsignedShort:
                if (attrib.components == 1)
                    return VK_FORMAT_R16_SINT;
                else if (attrib.components == 2)
                    return VK_FORMAT_R16G16_SINT;
                else if (attrib.components == 3)
                    return VK_FORMAT_R16G16B16_SINT;
                else if (attrib.components == 4)
                    return VK_FORMAT_R16G16B16_SINT;
                break;
            case TypeBind.Int, TypeBind.UnsignedInt:
                if (attrib.components == 1)
                    return VK_FORMAT_R32_SINT;
                else if (attrib.components == 2)
                    return VK_FORMAT_R32G32_SINT;
                else if (attrib.components == 3)
                    return VK_FORMAT_R32G32B32_SINT;
                else if (attrib.components == 4)
                    return VK_FORMAT_R32G32B32A32_SINT;
                break;
            case TypeBind.Float:
                if (attrib.components == 1)
                    return VK_FORMAT_R32_SFLOAT;
                else if (attrib.components == 2)
                    return VK_FORMAT_R32G32_SFLOAT;
                else if (attrib.components == 3)
                    return VK_FORMAT_R32G32B32_SFLOAT;
                else if (attrib.components == 4)
                    return VK_FORMAT_R32G32B32A32_SFLOAT;
                break;
            case TypeBind.Double:
                if (attrib.components == 1)
                    return VK_FORMAT_R64_SFLOAT;
                else if (attrib.components == 2)
                    return VK_FORMAT_R64G64_SFLOAT;
                else if (attrib.components == 3)
                    return VK_FORMAT_R64G64B64_SFLOAT;
                else if (attrib.components == 4)
                    return VK_FORMAT_R64G64B64A64_SFLOAT;
        }

        return VK_FORMAT_UNDEFINED;
    }

    /// Describe the binding of the buffer to the vertices.
    void vertexAttribPointer(AttribPointerInfo[] attribs) @trusted
    {
        inputDescript = VkVertexInputBindingDescription.init;

        uint i = 0;
        inputDescript.binding = 0;
        inputDescript.stride = attribs[0].stride;
        inputDescript.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;

        iad = new VkVertexInputAttributeDescription[](attribs.length);

        foreach (e; attribs)
        {
            VkVertexInputAttributeDescription c;
            c.binding = 0;
            c.location = e.location;
            c.format = vkFormat(e);
            c.offset = e.offset;

            iad[i] = c;

            i++;
        }
    }
}

final class VkShaderPipeline : IShaderPipeline
{
    VkGraphManip gapi;
    VkPipeline pipeline;

    VkShaderProgram vertex, fragment, geometry, compute;
    VkPipelineShaderStageCreateInfo[] stages;

    this(VkGraphManip gapi) @trusted
    {
        this.gapi = gapi;
    }

    void bindShader(IShaderProgram program) @safe
    {
        VkShaderProgram vprog = cast(VkShaderProgram) program;

        auto main = vprog.main();
        final switch (main.stage)
        {
            case StageType.vertex: 
                vertex = vprog; 
                VkPipelineShaderStageCreateInfo stage;
                stage.stage = VK_SHADER_STAGE_VERTEX_BIT;
                stage.Module = vprog._vertex.shModule;
                stage.pName = "main";

                stages ~= stage;
                break;
            case StageType.fragment: 
                fragment = vprog; 
                VkPipelineShaderStageCreateInfo stage;
                stage.stage = VK_SHADER_STAGE_FRAGMENT_BIT;
                stage.Module = vprog._fragment.shModule;
                stage.pName = "main";

                stages ~= stage;
                break;
            case StageType.geometry: 
                geometry = vprog; 
                VkPipelineShaderStageCreateInfo stage;
                stage.stage = VK_SHADER_STAGE_GEOMETRY_BIT;
                stage.Module = vprog._geometry.shModule;
                stage.pName = "main";

                stages ~= stage;
                break;
            case StageType.compute: 
                compute = vprog; 
                VkPipelineShaderStageCreateInfo stage;
                stage.stage = VK_SHADER_STAGE_COMPUTE_BIT;
                stage.Module = vprog._compute.shModule;
                stage.pName = "main";

                stages ~= stage;
                break;
        }
    }

    void createPipeline() @trusted
    {
        // if (pipeline !is null)
        // {
        //     vkDestroyPipeline(gapi.device, pipeline, null);
        // }

        VkGraphicsPipelineCreateInfo createInfo;
        createInfo.stageCount = cast(uint) stages.length;
        createInfo.pStages = stages.ptr;
        createInfo.pVertexInputState = &gapi.viState;
        createInfo.pInputAssemblyState = &gapi.inputAssembly;
        createInfo.pViewportState = &gapi.viewportState;
        createInfo.pRasterizationState = &gapi.rasterState; 
        createInfo.pMultisampleState = &gapi.msamState;
        createInfo.pDepthStencilState = null;
        createInfo.pColorBlendState = &gapi.cbState;
        createInfo.pDynamicState = &gapi.dynamicState;
        createInfo.layout = gapi.hLayout;
        createInfo.renderPass = gapi.renderPass;
        createInfo.subpass = 0;
        createInfo.basePipelineHandle = null;

        auto old = pipeline;
        if (old !is null)
        {
            createInfo.basePipelineIndex = 0;
            createInfo.basePipelineHandle = old;
        } else
        {
            createInfo.basePipelineHandle = null;
            createInfo.basePipelineIndex = -1;
        }

        if (vkCreateGraphicsPipelines(gapi.device, null, 1, &createInfo, null, &pipeline) != VkResult.VK_SUCCESS)
        {
            throw new Exception("[VK] Cannot create pipeline!");
        }

        if (old !is null)
            vkDestroyPipeline(gapi.device, old, null);
    }

    ~this() @trusted
    {
        if (pipeline !is null)
        {
            vkDestroyPipeline(gapi.device, pipeline, null);
        }
    }

    IShaderProgram vertexProgram() @safe { return vertex; }
    IShaderProgram fragmentProgram() @safe { return fragment; }
    IShaderProgram geometryProgram() @safe { return geometry; }
    IShaderProgram computeProgram() @safe { return compute; }
}

final class VkGFrameBuffer : IFrameBuffer
{
    VkGraphManip gapi;
    VkFramebuffer id;
    VkImageView view;

    this(VkGraphManip gapi) @safe
    {
        this.gapi = gapi;
    }

    this(VkGraphManip gapi, VkImageView view, uint w, uint h) @trusted
    {
        this.gapi = gapi;
        VkFramebufferCreateInfo fbCrtInfo;
        fbCrtInfo.renderPass = null;
        fbCrtInfo.attachmentCount = 1;
        fbCrtInfo.pAttachments = &view;
        fbCrtInfo.width = w;
        fbCrtInfo.height = h;
        fbCrtInfo.layers = 1;

        vkCreateFramebuffer(gapi.device, &fbCrtInfo, null, &id);
    }

    ~this() @trusted
    {
        vkDestroyFramebuffer(gapi.device, id, null);
    }

    void attach(ITexture texture) @safe
    {

    }

    void generateBuffer(uint w, uint h) @safe
    {
        VkFramebufferCreateInfo fbCrtInfo;
        fbCrtInfo.renderPass = null;
        fbCrtInfo.attachmentCount = 1;
        fbCrtInfo.pAttachments = null;
        fbCrtInfo.width = w;
        fbCrtInfo.height = h;
        fbCrtInfo.layers = 1;


    }

    void clear(Color!ubyte color) @safe
    {

    }
}

class VkGraphManip : IGraphManip
{
    alias VkProcAddr = PFN_vkGetInstanceProcAddr;

    GraphBackend backend() @safe { return GraphBackend.vulkan; }

    version(Windows)
    {
        string[] requiresInstanceExts = [
            "VK_KHR_win32_surface\0",
            "VK_KHR_surface\0",
            "VK_KHR_get_physical_device_properties2\0"
        ];
    } else
    version(Posix)
    {
        string[] requiresInstanceExts = [
            "VK_KHR_xlib_surface\0",
            "VK_KHR_surface\0",
            "VK_KHR_get_physical_device_properties2\0"
        ];
    }

    public
    {
        SharedLib library;
        VkInstance instance;
        VkPhysicalDevice pDevice;
        VkDevice device;
        VkPhysicalDevice pdevice;
        VkSurfaceKHR surface;

        VkSurfaceCapabilitiesKHR cap;
        VkSwapchainKHR swapChain;
        VkSurfaceFormatKHR spFormat;

        VkImage[] scImages;
        VkImageView[] scImageViews;
        VkPhysicalDeviceMemoryProperties memProperties;

        VkDynamicState[] dstates;

        VkShaderPipeline currPip;
        ModeDraw mdCache;

        VkGFrameBuffer[] scFbs;

        uint    qGraph,
                qTrans,
                qPresent;
    }

    string[2] rendererInfo() @safe
    {
        return ["NONGPU", "NONVENDOR"];
    }

    void pointSize(float size) @safe
    {

    }

    /// Initializes an abstraction object for loading a library.
    void initialize(bool discrete) @trusted
    {
        library = load("vulkan_lvp.dll");
        if (library == invalidHandle)
        {
            throw new Exception("[VK] Cannot find vulkan library!");
        }

        VkProcAddr proc;
        bindSymbol(library, cast(void**) &proc, "vkGetInstanceProcAddr");
        if (proc is null)
        {
            bindSymbol(library, cast(void**) &proc, "vk_icdGetInstanceProcAddr");
            if (proc is null)
                throw new Exception("[VK] Vulkan invalid library!");
        }

        if (proc is null)
            throw new Exception("[VK] Vulkan invalid library!");

        erupted.loadGlobalLevelFunctions(proc);

        uint ecount;
        VkExtensionProperties[] iExts;
        vkEnumerateInstanceExtensionProperties(null, &ecount, null);
        iExts = new VkExtensionProperties[](ecount);
        vkEnumerateInstanceExtensionProperties(null, &ecount, iExts.ptr);

        uint rq;
        string __eStr(in char[ VK_MAX_EXTENSION_NAME_SIZE ] __eName)
        {
            size_t i;
            while (__eName[i++] != '\0') {}
            return cast(string) __eName.dup[0 .. i];
        }

        foreach (e; iExts)
        {
            immutable name = __eStr(e.extensionName);
            uint ie = 0;
            foreach (re; requiresInstanceExts) { if (re == name) { rq++; break; } ie++; }
        }

        if (rq != requiresInstanceExts.length)
            throw new Exception("[VK] Cannot find requires instance extensions!");

        const VkApplicationInfo appInfo = VkApplicationInfo(
            VkStructureType.VK_STRUCTURE_TYPE_APPLICATION_INFO, null, "Tida", 0x103, "Tida", 0x103, VK_API_VERSION_1_0
        );

        char*[] rqexts;
        foreach (ref e; requiresInstanceExts)
            rqexts ~= cast(char*) &e[0];

        VkInstanceCreateInfo createInfo;
        createInfo.pApplicationInfo = &appInfo;
        createInfo.ppEnabledExtensionNames = cast(char**) rqexts.ptr;
        createInfo.enabledExtensionCount = cast(uint) requiresInstanceExts.length;

        immutable VkResult result = vkCreateInstance(&createInfo, null, &instance);
        if (result != VkResult.VK_SUCCESS)
            throw new Exception("[VK] Cannot create Vulkan instance!");

        erupted.loadInstanceLevelFunctions(instance);

        VkPhysicalDevice[] pdevices;
        uint cc;
        vkEnumeratePhysicalDevices(instance, &cc, null);
        pdevices = new VkPhysicalDevice[](cc);
        vkEnumeratePhysicalDevices(instance, &cc, pdevices.ptr);

        uint maxScore;
        uint maxID;
        VkPhysicalDeviceProperties props;

        for (uint i = 0; i < cc; i++)
        {
            uint score;
            VkPhysicalDeviceFeatures feat;
            vkGetPhysicalDeviceFeatures(pdevices[i], &feat);
            vkGetPhysicalDeviceProperties(pdevices[i], &props);

            switch (props.deviceType)
            {
                case VK_PHYSICAL_DEVICE_TYPE_INTEGRATED_GPU:
                    score += 500;
                break;

                case VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU:
                    score += 1000;
                break;

                case VK_PHYSICAL_DEVICE_TYPE_CPU:
                    score += 100;
                break;

                default: score += 50; break;
            }

            score += feat.geometryShader ? 500 : 0;
            score += feat.multiDrawIndirect ? 500 : 0;
            score += props.limits.maxImageDimension2D * 10;
            score += props.limits.maxFramebufferLayers * 10;

            if (score > maxScore)
            {
                maxScore = score;
                maxID = i;
            }
        }

        pdevice = pdevices[maxID];
        vkGetPhysicalDeviceMemoryProperties(pdevice, &memProperties);
    }

    void createSwapChain(Window window, VkSurfaceFormatKHR format) @trusted
    {
        import std.algorithm : max, min, clamp;
        VkExtent2D extent;
        extent.width = window.width;
        extent.height = window.height;

        VkSwapchainCreateInfoKHR scCreateInfo;
        scCreateInfo.surface = surface;
        scCreateInfo.minImageCount = cap.minImageCount + 1;
        scCreateInfo.imageFormat = format.format;
        scCreateInfo.imageColorSpace = format.colorSpace;
        scCreateInfo.imageExtent = extent;
        scCreateInfo.imageArrayLayers = 1;
        scCreateInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;

        if (qGraph != qPresent)
        {
            scCreateInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
            scCreateInfo.queueFamilyIndexCount = 2;
            scCreateInfo.pQueueFamilyIndices = cast(uint*) [qGraph, qPresent].ptr;
        } else
            scCreateInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;

        scCreateInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
        scCreateInfo.presentMode = VkPresentModeKHR.VK_PRESENT_MODE_MAILBOX_KHR;
        scCreateInfo.clipped = true;
        scCreateInfo.oldSwapchain = null;

        vkCreateSwapchainKHR = cast(typeof(vkCreateSwapchainKHR)) vkGetInstanceProcAddr(instance, "vkCreateSwapchainKHR");
        vkGetSwapchainImagesKHR = cast(typeof(vkGetSwapchainImagesKHR)) vkGetInstanceProcAddr(instance, "vkGetSwapchainImagesKHR");

        immutable code = vkCreateSwapchainKHR(device, &scCreateInfo, null, &swapChain);
        if (code != VkResult.VK_SUCCESS)
            throw new Exception("[VK] Cannot (re)-create swapChain!");

        uint scic = 0;
        vkGetSwapchainImagesKHR(device, swapChain, &scic, null);
        scImages = new VkImage[](scic);
        vkGetSwapchainImagesKHR(device, swapChain, &scic, &scImages[0]);

        scImageViews = new VkImageView[](scic);
        scFbs = new VkGFrameBuffer[](scic);

        uint scii = 0; 
        foreach (ref e; scImages)
        {
            VkImageViewCreateInfo scIVCrtInfo;
            scIVCrtInfo.image = e;
            scIVCrtInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
            scIVCrtInfo.format = format.format;
            scIVCrtInfo.components = VkComponentMapping(VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY, VK_COMPONENT_SWIZZLE_IDENTITY);
            scIVCrtInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
            scIVCrtInfo.subresourceRange.baseMipLevel = 0;
            scIVCrtInfo.subresourceRange.levelCount = 1;
            scIVCrtInfo.subresourceRange.baseArrayLayer = 0;
            scIVCrtInfo.subresourceRange.layerCount = 1;

            if (vkCreateImageView(device, &scIVCrtInfo, null, &scImageViews[scii]) != VkResult.VK_SUCCESS)
            {
                throw new Exception("[VK] Cannot create image view for swapchain!");
            }

            scFbs[scii] = new VkGFrameBuffer(this, scImageViews[scii], extent.width, extent.height);

            scii++;
        }
    }

    /// Create and bind a framebuffer surface to display in a window.
    ///
    /// Params:
    ///     window  = The window to bind the display to.
    ///     attribs = Graphics attributes.
    void createAndBindSurface(Window window, GraphicsAttributes attribs) @trusted
    {
        version(SDL)
        {
            import bindbc.sdl;
            SDL_Vulkan_CreateSurface(window.handle, instance, &surface);
        } else
        {
            version(Windows)
            {
                import erupted.platform_extensions;
                import tida.runtime : runtime;

                VkWin32SurfaceCreateInfoKHR createInfo;
                createInfo.hwnd = window.handle;
                createInfo.hinstance = runtime.instance();

                vkCreateWin32SurfaceKHR = cast(typeof(vkCreateWin32SurfaceKHR)) vkGetInstanceProcAddr(instance, "vkCreateWin32SurfaceKHR");

                if (vkCreateWin32SurfaceKHR is null)
                    throw new Exception("[VK] KHR_Win32_Surface extension is not a loaded!");

                immutable result = vkCreateWin32SurfaceKHR(instance, &createInfo, null, &surface);
                if (result != VkResult.VK_SUCCESS)
                    throw new Exception("[VK] Cannot create win32 surface!");
            }
        }

        uint qfc = 0;
        VkQueueFamilyProperties[] qfprops;
        vkGetPhysicalDeviceQueueFamilyProperties(pdevice, &qfc, null);
        qfprops = new VkQueueFamilyProperties[](qfc);
        vkGetPhysicalDeviceQueueFamilyProperties(pdevice, &qfc, qfprops.ptr);

        uint qfi = 0;
        VkDeviceQueueCreateInfo[] qfCrtInfo;
        foreach (e; qfprops)
        {
            if (e.queueFlags & VK_QUEUE_GRAPHICS_BIT)
            {
                qGraph = qfi;
                VkDeviceQueueCreateInfo qfCI;
                qfCI.queueFamilyIndex = qfi;
                qfCI.queueCount = 1;
                qfCrtInfo ~= qfCI;
            }
            if (e.queueFlags & VK_QUEUE_TRANSFER_BIT)
            {
                qTrans = qfi;
                VkDeviceQueueCreateInfo qfCI;
                qfCI.queueFamilyIndex = qfi;
                qfCI.queueCount = 1;
                qfCrtInfo ~= qfCI;
            }
            
            uint present = 0;
            vkGetPhysicalDeviceSurfaceSupportKHR(pdevice, qfi, surface, &present);
            if (present)
                qPresent = qfi;

            qfi++; 
        }

        VkDeviceCreateInfo dCreateInfo;
        dCreateInfo.pQueueCreateInfos = qfCrtInfo.ptr;
        dCreateInfo.queueCreateInfoCount = cast(uint) qfCrtInfo.length;

        immutable code = vkCreateDevice(pdevice, &dCreateInfo, null, &device);
        if (code != VkResult.VK_SUCCESS)
            throw new Exception("[VK] Cannot create device handle!");

        loadDeviceLevelFunctions(device);

        vkGetPhysicalDeviceSurfaceCapabilitiesKHR(pdevice, surface, &cap);

        uint fc = 0;
        VkSurfaceFormatKHR[] formats;
        vkGetPhysicalDeviceSurfaceFormatsKHR(pdevice, surface, &fc, null);
        formats = new VkSurfaceFormatKHR[](fc);
        vkGetPhysicalDeviceSurfaceFormatsKHR(pdevice, surface, &fc, formats.ptr);
        
        VkSurfaceFormatKHR needFormat;

        foreach (e; formats)
        {
            if (e.format == VK_FORMAT_B8G8R8A8_SRGB && e.colorSpace == VK_COLOR_SPACE_SRGB_NONLINEAR_KHR)
            {
                needFormat = e;
                break;
            }
        }

        if (needFormat == VkSurfaceFormatKHR.init)
            throw new Exception("[VK] Cannot find require format (BGRA8_SRGB NINLINEAR)");

        spFormat = needFormat;

        createSwapChain(window, needFormat);

        rasterState.depthClampEnable = false;
        rasterState.rasterizerDiscardEnable = true;
        rasterState.polygonMode = VK_POLYGON_MODE_FILL;
        rasterState.lineWidth = 1.0f;
        rasterState.cullMode = VK_CULL_MODE_BACK_BIT;
        rasterState.frontFace = VK_FRONT_FACE_CLOCKWISE;
        rasterState.depthBiasEnable = VK_FALSE;
        rasterState.depthBiasConstantFactor = 0.0f; // Optional
        rasterState.depthBiasClamp = 0.0f; // Optional
        rasterState.depthBiasSlopeFactor = 0.0f; // Optional

        msamState.sampleShadingEnable = false;
        msamState.rasterizationSamples = VK_SAMPLE_COUNT_1_BIT;
        msamState.minSampleShading = 1.0f;
        msamState.pSampleMask = null;
        msamState.alphaToCoverageEnable = false;
        msamState.alphaToOneEnable = false;

        cbaState.blendEnable = true;
        cbaState.srcColorBlendFactor = VK_BLEND_FACTOR_SRC_ALPHA;
        cbaState.dstColorBlendFactor = VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
        cbaState.colorBlendOp = VK_BLEND_OP_ADD;
        cbaState.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
        cbaState.dstAlphaBlendFactor = VK_BLEND_FACTOR_ZERO;
        cbaState.alphaBlendOp = VK_BLEND_OP_ADD;

        cbState.logicOpEnable = VK_FALSE;
        cbState.logicOp = VK_LOGIC_OP_COPY; // Optional
        cbState.attachmentCount = 1;
        cbState.pAttachments = &cbaState;
        cbState.blendConstants[0] = 0.0f; // Optional
        cbState.blendConstants[1] = 0.0f; // Optional
        cbState.blendConstants[2] = 0.0f; // Optional
        cbState.blendConstants[3] = 0.0f; // Optional

        pLayout.setLayoutCount = 0;
        pLayout.pushConstantRangeCount = 0;

        vkCreatePipelineLayout(device, &pLayout, null, &hLayout);

        inputAssembly.topology = VkPrimitiveTopology.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
        dstates = [
            VK_DYNAMIC_STATE_VIEWPORT,
            VK_DYNAMIC_STATE_SCISSOR
        ];

        dynamicState.dynamicStateCount = cast(uint) dstates.length;
        dynamicState.pDynamicStates = &dstates[0];
    }

    void recreatePipelines() @trusted
    {

    }

    /// Updating the surface when the window is resized.
    void update() @safe
    {

    }

    VkViewport pViewport;
    VkRect2D pScissor;
    VkPipelineViewportStateCreateInfo viewportState;
    VkPipelineMultisampleStateCreateInfo msamState;
    VkPipelineColorBlendAttachmentState cbaState;
    VkPipelineColorBlendStateCreateInfo cbState;
    VkPipelineLayoutCreateInfo pLayout;
    VkPipelineLayout hLayout;
    VkPipelineVertexInputStateCreateInfo viState;
    VkPipelineInputAssemblyStateCreateInfo inputAssembly;
    VkPipelineDynamicStateCreateInfo dynamicState;

    /// Settings for visible borders on the surface.
    ///
    /// Params:
    ///     x = Viewport offset x-axis.
    ///     y = Viewport offset y-axis.
    ///     w = Viewport width.
    ///     h = Viewport height.
    void viewport(float x, float y, float w, float h) @safe
    {
        pViewport = VkViewport(
            x, y, w, h, 0.0f, 1.0f
        );

        pScissor = VkRect2D(
            VkOffset2D(0, 0), VkExtent2D(cast(uint) w, cast(uint) h)
        );

        viewportState.viewportCount = 1;
        viewportState.scissorCount = 0;
        viewportState.pViewports = &pViewport;
        viewportState.pScissors = &pScissor;

        recreatePipelines();
    }

    VkPipelineRasterizationStateCreateInfo rasterState;

    auto vkBlend(BlendFactor factor) @safe
    {
        final switch (factor)
        {
            case BlendFactor.Zero: return VK_BLEND_FACTOR_ZERO;
            case BlendFactor.One: return VK_BLEND_FACTOR_ONE;
            case BlendFactor.SrcColor: return VK_BLEND_FACTOR_SRC_COLOR;
            case BlendFactor.DstColor: return VK_BLEND_FACTOR_DST_COLOR;
            case BlendFactor.SrcAlpha: return VK_BLEND_FACTOR_SRC_ALPHA;
            case BlendFactor.DstAlpha: return VK_BLEND_FACTOR_DST_ALPHA;
            case BlendFactor.OneMinusDstAlpha: return VK_BLEND_FACTOR_ONE_MINUS_DST_ALPHA;
            case BlendFactor.OneMinusSrcAlpha: return VK_BLEND_FACTOR_ONE_MINUS_SRC_ALPHA;
            case BlendFactor.OneMinusDstColor: return VK_BLEND_FACTOR_ONE_MINUS_DST_COLOR;
            case BlendFactor.OneMinusSrcColor: return VK_BLEND_FACTOR_ONE_MINUS_SRC_COLOR;
            case BlendFactor.ConstantAlpha: return VK_BLEND_FACTOR_CONSTANT_ALPHA;
            case BlendFactor.ConstantColor: return VK_BLEND_FACTOR_CONSTANT_COLOR;
            case BlendFactor.OneMinusConstanceAlpha: return VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_ALPHA;
            case BlendFactor.OneMinusConstantColor: return VK_BLEND_FACTOR_ONE_MINUS_CONSTANT_COLOR;
        }
    }

    /// Color mixing options.
    ///
    /// Params:
    ///     src     = Src factor.
    ///     dst     = Dst factor.
    ///     state   = Do I need to mix colors?
    void blendFactor(BlendFactor src, BlendFactor dst, bool state) @safe
    {   
        if (!state)
        {
            cbaState.blendEnable = false;
            return;
        }

        cbaState.blendEnable = true;

        auto sBlend = vkBlend(src);
        auto dBlend = vkBlend(dst);

        cbaState.srcColorBlendFactor = sBlend;
        cbaState.dstColorBlendFactor = dBlend;
        cbaState.colorBlendOp = VK_BLEND_OP_ADD;
        cbaState.srcAlphaBlendFactor = VK_BLEND_FACTOR_ONE;
        cbaState.dstAlphaBlendFactor = VK_BLEND_FACTOR_ZERO;
        cbaState.alphaBlendOp = VK_BLEND_OP_ADD;
    }

    float[4] _cc;

    /// Color clearing screen.
    void clearColor(Color!ubyte clr) @safe
    {
        _cc = [
            clr.rf, clr.gf, clr.bf, clr.af
        ];
    }

    void clear() @safe
    {

    }

    VkRenderPassCreateInfo rp;
    VkRenderPass renderPass;

    VkCommandPool cmdPool;
    VkCommandBuffer cmdBuff;
    uint imageIndex = 0;

    /// Drawing start.
    void begin() @trusted
    {
        rp = VkRenderPassCreateInfo .init;

        VkAttachmentDescription attach;
        attach.format = this.spFormat.format;
        attach.samples = VK_SAMPLE_COUNT_1_BIT;
        attach.loadOp = VK_ATTACHMENT_LOAD_OP_CLEAR;
        attach.storeOp = VK_ATTACHMENT_STORE_OP_STORE;
        attach.stencilLoadOp = VK_ATTACHMENT_LOAD_OP_DONT_CARE;
        attach.stencilStoreOp = VK_ATTACHMENT_STORE_OP_DONT_CARE;
        attach.initialLayout = VK_IMAGE_LAYOUT_UNDEFINED;
        attach.finalLayout = VK_IMAGE_LAYOUT_PRESENT_SRC_KHR;

        VkAttachmentReference attRef;
        attRef.attachment = 0;
        attRef.layout = VK_IMAGE_LAYOUT_COLOR_ATTACHMENT_OPTIMAL;

        VkSubpassDescription subpass;
        subpass.pipelineBindPoint = VK_PIPELINE_BIND_POINT_GRAPHICS;
        subpass.colorAttachmentCount = 1;
        subpass.pColorAttachments = &attRef;

        rp.attachmentCount = 1;
        rp.pAttachments = &attach;
        rp.subpassCount = 1;
        rp.pSubpasses = &subpass;

        if (vkCreateRenderPass(device, &rp, null, &renderPass) != VkResult.VK_SUCCESS)
        {
            throw new Exception("[VK] Cannot create render pass!");
        }

        if (currPip is null)
        {
            throw new Exception("[VK] Pipeline is not a bind!");
        }

        currPip.createPipeline();
    }

    void compute(ComputeDataType[] cmp) @safe
    {

    }

    auto vkTopology(ModeDraw mode) @safe
    {
        final switch (mode)
        {
            case ModeDraw.points:
                return VK_PRIMITIVE_TOPOLOGY_POINT_LIST;
            case ModeDraw.line:
                return VK_PRIMITIVE_TOPOLOGY_LINE_LIST;
            case ModeDraw.lineStrip:
                return VK_PRIMITIVE_TOPOLOGY_LINE_STRIP;
            case ModeDraw.triangle:
                return VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST;
            case ModeDraw.triangleStrip:
                return VK_PRIMITIVE_TOPOLOGY_TRIANGLE_STRIP;
        }
    }

    /// Drawing a primitive to the screen.
    ///
    /// Params:
    ///     mode    = The type of the rendered primitive.
    ///     first   = The amount of clipping of the initial vertices.
    ///     count   = The number of vertices to draw.
    void draw(ModeDraw mode, uint first, uint count) @safe
    {
        if (mdCache != mode)
        {
            inputAssembly.topology = vkTopology(mode);
            currPip.createPipeline();
        }
    }

    void drawIndexed(ModeDraw mode, uint icount) @safe
    {
        if (mdCache != mode)
        {
            inputAssembly.topology = vkTopology(mode);
            currPip.createPipeline();
        }


    }

    /// Shader program binding to use rendering.
    void bindProgram(IShaderPipeline shader) @safe
    {
        this.currPip = cast(VkShaderPipeline) shader;
    }

    /// Vertex info binding to use rendering.
    void bindVertexInfo(IVertexInfo vertInfo) @safe
    {
        VkVertexIn vin = cast(VkVertexIn) vertInfo;
        viState = VkPipelineVertexInputStateCreateInfo.init;
        viState.vertexBindingDescriptionCount = 1;
        viState.pVertexBindingDescriptions = &vin.inputDescript;
        viState.vertexAttributeDescriptionCount = cast(uint) vin.iad.length;
        viState.pVertexAttributeDescriptions = &vin.iad[0];
    }

    /// Texture binding to use rendering.
    void bindTexture(ITexture texture) @safe
    {

    }

    void bindBuffer(IBuffer buffer) @safe
    {

    }

    /// Framebuffer output to the window surface.
    void drawning() @safe
    {

    }

    void setFrameBuffer(IFrameBuffer) @safe
    {
        
    }

    IFrameBuffer cmainFrameBuffer() @safe
    {
        return null;
    }

    void setCMainFrameBuffer(IFrameBuffer fb) @safe
    {
        if (fb is null)
        {
            
        }
        else
        {
            
        }
    }

    /// Creates a shader.
    IShaderManip createShader(StageType stage) @safe
    {
        return new VkShader(this, stage);
    }

    /// Create a shader program.
    IShaderProgram createShaderProgram() @safe
    {
        return new VkShaderProgram(this);
    }

    IShaderPipeline createShaderPipeline() @trusted
    {
        return new VkShaderPipeline(this);
    }

    /// Buffer creation.
    IBuffer createBuffer(BufferType buffType = BufferType.array) @safe
    {
        return new VkGBuffer(this, buffType);
    }

    /// Create an immutable buffer.
    immutable(IBuffer) createImmutableBuffer(BufferType buffType = BufferType.array, inout void[] data = null) @safe
    {
        return null;
    }

    /// Generates information about buffer binding to vertices.
    IVertexInfo createVertexInfo() @safe
    {
        return new VkVertexIn(this);
    }

    /// Create a texture.
    ITexture createTexture(TextureType tt) @safe
    {
        return null;
    }

    IFrameBuffer createFrameBuffer() @safe
    {
        return null;
    }

    IFrameBuffer mainFrameBuffer() @safe
    {
        return null;
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