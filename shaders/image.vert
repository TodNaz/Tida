/*
Шейдер отрисовки текстуры.
*/
#version 420
layout (location = 0) in vec2 position;
layout (location = 1) in vec2 texCoord;

layout (location = 0) out vec2 oTexCoord;

layout (binding = 0) uniform UBO 
{
	mat4 projection;
	mat4 model;
} ubo;

void main()
{
	gl_Position = ubo.projection * ubo.model * vec4(position, 0.0, 1.0);

    oTexCoord = texCoord;
}
