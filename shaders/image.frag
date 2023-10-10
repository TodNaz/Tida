/*
Шейдер цветового градиента.
*/
#version 420

layout (location = 0) in vec2 texCoord;

// Соглашение о стандартныйх fragment данных.
layout (binding = 1) uniform Color
{
	vec4 color;
	vec2 size;
} clr;

layout (binding = 0) uniform sampler2D texture0;

layout (location = 0) out vec4 fragColor;

void main()
{
	fragColor = texture(texture0, texCoord) * clr.color;
}
