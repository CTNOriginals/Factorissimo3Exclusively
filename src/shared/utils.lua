local M = {}

---Returns a lookup table with every value of the list as a key
---@generic T
---@param list T[]
---@return {[T]: true}
M.ToSet = function(list)
	local set = {}

	for _, value in ipairs(list) do
		set[value] = true
	end

	return set
end

---True if the player is in the map editor, where the commands for building the scenario are allowed.
---Prints a message saying so otherwise.
---@param player LuaPlayer
---@param command string Name of the command, for the message
---@return boolean
M.RequireEditor = function(player, command)
	if player.controller_type == defines.controllers.editor then
		return true
	end

	player.print({ "message.command-editor-only", command })
	return false
end

---Area of the given radius around the position
---@param position MapPosition
---@param radius number
---@return BoundingBox
M.AreaAround = function(position, radius)
	return {
		{ position.x - radius, position.y - radius },
		{ position.x + radius, position.y + radius },
	}
end

---@param position MapPosition
---@param offset MapPosition
---@return MapPosition
M.OffsetPosition = function(position, offset)
	return {
		x = position.x + offset.x,
		y = position.y + offset.y,
	}
end

return M
