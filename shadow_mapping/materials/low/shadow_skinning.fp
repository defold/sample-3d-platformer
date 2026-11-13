#version 140

in mediump vec2 var_texcoord0;

uniform lowp sampler2D tex0;

void main()
{
	if (texture(tex0, var_texcoord0).a < 0.5)
	{
		discard;
	}
}
