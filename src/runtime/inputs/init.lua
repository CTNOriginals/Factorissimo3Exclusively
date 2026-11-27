-- Input combinators: constant combinators in the void that feed resources into the factory.
--
-- The allowed signal in the first slot is fed into the entity the combinator faces:
-- items onto a belt, fluids into a pipe.
-- Opening an input combinator shows a custom gui with only the allowed resources (see gui.lua).
-- A combinator is sorted when it is changed in that gui, its gui is closed, settings are pasted onto it,
-- or an undo/redo is applied:
--   active  - has a signal and a target, fed every config.feedInterval ticks
--   waiting - has a signal but no target, retried every config.retryInterval ticks, only while any are waiting
--   neither - empty or disabled

local const = require("shared.constants")
local config = require("shared.config")
local combinator = require("runtime.inputs.combinator")
local gui = require("runtime.inputs.gui")
local setup = require("runtime.inputs.setup")

---@class (exact) ActiveInput
---@field combinator LuaEntity
---@field target LuaEntity
---@field kind InputKind
---@field name string

---@class (exact) InputStorage
---@field active {[integer]: ActiveInput} Keyed by the combinator unit number
---@field waiting {[integer]: LuaEntity} Keyed by the combinator unit number

---@type fun()
local feedInputs
---@type fun()
local retryWaitingInputs

---@return InputStorage
local function getStorage()
	storage.inputs = storage.inputs or { active = {}, waiting = {} }
	return storage.inputs
end

-- Tick handlers

local function feedAndRetry()
	feedInputs()
	retryWaitingInputs()
end

---Registers the feed loop, and the retry check while any inputs are waiting.
---Registered here instead of through event_handler, so both can share an interval.
local function updateTickHandlers()
	local hasWaiting = storage.inputs ~= nil and next(storage.inputs.waiting) ~= nil

	if config.retryInterval == config.feedInterval then
		script.on_nth_tick(config.feedInterval, hasWaiting and feedAndRetry or feedInputs)
	else
		script.on_nth_tick(config.feedInterval, feedInputs)
		script.on_nth_tick(config.retryInterval, hasWaiting and retryWaitingInputs or nil)
	end
end

-- Sorting

---Cleans up the combinator and sorts it into the active list, the waiting list, or neither
---@param entity LuaEntity
local function sortInput(entity)
	local inputs = getStorage()
	local unitNumber = entity.unit_number --[[@as integer]]
	inputs.active[unitNumber] = nil
	inputs.waiting[unitNumber] = nil

	local behavior = entity.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
	if not behavior then
		return
	end

	combinator.removeInvalidSignals(behavior)
	if not combinator.isEnabled(entity, behavior) then
		return
	end

	local kind, name = combinator.getSelectedSignal(behavior)
	if not kind or not name then
		return
	end

	local target = combinator.findTarget(entity, kind)
	if target then
		inputs.active[unitNumber] = {
			combinator = entity,
			target = target,
			kind = kind,
			name = name,
		}
	else
		inputs.waiting[unitNumber] = entity
	end
end

---@param entity LuaEntity?
local function updateInput(entity)
	if not combinator.isInput(entity) then
		return
	end
	---@cast entity LuaEntity

	sortInput(entity)
	updateTickHandlers()
end

---Sorts every input combinator on every surface
local function scanAll()
	storage.inputs = { active = {}, waiting = {} }

	for _, surface in pairs(game.surfaces) do
		for _, entity in pairs(surface.find_entities_filtered({ name = const.inputEntity })) do
			if combinator.isInput(entity) then
				sortInput(entity)
			end
		end
	end

	updateTickHandlers()
end

-- Feeding

---@param target LuaEntity
---@param name string
local function insertOnBothLanes(target, name)
	for lane = 1, 2 do
		local line = target.get_transport_line(lane)
		if line.can_insert_at_back() then
			line.insert_at_back({ name = name, count = 1 })
		end
	end
end

