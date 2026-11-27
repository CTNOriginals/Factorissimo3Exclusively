---Settings to tweak the scenario with.
---A game keeps the scripts it was started with, so changes only apply to new games.

local M = {}

-- Inputs

---Items that may be fed onto belts, anything else is removed from the input combinators
M.allowedItems = {
	"iron-ore",
	"copper-ore",
	"coal",
	"stone",
	"uranium-ore",
}

---Fluids that may be fed into pipes, anything else is removed from the input combinators
M.allowedFluids = {
	"water",
	"crude-oil",
}

---Resources that cost a fluid to bring in, like mining them does in vanilla.
---Picking one builds a pipe through the wall beside the gap, which the fluid has to be delivered to.
---@type {[string]: InputCost}
M.inputCosts = {
	["uranium-ore"] = { fluid = "sulfuric-acid", amount = 1 },
}

---Ticks between feeds of the active inputs
M.feedInterval = 1

---Ticks between target checks of the inputs that have a signal but nothing to feed
M.retryInterval = 300

---Fluid per second that a single input feeds, so throughput takes more inputs like it does for items.
---Water matches an offshore pump, crude oil a decent oil field of around 8 pumpjacks.
---@type {[string]: number}
M.fluidRates = {
	["water"] = 1200,
	["crude-oil"] = 150,
}

---Fluid per second for allowed fluids that are missing from fluidRates
M.defaultFluidRate = 100

---Tiles around the player that the editor commands search, like /setup-inputs for wall gaps
M.setupRadius = 64

-- Research

---Technologies that are researched by mining a resource, which is impossible here, get one of these goals instead.
---A goal is reached when the force has the amount stored: fluids in storage tanks, items in chests.
---@type ResearchGoal[]
M.researchGoals = {
	{ technology = "oil-processing", kind = "fluid", name = "crude-oil", amount = 50000 },
	{ technology = "uranium-processing", kind = "item", name = "uranium-ore", amount = 500 },
}

---Ticks between checks of the research goals.
---Keep it different from feedInterval and retryInterval, which are registered separately and would replace it.
M.researchCheckInterval = 60

-- Spawn

---Where players spawn and respawn, inside the factory.
---The spawn set on this surface in the map editor is used instead, as long as it is inside a factory.
M.spawn = {
	surface = "nauvis-factory-floor",
	position = { x = 0, y = 0 },
}

---A character found on one of these surfaces is moved back to the spawn
M.outsideSurfaces = { "nauvis" }

return M
