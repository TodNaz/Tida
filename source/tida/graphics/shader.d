module tida.graphics.shader;

// SPIRV C++ INTERFACE

import core.stdcpp.vector;
import core.stdcpp.string;

alias spvc_context = void*;
alias spvc_compiler = void*;
alias spvc_parsed_ir = void*;
alias spvc_compiler_options = void*;

enum spvc_backend
{
	/* This backend can only perform reflection, no compiler options are supported. Maps to spirv_cross::Compiler. */
	SPVC_BACKEND_NONE = 0,
	SPVC_BACKEND_GLSL = 1, /* spirv_cross::CompilerGLSL */
	SPVC_BACKEND_HLSL = 2, /* CompilerHLSL */
	SPVC_BACKEND_MSL = 3, /* CompilerMSL */
	SPVC_BACKEND_CPP = 4, /* CompilerCPP */
	SPVC_BACKEND_JSON = 5, /* CompilerReflection w/ JSON backend */
	SPVC_BACKEND_INT_MAX = 0x7fffffff
}

enum spvc_capture_mode
{
	/* The Parsed IR payload will be copied, and the handle can be reused to create other compiler instances. */
	SPVC_CAPTURE_MODE_COPY = 0,

	/*
	 * The payload will now be owned by the compiler.
	 * parsed_ir should now be considered a dead blob and must not be used further.
	 * This is optimal for performance and should be the go-to option.
	 */
	SPVC_CAPTURE_MODE_TAKE_OWNERSHIP = 1,
}

struct spvc_buffer_range
{
	uint index;
	size_t offset;
	size_t range;
}

enum SPVC_COMPILER_OPTION_COMMON_BIT = 0x1000000;
enum SPVC_COMPILER_OPTION_GLSL_BIT = 0x2000000;
enum SPVC_COMPILER_OPTION_HLSL_BIT = 0x4000000;
enum SPVC_COMPILER_OPTION_MSL_BIT = 0x8000000;
enum SPVC_COMPILER_OPTION_LANG_BITS = 0x0f000000;
enum SPVC_COMPILER_OPTION_ENUM_BITS = 0xffffff;

enum spvc_compiler_option
{
	SPVC_COMPILER_OPTION_UNKNOWN = 0,

	SPVC_COMPILER_OPTION_FORCE_TEMPORARY = 1 | SPVC_COMPILER_OPTION_COMMON_BIT,
	SPVC_COMPILER_OPTION_FLATTEN_MULTIDIMENSIONAL_ARRAYS = 2 | SPVC_COMPILER_OPTION_COMMON_BIT,
	SPVC_COMPILER_OPTION_FIXUP_DEPTH_CONVENTION = 3 | SPVC_COMPILER_OPTION_COMMON_BIT,
	SPVC_COMPILER_OPTION_FLIP_VERTEX_Y = 4 | SPVC_COMPILER_OPTION_COMMON_BIT,

	SPVC_COMPILER_OPTION_GLSL_SUPPORT_NONZERO_BASE_INSTANCE = 5 | SPVC_COMPILER_OPTION_GLSL_BIT,
	SPVC_COMPILER_OPTION_GLSL_SEPARATE_SHADER_OBJECTS = 6 | SPVC_COMPILER_OPTION_GLSL_BIT,
	SPVC_COMPILER_OPTION_GLSL_ENABLE_420PACK_EXTENSION = 7 | SPVC_COMPILER_OPTION_GLSL_BIT,
	SPVC_COMPILER_OPTION_GLSL_VERSION = 8 | SPVC_COMPILER_OPTION_GLSL_BIT,
	SPVC_COMPILER_OPTION_GLSL_ES = 9 | SPVC_COMPILER_OPTION_GLSL_BIT,
	SPVC_COMPILER_OPTION_GLSL_VULKAN_SEMANTICS = 10 | SPVC_COMPILER_OPTION_GLSL_BIT,
	SPVC_COMPILER_OPTION_GLSL_ES_DEFAULT_FLOAT_PRECISION_HIGHP = 11 | SPVC_COMPILER_OPTION_GLSL_BIT,
	SPVC_COMPILER_OPTION_GLSL_ES_DEFAULT_INT_PRECISION_HIGHP = 12 | SPVC_COMPILER_OPTION_GLSL_BIT,

