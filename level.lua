import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local eventsmodule = require(import_prefix .. "events")
local configmodule = require(import_prefix .. "config")
local classmodule = require(import_prefix .. "class")
local roommodule = require(import_prefix .. "room")

local levels = {}

--[[local]] Level = class(function(self, level_datas, obs2, obs3)
	if type(level_datas) == "number" then
		self.__column_count = obs2
		self.__old_room = level_datas
		self.__room_number = level_datas
		self.__lores = {"", ""}
		self.__lore_begin = ""
		self.__lore_end   = {[false] = "", [true] = "You DIED..."}
		
		self.__rooms = {}
		for i = 1 - obs2, getArrayLength(obs3) - obs2 do
			self.__rooms[i] = Room(obs3[i])
		end
		
		self.__level_configuration = currentConfig:getLevelConfig()
		
		print("[Developer warning] [level module] Warning: obsolete level instanciation used. Please use the new version.")
	else
		self.__column_count = level_datas["column_count"]
		self.__old_room = level_datas["starting_room"]
		self.__room_number = level_datas["starting_room"]
		self.__lores = level_datas["lores"]
		self.__lore_begin = self.__lores[1]
		
		generic_death = "You DIED..."
		if type(self.__lores[2]) == "string" then self.__lore_end = {[false] = self.__lores[2], [true] = generic_end}
		elseif self.__lores[2][1] then
			if self.__lores[2][2] then self.__lore_end = {[false] = self.__lores[2][1], [true] = self.__lores[2][2]} else self.__lore_end = {[false] = self.__lores[2][1], [true] = generic_death} end
		elseif self.lores[2][false] then
			if self.__lores[2][true] then self.__lore_end = {[false] = self.__lores[2][false], [true] = self.__lores[2][true]} else self.__lore_end = {[false] = self.__lores[2][false], [true] = generic_death} end
		else self.__lore_end = {[false] = "", [true] = generic_death} end
		
		self.__rooms = {}
		for i = 1 - self.__column_count, getArrayLength(level_datas["rooms_datas"]) - self.__column_count do
			self.__rooms[i] = Room(level_datas["rooms_datas"][i])
		end
		
		self.__level_configuration = level_datas["level_conf"]
		if not self.__level_configuration then self.__level_configuration = currentConfig:getLevelConfig() end
	end
	
	self:initialize()
end)

function Level:refreshActiveRoomNearEvents()
	self:getActiveRoom():refreshRoomNearEvents(self:getRoomNumber() % self:getColumnCount(),
		self:getRoom(self:getRoomNumber() - self:getColumnCount()), self:getRoom(self:getRoomNumber() + self:getColumnCount()),
		self:getRoom(self:getRoomNumber() - 1), self:getRoom(self:getRoomNumber() + 1))
end

function Level:getMapSize() return getArrayLength(self:getRooms()) - 2 * self:getColumnCount() end

function Level:getLevelConfiguration() return self.__level_configuration end

function Level:getActiveRoomAttribute(attributeName) return self:getRoom(self.__room_number):getAttribute(attributeName)        end
function Level:setActiveRoomAttribute(attributeName, value) self:getRoom(self.__room_number):setAttribute(attributeName, value) end

function Level:getRoomAttribute(room, attributeName) return self:getRoom(room):getAttribute(attributeName)        end
function Level:setRoomAttribute(room, attributeName, value) self:getRoom(room):setAttribute(attributeName, value) end

function Level:getRoomNumber() return self.__room_number end
function Level:setRoom(room) self.__old_room = self.__room_number; self.__room_number = room end
function Level:restoreRoom() self.__room_number = self.__old_room end

function Level:getRooms() return self.__rooms end
function Level:getActiveRoom()  return self:getRooms()[self:getRoomNumber()] end
function Level:getRoom(room_no) return self:getRooms()[room_no]              end

