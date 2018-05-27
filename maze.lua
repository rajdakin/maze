import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

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

local levelmodule = require(import_prefix .. "level")

game_ended = false

function resetMaze()
	level = get_active_level()
	level:setAllRoomsSeenStatusAs(false)
end

resetMaze()

function sleep(s)
	local t0 = os.clock()
	while os.clock() - t0 <= s do end
end

function main()
	game_ended = false
	objects["sword"] = false
	objects["key"] = false
	objects["redkey"] = false
	print("You are in room 1, or \"starting room\". You can try to go in each 4 directions. What do you choose?")
	while not game_ended do	-- here starts interactive
		level:setRoomAttribute("saw", true)
		print("")
		io.write('"' .. directions["up"] .. '", "' .. directions["down"] .. '", "' .. directions["left"] .. '", "' .. directions["right"] .. '" (directions), "wait" (if you want to act with what is in the same room as you), "exit" or "map" : ')
		local movement = io.read()
		if (movement == directions["up"]) then
			-- go up !
			if level:getRoomAttribute("up") or ((not level:getRoomAttribute("door")) and (level:getRoomAttribute("dir_door") == "up")) or ((not level:getRoomAttribute("reddoor")) and (level:getRoomAttribute("dir_reddoor") == "up")) or (level:getRoomAttribute("grave") and (level:getRoomAttribute("exitdir") == "up")) then
				level:setRoom(level:getRoom() - level:getColumnCount())
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["down"]) then
			-- go down !
			if level:getRoomAttribute("down") or ((not level:getRoomAttribute("door")) and (level:getRoomAttribute("dir_door") == "down")) or ((not level:getRoomAttribute("reddoor")) and (level:getRoomAttribute("dir_reddoor") == "down")) or (level:getRoomAttribute("grave") and (level:getRoomAttribute("exitdir") == "down")) then
				level:setRoom(level:getRoom() + level:getColumnCount())
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["left"]) then
			-- go left !
			if level:getRoomAttribute("left") or ((not level:getRoomAttribute("door")) and (level:getRoomAttribute("dir_door") == "left")) or ((not level:getRoomAttribute("reddoor")) and (level:getRoomAttribute("dir_reddoor") == "left")) or (level:getRoomAttribute("grave") and (level:getRoomAttribute("exitdir") == "left")) then
				level:setRoom(level:getRoom() - 1)
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["right"]) then
			-- go right !
			if level:getRoomAttribute("right") or ((not level:getRoomAttribute("door")) and (level:getRoomAttribute("dir_door") == "right")) or ((not level:getRoomAttribute("reddoor")) and (level:getRoomAttribute("dir_reddoor") == "right")) or (level:getRoomAttribute("grave") and (level:getRoomAttribute("exitdir") == "right")) then
				level:setRoom(level:getRoom() + 1)
			else
				print "BOOMM !!"
			end
		elseif (movement == "w?") or (movement == "w ") or (movement == "m") or (movement == "map") then
			-- print the map
			level:printLevelMap(game_ended, objects)
		elseif (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") then
			game_ended = true
		elseif (movement == "w") or (movement == "wait") then
		else
			--print("EXCEPTION.UNKNOWN_COMMAND: " .. movement .. " AT LINE #XXXX")
			print("Unknown command: " .. movement)
		end
		if not ((movement == "w ?") or (movement == "w ") or (movement == "m") or (movement == "map")
		     or (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit")) then
			ret = level:checkLevelEvents(game_ended, objects)
			game_ended = ret[1]
			objects = ret[2]
		end
	end
	objects["sword"] = false
	objects["key"] = false
	objects["redkey"] = false
	io.write("The end!")
	io.flush()
	sleep(1)
	io.write("\8.")
	io.flush()
	sleep(1)
	io.write(".")
	io.flush()
	sleep(1)
	io.write(".")
	io.flush()
	sleep(2)
	io.write("\8\8\8?  ")
	io.flush()
	sleep(2)
	io.write("\8\8\8\8\8\8\8\8\8\8")
	return "(Yes, it is)"
end

print(main())
print("\nIf you are in interactive mode, you can restart the game by writing:")
print("resetMaze()")
print("main()")
print("\nTo see the map, write:")
print("level:printLevelMap(true, {false, false, false})")
if yes then
	print("Having exited, the full labyrinth is revealed because you now have its map!")
end
