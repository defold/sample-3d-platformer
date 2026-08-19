#version 140

in highp vec4 var_position;
in mediump vec3 var_normal;
in mediump vec2 var_texcoord0;
in highp mat4 var_view;
in highp vec4 var_shadow_coord;

out vec4 out_fragColor;

uniform mediump sampler2D tex0;
uniform highp sampler2D shadow_map;

// x: render depth caster pass, y: receive directional shadows.
uniform fs_uniforms
{
	highp vec4 shadow_pass;
	highp vec4 shadow_texel_size;
	highp vec4 shadow_params;
};

#define MAX_LIGHT_COUNT 8
#include "/builtins/materials/lighting.glsl"
#include "/shadow_mapping/materials/directional_shadows.glsl"
#include "/shadow_mapping/materials/shadowed_lighting.glsl"

void main()
{
	vec4 color = texture(tex0, var_texcoord0);
	if (shadow_pass.x > 0.5)
	{
		if (color.a < 0.1)
		{
			discard;
		}
		out_fragColor = vec4(1.0);
		return;
	}

	vec3 view_normal = normalize(var_normal);
	vec3 diffuse_light = diffuse_lambert(view_normal, var_position.xyz);
	if (shadow_pass.y > 0.5)
	{
		diffuse_light = shadowed_diffuse_lambert(view_normal, var_position.xyz);
	}
	vec3 lighting = ambient_light() + diffuse_light;
	out_fragColor = vec4(color.rgb * lighting, color.a);
}
