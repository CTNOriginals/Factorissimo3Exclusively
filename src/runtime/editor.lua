-- Commands for building the scenario map, which only work in the map editor.

local const = require("shared.constants")
local config = require("shared.config")
local utils = require("shared.utils")
local floor = require("runtime.floor")

---Builds the main factory floor with its power pole and input combinators.
---Everything in the area is removed first, so it is meant for a new map.
---@param command CustomCommandData
local function onSetupFloorCommand(command)
	local player = game.get_player(command.player_index)
	if not player or not utils.RequireEditor(player, command.name) then
		return
	end

	local surface = game.get_surface(config.floor.surface)
	if not surface then
		player.print({ "message.floor-surface-missing", config.floor.surface })
		return
	end

	local placed = floor.build(surface, player.force --[[@as LuaForce]])
	if not placed then
		player.print({ "message.floor-layout-missing", config.floor.layout })
		return
	end

	player.print({ "message.floor-built", surface.name, placed })
end

commands.add_command(const.commands.setupFloor, { "command-help.setup-floor" }, onSetupFloorCommand)
