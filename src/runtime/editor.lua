-- Commands for building the scenario map, which only work in the map editor.
-- Running them again is harmless, so they can be part of setting up a new map.

local const = require("shared.constants")
local config = require("shared.config")
local utils = require("shared.utils")

---Moves the power pole that Factorissimo places beside the entrance to the middle of it,
---so it is out of the way. Factorissimo keeps track of the pole itself, so it keeps working after the move.
---@param command CustomCommandData
local function onCenterPowerPoleCommand(command)
	local player = game.get_player(command.player_index)
	if not player or not utils.RequireEditor(player, command.name) then
		return
	end

	local surface = player.surface
	local area = utils.AreaAround(player.position, config.setupRadius)
	local pole = surface.find_entities_filtered({ area = area, name = const.factoryPowerPole, limit = 1 })[1]
	local entrance = surface.find_tiles_filtered({ area = area, name = const.entranceTile })

	if not pole or #entrance == 0 then
		player.print({ "message.power-pole-not-found" })
		return
	end

	-- The entrance is in the bottom wall, so only its horizontal middle is needed
	local left, right = math.huge, -math.huge
	for _, tile in pairs(entrance) do
		left = math.min(left, tile.position.x)
		right = math.max(right, tile.position.x + 1)
	end

	pole.teleport({ (left + right) / 2, pole.position.y })
	player.print({ "message.power-pole-centered" })
end

commands.add_command(const.commands.centerPowerPole, { "command-help.center-power-pole" }, onCenterPowerPoleCommand)
