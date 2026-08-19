---Mutable resources and settings owned by the render-script instance.
---@class ShadowMappingState
---@field shadow_model_pred any
---@field shadow_model_skinned_pred any
---@field shadow_target any|nil
---@field shadow_target_name string|nil
---@field shadow_target_resolution number|nil
---@field shadow_camera url|nil
---@field ultra_resolution number
---@field high_resolution number
---@field mid_resolution number
---@field maximum_resolution number
---@field ultra_pcf_kernel_size number
---@field high_pcf_kernel_size number
---@field mid_pcf_kernel_size number
---@field ultra_pcf_sample_spacing number
---@field high_pcf_sample_spacing number
---@field mid_pcf_sample_spacing number
---@field polygon_offset_factor number
---@field polygon_offset_units number
---@field receiver_min_bias number
---@field receiver_slope_bias number
---@field clip_to_texture matrix4
---@field receiver_constants any
---@field receiver_draw_options table
---@field skinned_receiver_constants any
---@field skinned_receiver_draw_options table
---@field shadow_depth_constants any
---@field shadow_depth_static_draw_options table
---@field shadow_depth_skinned_draw_options table
---@type ShadowMappingState
local M = {}
local tiers = require("shadow_mapping.tiers")

local MSG_SET_DIRECTIONAL_SHADOW = hash("set_directional_shadow")

local HIGH_BUFFER_NAME = "directional_shadow_high"
local MID_BUFFER_NAME = "directional_shadow_mid"
local ULTRA_BUFFER_NAME = "directional_shadow_ultra"
local SHADOW_MATERIAL_RESOURCE_NAME = "shadow_material"
local STATIC_MODEL_MATERIAL_RESOURCE_NAME = "static_model"
local SKINNED_MODEL_MATERIAL_RESOURCE_NAME = "skinned_model"
local SHADOW_SAMPLER = "shadow_map"
local MODEL_PREDICATE_NAME = "shadow_model"
local MODEL_PREDICATE_SKINNED_NAME = "shadow_model_skinned"

local DEFAULT_ULTRA_RESOLUTION = 8192
local DEFAULT_HIGH_RESOLUTION = 4096
local DEFAULT_MID_RESOLUTION = 2048
local DEFAULT_ULTRA_PCF_KERNEL_SIZE = 5
local DEFAULT_HIGH_PCF_KERNEL_SIZE = 3
local DEFAULT_MID_PCF_KERNEL_SIZE = 1
local DEFAULT_ULTRA_PCF_SAMPLE_SPACING = 0.75
local DEFAULT_HIGH_PCF_SAMPLE_SPACING = 0.75
local DEFAULT_MID_PCF_SAMPLE_SPACING = 1.0
local DEFAULT_POLYGON_OFFSET_FACTOR = 2.0
local DEFAULT_POLYGON_OFFSET_UNITS = 4.0
local DEFAULT_RECEIVER_MIN_BIAS = 0.0002
local DEFAULT_RECEIVER_SLOPE_BIAS = 0.0015

---@param kernel_size number
---@return boolean
local function is_valid_pcf_kernel_size(kernel_size)
	return kernel_size == 1 or kernel_size == 3 or kernel_size == 5
end

---@return matrix4
local function create_clip_to_texture_matrix()
	local matrix = vmath.matrix4()
	matrix.c0 = vmath.vector4(0.5, 0.0, 0.0, 0.0)
	matrix.c1 = vmath.vector4(0.0, 0.5, 0.0, 0.0)
	matrix.c2 = vmath.vector4(0.0, 0.0, 0.5, 0.0)
	matrix.c3 = vmath.vector4(0.5, 0.5, 0.5, 1.0)
	return matrix
end

---@param name string
---@param resolution number
---@return any
local function create_depth_target(name, resolution)
	local depth_params = {
		format = graphics.TEXTURE_FORMAT_DEPTH,
		width = resolution,
		height = resolution,
		min_filter = graphics.TEXTURE_FILTER_NEAREST,
		mag_filter = graphics.TEXTURE_FILTER_NEAREST,
		u_wrap = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		v_wrap = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		flags = render.TEXTURE_BIT,
	}
	return render.render_target(name, {
		[graphics.BUFFER_TYPE_DEPTH_BIT] = depth_params,
	})
end

