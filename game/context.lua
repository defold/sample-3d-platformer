---Runtime addresses for objects created with the game collection.
---With `script.shared_state` enabled, this module acts as a small address book
---for scripts that communicate through `msg.post()`.
---@class GameContext
---@field ui url|nil Gameplay GUI component.
---@field sounds url|nil Per-client sound component.
---@field local_player hash|nil Locally authoritative player game object.
---@field game url|nil Replicated round-state component.
---@field camera url|nil Local camera-follow component.
---@field shadows url|nil Directional-shadow setup component.
---@field player_visual_factories url[]|nil Character factories indexed by replicated variant.
---@type GameContext
local M = {
	ui = nil,
	sounds = nil,
	local_player = nil,
	game = nil,
	camera = nil,
	shadows = nil,
	player_visual_factories = nil
}

return M
