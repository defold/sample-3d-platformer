---Message identifiers used by the gameplay collection.
---Keeping the protocol in one module prevents senders and receivers from
---silently drifting to different string hashes.
---@class GameMessages
---@field COLLISION_RESPONSE hash Defold trigger collision response.
---@field CONTACT_POINT_RESPONSE hash Defold contact-point response.
---@field COIN_COLLECTED hash Add a locally collected coin to the player score.
---@field UPDATE_COIN_UI hash Update the local confirmed-coin display.
---@field SET_GAME_GOAL hash Configure the coin target shown by the GUI.
---@field FLAG_REACHED hash Ask the round controller to validate a winner.
---@field GAME_WIN_STATE_CHANGED hash Present a winner.
---@field FOLLOW_SHADOW_TARGET hash Make the shadow camera follow a visual object.
---@field RESET_PLAYER hash Reset the locally owned player for a new round.
---@field SOUND_COIN_COLLECTED hash Play the local coin sound.
---@field SOUND_JUMP hash Play the local jump sound.
---@field SOUND_LAND hash Play the local landing sound.
---@type GameMessages
local M = {
	COLLISION_RESPONSE = hash("collision_response"),
	CONTACT_POINT_RESPONSE = hash("contact_point_response"),
	COIN_COLLECTED = hash("coin_collected"),
	UPDATE_COIN_UI = hash("update_coin_ui"),
	SET_GAME_GOAL = hash("set_game_goal"),
	FLAG_REACHED = hash("flag_reached"),
	GAME_WIN_STATE_CHANGED = hash("game_win_state_changed"),
	FOLLOW_SHADOW_TARGET = hash("follow_shadow_target"),
	RESET_PLAYER = hash("reset_player"),

	SOUND_COIN_COLLECTED = hash("sound_coin_collected"),
	SOUND_JUMP = hash("sound_jump"),
	SOUND_LAND = hash("sound_land"),
}

return M
