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

---Ticks between feeds of the active inputs
M.feedInterval = 1

---Ticks between target checks of the inputs that have a signal but nothing to feed
M.retryInterval = 300

---Fluid inserted per feed, capped by what the pipe can hold
M.fluidPerFeed = 1000

---Tiles around the player that /setup-inputs searches for wall gaps
M.setupRadius = 64

-- Spawn

---Where players spawn and respawn, inside the factory
M.spawn = {
	surface = "nauvis-factory-floor",
	position = { x = 0, y = 0 },
}

---A character found on one of these surfaces is moved back to the spawn
M.outsideSurfaces = { "nauvis" }

-- Surfaces

---Surfaces that keep the map size of the scenario map.
---Every other surface, except the factory floors, generates without a size limit.
M.limitedSurfaces = { "nauvis" }

return M