function Level:getRoomCoordinates(room_no) local x, y = room_no % self:getColumnCount(), floor(room_no / self:getColumnCount()) if room_no % self:getColumnCount() == 0 then x = self:getColumnCount() y = y - 1 end return x, y end
function Level:getRoomFromCoordinates(x, y) return self:getRoom(x + y * self:getColumnCount()) end

function Level:getColumnCount() return self.__column_count end

function Level:setAllRoomsSeenStatusAs(seen)
	for k, v in pairs(self:getRooms()) do
		v:setAttribute("saw", seen)
	end
end

function Level:initialize()
	for k, v in pairs(self:getRooms()) do
		v:initialize()
		v:setUnreachable()
	end
end

function Level:printBeginingLore()
	print(self.__lore_begin)
end

function Level:printEndingLore(death, sword)
	print(self.__lore_end[death])
	-- Todo: use level's map reveal function
	self:setAllRoomsSeenStatusAs(not death)
end

function Level:reverseMap(objects)
	if objects and objects["key"] or objects["redkey"] or objects["sword"] then
		if objects["key"] then
			io.write("\27[A")
		end
		if objects["redkey"] then
			io.write("\27[A")
		end
		if objects["sword"] then
			io.write("\27[A")
		end
		io.write("\27[A")
	end
	io.write("\27[" .. min(self:getLevelConfiguration():getCamHeight(), floor(self:getMapSize() / self:getColumnCount())) * (getRoomDisplayWidth() - 1) + self:getLevelConfiguration():getMapYoffset() .. "A\27[J")
end

function Level:printLevelMap(is_ended, objects, doesDisplayAllMap)
	print("E = exit, S = sword, K = key, k = \27[9mred\27[00m \27[02;31mblood\27[00my key, \27[44m \27[00m = door, \27[41m \27[00m = red door, \27[45m \27[00m = grave to grave's origin,   = nothing particular, \27[01;30;07;47m?\27[00m = not yet discovered, \27[01;30;41;07m \27[00m = wall, \27[31mM\27[00m = monster, \27[31mT\27[00m = trap, \27[01;30;41;07mU\27[00m = unreachable")
	print("")
	if objects and objects["key"] or objects["redkey"] or objects["sword"] then
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
	
	local xOffset
	local yOffset
	local maxXcoord
	local maxYcoord
	local curXcoord
	local curYcoord
	
	if not doesDisplayAllMap then
		local camWidth  = self:getLevelConfiguration():getCamWidth ()
		local camHeight = self:getLevelConfiguration():getCamHeight()
		local roomX, roomY = self:getRoomCoordinates(self:getRoomNumber())
		xOffset = max(1, min(self:getColumnCount() - camWidth + 1, roomX - floor((camWidth - 1) / 2)))
		yOffset = max(0, min(floor(self:getMapSize() / self:getColumnCount()) - camHeight, roomY - floor((camHeight - 1) / 2)))
		maxXcoord = min(camWidth ,                           self:getColumnCount())  * (getRoomDisplayWidth() - 1) + 1
		maxYcoord = min(camHeight, floor(self:getMapSize() / self:getColumnCount())) * (getRoomDisplayWidth() - 1) + 1
	else
		xOffset = 1
		yOffset = 0
		maxXcoord = self:getColumnCount() * (getRoomDisplayWidth() - 1) + 1
		maxYcoord = floor(self:getMapSize() / self:getColumnCount()) * (getRoomDisplayWidth() - 1) + 1
	end
	
	io.write("\27[01;30;47;07m")
	for curXcoord = 1, maxXcoord do io.write(" ") end io.write("\27[00m\27[G")
	for curYcoord = 1, maxYcoord do io.write("\27[01;30;47;07m \27[00m\n") end io.write("\27[" .. maxYcoord .. "A")
	
	for curYcoord = 1, maxYcoord - 1, getRoomDisplayHeight() - 1 do
		for curXcoord = 1, maxXcoord - 1, getRoomDisplayWidth() - 1 do
			local roomX, roomY = (curXcoord - 1) / (getRoomDisplayWidth() - 1), (curYcoord - 1) / (getRoomDisplayHeight() - 1)
			local i = roomX + xOffset + (roomY + yOffset) * self:getColumnCount()
			
			local ret = self:getRoomFromCoordinates(roomX + xOffset, roomY + yOffset):printRoom(objets, (i == self:getRoomNumber()) and not is_ended)
			
			if ret:iskind(RoomPrintingError) then
				return LevelPrintingErrored(ret)
			end
		end
		io.write("\27[" .. getRoomDisplayHeight() - 1 .. "B\27[G")
	end
	print("\27[00m\n")
	
	return LevelPrintingDone()