	SPVC_COMPILER_OPTION_HLSL_SHADER_MODEL = 13 | SPVC_COMPILER_OPTION_HLSL_BIT,
	SPVC_COMPILER_OPTION_HLSL_POINT_SIZE_COMPAT = 14 | SPVC_COMPILER_OPTION_HLSL_BIT,
	SPVC_COMPILER_OPTION_HLSL_POINT_COORD_COMPAT = 15 | SPVC_COMPILER_OPTION_HLSL_BIT,
	SPVC_COMPILER_OPTION_HLSL_SUPPORT_NONZERO_BASE_VERTEX_BASE_INSTANCE = 16 | SPVC_COMPILER_OPTION_HLSL_BIT,

	SPVC_COMPILER_OPTION_MSL_VERSION = 17 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_TEXEL_BUFFER_TEXTURE_WIDTH = 18 | SPVC_COMPILER_OPTION_MSL_BIT,

	/* Obsolete, use SWIZZLE_BUFFER_INDEX instead. */
	SPVC_COMPILER_OPTION_MSL_AUX_BUFFER_INDEX = 19 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SWIZZLE_BUFFER_INDEX = 19 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_MSL_INDIRECT_PARAMS_BUFFER_INDEX = 20 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SHADER_OUTPUT_BUFFER_INDEX = 21 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SHADER_PATCH_OUTPUT_BUFFER_INDEX = 22 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SHADER_TESS_FACTOR_OUTPUT_BUFFER_INDEX = 23 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SHADER_INPUT_WORKGROUP_INDEX = 24 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ENABLE_POINT_SIZE_BUILTIN = 25 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_DISABLE_RASTERIZATION = 26 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_CAPTURE_OUTPUT_TO_BUFFER = 27 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SWIZZLE_TEXTURE_SAMPLES = 28 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_PAD_FRAGMENT_OUTPUT_COMPONENTS = 29 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_TESS_DOMAIN_ORIGIN_LOWER_LEFT = 30 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_PLATFORM = 31 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ARGUMENT_BUFFERS = 32 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_GLSL_EMIT_PUSH_CONSTANT_AS_UNIFORM_BUFFER = 33 | SPVC_COMPILER_OPTION_GLSL_BIT,

	SPVC_COMPILER_OPTION_MSL_TEXTURE_BUFFER_NATIVE = 34 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_GLSL_EMIT_UNIFORM_BUFFER_AS_PLAIN_UNIFORMS = 35 | SPVC_COMPILER_OPTION_GLSL_BIT,

	SPVC_COMPILER_OPTION_MSL_BUFFER_SIZE_BUFFER_INDEX = 36 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_EMIT_LINE_DIRECTIVES = 37 | SPVC_COMPILER_OPTION_COMMON_BIT,

	SPVC_COMPILER_OPTION_MSL_MULTIVIEW = 38 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_VIEW_MASK_BUFFER_INDEX = 39 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_DEVICE_INDEX = 40 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_VIEW_INDEX_FROM_DEVICE_INDEX = 41 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_DISPATCH_BASE = 42 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_DYNAMIC_OFFSETS_BUFFER_INDEX = 43 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_TEXTURE_1D_AS_2D = 44 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ENABLE_BASE_INDEX_ZERO = 45 | SPVC_COMPILER_OPTION_MSL_BIT,

	/* Obsolete. Use MSL_FRAMEBUFFER_FETCH_SUBPASS instead. */
	SPVC_COMPILER_OPTION_MSL_IOS_FRAMEBUFFER_FETCH_SUBPASS = 46 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_FRAMEBUFFER_FETCH_SUBPASS = 46 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_MSL_INVARIANT_FP_MATH = 47 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_EMULATE_CUBEMAP_ARRAY = 48 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ENABLE_DECORATION_BINDING = 49 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_FORCE_ACTIVE_ARGUMENT_BUFFER_RESOURCES = 50 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_FORCE_NATIVE_ARRAYS = 51 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_ENABLE_STORAGE_IMAGE_QUALIFIER_DEDUCTION = 52 | SPVC_COMPILER_OPTION_COMMON_BIT,

	SPVC_COMPILER_OPTION_HLSL_FORCE_STORAGE_BUFFER_AS_UAV = 53 | SPVC_COMPILER_OPTION_HLSL_BIT,

