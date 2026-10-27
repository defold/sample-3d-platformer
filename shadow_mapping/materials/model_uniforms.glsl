#ifndef PLATFORMER_MODEL_UNIFORMS_GLSL
#define PLATFORMER_MODEL_UNIFORMS_GLSL

// Keep the block identical in both shader stages. The camera matrices are
// constant for a draw and do not need to occupy interpolated varying slots.
uniform vs_uniforms
{
	highp mat4 mtx_view;
	highp mat4 mtx_proj;
	highp mat4 mtx_shadow;
};

// Defold's lighting helpers expect the view matrix under this name.
#define var_view mtx_view

#endif
