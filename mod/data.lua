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