	SPVC_COMPILER_OPTION_FORCE_ZERO_INITIALIZED_VARIABLES = 54 | SPVC_COMPILER_OPTION_COMMON_BIT,

	SPVC_COMPILER_OPTION_HLSL_NONWRITABLE_UAV_TEXTURE_AS_SRV = 55 | SPVC_COMPILER_OPTION_HLSL_BIT,

	SPVC_COMPILER_OPTION_MSL_ENABLE_FRAG_OUTPUT_MASK = 56 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ENABLE_FRAG_DEPTH_BUILTIN = 57 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ENABLE_FRAG_STENCIL_REF_BUILTIN = 58 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ENABLE_CLIP_DISTANCE_USER_VARYING = 59 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_HLSL_ENABLE_16BIT_TYPES = 60 | SPVC_COMPILER_OPTION_HLSL_BIT,

	SPVC_COMPILER_OPTION_MSL_MULTI_PATCH_WORKGROUP = 61 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SHADER_INPUT_BUFFER_INDEX = 62 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_SHADER_INDEX_BUFFER_INDEX = 63 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_VERTEX_FOR_TESSELLATION = 64 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_VERTEX_INDEX_TYPE = 65 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_GLSL_FORCE_FLATTENED_IO_BLOCKS = 66 | SPVC_COMPILER_OPTION_GLSL_BIT,

	SPVC_COMPILER_OPTION_MSL_MULTIVIEW_LAYERED_RENDERING = 67 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_ARRAYED_SUBPASS_INPUT = 68 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_R32UI_LINEAR_TEXTURE_ALIGNMENT = 69 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_R32UI_ALIGNMENT_CONSTANT_ID = 70 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_HLSL_FLATTEN_MATRIX_VERTEX_INPUT_SEMANTICS = 71 | SPVC_COMPILER_OPTION_HLSL_BIT,

	SPVC_COMPILER_OPTION_MSL_IOS_USE_SIMDGROUP_FUNCTIONS = 72 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_EMULATE_SUBGROUPS = 73 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_FIXED_SUBGROUP_SIZE = 74 | SPVC_COMPILER_OPTION_MSL_BIT,
	SPVC_COMPILER_OPTION_MSL_FORCE_SAMPLE_RATE_SHADING = 75 | SPVC_COMPILER_OPTION_MSL_BIT,

	SPVC_COMPILER_OPTION_INT_MAX = 0x7fffffff
}

