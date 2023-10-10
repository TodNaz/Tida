/*
Шейдер цветового градиента.
*/
#version 420
layout (location = 0) in vec2 position;

layout (binding = 0, std140) uniform UBO 
{
	mat4 projection;
	mat4 model;
} ubo;

void main()
{
	gl_Position = ubo.projection * ubo.model * vec4(position, 0.0, 1.0);
}
