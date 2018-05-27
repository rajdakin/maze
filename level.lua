import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local classmodule = require(import_prefix .. "class")
local utilmodule = require(import_prefix .. "util")

local levels = {}

local cardinals = {}
cardinals["up"] = "north"
cardinals["down"] = "south"
cardinals["left"] = "east"
cardinals["right"] = "west"

local Level = class(function(self, initial_room, level_length, level_array)
	self.__number_of_columns = level_length
	self.__old_room = initial_room
	self.__room = initial_room
	self.__datas = level_array
	
	self:initialize()
end)

function Level:getRoom()
	return self.__room
end

function Level:getRoomDatas()
	return self.__datas[self.get_room()]
end

function Level:getRoomsDatas()
	return self.__datas
end

function Level:getColumnCount()
	return self.__number_of_columns
end

function Level:setAllRoomsSeenStatusAs(seen)
	for k, v in pairs(self.__datas) do
		v["saw"] = seen
	end
end

local list_data = {"exit", "up", "down", "left", "right", "monster", "sword", "key", "door", "direction", "trap", "redkey", "reddoor", "grave", "graveorig", "saw"}
function Level:setUnreachables()
	local unreachable = false
	for k, v in pairs(self.__datas) do
		unreachable = true
		for key, val in pairs(list_data) do
			if v[val] then unreachable = false; break end
		end
		v["unreachable"] = unreachable
	end
end
function Level:initialize()
	for k, v in pairs(self.__datas) do
		for key, val in pairs(list_data) do
			if not v[val] then v[val] = false end
		end
	end
	
	self:setUnreachables()
end

function Level:printLevelMap(is_ended, objects)
	io.write("E = exit, s = sword, c = key, C = \27[9mred\27[00m \27[02;31mblood\27[00my key, d = door, D = red door, G = grave, g = grave's origin,   = nothing particular, \27[01;30;07;47m?\27[00m = not yet discovered, \27[01;30;41;07m \27[00m = wall")
	if not is_ended then
		io.write("\n\27[01;31mWITHOUT HACK, NEVER APPEARS!\27[00m")
	else
		io.write(",")
	end
	
	print(" \27[31mM\27[00m = monster, \27[31mT\27[00m = trap, \27[01;30;41;07mU\27[00m = unreachable")
	print("")
	if objects["key"] or objects["redkey"] or objects["sword"] then
		if objects["key"] then
			print("You have a \27[45;01;32mkey\27[00m.")
		end
		if objects["redkey"] then
			print("You have a \27[46;01;31mred key...?\27[00m.")
		end
		if objects["sword"] then
			print("You have a \27[01;39;40;07msword\27[00m.")
		end
		print("")
	end
	local sizeOfMap = getArrayLength(self.__datas) - 2 * self.__number_of_columns
	local i
	for i = 1, sizeOfMap do
		local v = self.__datas[i]
		if i % self.__number_of_columns == 1 then
			if i ~= 1 then
				print("\27[01;30;41;07m \27[00m")
			end
			io.write("\27[01;30;41;07m ")--+")
			for j = 1, self.__number_of_columns do
				if (self.__datas[i + j - self.__number_of_columns - 1]["down"]
					or (((not self.__datas[i + j - self.__number_of_columns - 1]["door"]) and (self.__datas[i + j - self.__number_of_columns - 1]["dir_door"] == "down"))
					and ((not self.__datas[i + j - self.__number_of_columns - 1]["reddoor"]) and (self.__datas[i + j - self.__number_of_columns - 1]["dir_reddoor"] == "down")))
					or (((not self.__datas[i + j - self.__number_of_columns - 1]["door"]) and (self.__datas[i + j - self.__number_of_columns - 1]["dir_door"] == "down"))
					and ((not self.__datas[i + j - self.__number_of_columns - 1]["reddoor"]) and (self.__datas[i + j - self.__number_of_columns - 1]["dir_reddoor"] == nil)))
					or (((not self.__datas[i + j - self.__number_of_columns - 1]["door"]) and (self.__datas[i + j - self.__number_of_columns - 1]["dir_door"] == nil))
					and ((not self.__datas[i + j - self.__number_of_columns - 1]["reddoor"]) and (self.__datas[i + j - self.__number_of_columns - 1]["dir_reddoor"] == "down")))
					or (self.__datas[i + j - self.__number_of_columns - 1]["grave"] and (self.__datas[i + j - self.__number_of_columns - 1]["exitdir"] == "down")))
					and (self.__datas[i + j - self.__number_of_columns - 1]["saw"] or self.__datas[i + j - 1]["saw"]) then
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
			and (v["saw"] or ((i % self.__number_of_columns ~= 1) and self.__datas[i - 1]["saw"])) then
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
		if (i == self.__room) and not is_ended then
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
		if (i == self.__room) and not is_ended then
			io.write("\27[00m")
		end
	end
	io.write("\27[01;30;41;07m \27[00m\n\27[01;30;41;07m ")
	for j = 1, self.__number_of_columns do
		io.write("  ")
	end
	print("\27[00m")