---Releases the tier-dependent depth target before replacing or disabling it.
local function release_shadow_target()
	if M.shadow_target then
		render.delete_render_target(M.shadow_target)
		M.shadow_target = nil
		M.shadow_target_name = nil
		M.shadow_target_resolution = nil
	end
end

---@return string
---@return number
local function get_target_properties()
	if tiers.is_ultra_tier() then
		return ULTRA_BUFFER_NAME, math.min(M.ultra_resolution, M.maximum_resolution)
	end
	if tiers.is_high_tier() then
		return HIGH_BUFFER_NAME, math.min(M.high_resolution, M.maximum_resolution)
	end
	if tiers.is_mid_tier() then
		return MID_BUFFER_NAME, math.min(M.mid_resolution, M.maximum_resolution)
	end
	return HIGH_BUFFER_NAME, math.min(M.high_resolution, M.maximum_resolution)
end

---@return any|nil
local function get_shadow_target()
	if tiers.is_shadows_ignored() or not M.shadow_camera then
		release_shadow_target()
		return nil
	end

	local name, resolution = get_target_properties()
	if M.shadow_target and M.shadow_target_name == name and M.shadow_target_resolution == resolution then
		return M.shadow_target
	end

	release_shadow_target()
	M.shadow_target = create_depth_target(name, resolution)
	M.shadow_target_name = name
	M.shadow_target_resolution = resolution
	print("Shadow target created:", name, resolution)
	return M.shadow_target
end

---Updates values shared by the static and skinned shadow receivers.
local function update_receiver_constants()
	local kernel_size = M.high_pcf_kernel_size
	local sample_spacing = M.high_pcf_sample_spacing
	if tiers.is_ultra_tier() then
		kernel_size = M.ultra_pcf_kernel_size
		sample_spacing = M.ultra_pcf_sample_spacing
	elseif tiers.is_mid_tier() then
		kernel_size = M.mid_pcf_kernel_size
		sample_spacing = M.mid_pcf_sample_spacing
	end
	local texel_size = 1.0 / M.shadow_target_resolution
	local shadow_texel_size = vmath.vector4(texel_size, texel_size, 0.0, 0.0)
	local shadow_params = vmath.vector4(
		kernel_size,
		sample_spacing,
		M.receiver_min_bias,
		M.receiver_slope_bias
	)
	M.receiver_constants.shadow_texel_size = shadow_texel_size
	M.receiver_constants.shadow_params = shadow_params
	M.skinned_receiver_constants.shadow_texel_size = shadow_texel_size
	M.skinned_receiver_constants.shadow_params = shadow_params
end

---Creates predicates and constant buffers owned by the render pipeline.
function M.init()
	local adapter_info = graphics.get_adapter_info()
	local limits = adapter_info.limits
	M.shadow_model_pred = render.predicate({ MODEL_PREDICATE_NAME })
	M.shadow_model_skinned_pred = render.predicate({ MODEL_PREDICATE_SKINNED_NAME })
	M.shadow_target = nil
	M.shadow_target_name = nil
	M.shadow_target_resolution = nil
	M.shadow_camera = nil
	M.ultra_resolution = DEFAULT_ULTRA_RESOLUTION
	M.high_resolution = DEFAULT_HIGH_RESOLUTION
	M.mid_resolution = DEFAULT_MID_RESOLUTION
	M.maximum_resolution = math.floor(math.min(
		limits.max_texture_size_2d,
		limits.max_framebuffer_width,
		limits.max_framebuffer_height
	))
	M.ultra_pcf_kernel_size = DEFAULT_ULTRA_PCF_KERNEL_SIZE
	M.high_pcf_kernel_size = DEFAULT_HIGH_PCF_KERNEL_SIZE
	M.mid_pcf_kernel_size = DEFAULT_MID_PCF_KERNEL_SIZE
	M.ultra_pcf_sample_spacing = DEFAULT_ULTRA_PCF_SAMPLE_SPACING
	M.high_pcf_sample_spacing = DEFAULT_HIGH_PCF_SAMPLE_SPACING
	M.mid_pcf_sample_spacing = DEFAULT_MID_PCF_SAMPLE_SPACING
	M.polygon_offset_factor = DEFAULT_POLYGON_OFFSET_FACTOR
	M.polygon_offset_units = DEFAULT_POLYGON_OFFSET_UNITS
	M.receiver_min_bias = DEFAULT_RECEIVER_MIN_BIAS
	M.receiver_slope_bias = DEFAULT_RECEIVER_SLOPE_BIAS
	M.clip_to_texture = create_clip_to_texture_matrix()
	M.receiver_constants = render.constant_buffer()
	M.receiver_constants.shadow_pass = vmath.vector4(0.0, 1.0, 0.0, 0.0)
	M.receiver_draw_options = { constants = M.receiver_constants }
	M.skinned_receiver_constants = render.constant_buffer()
	M.skinned_receiver_constants.shadow_pass = vmath.vector4(0.0, 1.0, 0.0, 0.0)
	M.skinned_receiver_draw_options = { constants = M.skinned_receiver_constants }
	M.shadow_depth_constants = render.constant_buffer()
	M.shadow_depth_constants.shadow_pass = vmath.vector4(1.0, 0.0, 0.0, 0.0)
	M.shadow_depth_static_draw_options = { constants = M.shadow_depth_constants }
	M.shadow_depth_skinned_draw_options = { constants = M.shadow_depth_constants }
