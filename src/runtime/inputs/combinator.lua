-- Reads and cleans up a single input combinator.

local const = require("shared.constants")
local config = require("shared.config")
local utils = require("shared.utils")
local research = require("runtime.research")

local M = {}

---@type {[InputKind]: {[string]: true}}
local allowedSignals = {
	item = utils.ToSet(config.allowedItems),
	fluid = utils.ToSet(config.allowedFluids),
}

---A signal without a type is an item, like in the game
---@param signal SignalID
---@return string
local function getSignalType(signal)
	return signal.type or "item"
end

---True if the signal is an allowed resource that the force has unlocked
---@param signal SignalID
---@param force LuaForce
---@return boolean
local function isAllowed(signal, force)
	local kind = getSignalType(signal)
	local names = allowedSignals[kind]
	return names ~= nil and names[signal.name] == true and research.isUnlocked(force, kind, signal.name)
end

---@param section LuaLogisticSection
---@return boolean
local function isGrouped(section)
	return section.group ~= nil and section.group ~= ""
end

---True if the entity is a constant combinator standing on a void tile
---@param entity LuaEntity?
---@return boolean
M.isInput = function(entity)
	return entity ~= nil
		and entity.valid
		and entity.name == const.inputEntity
		and entity.surface.get_tile(entity.position).name == const.voidTile
end

---Returns the entity in front of the combinator that can take the kind of signal
---@param entity LuaEntity
---@param kind InputKind
---@return LuaEntity?
M.findTarget = function(entity, kind)
	local offset = const.directionOffsets[entity.direction]
	local types = const.targetTypes[kind]
	if not offset or not types then
		return nil
	end

	return entity.surface.find_entities_filtered({
		position = utils.OffsetPosition(entity.position, offset),
		type = types,
		limit = 1,
	})[1]
end

---Clears every slot that holds anything other than an allowed item or fluid.
---Sections of a logistic group are skipped, since clearing them would change every combinator in the group.
---@param behavior LuaConstantCombinatorControlBehavior
M.removeInvalidSignals = function(behavior)
	for _, section in pairs(behavior.sections) do
		if not isGrouped(section) then
			for index = 1, section.filters_count do
				local signal = section.get_slot(index).value
				if signal and signal.name and not isAllowed(signal, behavior.entity.force --[[@as LuaForce]]) then
					section.clear_slot(index)
				end
			end
		end
	end
end

---False if the combinator is disabled by a script, switched off, or its first section is off
---@param entity LuaEntity
---@param behavior LuaConstantCombinatorControlBehavior?
---@return boolean
M.isEnabled = function(entity, behavior)
	if not behavior or entity.disabled_by_script or not behavior.enabled then
		return false
	end

	local section = behavior.get_section(1)
	return section ~= nil and section.active
end

---Returns the kind and name of the allowed signal in the first slot of the first section
---@param behavior LuaConstantCombinatorControlBehavior
---@return InputKind?, string?
M.getSelectedSignal = function(behavior)
	local section = behavior.get_section(1)
	if not section then
		return nil
	end

	local signal = section.get_slot(1).value
	if not signal or not signal.name or not isAllowed(signal, behavior.entity.force --[[@as LuaForce]]) then
		return nil
	end

	return getSignalType(signal) --[[@as InputKind]], signal.name
end

return M