enum SpvDecoration
{
	SpvDecorationRelaxedPrecision = 0,
    SpvDecorationSpecId = 1,
    SpvDecorationBlock = 2,
    SpvDecorationBufferBlock = 3,
    SpvDecorationRowMajor = 4,
    SpvDecorationColMajor = 5,
    SpvDecorationArrayStride = 6,
    SpvDecorationMatrixStride = 7,
    SpvDecorationGLSLShared = 8,
    SpvDecorationGLSLPacked = 9,
    SpvDecorationCPacked = 10,
    SpvDecorationBuiltIn = 11,
    SpvDecorationNoPerspective = 13,
    SpvDecorationFlat = 14,
    SpvDecorationPatch = 15,
    SpvDecorationCentroid = 16,
    SpvDecorationSample = 17,
    SpvDecorationInvariant = 18,
    SpvDecorationRestrict = 19,
    SpvDecorationAliased = 20,
    SpvDecorationVolatile = 21,
    SpvDecorationConstant = 22,
    SpvDecorationCoherent = 23,
    SpvDecorationNonWritable = 24,
    SpvDecorationNonReadable = 25,
    SpvDecorationUniform = 26,
    SpvDecorationUniformId = 27,
    SpvDecorationSaturatedConversion = 28,
    SpvDecorationStream = 29,
    SpvDecorationLocation = 30,
    SpvDecorationComponent = 31,
    SpvDecorationIndex = 32,
    SpvDecorationBinding = 33,
    SpvDecorationDescriptorSet = 34,
    SpvDecorationOffset = 35,
    SpvDecorationXfbBuffer = 36,
    SpvDecorationXfbStride = 37,
    SpvDecorationFuncParamAttr = 38,
    SpvDecorationFPRoundingMode = 39,
    SpvDecorationFPFastMathMode = 40,
    SpvDecorationLinkageAttributes = 41,
    SpvDecorationNoContraction = 42,
    SpvDecorationInputAttachmentIndex = 43,
    SpvDecorationAlignment = 44,
    SpvDecorationMaxByteOffset = 45,
    SpvDecorationAlignmentId = 46,
    SpvDecorationMaxByteOffsetId = 47,
    SpvDecorationNoSignedWrap = 4469,
    SpvDecorationNoUnsignedWrap = 4470,
    SpvDecorationExplicitInterpAMD = 4999,
    SpvDecorationOverrideCoverageNV = 5248,
    SpvDecorationPassthroughNV = 5250,
    SpvDecorationViewportRelativeNV = 5252,
    SpvDecorationSecondaryViewportRelativeNV = 5256,
    SpvDecorationPerPrimitiveNV = 5271,
    SpvDecorationPerViewNV = 5272,
    SpvDecorationPerTaskNV = 5273,
    SpvDecorationPerVertexNV = 5285,
    SpvDecorationNonUniform = 5300,
    SpvDecorationNonUniformEXT = 5300,
    SpvDecorationRestrictPointer = 5355,
    SpvDecorationRestrictPointerEXT = 5355,
    SpvDecorationAliasedPointer = 5356,
    SpvDecorationAliasedPointerEXT = 5356,
    SpvDecorationReferencedIndirectlyINTEL = 5602,
    SpvDecorationCounterBuffer = 5634,
    SpvDecorationHlslCounterBufferGOOGLE = 5634,
    SpvDecorationHlslSemanticGOOGLE = 5635,
    SpvDecorationUserSemantic = 5635,
    SpvDecorationUserTypeGOOGLE = 5636,
    SpvDecorationRegisterINTEL = 5825,
    SpvDecorationMemoryINTEL = 5826,
    SpvDecorationNumbanksINTEL = 5827,
    SpvDecorationBankwidthINTEL = 5828,
    SpvDecorationMaxPrivateCopiesINTEL = 5829,
    SpvDecorationSinglepumpINTEL = 5830,
    SpvDecorationDoublepumpINTEL = 5831,
    SpvDecorationMaxReplicatesINTEL = 5832,
    SpvDecorationSimpleDualPortINTEL = 5833,
    SpvDecorationMergeINTEL = 5834,
    SpvDecorationBankBitsINTEL = 5835,
    SpvDecorationForcePow2DepthINTEL = 5836,
    SpvDecorationMax = 0x7fffffff,
}

// struct spvc_reflected_resource
// {
	
// }

struct spvc_specialization_constant
{
	uint id;
	uint constant_id;
}

alias spvc_resources = void*;

enum spvc_resource_type
{
	SPVC_RESOURCE_TYPE_UNKNOWN = 0,
	SPVC_RESOURCE_TYPE_UNIFORM_BUFFER = 1,
	SPVC_RESOURCE_TYPE_STORAGE_BUFFER = 2,
	SPVC_RESOURCE_TYPE_STAGE_INPUT = 3,
	SPVC_RESOURCE_TYPE_STAGE_OUTPUT = 4,
	SPVC_RESOURCE_TYPE_SUBPASS_INPUT = 5,
	SPVC_RESOURCE_TYPE_STORAGE_IMAGE = 6,
	SPVC_RESOURCE_TYPE_SAMPLED_IMAGE = 7,
	SPVC_RESOURCE_TYPE_ATOMIC_COUNTER = 8,
	SPVC_RESOURCE_TYPE_PUSH_CONSTANT = 9,
	SPVC_RESOURCE_TYPE_SEPARATE_IMAGE = 10,
	SPVC_RESOURCE_TYPE_SEPARATE_SAMPLERS = 11,
	SPVC_RESOURCE_TYPE_ACCELERATION_STRUCTURE = 12,
	SPVC_RESOURCE_TYPE_RAY_QUERY = 13,
	SPVC_RESOURCE_TYPE_INT_MAX = 0x7fffffff
}

struct spvc_reflected_resource
{
	uint id;
	uint base_type_id;
	uint type_id;
	const char *name;
}