end

---@param message_id hash
---@param message table
---@return boolean handled
function M.on_message(message_id, message)
	if message_id ~= MSG_SET_DIRECTIONAL_SHADOW then
		return false
	end

	assert(message.camera, "set_directional_shadow requires message.camera")
	assert(message.ultra_resolution and message.ultra_resolution > 0,
		"set_directional_shadow requires a positive ultra_resolution")
	assert(message.high_resolution and message.high_resolution > 0,
		"set_directional_shadow requires a positive high_resolution")
	assert(message.mid_resolution and message.mid_resolution > 0,
		"set_directional_shadow requires a positive mid_resolution")
	M.shadow_camera = message.camera
	local ultra_resolution = math.floor(message.ultra_resolution)
	local high_resolution = math.floor(message.high_resolution)
	local mid_resolution = math.floor(message.mid_resolution)
	if M.ultra_resolution ~= ultra_resolution
		or M.high_resolution ~= high_resolution
		or M.mid_resolution ~= mid_resolution then
		M.ultra_resolution = ultra_resolution
		M.high_resolution = high_resolution
		M.mid_resolution = mid_resolution
		release_shadow_target()
	end
	M.ultra_pcf_kernel_size = message.ultra_pcf_kernel_size or M.ultra_pcf_kernel_size
	M.high_pcf_kernel_size = message.high_pcf_kernel_size or M.high_pcf_kernel_size
	M.mid_pcf_kernel_size = message.mid_pcf_kernel_size or M.mid_pcf_kernel_size
	M.ultra_pcf_sample_spacing = message.ultra_pcf_sample_spacing or M.ultra_pcf_sample_spacing
	M.high_pcf_sample_spacing = message.high_pcf_sample_spacing or M.high_pcf_sample_spacing
	M.mid_pcf_sample_spacing = message.mid_pcf_sample_spacing or M.mid_pcf_sample_spacing
	M.polygon_offset_factor = message.polygon_offset_factor or M.polygon_offset_factor
	M.polygon_offset_units = message.polygon_offset_units or M.polygon_offset_units
	M.receiver_min_bias = message.receiver_min_bias or M.receiver_min_bias
	M.receiver_slope_bias = message.receiver_slope_bias or M.receiver_slope_bias
	assert(is_valid_pcf_kernel_size(M.ultra_pcf_kernel_size), "ultra_pcf_kernel_size must be 1, 3, or 5")
	assert(is_valid_pcf_kernel_size(M.high_pcf_kernel_size), "high_pcf_kernel_size must be 1, 3, or 5")
	assert(is_valid_pcf_kernel_size(M.mid_pcf_kernel_size), "mid_pcf_kernel_size must be 1, 3, or 5")
	assert(M.ultra_pcf_sample_spacing >= 0.0, "ultra_pcf_sample_spacing must be non-negative")
	assert(M.high_pcf_sample_spacing >= 0.0, "high_pcf_sample_spacing must be non-negative")
	assert(M.mid_pcf_sample_spacing >= 0.0, "mid_pcf_sample_spacing must be non-negative")
	return true
end

