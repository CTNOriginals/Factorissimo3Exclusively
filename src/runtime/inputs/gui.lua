-- The gui of an input combinator, which replaces the vanilla one.
-- It only offers the allowed resources, so no other signal can be picked.

local const = require("shared.constants")
local config = require("shared.config")
local combinator = require("runtime.inputs.combinator")
local research = require("runtime.research")

local M = {}

---@alias InputGui.Action "select" | "clear" | "toggle" | "close"

---@class (exact) InputGui
---@field frame LuaGuiElement
---@field combinator LuaEntity
---@field switch LuaGuiElement
---@field choices LuaGuiElement

---@return {[integer]: InputGui} Keyed by the player index
local function getStorage()
	storage.inputGuis = storage.inputGuis or {}
	return storage.inputGuis
end

---@param action InputGui.Action
---@param fields table?
---@return Tags
local function actionTags(action, fields)
	local tags = fields or {}
	tags[const.gui.actionTag] = action
	return tags
end

---@param element LuaGuiElement
---@return InputGui.Action?
local function getAction(element)
	return element.tags[const.gui.actionTag] --[[@as InputGui.Action?]]
end

---@param entity LuaEntity
---@return LuaConstantCombinatorControlBehavior
local function getBehavior(entity)
	return entity.get_or_create_control_behavior() --[[@as LuaConstantCombinatorControlBehavior]]
end

-- Building

---@param frame LuaGuiElement
local function buildTitlebar(frame)
	local titlebar = frame.add({ type = "flow", direction = "horizontal" })
	titlebar.drag_target = frame

	titlebar.add({
		type = "label",
		style = "frame_title",
		caption = { "gui.input-title" },
		ignored_by_interaction = true,
	})

	local filler = titlebar.add({
		type = "empty-widget",
		style = "draggable_space_header",
		ignored_by_interaction = true,
	})
	filler.style.height = 24
	filler.style.horizontally_stretchable = true

	titlebar.add({
		type = "sprite-button",
		style = "frame_action_button",
		sprite = "utility/close",
		tooltip = { "gui.close-instruction" },
		tags = actionTags("close"),
	})
end

---Adds a button for the resource, if it exists and the force has unlocked it
---@param parent LuaGuiElement
---@param force LuaForce
---@param kind InputKind
---@param name string
local function addChoice(parent, force, kind, name)
	local prototype = prototypes[kind][name]
	if not prototype or not research.isUnlocked(force, kind, name) then
		return
	end

	parent.add({
		type = "sprite-button",
		style = "slot_button",
		sprite = kind .. "/" .. name,
		tooltip = prototype.localised_name,
		tags = actionTags("select", { kind = kind, name = name }),
	})
end

---@param parent LuaGuiElement
---@param force LuaForce
---@return LuaGuiElement
local function buildChoices(parent, force)
	local choices = parent.add({ type = "table", style = "filter_slot_table", column_count = 8 })

	for _, name in ipairs(config.allowedItems) do
		addChoice(choices, force, "item", name)
	end
	for _, name in ipairs(config.allowedFluids) do
		addChoice(choices, force, "fluid", name)
	end

	choices.add({
		type = "sprite-button",
		style = "slot_button",
		sprite = "utility/trash",
		tooltip = { "gui.input-clear" },
		tags = actionTags("clear"),
	})

	return choices
end

-- Updating

---Shows the current state of the combinator in the gui
---@param gui InputGui
local function refresh(gui)
	local behavior = getBehavior(gui.combinator)
	local kind, name = combinator.getSelectedSignal(behavior)

	gui.switch.switch_state = behavior.enabled and "right" or "left"

	for _, button in pairs(gui.choices.children) do
		local tags = button.tags
		button.toggled = getAction(button) == "select" and tags.kind == kind and tags.name == name
	end
end

---Puts the resource in the first slot, or clears it without a kind
---@param entity LuaEntity
---@param kind InputKind?
---@param name string?
local function setSignal(entity, kind, name)
	local behavior = getBehavior(entity)
	local section = behavior.get_section(1) or behavior.add_section()

	if kind and name then
		section.set_slot(1, { value = { type = kind, name = name, quality = "normal" }, min = 1 })
		section.active = true
	else
		section.clear_slot(1)
	end
end

-- Opening and closing

---@param player LuaPlayer
---@return LuaEntity? combinator The combinator the closed gui belonged to
M.close = function(player)
	local guis = getStorage()
	local gui = guis[player.index]
	guis[player.index] = nil

	if not gui then
		return nil
	end

	if gui.frame.valid then
		gui.frame.destroy()
	end

	return gui.combinator.valid and gui.combinator or nil
end

---Opens the gui for the combinator in place of the vanilla one
---@param player LuaPlayer
---@param entity LuaEntity
M.open = function(player, entity)
	M.close(player)

	local frame = player.gui.screen.add({
		type = "frame",
		name = const.gui.inputFrame,
		direction = "vertical",
	})
	frame.auto_center = true

	buildTitlebar(frame)

	local content = frame.add({
		type = "frame",
		style = "inside_shallow_frame_with_padding",
		direction = "vertical",
	})

	local switch = content.add({
		type = "switch",
		left_label_caption = { "gui.input-off" },
		right_label_caption = { "gui.input-on" },
		tags = actionTags("toggle"),
	})
	switch.style.bottom_margin = 8

	---@type InputGui
	local gui = {
		frame = frame,
		combinator = entity,
		switch = switch,
		choices = buildChoices(content, entity.force --[[@as LuaForce]]),
	}
	getStorage()[player.index] = gui

	refresh(gui)

	-- Replaces the vanilla gui, and makes E and escape close this one
	player.opened = frame
end

---True if the element is the frame of an input gui
---@param element LuaGuiElement?
---@return boolean
M.isFrame = function(element)
	return element ~= nil and element.valid and element.name == const.gui.inputFrame
end

-- Interaction

---Handles a click or switch in the gui
---@param event EventData.on_gui_click | EventData.on_gui_switch_state_changed
---@return LuaEntity? changed The combinator that was changed
M.onInteraction = function(event)
	local element = event.element
	if not element or not element.valid then
		return nil
	end

	local action = getAction(element)
	if not action then
		return nil
	end

	local player = game.get_player(event.player_index)
	local gui = getStorage()[event.player_index]
	if not player or not gui then
		return nil
	end

	if action == "close" or not gui.combinator.valid then
		return M.close(player)
	end

	if action == "select" then
		setSignal(gui.combinator, element.tags.kind --[[@as InputKind]], element.tags.name --[[@as string]])
		return M.close(player)
	end

	if action == "clear" then
		setSignal(gui.combinator, nil, nil)
		return M.close(player)
	end

	if action == "toggle" then
		getBehavior(gui.combinator).enabled = element.switch_state == "right"
	end

	refresh(gui)
	return gui.combinator
end

return M
