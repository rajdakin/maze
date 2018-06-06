import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

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
	level = get_active_level()
	level:setAllRoomsSeenStatusAs(false)
end

resetMaze()

function main()
	game_ended = false
	objects["sword"] = false
	objects["key"] = false
	objects["redkey"] = false
	print("You are in room 1, or \"starting room\". You can try to go in each 4 directions. What do you choose?")
	level:refreshActiveRoomNearEvents()
	while not game_ended do	-- here starts interactive
		level:setActiveRoomAttribute("saw", true)
		print("")
		
		local ret = level:printLevelMap(game_ended, objects, false)
		if ret:iskind(LevelPrintingErrored) then
			print()
			return "Internal error: " .. "[Level printing] " .. ret.reason.reason
		end
		
		io.write('"' .. directions["up"] .. '", "' .. directions["down"] .. '", "' .. directions["left"] .. '", "' .. directions["right"] .. '" (directions), "wait" (if you want to act with what is in the same room as you), "exit" or "map" : ')
		io.flush()
		local movement = io.read()
		if movement == nil then
			game_ended = true
			dead = true
			print()
			return "Ended because of: user's request"
		end
		
		level:reverseMap(objects)
		
		if (movement == directions["up"]) or (movement == '\27[A') then
			-- go up!
			if level:getActiveRoom():hasAccess("up") then
				level:setRoom(level:getRoomNumber() - level:getColumnCount())
				print("Moving up")
			else
				print("BOOMM !!")
			end
		elseif (movement == directions["down"]) or (movement == '\27[B') then
			-- go down!
			if level:getActiveRoom():hasAccess("down") then
				level:setRoom(level:getRoomNumber() + level:getColumnCount())
				print("Moving down")
			else
				print("BOOMM !!")
			end
		elseif (movement == directions["left"]) or (movement == '\27[D') then
			-- go left!
			if level:getActiveRoom():hasAccess("left") then
				level:setRoom(level:getRoomNumber() - 1)
				print("Moving left")
			else
				print("BOOMM !!")
			end
		elseif (movement == directions["right"]) or (movement == '\27[C') then
			-- go right!
			if level:getActiveRoom():hasAccess("right") then
				level:setRoom(level:getRoomNumber() + 1)
				print("Moving right")
			else
				print("BOOMM !!")
			end
		elseif (movement == "w?") or (movement == "w ") or (movement == "m") or (movement == "map") then
			-- print the map
			ret = level:printLevelMap(game_ended, objects, true)
			if ret:iskind(LevelPrintingErrored) then
				print()
				return "Internal error: " .. "[Level printing] " .. ret.reason.reason
			end
		elseif (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") then
			game_ended = true
			dead = true
		elseif (movement == "w") or (movement == "wait") then
			print("Waiting...")
		else
			print("Unknown command: " .. movement)
		end
		if not ((movement == "w ?") or (movement == "w ") or (movement == "m") or (movement == "map")
		     or (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit")) then
			local ret = level:checkLevelEvents(game_ended, objects)
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
					level:setAllRoomsSeenStatusAs(true)
				end
			end
		end
	end
	io.write("The end!") io.flush()
	sleep(1) io.write("\8.") io.flush()
	sleep(1) io.write(".") io.flush()
	sleep(1) io.write(".") io.flush()
	sleep(2) io.write("\8\8\8?  ") io.flush()
	sleep(2) io.write("\8\8\8\8\8\8\8\8\8\8")
	return "(Yes, it is)"
end

print(main())
print("\nIf you are in interactive mode, you can restart the game by writing:")
print("resetMaze()")
print("main()")
print("\nTo see the map, write:")
print("level:printLevelMap(true, {}, true)")
if dead then
	print("You died, so you haven't got the entire map.")
else
	print("Having exited, the full labyrinth is revealed because you now have its map!")
end