---@param camera_url url
---@return boolean|nil
function M.is_shadow_camera(camera_url)
	return M.shadow_camera and camera_url == M.shadow_camera
end

---Restores baseline GPU state before the frame's default target is cleared.
function M.prerender()
	render.set_color_mask(true, true, true, true)
	render.set_depth_func(graphics.COMPARE_FUNC_LEQUAL)
end

---Renders static and skinned casters into the directional depth texture.
function M.render_shadow()
	local shadow_target = get_shadow_target()
	if not shadow_target then
		return
	end

	local shadow_view = camera.get_view(M.shadow_camera)
	local shadow_projection = camera.get_projection(M.shadow_camera)
	local shadow_frustum = shadow_projection * shadow_view
	local shadow_matrix = M.clip_to_texture * shadow_frustum
	M.receiver_constants.mtx_shadow = shadow_matrix
	M.skinned_receiver_constants.mtx_shadow = shadow_matrix
	update_receiver_constants()

	render.set_render_target(shadow_target)
	render.set_viewport(0, 0, M.shadow_target_resolution, M.shadow_target_resolution)
	render.set_camera()
	render.set_view(shadow_view)
	render.set_projection(shadow_projection)
	render.set_color_mask(false, false, false, false)
	render.set_depth_mask(true)
	render.set_depth_func(graphics.COMPARE_FUNC_LEQUAL)
	render.enable_state(graphics.STATE_DEPTH_TEST)
	render.enable_state(graphics.STATE_CULL_FACE)
	render.set_cull_face(graphics.FACE_TYPE_BACK)
	render.disable_state(graphics.STATE_BLEND)
	render.enable_state(graphics.STATE_POLYGON_OFFSET_FILL)
	render.set_polygon_offset(M.polygon_offset_factor, M.polygon_offset_units)
	render.clear({
		[graphics.BUFFER_TYPE_DEPTH_BIT] = 1.0,
	})

	M.shadow_depth_static_draw_options.frustum = shadow_frustum
	M.shadow_depth_static_draw_options.frustum_planes = render.FRUSTUM_PLANES_ALL
	render.enable_material(SHADOW_MATERIAL_RESOURCE_NAME)
	render.draw(M.shadow_model_pred, M.shadow_depth_static_draw_options)
	render.disable_material()
	-- Animated component bounds can lag behind the skinned pose. Avoid CPU
	-- frustum rejection here and let the shadow-camera raster pass clip it.
	render.draw(M.shadow_model_skinned_pred, M.shadow_depth_skinned_draw_options)

	render.set_polygon_offset(0.0, 0.0)
	render.disable_state(graphics.STATE_POLYGON_OFFSET_FILL)
	render.set_color_mask(true, true, true, true)
	render.set_render_target(render.RENDER_TARGET_DEFAULT)
end

---Draws lit shadow receivers into the display camera target.
---@param view matrix4
---@param projection matrix4|nil
---@param frustum matrix4
function M.render_shadow_model(view, projection, frustum)
	if not projection then
		return
	end

	local shadow_target = get_shadow_target()
	render.set_projection(projection)
	render.set_view(view)
	render.enable_state(graphics.STATE_DEPTH_TEST)
	render.disable_state(graphics.STATE_STENCIL_TEST)
	render.disable_state(graphics.STATE_CULL_FACE)
	render.set_cull_face(graphics.FACE_TYPE_BACK)
	render.set_depth_mask(true)
	render.disable_state(graphics.STATE_BLEND)

	if shadow_target then
		render.enable_texture(SHADOW_SAMPLER, shadow_target, graphics.BUFFER_TYPE_DEPTH_BIT)
	end
	M.receiver_draw_options.frustum = frustum
	M.skinned_receiver_draw_options.frustum = frustum
	render.enable_material(tiers.get_tier_for_material(STATIC_MODEL_MATERIAL_RESOURCE_NAME))
	render.draw(M.shadow_model_pred, M.receiver_draw_options)
	render.disable_material()
	render.enable_material(tiers.get_tier_for_material(SKINNED_MODEL_MATERIAL_RESOURCE_NAME))
	render.draw(M.shadow_model_skinned_pred, M.skinned_receiver_draw_options)
	render.disable_material()
	if shadow_target then
		render.disable_texture(SHADOW_SAMPLER)
	end
end

return M
