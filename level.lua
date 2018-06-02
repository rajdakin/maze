import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local eventsmodule = require(import_prefix .. "events")
local classmodule = require(import_prefix .. "class")
local roommodule = require(import_prefix .. "room")

local levels = {}

--[[local]] Level = class(function(self, initial_room, level_length, level_array)
	self.__number_of_columns = level_length
	self.__old_room = initial_room
	self.__room_number = initial_room
	
	self.__rooms = {}
	for i = 1 - level_length, getArrayLength(level_array) - level_length do
		self.__rooms[i] = Room(level_array[i])
	end
	
	self:initialize()
end)

function Level:refreshActiveRoomNearEvents()
	self:getActiveRoom():refreshRoomNearEvents(self:getRoomNumber() % self:getColumnCount(),
		self:getRoom(self:getRoomNumber() - self:getColumnCount()), self:getRoom(self:getRoomNumber() + self:getColumnCount()),
		self:getRoom(self:getRoomNumber() - 1), self:getRoom(self:getRoomNumber() + 1))
end

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
	print("E = exit, S = sword, K = key, k = \27[9mred\27[00m \27[02;31mblood\27[00my key, \27[44m \27[00m = door, \27[41m \27[00m = red door, \27[45m \27[00m = grave to grave's origin,   = nothing particular, \27[01;30;07;47m?\27[00m = not yet discovered, \27[01;30;41;07m \27[00m = wall, \27[31mM\27[00m = monster, \27[31mT\27[00m = trap, \27[01;30;41;07mU\27[00m = unreachable")
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
	
	local w, h
	w = (getRoomDisplayWidth()  - 1) * self:getColumnCount() + 1
	h = (getRoomDisplayHeight() - 1) * self:getColumnCount() + 1
	local sizeOfMap = getArrayLength(self:getRooms()) - 2 * self:getColumnCount()
	local i, j
	
	io.write("\27[s\27[01;30;47;07m")
	for i = 1, w do
		io.write(" ")
	end
	io.write("\27[G")
	
	for i = 1, sizeOfMap do
		if i % self:getColumnCount() == 1 then
			if i ~= 1 then
				io.write("\27[" .. getRoomDisplayHeight() - 1 .. "B")
			end
			for j = 1, getRoomDisplayHeight() do
				io.write("\27[00m\n\27[s\27[01;30;47;07m \27[u")
			end
			io.write("\27[" .. getRoomDisplayHeight() .. "A\27[D")
		end
		self:getRoom(i):printRoom(objets, (i == self:getRoomNumber()) and not is_ended)
	end
	io.write("\27[" .. getRoomDisplayHeight() - 1 .. "B\n\27[G \27[D")
	io.flush()
end

function Level:checkLevelEvents(is_ended, objects)
	local i = self:getRoomNumber()
	ret = self:getRoom(i):checkRoomEvents(is_ended, objects, i % self:getColumnCount(),
	                                      self:getRoom(i - self:getColumnCount()), self:getRoom(i + self:getColumnCount()), 
										  self:getRoom(i - 1), self:getRoom(i + 1))
	is_ended = ret.ended
	objects = ret.objects
	if ret:isinstance(EventParsingReturnRoomChanging) then
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
	elseif ret:isinstance(EventParsingReturnRoomRestore) then
		self:restoreRoom()
		ret = self:checkLevelEvents(is_ended, objects)
	end
	
	return ret
end

require("contribution")
local function initialize_levels()
	levels[1] = Level(28, 7, {[-6] = {},                                                                                                              [-5] = {},                                           [-4] = {},                                                        [-3] = {},                                           [-2] = {},                                                        [-1] = {},                                                         [0] = {},
	                          {exit = true, dir_exit = "left",            down = true,                               door = true, dir_door = "left"}, {                                     right = true}, {           down = true, left = true, right = true},              {                        left = true, right = true}, {                        left = true, right = true},              {                        left = true, right = true, sword = true}, {           down = true, left = true},
	                          {                                up = true,              right = true, monster = true},                                 {           down = true, left = true, right = true}, {up = true,              left = true, right = true},              {                        left = true},               {up = true, down = true},                                         {           down = true,              right = true},               {up = true,              left = true},
	                          {                                           down = true, right = true},                                                 {up = true,              left = true},               {},                                                               {           down = true,              right = true}, {up = true,              left = true},                            {up = true, down = true,              right = true},               {           down = true, left = true},
	                          {                                up = true,              right = true},                                                 {                        left = true, right = true}, {                        left = true, right = true, key = true},  {up = true,              left = true, right = true}, {                        left = true, right = true, trap = true}, {up = true,              left = true, right = true},               {up = true,              left = true},
	                          {},                                                                                                                     {},                                                  {},                                                               {},                                                  {},                                                               {},                                                                {}}
	)
	levels[2] = Level(23, 7, {[-6] = {},                                                                  [-5] = {},                                           [-4] = {},                                                          [-3] = {},                                                                                                                   [-2] = {},                                                                                             [-1] = {},                                                           [0] = {},
	                          {right = true,                             door = true, dir_door = "down"}, {           down = true, left = true},               {           down = true,              right = true},                {exit = true, dir_exit = "up",                         left = true,                           door = true, dir_door = "up"}, {},                                                                                                    {           down = true,                            monster = true}, {},
	                          {right = true,                 key = true, door = true, dir_door = "up"},   {up = true, down = true, left = true, right = true}, {up = true,              left = true},                              {                                                                   right = true},                                           {           down = true, left = true, right = true, sword = true},                                     {up = true, down = true, left = true, right = true},                 {left = true, trap = true},
	                          {},                                                                         {up = true, down = true,              right = true}, {                        left = true, right = true},                {                                         down = true, left = true, right = true, key = true},                               {up = true,              left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                          {},                                                                         {up = true, down = true,              right = true}, {                        left = true},                              {                              up = true,                           right = true},                                           {                        left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                          {right = true, monster = true},                                             {up = true,              left = true, right = true}, {                        left = true, right = true, redkey = true}, {                                                      left = true, right = true},                                           {                        left = true,               sword = true, reddoor = true, dir_reddoor = "up"}, {up = true,                           right = true},                 {left = true, trap = true},
	                          {},                                                                         {},                                                  {},                                                                 {},                                                                                                                          {},                                                                         {},                                                                                             {}}
	)
	levels[-1] = Level(4, 2, {[-1] = {},                                                                                                                                                                  [0] = {},
	                          {exit = true, dir_exit = "left",                reddoor = true, dir_reddoor = "left", right = true, grave = true, deadlygrave = true, keyneeded = "key", exitdir = "down"}, {           down = true,             graveorig = true},
	                          {                                redkey = true},                                                                                                                            {up = true,              key = true},
	                          {},                                                                                                                                                                         {}}
	)
	levels[-2] = Level(4, 2, {[-1] = {},                                                                                              [0] = {},
	                          {exit = true, dir_exit = "left", reddoor = true, dir_reddoor = "left", door = true, dir_door = "left"}, {graveorig = true, down = true},
	                          {},                                                                                                     {up = true, key = true, redkey = true},
	                          {},                                                                                                     {}}
	)
	levels[-3] = Level(1, 2, {[-1] = {},                                                                                                                     [0] = {},
	                          {           down = true, right = true, redkey = true},                                                                         {exit = true, dir_exit = "up", left = true, reddoor = true, dir_reddoor = "up"},
	                          {up = true,                                           door = true, dir_door = "right", reddoor = true, dir_reddoor = "right"}, {},
	                          {},                                                                                                                            {}}
	)
	
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
