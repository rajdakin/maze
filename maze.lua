import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local consolemodule = require(import_prefix .. "console")
local levelmodule = require(import_prefix .. "level")

directions = {}
directions["up"] = "u"
directions["down"] = "d"
directions["left"] = "l"
directions["right"] = "r"

cardinals = {}
cardinals["up"] = "north"
cardinals["down"] = "south"
cardinals["left"] = "east"
cardinals["right"] = "west"

objects = {}

objects["sword"] = false
objects["key"] = false
objects["redkey"] = false

game_ended = false

function resetMaze()
	levelManager:getActiveLevel():setAllRoomsSeenStatusAs(false)
end

resetMaze()

function main()
	game_ended = false
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
		
		console:printLore('"' .. directions["up"] .. '", "' .. directions["down"] .. '", "' .. directions["left"] .. '", "' .. directions["right"] .. '" (directions), "wait" (if you want to act with what is in the same room as you), "exit" or "map" : ')
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
		
		if (movement == directions["up"]) or (movement == '\27[A') then
			-- go up!
			if levelManager:getActiveLevel():getActiveRoom():hasAccess("up") then
				levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() - levelManager:getActiveLevel():getColumnCount())
				console:printLore("Moving up\n")
			else
				console:printLore("BOOMM !!\n")
			end
		elseif (movement == directions["down"]) or (movement == '\27[B') then
			-- go down!
			if levelManager:getActiveLevel():getActiveRoom():hasAccess("down") then
				levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() + levelManager:getActiveLevel():getColumnCount())
				console:printLore("Moving down\n")
			else
				console:printLore("BOOMM !!\n")
			end
		elseif (movement == directions["left"]) or (movement == '\27[D') then
			-- go left!
			if levelManager:getActiveLevel():getActiveRoom():hasAccess("left") then
				levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() - 1)
				console:printLore("Moving left\n")
			else
				console:printLore("BOOMM !!\n")
			end
		elseif (movement == directions["right"]) or (movement == '\27[C') then
			-- go right!
			if levelManager:getActiveLevel():getActiveRoom():hasAccess("right") then
				levelManager:getActiveLevel():setRoom(levelManager:getActiveLevel():getRoomNumber() + 1)
				console:printLore("Moving right\n")
			else
				console:printLore("BOOMM !!\n")
			end
		elseif (movement == "w?") or (movement == "w ") or (movement == "m") or (movement == "map") then
			-- print the map
			ret = levelManager:getActiveLevel():printLevelMap(game_ended, objects, true)
			if ret:iskind(LevelPrintingErrored) then
				console:printLore("\n")
				return "Internal error: " .. "[Level printing] " .. ret.reason.reason
			end
		elseif (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") then
			game_ended = true
			dead = true
		elseif (movement == "w") or (movement == "wait") then
			console:printLore("Waiting...\n")
		else
			console:print("Unknown command: " .. movement .. "\n", LogLevel.ERROR, "maze.lua/main")
		end
		if not ((movement == "w ?") or (movement == "w ") or (movement == "m") or (movement == "map")
		     or (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit")) then
			local ret = levelManager:getActiveLevel():checkLevelEvents(game_ended, objects)
			game_ended = ret.ended
			objects = ret.objects
			if ret:iskind(EventParsingResultEnded) then
				dead = true
				print()
				return "Ended because of: " .. ret.reason
			elseif ret:iskind(EventParsingResultExited) then
				resetMaze()
				dead = ret.dead
				if not dead then
					levelManager:getActiveLevel():setAllRoomsSeenStatusAs(true)
				end
			end
		end
	end
	levelManager:getActiveLevel():printEndingLore(dead, objects["sword"])
	console:printLore("The end!")
	sleep(1) console:printLore("\8.")
	sleep(1) console:printLore(".")
	sleep(1) console:printLore(".")
	sleep(2) console:printLore("\8\8\8?  ")
	sleep(2) console:printLore("\8\8\8\8\8\8\8\8\8\8")
	return "(Yes, it is)"
end

console:printLore(main() .. "\n")
console:printLore("\nIf you are in interactive mode, you can restart the game by writing:\n")
console:printLore("resetMaze()\n")
console:printLore("main()\n")
console:printLore("\nTo see the map, write:\n")
console:printLore("levelManager:getActiveLevel():printLevelMap(true, {}, true)\n")
if dead then
	console:printLore("You died, so you haven't got the entire map.\n")
else
	console:printLore("Having exited, the full labyrinth is revealed because you now have its map!\n")
end
