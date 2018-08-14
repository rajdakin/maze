local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local consolemodule = require(import_prefix .. "console")
local levelmodule = require(import_prefix .. "level")

directions = {}
directions["up"] = "u"
directions["down"] = "d"
directions["left"] = "l"
directions["right"] = "r"

objects = {}
objects["sword"] = false
objects["key"] = false
objects["redkey"] = false

game_ended = false

function resetMaze()
	if levelManager:getActiveLevel():getLevelConfiguration():getDifficulty() > 1 then
		levelManager:getActiveLevel():setAllRoomsSeenStatusAs(false)
	end
end

resetMaze()

function main()
	while levelManager:getActiveLevel() do
		levelManager:getActiveLevel():initialize()
		resetMaze()
		stateManager:pushMainState("ig")
		
		game_ended = false
		dead = false
		
		dictionary:resetAlternatives()
		dictionary:setAlternative({"ig"}, "help", tostring(levelManager:getActiveLevel():getLevelConfiguration():doesDisplayFullMap()))
		--[[dictionary:setAlternative({"ig"}, "sword", "false")
		dictionary:setAlternative({"ig"}, "key", "false")
		dictionary:setAlternative({"ig"}, "redkey", "false")
		dictionary:setAlternative({"ig", "sword"}, "take", "false")
		dictionary:setAlternative({"ig", "keydoors", "group", "key"}, "take", "false")
		dictionary:setAlternative({"ig", "keydoors", "redgroup", "key"}, "take", "false")]]
		
		objects["sword"] = false
		objects["key"] = false
		objects["redkey"] = false
		levelManager:getActiveLevel():printBeginingLore()
		levelManager:getActiveLevel():refreshActiveRoomNearEvents()
		while not game_ended do	-- here starts interactive
			levelManager:getActiveLevel():setActiveRoomAttribute("saw", true)
			console:printLore("\n")
			
			local ret = levelManager:getActiveLevel():printLevelMap(game_ended, objects, false)
			if ret:iskind(LevelPrintingErrored) then
				print()
				return "Internal error: " .. "[Level printing] " .. ret.reason.reason
			end
			
			console:printLore(dictionary:translate(stateManager:getStatesStack(), "prompt"))
			local returned = console:read()
			local success, eos, movement = returned.success, returned.eos, returned.returned
			if not success then
				game_ended = true
				dead = true
				print()
				return "Internal error: " .. "[Level movement parsing] " .. " input reading error (" .. movement .. ")"
			elseif eos then
				game_ended = true
				dead = true
				print()
				return "Ended because of: user's request"
			end
			
			levelManager:getActiveLevel():reverseMap(objects)
			console:printLore("\n")
			
			if (movement == "") or (movement == "h") or (movement == "help") then
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "help",
						directions["up"], directions["down"], directions["left"], directions["right"], dictionary:translate({"mm"}, "eqc"))
				)
			elseif (movement == directions["up"]) or (movement == '\27[A') then
				-- go up!
				stateManager:pushState("move")
				if levelManager:getActiveLevel():getActiveRoom():hasAccess("up") then
					levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() - levelManager:getActiveLevel():getColumnCount())
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "up"))
				else
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "fail"))
				end
				stateManager:popState()
			elseif (movement == directions["down"]) or (movement == '\27[B') then
				-- go down!
				stateManager:pushState("move")
				if levelManager:getActiveLevel():getActiveRoom():hasAccess("down") then
					levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() + levelManager:getActiveLevel():getColumnCount())
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "down"))
				else
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "fail"))
				end
				stateManager:popState()
			elseif (movement == directions["left"]) or (movement == '\27[D') then
				-- go left!
				stateManager:pushState("move")
				if levelManager:getActiveLevel():getActiveRoom():hasAccess("left") then
					levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() - 1)
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "left"))
				else
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "fail"))
				end
				stateManager:popState()
			elseif (movement == directions["right"]) or (movement == '\27[C') then
				-- go right!
				stateManager:pushState("move")
				if levelManager:getActiveLevel():getActiveRoom():hasAccess("right") then
					levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() + 1)
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "right"))
				else
					console:printLore(dictionary:translate(stateManager:getStatesStack(), "fail"))
				end
				stateManager:popState()
			elseif (movement == "w?") or (movement == "w ") or (movement == "m") or (movement == "map") then
				-- print the map
				ret = levelManager:getActiveLevel():printLevelMap(game_ended, objects, true)
				if ret:iskind(LevelPrintingErrored) then
					console:printLore("\27[00m\n")
					return "Internal error: " .. "[Level printing] " .. ret.reason.reason
				elseif ret:iskind(LevelPrintingIgnored) then
					console:printLore("\27[A")
				end
			elseif (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") then
				game_ended = true
				dead = true
				
				return "Exit."
			elseif (movement == "w") or (movement == "wait") then
				stateManager:pushState("wait")
				
				console:printLore(dictionary:translate(stateManager:getStatesStack(), "lore"))
				
				stateManager:popState()
			elseif (movement == "suicide") then
				stateManager:pushState("suicide")
				
				console:printLore(dictionary:translate(stateManager:getStatesStack(), "lore"))
				
				game_ended = true
				dead = true
				resetMaze()
				
				stateManager:popState()
			else
				console:print("Unknown command: " .. movement .. "\n", LogLevel.ERROR, "maze.lua/main")
			end
			if not ((movement == "w ?") or (movement == "w ") or (movement == "m") or (movement == "map")
			     or (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") or (movement == "") or (movement == "h")
		         or (movement == "help") or (movement == "suicide")) then
				local ret = levelManager:getActiveLevel():checkLevelEvents(game_ended, objects)
				game_ended = ret.ended
				objects = ret.objects
				if ret:iskind(EventParsingResultEnded) then
					dead = true
					print()
					return "Ended because of: " .. ret.reason
				elseif ret:iskind(EventParsingResultExited) then
					dead = ret.dead
				end
				if dead then resetMaze() end
			end
		end
		local doNextLevel = levelManager:getActiveLevel():printEndingLore(dead, objects)
		console:printLore("The end!")
		sleep(1) console:printLore("\8.")
		sleep(1) console:printLore(".")
		sleep(1) console:printLore(".")
		sleep(2) console:printLore("\8\8\8?  ")
		sleep(2) console:printLore("\8\8\8\8\8\8\8\8\8\8Nope      ")
		
		if doNextLevel then levelManager:setLevelNumber(levelManager:getLevelNumber() + 1) sleep(1)
		-- else break
		end
		
		stateManager:popMainState()
	end
	return "\8\8\8\8\8\8\8\8\8\8(Yes, it is)"
end

console:printLore("Write 'h'<Enter> to get the help at any time.\n")
console:printLore(main() .. "\n")
console:printLore("\nIf you are in interactive mode, you can restart the game by writing:\n")
console:printLore("main()\n\n")
if not levelManager:getLevel(levelManager:getLevelNumber() - 1):getLevelConfiguration():doesDisplayFullMap() then
	console:printLore("\nThe map is disabled.\nTo enable it, write:\n")
	console:printLore("levelManager:getLevel(levelManager:getLevelNumber() - 1):getLevelConfiguration().__displayMap = true\n")
end
console:printLore("To see the map (if enabled), write:\n")
console:printLore("levelManager:getLevel(levelManager:getLevelNumber() - 1):printLevelMap(true, {}, true)\n")
console:printLore("(Note: if you exitd the level using the exit command or equivlent, remove the ' - 1' part.)\n\n")
if dead then
	console:printLore("You died, so you haven't got the entire map.\n")
else
	console:printLore("Having exited, the full labyrinth is revealed because you now have its map!\n")
end
