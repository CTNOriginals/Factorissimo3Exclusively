-- Keeps the players inside the factory.
-- On joining, respawning and leaving the map editor, a character outside is moved to the spawn.
-- The spawn is the force's spawn on the factory floor, as set in the map editor,
-- unless that is not inside a factory, then it falls back to config.spawn.position.

local const = require("shared.constants")
local config = require("shared.config")
local utils = require("shared.utils")

local outsideSurfaces = utils.ToSet(config.outsideSurfaces)

---@return LuaSurface?
local function getSpawnSurface()
	return game.get_surface(config.spawn.surface)
end

---Returns the force's spawn on the surface if it is inside a factory, or the spawn from the config
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

---@param player LuaPlayer?
local function moveToSpawn(player)
	if not player or not player.valid or not player.character then
		return
	end

	if not outsideSurfaces[player.character.surface.name] then
		return
	end

	local surface = getSpawnSurface()
	if not surface then
		player.print({ "message.spawn-surface-missing", config.spawn.surface })
		return
	end

	local spawn = getSpawnPosition(player.force --[[@as LuaForce]], surface)
	local position = surface.find_non_colliding_position("character", spawn, 10, 0.5)
	player.teleport(position or spawn, surface)
end

---@param force LuaForce
local function setForceSpawn(force)
	local surface = getSpawnSurface()
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
	if not player then
		return
	end

	player.cheat_mode = false
	moveToSpawn(player)
end

---@param event EventData.on_player_respawned
local function onPlayerRespawned(event)
	moveToSpawn(game.get_player(event.player_index))
end

---@param event EventData.on_player_toggled_map_editor
local function onToggledMapEditor(event)
	local player = game.get_player(event.player_index)
	if player and player.controller_type ~= defines.controllers.editor then
		moveToSpawn(player)
	end
end

---Forces created later (e.g. by other mods) also respawn inside the factory
---@param event EventData.on_force_created
local function onForceCreated(event)
	setForceSpawn(event.force)
end

return {
	on_init = setAllForceSpawns,
	on_configuration_changed = setAllForceSpawns,
	events = {
		[defines.events.on_player_created] = onPlayerCreated,
		[defines.events.on_player_respawned] = onPlayerRespawned,
		[defines.events.on_player_toggled_map_editor] = onToggledMapEditor,
		[defines.events.on_force_created] = onForceCreated,
	},
}
