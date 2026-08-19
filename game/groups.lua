---Physics collision groups shared by gameplay scripts.
---@class CollisionGroups
---@field PLAYER hash Player collision objects.
---@field PLATFORM hash Static and moving surfaces that support the player.
---@type CollisionGroups
local M = {}

M.PLAYER = hash("player")
M.PLATFORM = hash("platform")

return M
