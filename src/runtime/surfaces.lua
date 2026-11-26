-- The scenario map is limited to the factory building, and new surfaces inherit that map size.
-- This lifts the limit from every other surface (planets, sandboxes of other mods), so they generate like normal.

local config = require("shared.config")
local const = require("shared.constants")
local utils = require("shared.utils")

local limitedSurfaces = utils.ToSet(config.limitedSurfaces)

---@param name string
---@return boolean
local function isFactoryFloor(name)
	local suffix = const.factoryFloorSuffix
	return name:sub(-#suffix) == suffix
end

---@param surface LuaSurface?
local function unlimitSize(surface)
	if not surface or limitedSurfaces[surface.name] or isFactoryFloor(surface.name) then
		return
	end

	local settings = surface.map_gen_settings
	settings.width = const.unlimitedMapSize
	settings.height = const.unlimitedMapSize
	surface.map_gen_settings = settings
end

local function onInit()
	for _, surface in pairs(game.surfaces) do
		unlimitSize(surface)
	end
end

---@param event EventData.on_surface_created
local function onSurfaceCreated(event)
	unlimitSize(game.get_surface(event.surface_index))
end

return {
	on_init = onInit,
	events = {
		[defines.events.on_surface_created] = onSurfaceCreated,
	},
}
