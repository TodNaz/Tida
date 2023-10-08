/*
Шейдер цветового градиента.
*/
#version 420

// Соглашение о стандартныйх fragment данных.
layout (binding = 0) uniform Color
{
	vec4 color;
	vec2 size;
} clr;

layout (location = 0) out vec4 fragColor;

void main()
{
	fragColor = clr.color;
}
