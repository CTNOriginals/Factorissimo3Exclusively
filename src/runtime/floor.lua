-- The main factory floor is built on the surface itself rather than inside a Factorissimo factory.
-- That way, factories built on it count as built in the open world and need no recursion research,
-- while the factories inside those follow Factorissimo's rules as usual.
--
-- It copies the shape of a Factorissimo factory in its own colours: the walls and their gaps, and the entrance
-- as a wall platform that holds the power pole. It imitates what Factorissimo does inside its factories:
-- one power pole that powers the whole floor, darkness until the lights upgrade
-- and no solar power until the greenhouse upgrade.

local const = require("shared.constants")
local config = require("shared.config")
local setup = require("runtime.inputs.setup")

local M = {}

---@class (exact) FloorRect
---@field x1 integer
---@field y1 integer
---@field x2 integer Exclusive
---@field y2 integer Exclusive

---@return LuaSurface?
local function getSurface()
	return game.get_surface(config.floor.surface)
end

---@param tiles Tile[]
---@param name string
---@param rect FloorRect
local function addRect(tiles, name, rect)
	for x = rect.x1, rect.x2 - 1 do
		for y = rect.y1, rect.y2 - 1 do
			table.insert(tiles, { name = name, position = { x, y } })
		end
	end
end

---@param rect FloorRect
---@param bounds FloorRect
---@return boolean
local function isInside(rect, bounds)
	return rect.x1 >= bounds.x1 and rect.y1 >= bounds.y1 and rect.x2 <= bounds.x2 and rect.y2 <= bounds.y2
end

---Returns the wall tile, or the fallback when the configured one does not exist
---@return string
local function getWallTile()
	if prototypes.tile[config.floor.wallTile] then
		return config.floor.wallTile
	end

	return config.floor.fallbackWallTile
end

---Builds the floor around 0, 0 in the shape of the Factorissimo layout, with its power pole and input combinators.
---Everything in the area is removed first. The entrance is filled in with wall, since there is no outside to go to,
---and the pole stands on it.
---@param surface LuaSurface
---@param force LuaForce
---@return integer? placed Input combinators placed, nil if Factorissimo has no such layout
M.build = function(surface, force)
	local layout = remote.call("factorissimo", "create_layout", config.floor.layout, prototypes.quality.normal)
	if not layout then
		return nil
	end

	-- The outer wall, which every other part of the floor fits in, except the entrance
	---@type FloorRect
	local outer = layout.rectangles[1]
	local wallTile = getWallTile()
	local margin = 2
	local area = {
		{ outer.x1 - margin, outer.y1 - margin },
		{ outer.x2 + margin, outer.y2 + margin },
	}

	-- The area can reach past the generated chunks on a small map
	local radius = math.ceil(math.max(-outer.x1, -outer.y1, outer.x2, outer.y2) / 32) + 1
	surface.request_to_generate_chunks({ 0, 0 }, radius)
	surface.force_generate_chunk_requests()

	for _, entity in pairs(surface.find_entities_filtered({ area = area })) do
		if entity.valid and entity.type ~= "character" then
			entity.destroy()
		end
	end
	surface.destroy_decoratives({ area = area })

	---@type Tile[]
	local tiles = {}
	addRect(tiles, const.voidTile, {
		x1 = outer.x1 - margin,
		y1 = outer.y1 - margin,
		x2 = outer.x2 + margin,
		y2 = outer.y2 + margin,
	})

	-- Only the floor itself is floor, everything else (the walls and the entrance) becomes wall.
	-- The number pattern on the floor is left out.
	---@type FloorRect?
	local entrance
	for _, rect in ipairs(layout.rectangles) do
		local isFloor = rect.tile == layout.connection_tile and isInside(rect, outer)
		addRect(tiles, isFloor and config.floor.floorTile or wallTile, rect)

		if not isInside(rect, outer) then
			entrance = rect
		end
	end
	for _, connection in pairs(layout.connections) do
		table.insert(tiles, { name = config.floor.floorTile, position = { connection.inside_x, connection.inside_y } })
	end

	surface.set_tiles(tiles)

	-- On the entrance platform, in the row Factorissimo puts its own pole in
	local poleX = entrance and (entrance.x1 + entrance.x2) / 2 or 0
	local pole = surface.create_entity({
		name = const.floorPole,
		position = { poleX, layout.inside_energy_y },
		force = force,
	})
	if pole then
		pole.destructible = false
		pole.minable_flag = false
	end

	return setup.placeCombinators(surface, force, { x = 0, y = 0 })
end

-- Upgrades

---@param force LuaForce
---@param name string
---@return boolean
local function hasResearched(force, name)
	local technology = force.technologies[name]
	return technology ~= nil and technology.researched
end

---Applies the lights and greenhouse upgrades to the floor, like Factorissimo does inside its factories
local function applyUpgrades()
	local surface = getSurface()
	local force = game.forces[config.floor.force]
	if not surface or not force then
		return
	end

	surface.daytime = hasResearched(force, const.factorissimo.lightsTechnology) and 1 or 0.5
	surface.freeze_daytime = true

	-- Stored once, since the property is changed below
	storage.floorSolarPower = storage.floorSolarPower or surface.get_property("solar-power")
	local hasGreenhouse = hasResearched(force, const.factorissimo.greenhouseTechnology)
	surface.set_property("solar-power", hasGreenhouse and storage.floorSolarPower / 2 or 0)
end

---@param event EventData.on_research_finished | EventData.on_research_reversed
local function onResearchChanged(event)
	local name = event.research.name
	if name == const.factorissimo.lightsTechnology or name == const.factorissimo.greenhouseTechnology then
		applyUpgrades()
	end
end

M.on_init = applyUpgrades
M.on_configuration_changed = applyUpgrades
M.events = {
	[defines.events.on_research_finished] = onResearchChanged,
	[defines.events.on_research_reversed] = onResearchChanged,
}

return M
