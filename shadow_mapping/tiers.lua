local M = {}

M.LOW = "low_material"
M.MID = "mid_material"
M.HIGH = "high_material"
M.ULTRA = "ultra_material"

M.MSG_DECIDE = hash("MSG_DECIDE")

local current_tier = M.HIGH
local ultra_enabled = false
local materials = {}

---@param tier string
function M.change_tier(tier)
	current_tier = tier
end

---@param enabled boolean
function M.configure_ultra(enabled)
	ultra_enabled = enabled
end

---@return boolean
function M.is_ultra_enabled()
	return ultra_enabled
end

---@param name string
---@return string
function M.get_tier_for_material(name)
	if not materials[name] then
		materials[name] = {}
		materials[name][M.LOW] = name .. "_" .. M.LOW
		materials[name][M.MID] = name .. "_" .. M.MID
		materials[name][M.HIGH] = name .. "_" .. M.HIGH
		materials[name][M.ULTRA] = name .. "_" .. M.ULTRA
	end
	return materials[name][current_tier]
end

---@return boolean
function M.is_shadows_ignored()
	return M.LOW == current_tier
end

---@return boolean
function M.is_ultra_tier()
	return M.ULTRA == current_tier
end

---@return boolean
function M.is_high_tier()
	return M.HIGH == current_tier
end

---@return boolean
function M.is_mid_tier()
	return M.MID == current_tier
end

return M