end

function Level:checkLevelEvents(is_ended, objects)
	local i = self:getRoomNumber()
	ret = self:getRoom(i):checkRoomEvents(is_ended, objects, i % self:getColumnCount(),
	                                      self:getRoom(i - self:getColumnCount()), self:getRoom(i + self:getColumnCount()), 
										  self:getRoom(i - 1), self:getRoom(i + 1))
	is_ended = ret.ended
	objects = ret.objects
	if ret:isinstance(EventParsingResultRoomChanging) then
		if ret.room == "up" then
			ret.room = self:getRoomNumber() - self:getColumnCount()
		elseif ret.room == "down" then
			ret.room = self:getRoomNumber() + self:getColumnCount()
		elseif ret.room == "left" then
			ret.room = self:getRoomNumber() - 1
		elseif ret.room == "right" then
			ret.room = self:getRoomNumber() + 1
		end
		self:setRoom(ret.room)
		ret = self:checkLevelEvents(is_ended, objects)
	elseif ret:isinstance(EventParsingResultRoomRestore) then
		self:restoreRoom()
		ret = self:checkLevelEvents(is_ended, objects)
	end
	
	return ret
end

require("contribution")
local function initialize_levels()
	levels[1] = Level({["level_array_version"] = 1,
	    ["starting_room"] = 28,
	    ["column_count"] = 7,
	    ["rooms_datas"] = {[-6] = {},                                                                                                              [-5] = {},                                           [-4] = {},                                                        [-3] = {},                                           [-2] = {},                                                        [-1] = {},                                                         [0] = {},
	                       {exit = true, dir_exit = "left",            down = true,                               door = true, dir_door = "left"}, {                                     right = true}, {           down = true, left = true, right = true},              {                        left = true, right = true}, {                        left = true, right = true},              {                        left = true, right = true, sword = true}, {           down = true, left = true},
	                       {                                up = true,              right = true, monster = true},                                 {           down = true, left = true, right = true}, {up = true,              left = true, right = true},              {                        left = true},               {up = true, down = true},                                         {           down = true,              right = true},               {up = true,              left = true},
	                       {                                           down = true, right = true},                                                 {up = true,              left = true},               {},                                                               {           down = true,              right = true}, {up = true,              left = true},                            {up = true, down = true,              right = true},               {           down = true, left = true},
	                       {                                up = true,              right = true},                                                 {                        left = true, right = true}, {                        left = true, right = true, key = true},  {up = true,              left = true, right = true}, {                        left = true, right = true, trap = true}, {up = true,              left = true, right = true},               {up = true,              left = true},
	                       {},                                                                                                                     {},                                                  {},                                                               {},                                                  {},                                                               {},                                                                {}},
	    ["lores"] = {
	        "You arrived in a room. You don't know how you got here, or how to escape, neiher where you are.\nYou can however move, and you feels you have a huge carrying capacity, like the one from video game's character.\nWhat do you do?",
	        "After a long corridor, you found the map of the labyrinth you escaped. You continued to walk, but then you heard a \27[3mclick!\27[00m and you felt into the darkness...\n...Wait, not really...\n...Yeah, you just felt into an other maze."
		},
	    ["map_reveal"] = function(dead, sword) return not dead end -- Not yet implemented
	})
	levels[2] = Level({["level_array_version"] = 1,
		["starting_room"] = 23,
		["column_count"] = 7,
		["rooms_datas"] = {[-6] = {},                                                                  [-5] = {},                                           [-4] = {},                                                          [-3] = {},                                                                                                                   [-2] = {},                                                                                             [-1] = {},                                                           [0] = {},
	                       {right = true,                             door = true, dir_door = "down"}, {           down = true, left = true},               {           down = true,              right = true},                {exit = true, dir_exit = "up",                         left = true,                           door = true, dir_door = "up"}, {},                                                                                                    {           down = true,                            monster = true}, {},
	                       {right = true,                 key = true, door = true, dir_door = "up"},   {up = true, down = true, left = true, right = true}, {up = true,              left = true},                              {                                                                   right = true},                                           {           down = true, left = true, right = true, sword = true},                                     {up = true, down = true, left = true, right = true},                 {left = true, trap = true},
	                       {},                                                                         {up = true, down = true,              right = true}, {                        left = true, right = true},                {                                         down = true, left = true, right = true, key = true},                               {up = true,              left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                       {},                                                                         {up = true, down = true,              right = true}, {                        left = true},                              {                              up = true,                           right = true},                                           {                        left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                       {right = true, monster = true},                                             {up = true,              left = true, right = true}, {                        left = true, right = true, redkey = true}, {                                                      left = true, right = true},                                           {                        left = true,               sword = true, reddoor = true, dir_reddoor = "up"}, {up = true,                           right = true},                 {left = true, trap = true},
						   {},                                                                         {},                                                  {},                                                                 {},                                                                                                                          {},                                                                         {},                                                                                             {}},
	    ["lores"] = {
			"", -- Usually, you don't want anything for when you spawn in the maze.
			{"You walked along... an.. other corridor?   When you found yet another map. You continued along the corridor...\n...and you emerged to the surface! You are\n\nFREE!", "You died, even if this would've been the end anyways..."}
		}
	})
	levels[-1] = Level({["level_array_version"] = 1, ["starting_room"] = 4, ["column_count"] = 2, ["rooms_datas"] = {[-1] = {},                                                                                                                                                                  [0] = {},
	                                                                                                                 {exit = true, dir_exit = "left",                reddoor = true, dir_reddoor = "left", right = true, grave = true, deadlygrave = true, keyneeded = "key", exitdir = "down"}, {           down = true,             graveorig = true},
	                                                                                                                 {                                redkey = true},                                                                                                                            {up = true,              key = true},
	                                                                                                                 {},                                                                                                                                                                         {}}, ["lores"] = {"", ""} -- tests levels, no lores
	})
	levels[-2] = Level({["level_array_version"] = 1, ["starting_room"] = 4, ["column_count"] = 2, ["rooms_datas"] = {[-1] = {},                                                                                              [0] = {},
	                                                                                                                 {exit = true, dir_exit = "left", reddoor = true, dir_reddoor = "left", door = true, dir_door = "left"}, {graveorig = true, down = true},
	                                                                                                                 {},                                                                                                     {up = true, key = true, redkey = true},
	                                                                                                                 {},                                                                                                     {}}, ["lores"] = {"", ""} -- tests levels, no lores
	})
	levels[-3] = Level({["level_array_version"] = 1, ["starting_room"] = 1, ["column_count"] = 2, ["rooms_datas"] = {[-1] = {},                                                                                                                     [0] = {},
	                                                                                                                 {           down = true, right = true, redkey = true},                                                                         {exit = true, dir_exit = "up", left = true, reddoor = true, dir_reddoor = "up"},
	                                                                                                                 {up = true,                                           door = true, dir_door = "right", reddoor = true, dir_reddoor = "right"}, {},
	                                                                                                                 {},                                                                                                                            {}}, ["lores"] = {"", ""} -- tests levels, no lores
	})
	
	add_contrib_levels()
end

function get_levels()
	return levels
end

function get_active_level()
	local levels = get_levels()
	return levels[getArrayLength(levels) - 3]
end

initialize_levels()
