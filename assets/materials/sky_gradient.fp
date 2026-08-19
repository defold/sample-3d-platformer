#version 140

in mediump float var_screen_height;

out vec4 out_fragColor;

#define LOWER_COLOR vec3(0.46, 0.47, 0.80)
#define HORIZON_COLOR vec3(0.65, 0.69, 0.91)
#define UPPER_COLOR vec3(0.83, 0.84, 0.97)

void main()
{
	mediump float height = var_screen_height * 0.5 + 0.5;
	mediump vec3 color = mix(LOWER_COLOR, HORIZON_COLOR, smoothstep(0.0, 0.62, height));
	color = mix(color, UPPER_COLOR, smoothstep(0.48, 1.0, height));
	out_fragColor = vec4(color, 1.0);
}
