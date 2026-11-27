-- Some resources cost a fluid to bring in, like uranium ore needs sulfuric acid to be mined in vanilla.
--
-- Picking such a resource builds a pipe from behind the combinator, through the void and under the wall,
-- that comes up in the wall tile beside the gap. The fluid has to be piped in there from inside the factory,
-- and every item fed takes its cost out of that pipe.
--
-- For an input in the bottom wall, seen from above (# wall, G gap, C combinator, U pipe to ground, = pipe):
--   # U G #
--     U C
--     = =

local const = require("shared.constants")
local config = require("shared.config")
local utils = require("shared.utils")

---@class (exact) InputCost
---@field fluid string
---@field amount number Fluid per item fed

---@class (exact) InputCostPipes
---@field entities LuaEntity[]
---@field source LuaEntity The pipe end in the wall, which the fluid is taken from

local M = {}

---@param offset MapPosition
---@return MapPosition
local function negate(offset)
	return { x = -offset.x, y = -offset.y }
end

---@param offset MapPosition
---@return defines.direction?
local function getDirection(offset)
	for direction, directionOffset in pairs(const.directionOffsets) do
		if directionOffset.x == offset.x and directionOffset.y == offset.y then
			return direction
		end
	end

	return nil
end

---Returns the side of the gap that has a wall tile for the pipe to come up in
---@param surface LuaSurface
---@param gap MapPosition
---@param inward MapPosition
---@return MapPosition?
local function findWallSide(surface, gap, inward)
	local gapTile = surface.get_tile(gap.x, gap.y).name

	for _, side in ipairs({ { x = inward.y, y = inward.x }, { x = -inward.y, y = -inward.x } }) do
		local position = utils.OffsetPosition(gap, side)
		local tile = surface.get_tile(position.x, position.y).name

		if tile ~= const.voidTile and tile ~= gapTile then
			return side
		end
	end

	return nil
end

---Returns the fluid cost of the resource, if it has one
---@param kind InputKind
---@param name string
---@return InputCost?
M.get = function(kind, name)
	if kind ~= "item" then
		return nil
	end

	return config.inputCosts[name]
end

---Builds the pipe for the fluid cost of the combinator
---@param combinator LuaEntity
---@return InputCostPipes?
M.build = function(combinator)
	local inward = const.directionOffsets[combinator.direction]
	if not inward then
		return nil
	end

	local surface = combinator.surface
	local gap = utils.OffsetPosition(combinator.position, inward)
	local side = findWallSide(surface, gap, inward)
	if not side then
		return nil
	end

	local outward = negate(inward)
	local beside = utils.OffsetPosition(combinator.position, side)

	local parts = {
		{ name = "pipe-to-ground", position = utils.OffsetPosition(gap, side), direction = getDirection(inward) },
		{ name = "pipe-to-ground", position = beside, direction = getDirection(outward) },
		{ name = "pipe", position = utils.OffsetPosition(beside, outward) },
		{ name = "pipe", position = utils.OffsetPosition(combinator.position, outward) },
	}

	---@type LuaEntity[]
	local entities = {}

	for _, part in ipairs(parts) do
		-- Left behind by an earlier build that is no longer tracked
		for _, existing in pairs(surface.find_entities_filtered({ position = part.position, name = part.name })) do
			existing.destroy()
		end

		local entity = surface.create_entity({
			name = part.name,
			position = part.position,
			direction = part.direction,
			force = combinator.force,
		})

		if entity then
			entity.destructible = false
			entity.minable_flag = false
			entity.rotatable = false
			table.insert(entities, entity)
		end
	end

	if #entities ~= #parts then
		M.remove({ entities = entities, source = entities[1] })
		return nil
	end

	return { entities = entities, source = entities[1] }
end

---@param pipes InputCostPipes
M.remove = function(pipes)
	for _, entity in ipairs(pipes.entities) do
		if entity.valid then
			entity.destroy()
		end
	end
end

---Takes the cost out of the pipes, false if there is not enough fluid
---@param cost InputCost
---@param pipes InputCostPipes?
---@return boolean paid
M.pay = function(cost, pipes)
	if not pipes or not pipes.source.valid then
		return false
	end

	if pipes.source.get_fluid_count(cost.fluid) < cost.amount then
		return false
	end

	pipes.source.remove_fluid({ name = cost.fluid, amount = cost.amount })
	return true
end

return M
