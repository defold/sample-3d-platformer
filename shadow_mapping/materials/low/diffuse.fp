#version 140

in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
in highp mat4 var_view;
in highp vec4 var_shadow_coord;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;

#define MAX_LIGHT_COUNT 8
#include "/builtins/materials/lighting.glsl"

void main()
{
	vec4 color = texture(tex0, var_texcoord0);
	vec3 view_normal = normalize(var_normal);
	vec3 lighting = ambient_light() + diffuse_lambert(view_normal, var_position.xyz);
	out_fragColor = vec4(color.rgb * lighting, color.a);
}