end

function Level:checkLevelEvents(is_ended, objects)
	if self:getRoomAttribute("sword") then
		io.write("You see a sword on a book, that says that this sword will self-disintegrate with its first target.\nYou turn the page and you read that you can only have one at a time and that if you take this one, every other sword will disintegrates.\n")
		if objects["sword"] then io.write("You do already have one. ") end
		io.write("Do you want to take this sword? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
		local reponse = io.read()
		if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
			objects["sword"] = true
			self:setRoomAttribute("sword", false)
		end
	end
	if self:getRoomAttribute("monster") then
		if objects["sword"] then
			print("You see a monster! Quick, you arm your weapon... the moment it runs toward you! Your sword kills him, but it disintegrates... You don't have a sword anymore.")
			objects["sword"] = false
			self:setRoomAttribute("monster", false)
		else
			print("Yous see a monster, but, due to your lack of equipment, you don't have any weapon... While you try to escape, the monster catch you and eat you. You are DEAD!")
			objects["sword"] = false
			is_ended = true
			objects["key"] = false
			objects["redkey"] = false
		end
	end
	if self:getRoomAttribute("key") then
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
		io.write("\nIf you insert it in a closed door and then you remove it, it will self-disintegrate.\nIf the door isn't locked, then you'll be able to remove it without worrying. One the door unlocked, remove the key and no one will be able to lock it again (with one exception).\nIf you lock a door...\"\nThen a lot of explanations.\n\"If you take this key, every other key you have will disintegrate.\"\n\n")
		if objects["key"] then io.write("You do already have a key. ") end
		io.write("Do you want to take it? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
		io.flush()
		local reponse = io.read()
		if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
			objects["key"] = true
			self:setRoomAttribute("key", false)
		end
	end
	if self:getRoomAttribute("door") then
		if objects["key"] then
			if (not self:getRoomAttribute("exit")) or (self:getRoomAttribute("dir_exit") ~= self:getRoomAttribute("dir_door")) then
				print("You see a door at the " .. cardinals[self:getRoomAttribute("dir_door")] .. ", that you open with your key.\nBut when you release the key, the door is closing by itself!\nYou reopen it, but before that the door closes, you remove your key, and the door stay opened.\nThe key disintegrate. You don't have the key anymore.")
				objects["key"] = false
				self:setRoomAttribute("door", false)
				if (self:getRoomAttribute("dir_door") == "up") then
					self:setAttribute(self:getRoom() - self:getColumnCount(), "door", false)
					self:setAttribute(self:getRoom() - self:getColumnCount(), "dir_door", "down")
				elseif (self:getRoomAttribute("dir_door") == "down") then
					self:setAttribute(self:getRoom() + self:getColumnCount(), "door", false)
					self:setAttribute(self:getRoom() + self:getColumnCount(), "dir_door", "up")
				elseif (self:getRoomAttribute("dir_door") == "left") then
					self:setAttribute(self:getRoom() - 1, "door", false)
					self:setAttribute(self:getRoom() - 1, "dir_door", "right")
				elseif (self:getRoomAttribute("dir_door") == "right") then
					self:setAttribute(self:getRoom() + 1, "door", false)
					self:setAttribute(self:getRoom() + 1, "dir_door", "left")
				else
					print("EXCEPTION.UNKNOWN_DOOR_DIR: " .. self:getRoomAttribute("dir_door") .. " AT LINE #")
				end
			else
				print("You see the exit at the " .. cardinals[self:getRoomAttribute("dir_exit")] .. "!\nQuick, you take your key and you open the exit door.\nYou survived against the monsters and the traps and you WON!")
				resetMaze()
				setRoomsAsSeen()
				is_ended = true
			end
		else
			print("You see a door at the " .. cardinals[self:getRoomAttribute("dir_door")] .. ".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door won't open...\nYou cannot move to the " .. cardinals[self:getRoomAttribute("dir_door")] .. ".")
		end
	end
	if self:getRoomAttribute("reddoor") then
		if objects["redkey"] then
			if (not self:getRoomAttribute("exit")) or (self:getRoomAttribute("dir_exit") ~= self:getRoomAttribute("dir_reddoor")) then
				print("You see a door you don't want to approach at the " .. cardinals[self:getRoomAttribute("dir_reddoor")] .. ".\nHopefully, you remember that you have a red key, of the same color than the door. You open the door.")
				objects["redkey"] = false
				self:setRoomAttribute("reddoor", false)
				if (self:getRoomAttribute("dir_reddoor") == "up") then
					self:setAttribute(self:getRoom() - self:getColumnCount(), "reddoor", false)
					self:setAttribute(self:getRoom() - self:getColumnCount(), "dir_reddoor", "down")
				elseif (self:getRoomAttribute("dir_reddoor") == "down") then
					self:setAttribute(self:getRoom() + self:getColumnCount(), "reddoor", false)
					self:setAttribute(self:getRoom() + self:getColumnCount(), "dir_reddoor", "up")
				elseif (self:getRoomAttribute("dir_reddoor") == "left") then
					self:setAttribute(self:getRoom() - 1, "reddoor", false)
					self:setAttribute(self:getRoom() - 1, "dir_reddoor", "right")
				elseif (self:getRoomAttribute("dir_reddoor") == "right") then
					self:setAttribute(self:getRoom() + 1, "reddoor", false)
					self:setAttribute(self:getRoom() + 1, "dir_reddoor", "left")
				else
					print("EXCEPTION.UNKNOWN_REDDOOR_DIR: " .. self:getRoomAttribute("dir_reddoor") .. " AT LINE #X")
				end
			else
				print("You see a door you don't want to approach at the " .. cardinals[self:getRoomAttribute("dir_exit")] .. " blocking the exit!\nHopefully, you remember that you have a red key, of the same color than the door. You open the door and you exit this maze!\nYou survived against the monsters and the traps and you WON!")
				resetMaze()
				setRoomsAsSeen()
				is_ended = true
			end
		else
			io.write("You see a door you don't want to approach at the " .. cardinals[self:getRoomAttribute("dir_exit")])
			if self:getRoomAttribute("exit") and (self:getRoomAttribute("dir_exit") == self:getRoomAttribute("dir_reddoor")) then
				io.write(" blocking the exit..")
			end
			io.write(".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door doesn't open...\nYou cannot ")
			if self:getRoomAttribute("exit") and (self:getRoomAttribute("dir_exit") == self:getRoomAttribute("dir_reddoor")) then
				io.write("exit the maze..")
			else
				io.write("go to " .. cardinals[self:getRoomAttribute("dir_reddoor")])
			end
			print(".")
		end
	end
	if self:getRoomAttribute("trap") then
		print("You felt into a trap, and, with terrible pain, you DIE.")
		is_ended = true
	end
	if not is_ended then
		if self:getRoomAttribute("redkey") then
			io.write("You see a red")
			io.flush()
			sleep(1)
			io.write("\8\8\8wait, no")
			io.flush()
			sleep(1)
			io.write("\8\8\8\8\8\8\8\8bloody key in a book.\nIt says that this key already closed a door, and only it can reopen it.\n")
			if objects["redkey"] then
				print("You decided not to take it, as you already have one.")
			else
				io.write('Do you want to take it? "O"/"o"/"Y"/"y" means yes, anything else to cancel: ')
				local reponse = io.read()
				if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
					objects["redkey"] = true
					self:setRoomAttribute("redkey", false)
				end
			end
		end
		if (self:getAttribute(self:getRoom() + 1, "key") and (not (self:getRoom() % self:getColumnCount() == 0))) or (self:getAttribute(self:getRoom() - 1, "key") and (not (self:getRoom() % self:getColumnCount() == 1))) or (self:getAttribute(self:getRoom() + self:getColumnCount(), "key")) or (self:getAttribute(self:getRoom() - self:getColumnCount(), "key")) then
			print("You briefly see a shining, but you couldn't say from where it comes from.")
		end
		if (self:getAttribute(self:getRoom() + 1, "redkey") and (not (self:getRoom() % self:getColumnCount() == 0))) or (self:getAttribute(self:getRoom() - 1, "redkey") and (not (self:getRoom() % self:getColumnCount() == 1))) or (self:getAttribute(self:getRoom() + self:getColumnCount(), "redkey")) or (self:getAttribute(self:getRoom() - self:getColumnCount(), "redkey")) then
			print("A deadly light?? questions you, but you couldn't say from where it comes from.")
		end
		if (self:getAttribute(self:getRoom() + 1, "sword") and (not (self:getRoom() % self:getColumnCount() == 0))) or (self:getAttribute(self:getRoom() - 1, "sword") and (not (self:getRoom() % self:getColumnCount() == 1))) or (self:getAttribute(self:getRoom() + self:getColumnCount(), "sword")) or (self:getAttribute(self:getRoom() - self:getColumnCount(), "sword")) then
			print("You briefly see a sharpened blade in a nearly room.")
		end
		if (self:getAttribute(self:getRoom() + 1, "monster") and (not (self:getRoom() % self:getColumnCount() == 0))) or (self:getAttribute(self:getRoom() - 1, "monster") and (not (self:getRoom() % self:getColumnCount() == 1))) or (self:getAttribute(self:getRoom() + self:getColumnCount(), "monster")) or (self:getAttribute(self:getRoom() - self:getColumnCount(), "monster")) then
			print("A terrifying scream chills your blood, but it is so powerful you can't tell where does it come from.")
		end
		if (self:getAttribute(self:getRoom() + 1, "exit") and (not (self:getRoom() % self:getColumnCount() == 0))) or (self:getAttribute(self:getRoom() - 1, "exit") and (not (self:getRoom() % self:getColumnCount() == 1))) or (self:getAttribute(self:getRoom() + self:getColumnCount(), "exit")) or (self:getAttribute(self:getRoom() - self:getColumnCount(), "exit")) then
			print("You hear the storm, then see a sunbeam! The exit is near this room...")
		end
		if self:getRoomAttribute("grave") and self:getRoomAttribute("deadlygrave") then
			io.write("You chose to enter the room underneath, but it appears to be a grave.\n")
			if (self:getRoomAttribute("keyneeded") == "redkey") and (objects["redkey"] == true) or ((self:getRoomAttribute("keyneeded") == "key") and (objects["key"] == true)) then
				io.write("Hopefully, you can exit it thanks to the ")
				if (self:getRoomAttribute("keyneeded") == "redkey") and (objects["redkey"] == true) then
					io.write("red key")
					objects["redkey"] = false
				end
				if (self:getRoomAttribute("keyneeded") == "key") and (objects["key"] == true) then
					io.write("key")
					objects["key"] = false
				else
					io.write("EXCEPTION.UNKNOWN_KEY_VALUE: " .. self:getRoomAttribute("keyneeded") .. " AT LINE #XX")
				end
				io.write(", so you open the grave's exit, located at the ")
				self:setRoomAttribute("deadlygrave", false)
			else
				is_ended = true
				print("You DIE.\nYou could've exit if you had the ")
				if (self:getRoomAttribute("keyneeded") == "key") then
					io.write("key")
				elseif (self:getRoomAttribute("keyneeded") == "redkey") then
					io.write("red key")
				else
					io.write("EXCEPTION.UNKNOWN_KEY_VALUE: " .. self:getRoomAttribute("keyneeded") .. " AT LINE #XX")
				end
				io.write(" of the exit located at the ")
			end
			print(cardinals[self:getRoomAttribute("exitdir")] .. ".")
			if self:getRoomAttribute("exitdir") == "up" then
				self:setAttribute(self:getRoom() - self:getColumnCount(), "down", true)
			elseif self:getRoomAttribute("exitdir") == "down" then
				self:setAttribute(self:getRoom() + self:getColumnCount(), "up", true)
			elseif self:getRoomAttribute("exitdir") == "left" then
				self:setAttribute(self:getRoom() - 1, "right", true)
			elseif self:getRoomAttribute("exitdir") == "right" then
				self:setAttribute(self:getRoom() + 1, "left", true)
			else
				print("EXCEPTION.UNKNOWN_EXIT_DIR: " .. self:getRoomAttribute("exitdir") .. " AT LINE #XXX")
			end
		end
		if self:getRoomAttribute("graveorig") then
			io.write("After having walked across stairs, you see a room filled with skeletons.\nA grid is located on the ground and leads to another room.\nDo you want to continue and go donwstairs or go backwards ? (O / o / Y / y means go downstairs, everything else means go back): ")
			self:setRoomAttribute("saw", true)
			local resultat = io.read()
			if (resultat == 'O') or (resultat == 'o') or (resultat == 'Y') or (resultat == 'y') then
				self:setRoom(self:getRoom() - 1)
				return self:checkLevelEvents(is_ended, objects)
			else
				self:restoreRoom()
				return self:checkLevelEvents(is_ended, objects)
			end
		end
	end
	return {is_ended, objects}
end

function Level:getRoomAttribute(attributeName) return self.__datas[self.__room][attributeName] end
function Level:setRoomAttribute(attributeName, status) self.__datas[self.__room][attributeName] = status end

function Level:getAttribute(room, attributeName) return self.__datas[room][attributeName] end
function Level:setAttribute(room, attributeName, status) self.__datas[room][attributeName] = status end

function Level:setRoom(room) self.__old_room = self.__room; self.__room = room end
function Level:restoreRoom() self.__room = self.__old_room end

function getArrayLength(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

local function initialize_levels()
	levels[1] = Level(28, 7, {[-6] = {},                                                                                                              [-5] = {},                                           [-4] = {},                                                        [-3] = {},                                           [-2] = {},                                                        [-1] = {},                                                         [0] = {},
	                          {exit = true, dir_exit = "left",            down = true,                               door = true, dir_door = "left"}, {                                     right = true}, {           down = true, left = true, right = true},              {                        left = true, right = true}, {                        left = true, right = true},              {                        left = true, right = true, sword = true}, {           down = true, left = true},
	                          {                                up = true,              right = true, monster = true},                                 {           down = true, left = true, right = true}, {up = true,              left = true, right = true},              {                        left = true},               {up = true, down = true},                                         {           down = true,              right = true},               {up = true,              left = true},
	                          {                                           down = true, right = true},                                                 {up = true,              left = true},               {},                                                               {           down = true,              right = true}, {up = true,              left = true},                            {up = true, down = true,              right = true},               {           down = true, left = true},
	                          {                                up = true,              right = true},                                                 {                        left = true, right = true}, {                        left = true, right = true, key = true},  {up = true,              left = true, right = true}, {                        left = true, right = true, trap = true}, {up = true,              left = true, right = true},               {up = true,              left = true},
	                          {},                                                                                                                     {},                                                  {},                                                               {},                                                  {},                                                               {},                                                                {}}
	)
	levels[2] = Level(23, 7, {[-6] = {},                                                                             [-5] = {},                                           [-4] = {},                                                          [-3] = {},                                                                                                                   [-2] = {},                                                                                             [-1] = {},                                                           [0] = {},
	                          {           right = true,                             door = true, dir_door = "down"}, {           down = true, left = true},               {           down = true,              right = true},                {exit = true, dir_exit = "up",                         left = true,                           door = true, dir_door = "up"}, {},                                                                                                    {           down = true,                            monster = true}, {},
	                          {up = true, right = true,                 key = true, door = true, dir_door = "up"},   {up = true, down = true, left = true, right = true}, {up = true,              left = true},                              {                                                                   right = true},                                           {           down = true, left = true, right = true, sword = true},                                     {up = true, down = true, left = true, right = true},                 {left = true, trap = true},
	                          {},                                                                                    {up = true, down = true,              right = true}, {                        left = true, right = true},                {                                         down = true, left = true, right = true, key = true},                               {up = true,              left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                          {},                                                                                    {up = true, down = true,              right = true}, {                        left = true},                              {                              up = true,                           right = true},                                           {                        left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                          {           right = true, monster = true},                                             {up = true,              left = true, right = true}, {                        left = true, right = true, redkey = true}, {                                                      left = true, right = true},                                           {up = true,              left = true,               sword = true, reddoor = true, dir_reddoor = "up"}, {up = true,                           right = true},                 {left = true, trap = true},
	                          {},                                                                                    {},                                                  {},                                                                 {},                                                                                                                          {},                                                                         {},                                                                                             {}}
	)
	levels[-1] = Level(4, 2, {[-1] = {},                                                                                                                                                                   [0] = {},
	                          {exit = true, dir_exit = "left",                 reddoor = true, dir_reddoor = "left", right = true, grave = true, deadlygrave = true, keyneeded = "key", exitdir = "down"}, {           down = true,             graveorig = true},
	                          {                                redkey = true},                                                                                                                             {up = true,              key = true},
	                          {},                                                                                                                                                                          {}}
	)
	levels[-2] = Level(4, 2, {[-1] = {},                                                                                              [0] = {},
	                          {exit = true, dir_exit = "left", reddoor = true, dir_reddoor = "left", door = true, dir_door = "left"}, {graveorig = true, down = true},
	                          {},                                                                                                     {up = true, key = true, redkey = true},
	                          {},                                                                                                     {}}
	)
end

function get_levels()
	return levels
end

function get_active_level()
	local levels = get_levels()
	return levels[2]
end

initialize_levels()
