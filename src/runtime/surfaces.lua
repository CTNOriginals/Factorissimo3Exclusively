-- The scenario map is limited to the factory building, and new surfaces inherit that map size.
-- This lifts the limit from surfaces that are not part of the challenge (like the sandboxes of other mods),
-- so they generate like normal. Planets, space platforms and factory floors are left alone.

local const = require("shared.constants")

---@param name string
---@return boolean
local function isFactoryFloor(name)
	local suffix = const.factoryFloorSuffix
	return name:sub(-#suffix) == suffix
end

---@param surface LuaSurface
---@return boolean
local function isPartOfGame(surface)
	return surface.planet ~= nil or surface.platform ~= nil or isFactoryFloor(surface.name)
end

---@param surface LuaSurface?
local function unlimitSize(surface)
	if not surface or isPartOfGame(surface) then
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