extern(C)
{
    alias spvc_context_create_f = int function(spvc_context*);
    alias spvc_context_destroy_f = void function(spvc_context);
    alias spvc_context_create_compiler_f = int function(spvc_context, spvc_backend, spvc_parsed_ir, spvc_capture_mode, spvc_compiler*);
    alias spvc_context_parse_spirv_f = int function(spvc_context context, const uint *spirv, size_t word_count,
                                                    spvc_parsed_ir *parsed_ir);
    alias spvc_compiler_compile_f = int function(spvc_compiler, char** source);
    alias spvc_compiler_create_compiler_options_f = int function(spvc_compiler, spvc_compiler_options*);
    alias spvc_compiler_install_compiler_options_f = int function(spvc_compiler, spvc_compiler_options);
    alias spvc_compiler_options_set_uint_f = int function(spvc_compiler_options, spvc_compiler_option, uint);
	alias spvc_compiler_get_active_buffer_ranges_f = int function(spvc_compiler, uint, spvc_buffer_range**, size_t* num);
	alias spvc_compiler_get_buffer_block_decorations_f = int function(spvc_compiler, uint, SpvDecoration**, size_t*);
	alias spvc_compiler_get_specialization_constants_f = int function(spvc_compiler, spvc_specialization_constant**, size_t*);
	alias spvc_compiler_create_shader_resources_f = int function(spvc_compiler, spvc_resources*);
	alias spvc_resources_get_resource_list_for_type_f = int function(spvc_resources, spvc_resource_type, spvc_reflected_resource**, size_t*);
}

__gshared
{
    spvc_context_create_f spvc_context_create;
    spvc_context_destroy_f spvc_context_destroy;
    spvc_context_create_compiler_f spvc_context_create_compiler;
    spvc_context_parse_spirv_f spvc_context_parse_spirv;
    spvc_compiler_compile_f spvc_compiler_compile;
    spvc_compiler_create_compiler_options_f spvc_compiler_create_compiler_options;
    spvc_compiler_install_compiler_options_f spvc_compiler_install_compiler_options;
    spvc_compiler_options_set_uint_f spvc_compiler_options_set_uint;
	spvc_compiler_get_active_buffer_ranges_f spvc_compiler_get_active_buffer_ranges;
	spvc_compiler_get_buffer_block_decorations_f spvc_compiler_get_buffer_block_decorations;
	spvc_compiler_get_specialization_constants_f spvc_compiler_get_specialization_constants;
	spvc_compiler_create_shader_resources_f spvc_compiler_create_shader_resources;
	spvc_resources_get_resource_list_for_type_f spvc_resources_get_resource_list_for_type;
}

enum ShaderSourceType
{
    GLSL,
    HLSL
}

spvc_backend backengFromType(ShaderSourceType type)
{
    final switch(type)
    {
        case ShaderSourceType.GLSL: return spvc_backend.SPVC_BACKEND_GLSL;
        case ShaderSourceType.HLSL: return spvc_backend.SPVC_BACKEND_HLSL;
    }
}

import bindbc.loader;

__gshared
{
    SharedLib lib;
}

void spirvLoad()
{
    version(Windows)
    {
        lib = load("spirv-cross-c-shared.dll");
    }

    if (lib == invalidHandle)
    {
        throw new Exception("[SPIRV-CROSS] Not find require spirv-cross-c-shared library!");
    }

    lib.bindSymbol(cast(void**) &spvc_context_create, "spvc_context_create");
    lib.bindSymbol(cast(void**) &spvc_context_destroy, "spvc_context_destroy");
    lib.bindSymbol(cast(void**) &spvc_context_create_compiler, "spvc_context_create_compiler");
    lib.bindSymbol(cast(void**) &spvc_context_parse_spirv, "spvc_context_parse_spirv");
    lib.bindSymbol(cast(void**) &spvc_compiler_compile, "spvc_compiler_compile");
    lib.bindSymbol(cast(void**) &spvc_compiler_create_compiler_options, "spvc_compiler_create_compiler_options");
    lib.bindSymbol(cast(void**) &spvc_compiler_install_compiler_options, "spvc_compiler_install_compiler_options");
    lib.bindSymbol(cast(void**) &spvc_compiler_options_set_uint, "spvc_compiler_options_set_uint");
	lib.bindSymbol(cast(void**) &spvc_compiler_get_active_buffer_ranges, "spvc_compiler_get_active_buffer_ranges");
	lib.bindSymbol(cast(void**) &spvc_compiler_get_buffer_block_decorations, "spvc_compiler_get_buffer_block_decorations");
	lib.bindSymbol(cast(void**) &spvc_compiler_get_specialization_constants, "spvc_compiler_get_specialization_constants");
	lib.bindSymbol(cast(void**) &spvc_compiler_create_shader_resources, "spvc_compiler_create_shader_resources");
	lib.bindSymbol(cast(void**) &spvc_resources_get_resource_list_for_type, "spvc_resources_get_resource_list_for_type");

}

