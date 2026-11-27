-- A scenario has no data stage, so the prototypes it needs are defined by the mod around it.

-- Inputs linked to the controls on Q, so the scenario can close its gui with them
data:extend({
	{
		type = "custom-input",
		name = "factorissimo3-exclusively-clear-cursor",
		key_sequence = "",
		linked_game_control = "clear-cursor",
	},
	{
		type = "custom-input",
		name = "factorissimo3-exclusively-pipette",
		key_sequence = "",
		linked_game_control = "pipette",
	},
})

-- Pipe pictures with a connection on one side, drawn by the scenario over the acid pipe behind an input,
-- so it looks connected to the combinator
for _, side in ipairs({ "up", "down", "left", "right" }) do
	data:extend({
		{
			type = "sprite",
			name = "factorissimo3-exclusively-pipe-t-" .. side,
			filename = "__base__/graphics/entity/pipe/pipe-t-" .. side .. ".png",
			priority = "extra-high",
			width = 128,
			height = 128,
			scale = 0.5,
		},
	})
end

-- The main factory floor is not a real factory, so it gets its own copy of the power pole inside factories:
-- one pole that powers the whole floor. It is not hidden, since Factorissimo only connects the power of
-- factories built on the floor to poles that are not.
local factoryPole = data.raw["electric-pole"]["factory-power-pole"]
if factoryPole then
	local pole = table.deepcopy(factoryPole)
	pole.name = "factorissimo3-exclusively-floor-pole"
	pole.localised_name = { "entity-name.factory-power-pole" }
	pole.hidden = false
	pole.hidden_in_factoriopedia = true
	data:extend({ pole })
end
