-- Places an input combinator behind every gap in the factory walls.
--
-- A gap is a single tile in the outer wall line: a tile with void behind it,
-- whose two neighbours along the wall are a different tile (the wall).
-- Wall tiles and the wider entrance are skipped, since they have a neighbour of the same tile along the wall.

local const = require("shared.constants")
local config = require("shared.config")
local utils = require("shared.utils")

local M = {}

---@class (exact) WallSide
---@field out MapPosition Offset from the gap to the void tile behind it
---@field facing defines.direction Direction a combinator on the void tile faces, back at the gap
---@field along MapPosition[] Offsets from the gap to its neighbours along the wall

---@type WallSide[]
local wallSides = {
	{ out = { x = 0, y = -1 }, facing = defines.direction.south, along = { { x = -1, y = 0 }, { x = 1, y = 0 } } },
	{ out = { x = 0, y = 1 }, facing = defines.direction.north, along = { { x = -1, y = 0 }, { x = 1, y = 0 } } },
	{ out = { x = -1, y = 0 }, facing = defines.direction.east, along = { { x = 0, y = -1 }, { x = 0, y = 1 } } },
	{ out = { x = 1, y = 0 }, facing = defines.direction.west, along = { { x = 0, y = -1 }, { x = 0, y = 1 } } },
}

---@param surface LuaSurface
---@param position MapPosition
---@return string
local function getTileName(surface, position)
	return surface.get_tile(position.x, position.y).name
end

---True if both tiles along the wall differ from the gap tile, so the gap is one tile wide
---@param surface LuaSurface
---@param position MapPosition
---@param tileName string
---@param side WallSide
---@return boolean
local function isSingleGap(surface, position, tileName, side)
	for _, offset in ipairs(side.along) do
		if getTileName(surface, utils.OffsetPosition(position, offset)) == tileName then
			return false
		end
	end

	return true
end

---Places a locked input combinator on the tile if it has none yet
---@param surface LuaSurface
---@param force LuaForce
---@param tilePosition TilePosition
---@param direction defines.direction
---@return boolean placed
local function tryPlace(surface, force, tilePosition, direction)
	local position = { x = tilePosition.x + 0.5, y = tilePosition.y + 0.5 }
	if surface.count_entities_filtered({ position = position, name = const.inputEntity }) > 0 then
		return false
	end

	local entity = surface.create_entity({
		name = const.inputEntity,
		position = position,
		direction = direction,
		force = force,
	})
	if not entity then
		return false
	end

	entity.destructible = false
	entity.minable_flag = false
	return true
end

---Places input combinators behind every gap within config.setupRadius of the center
---@param surface LuaSurface
---@param force LuaForce
---@param center MapPosition
---@return integer placed
M.placeCombinators = function(surface, force, center)
	local radius = config.setupRadius
	local area = {
		{ center.x - radius, center.y - radius },
		{ center.x + radius, center.y + radius },
	}
	local placed = 0

	local tiles = surface.find_tiles_filtered({ area = area, name = const.voidTile, invert = true })
	for _, tile in pairs(tiles) do
		local position = tile.position

		for _, side in ipairs(wallSides) do
			local behind = utils.OffsetPosition(position, side.out)

			if getTileName(surface, behind) == const.voidTile
				and isSingleGap(surface, position, tile.name, side)
				and tryPlace(surface, force, behind, side.facing)
			then
				placed = placed + 1
			end
		end
	end

	return placed
end

return M
