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
