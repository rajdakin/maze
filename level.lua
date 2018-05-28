import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")
local roommodule = require(import_prefix .. "room")

local levels = {}

local cardinals = {}
cardinals["up"] = "north"
cardinals["down"] = "south"
cardinals["left"] = "east"
cardinals["right"] = "west"

local Level = class(function(self, initial_room, level_length, level_array)
	self.__number_of_columns = level_length
	self.__old_room = initial_room
	self.__room_number = initial_room
	
	self.__rooms = {}
	for i = 1 - level_length, getArrayLength(level_array) - level_length do
		self.__rooms[i] = Room(level_array[i])
	end
	
	self:initialize()
end)


function Level:getActiveRoomAttribute(attributeName) return self:getRoom(self.__room_number):getAttribute(attributeName)        end
function Level:setActiveRoomAttribute(attributeName, value) self:getRoom(self.__room_number):setAttribute(attributeName, value) end

function Level:getRoomAttribute(room, attributeName) return self:getRoom(room):getAttribute(attributeName)        end
function Level:setRoomAttribute(room, attributeName, value) print(room); self:getRoom(room):setAttribute(attributeName, value) end

function Level:getRoomNumber() return self.__room_number end
function Level:setRoom(room) self.__old_room = self.__room_number; self.__room_number = room end
function Level:restoreRoom() self.__room_number = self.__old_room end

function Level:getRooms() return self.__rooms end
function Level:getActiveRoom()  return self:getRooms()[self:getRoomNumber()] end
function Level:getRoom(room_no) return self:getRooms()[room_no]              end

function Level:getColumnCount() return self.__number_of_columns end

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
	local sizeOfMap = getArrayLength(self:getRooms()) - 2 * self:getColumnCount()
	local i
	for i = 1, sizeOfMap do
		if i % self:getColumnCount() == 1 then
			if i ~= 1 then
				print("\27[01;30;41;07m \27[00m")
			end
			io.write("\27[01;30;41;07m ")--+")
			for j = 1, self:getColumnCount() do
				if (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "down")
					or (((not self:getRoomAttribute(i + j - self:getColumnCount() - 1, "door")) and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "dir_door") == "down"))
					and ((not self:getRoomAttribute(i + j - self:getColumnCount() - 1, "reddoor")) and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "dir_reddoor") == "down")))
					or (((not self:getRoomAttribute(i + j - self:getColumnCount() - 1, "door")) and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "dir_door") == "down"))
					and ((not self:getRoomAttribute(i + j - self:getColumnCount() - 1, "reddoor")) and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "dir_reddoor") == nil)))
					or (((not self:getRoomAttribute(i + j - self:getColumnCount() - 1, "door")) and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "dir_door") == nil))
					and ((not self:getRoomAttribute(i + j - self:getColumnCount() - 1, "reddoor")) and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "dir_reddoor") == "down")))
					or (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "grave") and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "exitdir") == "down")))
					and (self:getRoomAttribute(i + j - self:getColumnCount() - 1, "saw") or self:getRoomAttribute(i + j - 1, "saw")) then
					io.write("\27[00m")-- ")
				--else
				--	io.write("-")
				end
				io.write(" \27[01;30;41;07m ")--+")
			end
			print("\27[00m")
		end
		self:getRoom(i):printRoom(objets, (i == self:getRoomNumber()) and not is_ended, (i % self:getColumnCount() ~= 1) and self:getRoomAttribute(i - 1, "saw"))
	end
	io.write("\27[01;30;41;07m \27[00m\n\27[01;30;41;07m ")
	for j = 1, self:getColumnCount() do
		io.write("  ")
	end
	print("\27[00m")
end

function Level:checkLevelEvents(is_ended, objects)
	ret = self:getActiveRoom():checkRoomEvents(is_ended, objects, self:getRoomNumber() % self:getColumnCount(), self)
	return ret
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
