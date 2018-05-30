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
		io.write('"' .. directions["up"] .. '", "' .. directions["down"] .. '", "' .. directions["left"] .. '", "' .. directions["right"] .. '" (directions), "wait" (if you want to act with what is in the same room as you), "exit" or "map" : ')
		
		local movement = io.read()
		if movement == nil then
			game_ended = true
			print()
			return "Ended because of: user's request"
		end
		
		if (movement == directions["up"]) then
			-- go up!
			if level:getActiveRoomAttribute("up") or ((not level:getActiveRoomAttribute("door")) and (level:getActiveRoomAttribute("dir_door") == "up")) or ((not level:getActiveRoomAttribute("reddoor")) and (level:getActiveRoomAttribute("dir_reddoor") == "up")) or (level:getActiveRoomAttribute("grave") and (level:getActiveRoomAttribute("exitdir") == "up")) then
				level:setRoom(level:getRoomNumber() - level:getColumnCount())
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["down"]) then
			-- go down!
			if level:getActiveRoomAttribute("down") or ((not level:getActiveRoomAttribute("door")) and (level:getActiveRoomAttribute("dir_door") == "down")) or ((not level:getActiveRoomAttribute("reddoor")) and (level:getActiveRoomAttribute("dir_reddoor") == "down")) or (level:getActiveRoomAttribute("grave") and (level:getActiveRoomAttribute("exitdir") == "down")) then
				level:setRoom(level:getRoomNumber() + level:getColumnCount())
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["left"]) then
			-- go left!
			if level:getActiveRoomAttribute("left") or ((not level:getActiveRoomAttribute("door")) and (level:getActiveRoomAttribute("dir_door") == "left")) or ((not level:getActiveRoomAttribute("reddoor")) and (level:getActiveRoomAttribute("dir_reddoor") == "left")) or (level:getActiveRoomAttribute("grave") and (level:getActiveRoomAttribute("exitdir") == "left")) then
				level:setRoom(level:getRoomNumber() - 1)
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["right"]) then
			-- go right!
			if level:getActiveRoomAttribute("right") or ((not level:getActiveRoomAttribute("door")) and (level:getActiveRoomAttribute("dir_door") == "right")) or ((not level:getActiveRoomAttribute("reddoor")) and (level:getActiveRoomAttribute("dir_reddoor") == "right")) or (level:getActiveRoomAttribute("grave") and (level:getActiveRoomAttribute("exitdir") == "right")) then
				level:setRoom(level:getRoomNumber() + 1)
			else
				print "BOOMM !!"
			end
		elseif (movement == "w?") or (movement == "w ") or (movement == "m") or (movement == "map") then
			-- print the map
			level:printLevelMap(game_ended, objects)
		elseif (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") then
			game_ended = true
			dead = true
		elseif (movement == "w") or (movement == "wait") then
		else
			print("Unknown command: " .. movement)
		end
		if not ((movement == "w ?") or (movement == "w ") or (movement == "m") or (movement == "map")
		     or (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit")) then
			local ret = level:checkLevelEvents(game_ended, objects)
			game_ended = ret.ended
			objects = ret.objects
			if ret:iskind(EventParsingReturnExited) then
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
print("level:printLevelMap(true, {})")
if dead then
	print("You died, so you haven't got the entire map.")
else
	print("Having exited, the full labyrinth is revealed because you now have its map!")
end
