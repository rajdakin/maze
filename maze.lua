local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

printAnyError(function()
local statemodule = load_module(import_prefix .. "state", true)

local levelmodule = load_module(import_prefix .. "level", true)

-- main - run all levels from the active level up to the final one, processing all the logic at the same time
function main()
	stateManager.__exit = false
	stateManager:pushMainState("mm")
	stateManager:runLoop()
end

-- This is the pre- and post-messages
console:printLore("Write 'h'<Enter> to get the help at any time when in play mode.\n")
stateManager:getState():onPush()
stateManager:runLoop()
console:printLore("\n")
console:printLore("\nIf you are in interactive mode, you can restart the game by writing:\n")
console:printLore("main()\n\n")
local lvnum = levelManager:getLevelNumber()
if not levelManager:getLevel(lvnum) then if levelManager:getConfig():doLoadTestLevels() then lvnum = lvnum - 1
                                         else lvnum = lvnum + 1 end end
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

end)
