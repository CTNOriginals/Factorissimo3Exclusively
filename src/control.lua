local handler = require("event_handler")

-- Freeplay provides the starting items, the intro message and the rocket launch victory
require("__base__/script/freeplay/control.lua")

handler.add_lib(require("runtime.freeplay"))
handler.add_lib(require("runtime.spawn"))
handler.add_lib(require("runtime.inputs.init"))
