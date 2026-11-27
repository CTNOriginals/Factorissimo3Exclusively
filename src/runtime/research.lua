-- Some technologies are researched by mining a resource, which is impossible inside the factory.
-- Those get a goal that fits the scenario instead (see config.researchGoals).
-- The technology gui still shows the vanilla requirement, since that text comes from the prototype,
-- so the goal is shown in the goal window while the technology is available.
-- The resource of a goal is locked in the input combinators until its technology is available.

local config = require("shared.config")

---@alias ResearchGoal.Kind "fluid" | "item"

---@class (exact) ResearchGoal
---@field technology string Technology the goal researches
---@field kind ResearchGoal.Kind
---@field name string Fluid or item to store
---@field amount integer

---@class (exact) ResearchGoalState
---@field announced {[string]: true} Technologies whose goal has been announced, by name
---@field shown boolean True while this script shows a goal in the goal window

local M = {}

---Goals by the resource they are about, as "<kind>/<name>"
---@type {[string]: ResearchGoal}
local goalsByResource = {}
for _, goal in ipairs(config.researchGoals) do
	goalsByResource[goal.kind .. "/" .. goal.name] = goal
end

---Returns how much of the resource the force has stored, per goal kind
---@type {[ResearchGoal.Kind]: fun(force: LuaForce, name: string): number}
local counters = {
	fluid = function(force, name)
		local total = 0

		for _, surface in pairs(game.surfaces) do
			for _, tank in pairs(surface.find_entities_filtered({ type = "storage-tank", force = force })) do
				total = total + tank.get_fluid_count(name)
			end
		end

		return total
	end,

	item = function(force, name)
		local total = 0

		for _, surface in pairs(game.surfaces) do
			for _, chest in pairs(surface.find_entities_filtered({ type = { "container", "logistic-container" }, force = force })) do
				local inventory = chest.get_inventory(defines.inventory.chest)
				if inventory then
					total = total + inventory.get_item_count(name)
				end
			end
		end

		return total
	end,
}

---@param force LuaForce
---@return ResearchGoalState
local function getState(force)
	storage.researchGoals = storage.researchGoals or {}

	local state = storage.researchGoals[force.index]
	if not state then
		state = { announced = {}, shown = false }
		storage.researchGoals[force.index] = state
	end

	return state
end

---True if the technology could be researched now, like a trigger technology becomes in vanilla
---@param technology LuaTechnology
---@return boolean
local function isAvailable(technology)
	if not technology.enabled or technology.researched then
		return false
	end

	for _, prerequisite in pairs(technology.prerequisites) do
		if not prerequisite.researched then
			return false
		end
	end

	return true
end

---True if the force may use the resource: it has no goal, or the technology of its goal is available or researched
---@param force LuaForce
---@param kind string
---@param name string
---@return boolean
M.isUnlocked = function(force, kind, name)
	local goal = goalsByResource[kind .. "/" .. name]
	if not goal then
		return true
	end

	local technology = force.technologies[goal.technology]
	return technology == nil or technology.researched or isAvailable(technology)
end

---@param goal ResearchGoal
---@param technology LuaTechnology
---@param count number
---@return LocalisedString
local function describe(goal, technology, count)
	return {
		"goal." .. goal.kind,
		goal.technology,
		technology.localised_name,
		goal.name,
		math.floor(count),
		goal.amount,
	}
end

---Shows the description in the goal window of every player of the force, or clears it without one
---@param force LuaForce
---@param description LocalisedString?
local function showGoal(force, description)
	local state = getState(force)

	-- Only clears the goal window if this script filled it, so goals of other scripts are left alone
	if not description and not state.shown then
		return
	end

	for _, player in pairs(force.players) do
		player.set_goal_description(description or "", true)
	end

	state.shown = description ~= nil
end

---Researches the technologies whose goal is reached, and shows the progress of the others
---@param force LuaForce
local function checkGoals(force)
	local state = getState(force)
	---@type LocalisedString
	local lines = { "" }

	for _, goal in ipairs(config.researchGoals) do
		local technology = force.technologies[goal.technology]

		if technology and isAvailable(technology) then
			local count = counters[goal.kind](force, goal.name)

			if count >= goal.amount then
				technology.researched = true
			else
				if not state.announced[goal.technology] then
					state.announced[goal.technology] = true
					force.print({ "message.research-goal", goal.technology, technology.localised_name })
				end

				if #lines > 1 then
					table.insert(lines, "\n")
				end
				table.insert(lines, describe(goal, technology, count))
			end
		end
	end

	showGoal(force, #lines > 1 and lines or nil)
end

local function checkAllGoals()
	for _, force in pairs(game.forces) do
		if #force.players > 0 then
			checkGoals(force)
		end
	end
end

M.on_nth_tick = {
	[config.researchCheckInterval] = checkAllGoals,
}

return M
