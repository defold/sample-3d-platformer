#ifndef PLATFORMER_SHADOWED_LIGHTING_GLSL
#define PLATFORMER_SHADOWED_LIGHTING_GLSL

vec3 shadowed_diffuse_lambert(vec3 view_normal, vec3 view_position)
{
	vec3 total_light = vec3(0.0);
	int light_count = int(light_info.w);
	for (int i = 0; i < MAX_LIGHT_COUNT; ++i)
	{
		if (i >= light_count)
		{
			break;
		}

		vec3 contribution = diffuse_lambert(i, view_normal, view_position);
		if (int(lights[i].params.x) == LIGHT_DIRECTIONAL)
		{
			highp vec3 direction_to_light = -world_to_view_dir(lights[i].direction_range.xyz);
			contribution *= directional_shadow_visibility(
				shadow_map,
				var_shadow_coord,
				shadow_texel_size.xy,
				shadow_params,
				view_normal,
				direction_to_light
			);
		}
		total_light += contribution;
	}
	return total_light;
}

#endif
