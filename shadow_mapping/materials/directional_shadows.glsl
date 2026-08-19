#ifndef PLATFORMER_DIRECTIONAL_SHADOWS_GLSL
#define PLATFORMER_DIRECTIONAL_SHADOWS_GLSL

highp float directional_shadow_compare(
	sampler2D shadow_texture,
	highp vec2 uv,
	highp float receiver_depth)
{
	if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0))))
	{
		return 1.0;
	}
	highp float stored_depth = texture(shadow_texture, uv).r;
	return receiver_depth <= stored_depth ? 1.0 : 0.0;
}

highp float directional_shadow_receiver_bias(
	highp vec3 view_normal,
	highp vec3 direction_to_light,
	highp float minimum_bias,
	highp float slope_bias)
{
	highp float normal_light = max(dot(view_normal, direction_to_light), 0.0);
	return max(minimum_bias, slope_bias * (1.0 - normal_light));
}

highp float directional_shadow_pcf_3x3(
	sampler2D shadow_texture,
	highp vec2 center_uv,
	highp float receiver_depth,
	highp vec2 sample_step)
{
	highp float visibility = 0.0;
	for (int y = -1; y <= 1; ++y)
	{
		for (int x = -1; x <= 1; ++x)
		{
			highp vec2 offset = vec2(float(x), float(y)) * sample_step;
			visibility += directional_shadow_compare(shadow_texture, center_uv + offset, receiver_depth);
		}
	}
	return visibility / 9.0;
}

highp float directional_shadow_pcf_5x5(
	sampler2D shadow_texture,
	highp vec2 center_uv,
	highp float receiver_depth,
	highp vec2 sample_step)
{
	highp float visibility = 0.0;
	for (int y = -2; y <= 2; ++y)
	{
		for (int x = -2; x <= 2; ++x)
		{
			highp vec2 offset = vec2(float(x), float(y)) * sample_step;
			visibility += directional_shadow_compare(shadow_texture, center_uv + offset, receiver_depth);
		}
	}
	return visibility / 25.0;
}

highp float directional_shadow_visibility(
	sampler2D shadow_texture,
	highp vec4 shadow_coord,
	highp vec2 shadow_texel_size,
	highp vec4 shadow_params,
	highp vec3 view_normal,
	highp vec3 direction_to_light)
{
	if (shadow_coord.w <= 0.0)
	{
		return 1.0;
	}

	highp vec3 projected = shadow_coord.xyz / shadow_coord.w;
	if (any(lessThan(projected, vec3(0.0))) || any(greaterThan(projected, vec3(1.0))))
	{
		return 1.0;
	}

	highp float receiver_depth = projected.z - directional_shadow_receiver_bias(
		view_normal,
		direction_to_light,
		shadow_params.z,
		shadow_params.w
	);
	int kernel_size = int(shadow_params.x + 0.5);
	if (kernel_size == 3)
	{
		return directional_shadow_pcf_3x3(
			shadow_texture,
			projected.xy,
			receiver_depth,
			shadow_texel_size * shadow_params.y
		);
	}
	if (kernel_size == 5)
	{
		return directional_shadow_pcf_5x5(
			shadow_texture,
			projected.xy,
			receiver_depth,
			shadow_texel_size * shadow_params.y
		);
	}
	return directional_shadow_compare(shadow_texture, projected.xy, receiver_depth);
}

#endif
