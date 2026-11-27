-- Sets the spawn of every force on the main factory floor.
-- The spawn set in the map editor is kept as long as it is on the floor, otherwise config.spawn.position is used.
-- New players also start with cheat mode off.

local const = require("shared.constants")
local config = require("shared.config")

---Returns the force's spawn on the surface if it is on the floor, or the spawn from the config
---@param force LuaForce
---@param surface LuaSurface
---@return MapPosition
local function getSpawnPosition(force, surface)
	local position = force.get_spawn_position(surface)

	if surface.get_tile(position.x, position.y).name == const.voidTile then
		return config.spawn.position
	end

	return position
end

---@param force LuaForce
local function setForceSpawn(force)
	local surface = game.get_surface(config.floor.surface)
	if surface then
		force.set_spawn_position(getSpawnPosition(force, surface), surface)
	end
end

local function setAllForceSpawns()
	for _, force in pairs(game.forces) do
		setForceSpawn(force)
	end
end

---@param event EventData.on_player_created
local function onPlayerCreated(event)
	local player = game.get_player(event.player_index)
	if player then
		player.cheat_mode = false
	end
end

---Forces created later (e.g. by other mods) also spawn on the floor
---@param event EventData.on_force_created
local function onForceCreated(event)
	setForceSpawn(event.force)
end

return {
	on_init = setAllForceSpawns,
	on_configuration_changed = setAllForceSpawns,
	events = {
		[defines.events.on_player_created] = onPlayerCreated,
		[defines.events.on_force_created] = onForceCreated,
	},
}
