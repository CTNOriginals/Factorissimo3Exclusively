-- Adjusts the freeplay script this scenario is built on.

---@return boolean
local function hasFreeplay()
	return remote.interfaces["freeplay"] ~= nil
end

local function onInit()
	if not hasFreeplay() then
		return
	end

	-- The crash site and its intro cutscene would be placed outside the factory
	remote.call("freeplay", "set_disable_crashsite", true)
	remote.call("freeplay", "set_custom_intro_message", { "message.intro" })
end

return {
	on_init = onInit,
}
