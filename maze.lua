#!/usr/bin/env lua

local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

printAnyError(function()
local statemodule = load_module(import_prefix .. "state", true)

local levelmodule = load_module(import_prefix .. "level", true)

-- Normal entry point
console:printLore("Write 'h'<Enter> to get the help at any time when in play mode.\n")
stateManager:getState():onPush()
-- Game entry point
stateManager:runLoop()

--[[ Not totally accurate anymore, you can still use parts of it but push the main state 'gameWrapper' instead of 'mm'
console:printLore("\n")
console:printLore("\nIf you are in interactive mode, you can restart the game by writing:\n")
console:printLore("main()\n\n")
local lvnum = levelManager:getLevelNumber()
if not levelManager:getLevel(lvnum) then if levelManager:getConfig():doLoadTestLevels() then lvnum = lvnum + 1
                                         else lvnum = lvnum - 1 end end
lvNum = tostring(lvnum)
if levelManager:getLevel(lvnum) and not levelManager:getLevel(lvnum):getLevelConfiguration():doesDisplayFullMap() then
	console:printLore("\nThe map is disabled.\nTo enable it, write:\n")
	console:printLore("levelManager:getLevel(" .. lvNum .. "):getLevelConfiguration().__displayMap = true\n")
end
console:printLore("To see the map (if enabled), write:\n")
console:printLore("levelManager:getLevel(" .. lvNum .. "):printLevelMap(true, Objects(1), true)\n")
if dead then
	console:printLore("You died, so you haven't got the entire map.\n")
else
	console:printLore("Having exited, the full labyrinth is revealed because you now have its map!\n")
end
]]
-- This is better
console:printLore("\n\nIf you are in interactive mode, you can restart the game by writing:\n")
console:printLore("stateManager:reset('mm')\nstateManager:runLoop()\n")

end)
