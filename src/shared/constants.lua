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

-- Surfaces

---Factorissimo names its factory floor surfaces "<planet>-factory-floor"
M.factoryFloorSuffix = "-factory-floor"

---The default map width and height, which is no limit in practice
M.unlimitedMapSize = 2000000

-- GUI

M.gui = {}
M.gui.prefix = M.name .. "-"
M.gui.inputFrame = M.gui.prefix .. "input"
---Tag key that holds the action of an element, prefixed so elements of other mods are never mistaken for ours
M.gui.actionTag = M.gui.prefix .. "action"

-- Commands

M.commands = {}
M.commands.setupInputs = "setup-inputs"

return M
