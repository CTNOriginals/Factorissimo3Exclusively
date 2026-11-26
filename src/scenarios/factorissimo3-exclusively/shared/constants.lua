---@alias InputKind "item" | "fluid"

local M = {}

M.name = "factorissimo3-exclusively"

-- Tiles

---The tile outside every factory floor, where the input combinators stand
M.voidTile = "out-of-map"

-- Inputs

M.inputEntity = "constant-combinator"

---Entity types an input can feed, per signal type.
---Item targets are fed on transport lines 1 and 2, which every type listed here has.
---@type {[InputKind]: string[]}
M.targetTypes = {
	item = { "transport-belt", "underground-belt", "loader", "loader-1x1" },
	fluid = { "pipe", "pipe-to-ground" },
}

-- Directions

---Offset to the tile in front of an entity, per direction
---@type {[defines.direction]: MapPosition}
M.directionOffsets = {
	[defines.direction.north] = { x = 0, y = -1 },
	[defines.direction.east] = { x = 1, y = 0 },
	[defines.direction.south] = { x = 0, y = 1 },
	[defines.direction.west] = { x = -1, y = 0 },
}

return M