struct UBInfo
{
	uint id;
	spvc_buffer_range[] ranges;

	size_t sizeBuffer() @safe
	{
		size_t result;
		foreach (e; ranges) {
			result += e.range;
			if (e.range % 16 != 0)
			{
				result += 16 - e.range;
			}
		}

		return result;
	}
}

class ShaderCompiler
{
    spvc_context ctx;
    spvc_parsed_ir pir;
    spvc_compiler compiler;
    ShaderSourceType srcType;

    this(ShaderSourceType type)
    {
        if (lib == invalidHandle)
        {
            spirvLoad();
        }

        spvc_context_create(&ctx);
        this.srcType = type;
    }

    ~this()
    {
        spvc_context_destroy(ctx);
    }

	UBInfo[] ubos;

	void uboSetup(void[] data) @trusted
	{
		if (spvc_context_parse_spirv(ctx, cast(uint*) data.ptr, data.length / uint.sizeof, &pir) != 0)
        {
            throw new Exception("[SPIRV-CROSS] Error parse SPIR-V code!");
        }

		if (spvc_context_create_compiler(ctx, srcType.backengFromType, pir, spvc_capture_mode.SPVC_CAPTURE_MODE_COPY, &compiler) != 0)
        {
            throw new Exception("[SPIRV-CROSS] Error create compiler!");
        }

		spvc_resources _rs;
		spvc_reflected_resource* rs;
		size_t numRS;
		if (spvc_compiler_create_shader_resources(compiler, &_rs))
		{
			throw new Exception("Not create shader resources!");
		}

		spvc_resources_get_resource_list_for_type(_rs, spvc_resource_type.SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, &rs, &numRS);
		if (numRS != 0)
		{
			foreach (e; rs[0 .. numRS])
			{
				UBInfo info;
				info.id = e.id;

				spvc_buffer_range* ranges;
				size_t numRanges;
				spvc_compiler_get_active_buffer_ranges(compiler, e.id, &ranges, &numRanges);
				info.ranges = ranges[0 .. numRanges];

				ubos ~= info;
			}
		}
	}

    string compile(void[] data)
    {
        import std.conv : to;

        if (spvc_context_parse_spirv(ctx, cast(uint*) data.ptr, data.length / uint.sizeof, &pir) != 0)
        {
            throw new Exception("[SPIRV-CROSS] Error parse SPIR-V code!");
        }

        if (spvc_context_create_compiler(ctx, srcType.backengFromType, pir, spvc_capture_mode.SPVC_CAPTURE_MODE_COPY, &compiler) != 0)
        {
            throw new Exception("[SPIRV-CROSS] Error create compiler!");
        }

        spvc_compiler_options on;
        spvc_compiler_create_compiler_options(compiler, &on);
        spvc_compiler_options_set_uint(on, spvc_compiler_option.SPVC_COMPILER_OPTION_HLSL_SHADER_MODEL, 50);
        spvc_compiler_install_compiler_options(compiler, on);

		char* src;
        if (spvc_compiler_compile(compiler, &src) != 0)
        {
            throw new Exception("[SPIRV-CROSS] Error compile SPIRV to source!");		
        }

		spvc_resources _rs;
		spvc_reflected_resource* rs;
		size_t numRS;
		if (spvc_compiler_create_shader_resources(compiler, &_rs))
		{
			throw new Exception("Not create shader resources!");
		}

		spvc_resources_get_resource_list_for_type(_rs, spvc_resource_type.SPVC_RESOURCE_TYPE_UNIFORM_BUFFER, &rs, &numRS);
		if (numRS != 0)
		{
			foreach (e; rs[0 .. numRS])
			{
				UBInfo info;
				info.id = e.id;

				spvc_buffer_range* ranges;
				size_t numRanges;
				spvc_compiler_get_active_buffer_ranges(compiler, e.id, &ranges, &numRanges);
				info.ranges = ranges[0 .. numRanges];

				ubos ~= info;
			}
		}

        return to!(string)(src);
    }
}