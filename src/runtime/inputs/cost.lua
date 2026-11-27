-- Some resources cost a fluid to bring in, like uranium ore needs sulfuric acid to be mined in vanilla.
--
-- Picking such a resource builds pipes around the combinator in the void, with a pipe to ground on each side
-- that faces the factory. The player connects to either one with a pipe to ground of their own inside the wall,
-- and every item fed takes its cost out of those pipes.
--
-- For an input in the bottom wall, seen from above (# wall, G gap, C combinator, U pipe to ground, = pipe):
--   # # G # #
--     U C U
--     = = =

local const = require("shared.constants")
local config = require("shared.config")
local utils = require("shared.utils")

---@class (exact) InputCost
---@field fluid string
---@field amount number Fluid per item fed

---@class (exact) InputCostPipes
---@field entities LuaEntity[]
---@field source LuaEntity The pipe behind the combinator, which the fluid is taken from

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

---Draws the pipe behind the combinator as connected to it, to show the fluid goes into it.
---Skipped when the sprite is missing, since it comes from the mod around the scenario.
---The drawing is removed along with the pipe.
---@param combinator LuaEntity
---@param pipe LuaEntity
local function drawConnection(combinator, pipe)
	local sprite = const.pipeConnectionSprites[combinator.direction]
	if not sprite or not helpers.is_valid_sprite_path(sprite) then
		return
	end

	rendering.draw_sprite({
		sprite = sprite,
		target = pipe,
		surface = pipe.surface,
		render_layer = "higher-object-under",
	})
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
	local outward = negate(inward)
	local behind = utils.OffsetPosition(combinator.position, outward)

	-- The pipe behind the combinator goes first, since it is the source
	local parts = {
		{ name = "pipe", position = behind },
	}

	for _, side in ipairs({ { x = inward.y, y = inward.x }, { x = -inward.y, y = -inward.x } }) do
		-- Its underground side faces the factory, to be met by a pipe to ground inside the wall
		local beside = utils.OffsetPosition(combinator.position, side)
		table.insert(parts, { name = "pipe-to-ground", position = beside, direction = getDirection(outward) })
		table.insert(parts, { name = "pipe", position = utils.OffsetPosition(behind, side) })
	end

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

	drawConnection(combinator, entities[1])

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

	-- A pipe has a single fluid storage, and the count above made sure it holds the cost fluid
	pipes.source.remove_fluid(1, cost.amount)
	return true
end

return M