---@type {[InputKind]: fun(target: LuaEntity, name: string)}
local feeders = {
	item = insertOnBothLanes,
	fluid = function(target, name)
		target.insert_fluid({ name = name, amount = config.fluidPerFeed })
	end,
}

---False if the input changed in a way no event reports: its target is gone, it got disabled,
---or its signal changed (undo, blueprints, logistic groups, other scripts)
---@param input ActiveInput
---@return boolean
local function isUnchanged(input)
	if not input.target.valid then
		return false
	end

	local behavior = input.combinator.get_control_behavior() --[[@as LuaConstantCombinatorControlBehavior?]]
	if not behavior or not combinator.isEnabled(input.combinator, behavior) then
		return false
	end

	local kind, name = combinator.getSelectedSignal(behavior)
	return kind == input.kind and name == input.name
end

feedInputs = function()
	local inputs = getStorage()
	---@type LuaEntity[]
	local changed = {}

	for unitNumber, input in pairs(inputs.active) do
		if not input.combinator.valid then
			inputs.active[unitNumber] = nil
		elseif isUnchanged(input) then
			feeders[input.kind](input.target, input.name)
		else
			table.insert(changed, input.combinator)
		end
	end

	-- Sorted after the loop, since sorting adds entries to the list being looped over
	for _, entity in ipairs(changed) do
		updateInput(entity)
	end
end

retryWaitingInputs = function()
	local inputs = getStorage()

	-- Copied first, since sorting adds entries to the list being looped over
	---@type {[integer]: LuaEntity}
	local waiting = {}
	for unitNumber, entity in pairs(inputs.waiting) do
		waiting[unitNumber] = entity
	end

	for unitNumber, entity in pairs(waiting) do
		if entity.valid then
			sortInput(entity)
		else
			inputs.waiting[unitNumber] = nil
		end
	end

	updateTickHandlers()
end

-- Commands

---Places input combinators behind every wall gap of the factory the player is in.
---Only works in the map editor, as it is meant for building the scenario.
---@param command CustomCommandData
local function onSetupInputsCommand(command)
	local player = game.get_player(command.player_index)
	if not player then
		return
	end

	if player.controller_type ~= defines.controllers.editor then
		player.print({ "message.setup-inputs-editor-only" })
		return
	end

	local placed = setup.placeCombinators(player.surface, player.force --[[@as LuaForce]], player.position)
	scanAll()

	player.print({ "message.setup-inputs-placed", placed, player.surface.name })
end

commands.add_command(const.commands.setupInputs, { "command-help.setup-inputs" }, onSetupInputsCommand)

-- Events

---@param event EventData.on_gui_opened
local function onGuiOpened(event)
	if event.gui_type ~= defines.gui_type.entity or not combinator.isInput(event.entity) then
		return
	end

	local player = game.get_player(event.player_index)
	if player then
		gui.open(player, event.entity --[[@as LuaEntity]])
	end
end

---@param event EventData.on_gui_closed
local function onGuiClosed(event)
	if event.gui_type == defines.gui_type.entity then
		updateInput(event.entity)
	elseif gui.isFrame(event.element) then
		local player = game.get_player(event.player_index)
		if player then
			updateInput(gui.close(player))
		end
	end
end

---@param event EventData.on_gui_click | EventData.on_gui_switch_state_changed
local function onGuiInteraction(event)
	updateInput(gui.onInteraction(event))
end

---@param event EventData.on_entity_settings_pasted
local function onSettingsPasted(event)
	updateInput(event.destination)
end

return {
	on_init = scanAll,
	on_load = updateTickHandlers,
	on_configuration_changed = scanAll,
	events = {
		[defines.events.on_gui_opened] = onGuiOpened,
		[defines.events.on_gui_closed] = onGuiClosed,
		[defines.events.on_gui_click] = onGuiInteraction,
		[defines.events.on_gui_switch_state_changed] = onGuiInteraction,
		[defines.events.on_entity_settings_pasted] = onSettingsPasted,
		-- An undo/redo can give a combinator a signal without any other event
		[defines.events.on_undo_applied] = scanAll,
		[defines.events.on_redo_applied] = scanAll,
	},
}
