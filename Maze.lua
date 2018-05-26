#!/usr/local/bin/lua

directions = {}

directions["up"] = "u"
directions["down"] = "d"
directions["left"] = "l"
directions["right"] = "r"

dir = {}
dir["up"] = "north"
dir["down"] = "south"
dir["left"] = "east"
dir["right"] = "west"

--room = 28
--old_room = 28

sword = false

key = false

redkey = false

last_data = "nil"
last_data_index = 0

list_data = {"exit", "up", "down", "left", "right", "monster", "sword", "key", "door", "direction", "trap", "redkey", "reddoor", "grave", "graveorig", "saw", "unreachable", "nil"}

end_ = false

function UnFakingSaw()
	for k, v in pairs(doors) do
		v["saw"] = false
	end
	yes = false
end
function FakingSaw()
	for k, v in pairs(doors) do
		v["saw"] = true
	end
	yes = true
end

function GetLength(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function GetData()
	if last_data_index == GetLength(list_data) then
		last_data = "nil"
		last_data_index = 0
	else
		last_data = list_data[last_data_index + 1]
		last_data_index = last_data_index + 1
	end
	if last_data ~= "nil" then
		return last_data
	else
		last_data_index = 0
		return nil
	end
end

function ResetDoors()
	NumberInALine = 7
	-- 1 2 3 4 5 6 7
	-- 8 9 . . .
--	doors = {[-6] = {},                                                                     [-5] = {},                                [-4] = {},                                [-3] = {},                              [-2] = {},                                [-1] = {},                                 [0] = {},
--	         {exit = true, down = true, dir_exit = "left", door = true, dir_door = "left"}, {right = true},                           {left = true, right = true, down = true}, {left = true, right = true},            {left = true, right = true},              {left = true, right = true, sword = true}, {down = true, left = true},
--	         {up = true, right = true, monster = true},                                     {down = true, left = true, right = true}, {up = true, left = true, right = true},   {left = true},                          {up = true, down = true},                 {down = true, right = true},               {up = true, left = true},
--	         {down = true, right = true},                                                   {up = true, left = true},                 {},                                       {down = true, right = true},            {up = true, left = true},                 {up = true, down = true, right = true},    {down = true, left = true},
--	         {up = true, right = true},                                                     {left = true, right = true},              {left = true, right = true, key = true},  {left = true, right = true, up = true}, {left = true, right = true, trap = true}, {up = true, left = true, right = true},    {up = true, left = true},
--	         {},                                                                            {},                                       {},                                       {},                                     {},                                       {},                                        {}}
--	room = 28
	doors = {[-6] = {},                                                           [-5] = {},                                           [-4] = {},                                  [-3] = {},                                                                 [-2] = {},                                                                  [-1] = {},                                           [0] = {},
	         {right = true, door = true, dir_door = "down"},                      {down = true, left = true},                          {down = true, right = true},                {exit = true, left = true, dir_exit = "up", door = true, dir_door = "up"}, {},                                                                         {down = true, monster = true},                       {},
	         {up = true, right = true, key = true, door = true, dir_door = "up"}, {up = true, down = true, left = true, right = true}, {up = true, left = true},                   {right = true},                                                            {down = true, left = true, right = true, sword = true},                     {up = true, down = true, left = true, right = true}, {left = true, trap = true},
	         {},                                                                  {up = true, down = true, right = true},              {left = true, right = true},                {down = true, left = true, right = true, key = true},                      {up = true, left = true, right = true},                                     {up = true, down = true, left = true},               {},
	         {},                                                                  {up = true, down = true, right = true},              {left = true},                              {up = true, right = true},                                                 {left = true, right = true},                                                {up = true, down = true, left = true},               {},
	         {right = true, monster = true},                                      {up = true, left = true, right = true},              {left = true, right = true, redkey = true}, {left = true, right = true},                                               {up = true, left = true, sword = true, reddoor = true, dir_reddoor = "up"}, {up = true, right = true},                           {left = true, trap = true},
	         {},                                                                  {},                                                  {},                                         {},                                                                        {},                                                                         {},                                                  {}}
	room = 23
	-- TESTS
--	doors = {[-1] = {},                                                                                                                                                   [0] = {},
--	         {exit = true, dir_exit = "left", reddoor = true, dir_reddoor = "left", right = true, grave = true, deadlygrave = true, keyneeded = "key", exitdir = "down"}, {graveorig = true, down = true},
--	         {redkey = true},                                                                                                                                             {up = true, key = true},
--	         {},                                                                                                                                                          {}}
--	room = 4
--	doors = {[-1] = {},                                                                                              [0] = {},
--	         {exit = true, dir_exit = "left", reddoor = true, dir_reddoor = "left", door = true, dir_door = "left"}, {graveorig = true, down = true},
--	         {},                                                                                                     {up = true, key = true, redkey = true},
--	         {},                                                                                                     {}}
--	room = 4
	UnFakingSaw()

	-- unreachables
	local isUnreachable
	local i = 1
	local data = GetData
	while i < GetLength(doors) - NumberInALine do
		isUnreachable = true
		while (data() ~= nil) and isUnreachable do
			if doors[i][last_data] then
				isUnreachable = false
			end
		end
		last_data = "nil"
		last_data_index = 0
		if isUnreachable then
			doors[i]["unreachable"] = true
		end
		i = i + 1
	end
end

ResetDoors()

function PERCENT(Number, Percentage)
	local returns = Number
	while returns >= Percentage do
		returns = returns - Percentage
	end
	return returns
end

function PrintMap()
	io.write("E = exit, s = sword, c = key, C = \27[9mred\27[00m \27[02;31mblood\27[00my key, d = door, D = red door, G = grave, g = grave's origin,   = nothing particular, \27[01;30;07;47m?\27[00m = not yet discovered, \27[01;30;41;07m \27[00m = wall")
	if not end_ then
		io.write("\n\27[01;31mWITHOUT HACK, NEVER APPEARS!\27[00m")
	else
		io.write(",")
	end
	print(" \27[31mM\27[00m = monster, \27[31mT\27[00m = trap, \27[01;30;41;07mU\27[00m = unreachable")
	print("")
	if key or redkey or sword then
		if key then
			print("You have a \27[45;01;32mkey\27[00m.")
		end
		if redkey then
			print("You have a \27[46;01;31mred key...?\27[00m.")
		end
		if sword then
			print("You have a \27[01;39;40;07msword\27[00m.")
		end
		print("")
	end
	local sizeOfMap = GetLength(doors) - 2 * NumberInALine
	for i = 1, sizeOfMap do
		local v = doors[i]
		if PERCENT(i, NumberInALine) == 1 then
			if i ~= 1 then
				print("\27[01;30;41;07m \27[00m")
			end
			io.write("\27[01;30;41;07m ")--+")
			for j = 1, NumberInALine do
				if (doors[i + j - NumberInALine - 1]["down"]
				   or (((not doors[i + j - NumberInALine - 1]["door"]) and (doors[i + j - NumberInALine - 1]["dir_door"] == "down"))
				   and ((not doors[i + j - NumberInALine - 1]["reddoor"]) and (doors[i + j - NumberInALine - 1]["dir_reddoor"] == "down")))
				   or (((not doors[i + j - NumberInALine - 1]["door"]) and (doors[i + j - NumberInALine - 1]["dir_door"] == "down"))
				   and ((not doors[i + j - NumberInALine - 1]["reddoor"]) and (doors[i + j - NumberInALine - 1]["dir_reddoor"] == nil)))
				   or (((not doors[i + j - NumberInALine - 1]["door"]) and (doors[i + j - NumberInALine - 1]["dir_door"] == nil))
				   and ((not doors[i + j - NumberInALine - 1]["reddoor"]) and (doors[i + j - NumberInALine - 1]["dir_reddoor"] == "down")))
				   or (doors[i + j - NumberInALine - 1]["grave"] and (doors[i + j - NumberInALine - 1]["exitdir"] == "down")))
				 and (doors[i + j - NumberInALine - 1]["saw"] or doors[i + j - 1]["saw"]) then
					io.write("\27[00m")-- ")
				--else
				--	io.write("-")
				end
				io.write(" \27[01;30;41;07m ")--+")
			end
			print("\27[00m")
		end
		if (v["left"]
		   or (((not v["door"]) and (v["dir_door"] == "left"))
		   and ((not v["reddoor"]) and (v["dir_reddoor"] == "left")))
		   or (((not v["door"]) and (v["dir_door"] == "left"))
		   and ((not v["reddoor"]) and (v["dir_reddoor"] == nil)))
		   or (((not v["door"]) and (v["dir_door"] == nil))
		   and ((not v["reddoor"]) and (v["dir_reddoor"] == "left")))
		   or (v["grave"] and (v["exitdir"] == "left"))
		   or  v["graveorig"])
		 and (v["saw"] or ((PERCENT(i, NumberInALine) ~= 1) and doors[i - 1]["saw"])) then
			if v["graveorig"] then
				--io.write("/")
				io.write("\27[44;31m \27[00m")
			else
				--io.write(" ")
				io.write(" ")
			end
		else
			--io.write("|")
			io.write("\27[01;30;41;07m \27[00m")
		end
		if (i == room) and not end_ then
			io.write("\27[43m")
		end
		if v["saw"] then
			if v["exit"] then
				io.write("E")
			elseif v["sword"] then
				io.write("s")
			elseif v["key"] then
				io.write("c")
			elseif v["redkey"] then
				io.write("C")
			elseif v["door"] then
				io.write("d")
			elseif v["reddoor"] then
				io.write("D")
			elseif v["grave"] then
				io.write("G")
			elseif v["graveorig"] then
				io.write("g")
			elseif v["monster"] then
				io.write("\27[31mM\27[00m")
			elseif v["trap"] then
				io.write("\27[31mT\27[00m")
			elseif v["unreachable"] then
				io.write("\27[01;30;41;07mU\27[00m")
			else
				io.write(" ")
			end
		else
			io.write("\27[01;30;07;47m?\27[00m")
		end
		if (i == room) and not end_ then
			io.write("\27[00m")
		end
	end
	print("\27[01;30;41;07m \27[00m")
	io.write("\27[01;30;41;07m ")
	for j = 1, NumberInALine do
		io.write("  ")
	end
	print("\27[00m")
--	print("|")
--	io.write("+")
--	for j = 1, NumberInALine do
--		io.write("-+")
--	end
--	print("")
end

function sleep(s)
	local t0 = os.clock()
	while os.clock() - t0 <= s do end
end

function Initializer()
	local i = 1 - NumberInALine
	local data = GetData
	while i < GetLength(doors) - NumberInALine do
		while data() ~= nil do
			if not doors[i][last_data] then
				doors[i][last_data] = false
			end
		end
		i = i + 1
	end
end

function CheckRoom()
	if doors[room]["sword"] then
		io.write("You see a sword on a book, that says that this sword will self-disintegrate with its first target.\nYou turn the page and you read that you can only have one at a time and that if you take this one, every other sword will disintegrates.\n")
		if (sword) then io.write("You do already have one. ") end
		io.write("Do you want to take this sword? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
		local reponse = io.read()
		if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
			sword = true
			doors[room]["sword"] = false
		end
	end
	if doors[room]["monster"] then
		if sword then
			print("You see a monster! Quick, you arm your weapon... the moment it runs toward you! Your sword kills him, but it disintegrates... You don't have a sword anymore.")
			sword = false
			doors[room]["monster"] = false
		else
			print("Yous see a monster, but, due to your lack of equipment, you don't have any weapon... While you try to escape, the monster caught you and ate you. You are DEAD!")
			sword = false
			end_ = true
			key = false
			redkey = false
		end
	end
	if doors[room]["key"] then
		io.write("You see a key in a book. You can reach the key only by reading the book.")
		io.flush()
		sleep(0.5)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write("\8\8\8???, so you ")
		for i = 0, 1 do
			io.write("read it")
			io.flush()
			sleep(1)
			io.write(".")
			io.flush()
			sleep(1)
			io.write(".")
			io.flush()
			sleep(1)
			io.write(".")
			io.flush()
			sleep(1)
			io.write(" and ")
		end
		io.write("\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8                       \8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8")
		io.flush()
		sleep(1)
		io.write(", and you see a part about the key:\n")
		io.flush()
		sleep(0.5)
		io.write("\"This key is destined to the first that will find it. But beware! This key has a unique usage, but persistant.")
		io.flush()
		sleep(1)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write("\8\8\8?? \8")
		io.write("\nIf you insert it in a closed door and that you removed it, it will self-disintegrate.\nIf the door isn't locked, then you'll be able to remove it without worrying. One the door unlocked, remove the key and no one will be able to lock it again (with one exception).\nIf you lock a door...\"\nThen a lot of explanations.\n\"If you take this key, every other key you have will disintegrate.\"\n\n")
		if key then io.write("You do already have a key. ") end
		io.write("Do you want to take it? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
		io.flush()
		local reponse = io.read()
		if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
			key = true
			doors[room]["key"] = false
		end
	end
	if doors[room]["door"] then
		if key then
			if (not doors[room]["exit"]) or (doors[room]["dir_exit"] ~= doors[room]["dir_door"]) then
				print("You see a door at the " .. dir[doors[room]["dir_door"]] .. ", that you open with your key.\nBut when you release the key, the door is closing by itself!\nYou reopen it, but before that the door closes, you remove your key, and the door stay opened.\nThe key disintegrate. You don't have the key anymore.")
				key = false
				doors[room]["door"] = false
				if (doors[room]["dir_door"] == "up") then
					doors[room - NumberInALine]["door"] = false
					doors[room - NumberInALine]["dir_door"] = "down"
				elseif (doors[room]["dir_door"] == "down") then
					doors[room + NumberInALine]["door"] = false
					doors[room + NumberInALine]["dir_door"] = "up"
				elseif (doors[room]["dir_door"] == "left") then
					doors[room - 1]["door"] = false
					doors[room - 1]["dir_door"] = "right"
				elseif (doors[room]["dir_door"] == "right") then
					doors[room + 1]["door"] = false
					doors[room + 1]["dir_door"] = "left"
				else
					print("EXCEPTION.UNKNOWN_DOOR_DIR: " .. doors[room]["dir_door"] .. " AT LINE #")
				end
			else
				print("You see the exit at the " .. dir[doors[room]["dir_exit"]] .. "!\nQuick, you take your key and you open the exit door.\nYou survived against the monsters and the traps and you WON!")
				ResetDoors()
				FakingSaw()
				end_ = true
			end
		else
			print("You see a door at the " .. dir[doors[room]["dir_exit"]] .. ".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door won't open...\nYou cannot move to the " .. dir[doors[room]["dir_door"]] .. ".")
		end
	end
	if doors[room]["reddoor"] then
		if redkey then
			if (not doors[room]["exit"]) or (doors[room]["dir_exit"] ~= doors[room]["dir_reddoor"]) then
				print("You see a door you don't want to approach at the " .. dir[doors[room]["dir_reddoor"]] .. ".\nHopefully, you remember that you have a red key, of the same color than the door. You open the door.")
				redkey = false
				doors[room]["reddoor"] = false
				if (doors[room]["dir_reddoor"] == "up") then
					doors[room - NumberInALine]["reddoor"] = false
					doors[room - NumberInALine]["dir_reddoor"] = "down"
				elseif (doors[room]["dir_reddoor"] == "down") then
					doors[room + NumberInALine]["reddoor"] = false
					doors[room + NumberInALine]["dir_reddoor"] = "up"
				elseif (doors[room]["dir_reddoor"] == "left") then
					doors[room - 1]["reddoor"] = false
					doors[room - 1]["dir_reddoor"] = "right"
				elseif (doors[room]["dir_reddoor"] == "right") then
					doors[room + 1]["reddoor"] = false
					doors[room + 1]["dir_reddoor"] = "left"
				else
					print("EXCEPTION.UNKNOWN_REDDOOR_DIR: " .. doors[room]["dir_reddoor"] .. " AT LINE #X")
				end
			else
				print("You see a door you don't want to approach at the " .. dir[doors[room]["dir_exit"]] .. " blocking the exit!\nHopefully, you remember that you have a red key, of the same color than the door. You open the door and you exit this maze!\nYou survived against the monsters and the traps and you WON!")
				ResetDoors()
				FakingSaw()
				end_ = true
			end
		else
			io.write("You see a door you don't want to approach at the " .. dir[doors[room]["dir_exit"]])
			io.write("Vous voyez une door de mauvais augure")
			if doors[room]["exit"] and (doors[room]["dir_exit"] == doors[room]["dir_reddoor"]) then
				io.write(" bloquant la sortie..")
			end
			io.write(".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door doesn't open...\nYou cannot ")
			if doors[room]["exit"] and (doors[room]["dir_exit"] == doors[room]["dir_reddoor"]) then
				io.write("exit the maze..")
			else
				io.write("go to " .. dir[doors[room]["dir_reddoor"]])
			end
			print(".")
		end
	end
	if doors[room]["trap"] then
		print("You felt into a trap, and, with terrible pain, you DIE.")
		end_ = true
	end
	if not end_ then
		if doors[room]["redkey"] then
			io.write("You see a red")
			io.flush()
			sleep(1)
			io.write("\8\8\8wait, no")
			io.flush()
			sleep(1)
			io.write("\8\8\8\8\8\8\8\8bloody key in a book.\nIt says that this key already closed a door, and only it can reopen it.\n")
			if redkey then
				print("You decided not to take it, as you already have one.")
			else
				io.write('Do you want to take it? "O"/"o"/"Y"/"y" means yes, anything else to cancel: ')
				local reponse = io.read()
				if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
					redkey = true
					doors[room]["redkey"] = false
				end
			end
		end
		if (doors[room + 1]["key"] and (not (PERCENT(room, NumberInALine) == 0))) or (doors[room - 1]["key"] and (not (PERCENT(room, NumberInALine) == 1))) or (doors[room + NumberInALine]["key"]) or (doors[room - NumberInALine]["key"]) then
			print("You briefly see a shining, but you couldn't say from where it comes from.")
		end
		if (doors[room + 1]["redkey"] and (not (PERCENT(room, NumberInALine) == 0))) or (doors[room - 1]["redkey"] and (not (PERCENT(room, NumberInALine) == 1))) or (doors[room + NumberInALine]["redkey"]) or (doors[room - NumberInALine]["redkey"]) then
			print("A deadly light?? questions you, but you couldn't say from where it comes from.")
		end
		if (doors[room + 1]["sword"] and (not (PERCENT(room, NumberInALine) == 0))) or (doors[room - 1]["sword"] and (not (PERCENT(room, NumberInALine) == 1))) or (doors[room + NumberInALine]["sword"]) or (doors[room - NumberInALine]["sword"]) then
			print("You briefly see a sharpened blade in a nearly room.")
		end
		if (doors[room + 1]["monster"] and (not (PERCENT(room, NumberInALine) == 0))) or (doors[room - 1]["monster"] and (not (PERCENT(room, NumberInALine) == 1))) or (doors[room + NumberInALine]["monster"]) or (doors[room - NumberInALine]["monster"]) then
			print("A terrifying scream chills your blood, but it is so powerful you can't tell where does it come from.")
		end
		if (doors[room + 1]["exit"] and (not (PERCENT(room, NumberInALine) == 0))) or (doors[room - 1]["exit"] and (not (PERCENT(room, NumberInALine) == 1))) or (doors[room + NumberInALine]["exit"]) or (doors[room - NumberInALine]["exit"]) then
			print("You hear the storm, then see a sunbeam! The exit is near this room...")
		end
		if doors[room]["grave"] and doors[room]["deadlygrave"] then
			io.write("You chose to enter the room underneath, but it is a grave.\n")
			if (doors[room]["keyneeded"] == "redkey") and (redkey == true) or ((doors[room]["keyneeded"] == "key") and (key == true)) then
				io.write("Hopefully, you can exit it thanks to the ")
				if (doors[room]["keyneeded"] == "redkey") and (redkey == true) then
					io.write("red key")
					redkey = false
				end
				if (doors[room]["keyneeded"] == "key") and (key == true) then
					io.write("key")
					key = false
				else
					io.write("EXCEPTION.UNKNOWN_KEY_VALUE: " .. doors[room]["keyneeded"] .. " AT LINE #XX")
				end
				io.write(", so you open the grave's exit, located at the ")
				doors[room]["deadlygrave"] = false
			else
				end_ = true
				print("You DIE.\nYou could've exit if you had the ")
				if (doors[room]["keyneeded"] == "key") then
					io.write("key")
				elseif (doors[room]["keyneeded"] == "redkey") then
					io.write("red key")
				else
					io.write("EXCEPTION.UNKNOWN_KEY_VALUE: " .. doors[room]["keyneeded"] .. " AT LINE #XX")
				end
				io.write(" of the exit located at the ")
			end
			print(dir[doors[room]["exitdir"]] .. ".")
			if doors[room]["exitdir"] == "up" then
				doors[room - NumberInALine]["down"] = true
			elseif doors[room]["exitdir"] == "down" then
				doors[room + NumberInALine]["up"] = true
			elseif doors[room]["exitdir"] == "left" then
				doors[room - 1]["right"] = true
			elseif doors[room]["exitdir"] == "right" then
				doors[room + 1]["left"] = true
			else
				print("EXCEPTION.UNKNOWN_EXIT_DIR: " .. doors[room]["exitdir"] .. " AT LINE #XXX")
			end
		end
		if doors[room]["graveorig"] then
			io.write("After having walked across stairs, you see a room filled with skeletons.\nA grid is located on the ground and leads to another room.\nDo you want to continue and go donwstairs or go backwards ? (O / o / Y / y means go downstairs, everything else means go back): ")
			doors[room]["saw"] = true
			local resultat = io.read()
			if (resultat == 'O') or (resultat == 'o') or (resultat == 'Y') or (resultat == 'y') then
				room = room - 1
				CheckRoom()
			else
				room = old_room
				CheckRoom()
			end
		end
	end
end

function main()
--	ResetDoors()
	Initializer()
	end_ = false
	sword = false
	key = false
	redkey = false
--	room = 28
--	room = 23
	print("You are in room 1, or \"starting room\". You can try to go in each 4 directions. What do you choose?")
	while not end_ do	-- here starts interactive
		doors[room]["saw"] = true
		old_room = room
		print("")
		io.write('"' .. directions["up"] .. '", "' .. directions["down"] .. '", "' .. directions["left"] .. '", "' .. directions["right"] .. '" (directions), "wait" (if you want to act with what is in the same room as you), "exit" or "map" : ')
		local movement = io.read()
		if (movement == directions["up"]) then
			-- go up !
			if doors[room]["up"] or ((not doors[room]["door"]) and (doors[room]["dir_door"] == "up")) or ((not doors[room]["reddoor"]) and (doors[room]["dir_reddoor"] == "up")) or (doors[room]["grave"] and (doors[room]["exitdir"] == "up")) then
				room = room - NumberInALine
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["down"]) then
			-- go down !
			if doors[room]["down"] or ((not doors[room]["door"]) and (doors[room]["dir_door"] == "down")) or ((not doors[room]["reddoor"]) and (doors[room]["dir_reddoor"] == "down")) or (doors[room]["grave"] and (doors[room]["exitdir"] == "down")) then
				room = room + NumberInALine
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["left"]) then
			-- go left !
			if doors[room]["left"] or ((not doors[room]["door"]) and (doors[room]["dir_door"] == "left")) or ((not doors[room]["reddoor"]) and (doors[room]["dir_reddoor"] == "left")) or (doors[room]["grave"] and (doors[room]["exitdir"] == "left")) then
				room = room - 1
			else
				print "BOOMM !!"
			end
		elseif (movement == directions["right"]) then
			-- go right !
			if doors[room]["right"] or ((not doors[room]["door"]) and (doors[room]["dir_door"] == "right")) or ((not doors[room]["reddoor"]) and (doors[room]["dir_reddoor"] == "right")) or (doors[room]["grave"] and (doors[room]["exitdir"] == "right")) then
				room = room + 1
			else
				print "BOOMM !!"
			end
		elseif (movement == "w?") or (movement == "w ") or (movement == "m") or (movement == "map") then
			-- say the room
			--print(room)
			--print(doors[room]["up"])
			--print(doors[room]["down"])
			--print(doors[room]["left"])
			--print(doors[room]["right"])
			-- print the MAP instead of saying room
			PrintMap()
		elseif (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") then
			end_ = true
		elseif (movement == "w") or (movement == "wait") then
		else
			--print("EXCEPTION.UNKNOWN_COMMAND: " .. movement .. " AT LINE #XXXX")
			print("Unknown command: " .. movement)
		end
		if not ((movement == "w ?") or (movement == "w ") or (movement == "m") or (movement == "map")
		     or (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit")) then
			CheckRoom()
		end
	end
	sword = false
	key = false
	redkey = false
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
print("ResetDoors()")
print("main()")
print("\nTo see the map, write:")
print("PrintMap()")
if yes then
	print("Having exited, the full labyrinth is revealed because you now have its map!")
end
