local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local contributionmodule = require(import_prefix .. "contribution")
local utilmodule = require(import_prefix .. "util")

local dictionarymodule = require(import_prefix .. "dictionary")
local consolemodule = require(import_prefix .. "console")
local configmodule = require(import_prefix .. "config")
local eventsmodule = require(import_prefix .. "events")
local classmodule = require(import_prefix .. "class")
local roommodule = require(import_prefix .. "room")

--[[ Level - the level class
	Holds the level's room and logic functions
	
	level_datas - the level datas
	level_config - the default level configuration = the level config of the level manager config
	obs3 - the 3rd level argument, used only for an obsolete way of instanciating the level.
]]
Level = class(function(self, level_datas, level_config, obs3)
	if type(level_datas) == "number" then
		self.__column_count = level_config
		self.__starting_room = level_datas
		self.__starting_rooms_datas = obs3
		
		self.__lores = {"", ""}
		self.__lore_begin = ""
		self.__lore_end   = {[false] = "", [true] = "You DIED..."}
		
		self.__level_configuration = currentConfig:getLevelManagerConfig():getLevelConfig()
		
		local init = self:initialize()
		self.initialize_status = {success = init.success, obsolete = true, old = true, opt = init}
	else
		self.__array_version = level_datas["level_array_version"]
		
		if self.__array_version == 1 then
			self.__column_count = level_datas["column_count"]
			self.__starting_room = level_datas["starting_room"]
			self.__starting_rooms_datas = level_datas["rooms_datas"]
			
			self.__lores = level_datas["lores"]
			
			if self.__lores then
				self.__lore_begin = self.__lores[1]
			end
			
			local generic_death = "You DIED..."
			if self.__lores and (type(self.__lores[2]) == "string") then self.__lore_end = {[false] = self.__lores[2], [true] = generic_death}
			elseif self.__lores and self.__lores[2][1] then
				if self.__lores[2][2] then self.__lore_end = {[false] = self.__lores[2][1], [true] = self.__lores[2][2]} else self.__lore_end = {[false] = self.__lores[2][1], [true] = generic_death} end
			elseif self.__lores and self.lores[2][false] then
				if self.__lores[2][true] then self.__lore_end = {[false] = self.__lores[2][false], [true] = self.__lores[2][true]} else self.__lore_end = {[false] = self.__lores[2][false], [true] = generic_death} end
			else self.__lore_end = {[false] = "", [true] = generic_death} end
			
			self.__level_configuration = level_datas["level_conf"]
			if self.__level_configuration then console:print("Using custom level configuration.\n", LogLevel.WARNING_DEV, "level.lua/Level:(init)")
			else self.__level_configuration = level_config end
			
			self.__map_reveal = level_datas["map_reveal"]
			self.__win_level = level_datas["win_level"]
			if not self.__map_reveal then self.__map_reveal = function(dead, objects) return not dead end end
			if not self.__win_level  then self.__win_level  = function(      objects) return true     end end
			
			local init = self:initialize()
			self.initialize_status = {success = init.success, obsolete = false, old = true, opt = init}
		elseif self.__array_version == 2 then
			dictionary:addLevel(level_datas["__id"])
			
			self.__column_count = level_datas["column_count"]
			self.__starting_room = level_datas["starting_room"]
			self.__starting_rooms_datas = level_datas["rooms_datas"]
			
			self.__level_id = level_datas["__id"]
			
			self.__level_configuration = level_datas["level_conf"]
			if self.__level_configuration then console:print("Using custom level configuration.\n", LogLevel.WARNING_DEV, "level.lua/Level:(init)")
			else self.__level_configuration = level_config end
			
			self.__map_reveal       = level_datas["map_reveal"]
			self.__win_level        = level_datas["win_level"]
			self.__alternative_lore = level_datas["alternative_lore"]
			if not self.__map_reveal       then self.__map_reveal       = function(dead, objects) return not dead end end
			if not self.__win_level        then self.__win_level        = function(      objects) return true     end end
			if not self.__alternative_lore then self.__alternative_lore = function(dead, objects) if dead then return {state = "death", alt = "default"} else return {state = "victory", alt = "default"} end end end
			
			local init = self:initialize()
			self.initialize_status = {success = init.success, obsolete = false, old = false, opt = init}
		else
			console:print("Error: unknown level array version.", LogLevel.ERROR, "level.lua/Level:(init)")
			self.initialize_status = {success = false, opt = "Bad level array version."}
		end
	end
	
	local status = self.initialize_status
	if status.obsolete then console:print("Warning: obsolete level instanciation used. Please use the newer version.\n", LogLevel.WARNING_DEV, "level.lua/Level:(init)")
	elseif status.old then console:print("Old level instanciation used. A newer version is available.\n", LogLevel.LOG, "level.lua/Level:(init)")
	end
end)

function Level:getMapSize() return getArrayLength(self:getRooms()) - 2 * self:getColumnCount() end

function Level:getLevelConfiguration() return self.__level_configuration end

function Level:getActiveRoomAttribute(attributeName) return self:getRoomAttribute(self:getRoomNumber(), attributeName)        end
function Level:setActiveRoomAttribute(attributeName, value) self:setRoomAttribute(self:getRoomNumber(), attributeName, value) end

function Level:getRoomAttribute(room, attributeName) return self:getRoom(room):getAttribute(attributeName)        end
function Level:setRoomAttribute(room, attributeName, value) self:getRoom(room):setAttribute(attributeName, value) end

function Level:getRoomNumber() return self.__room_number end
function Level:setRoom(room) self.__old_room = self.__room_number; self.__room_number = room end
function Level:restoreRoom() self.__room_number = self.__old_room end

function Level:getRooms() return self.__rooms end
function Level:getActiveRoom()  return self:getRooms()[self:getRoomNumber()] end
function Level:getRoom(room_no) return self:getRooms()[room_no]              end

function Level:getRoomCoordinates(room_no) local x, y = room_no % self:getColumnCount(), floor(room_no / self:getColumnCount()) if room_no % self:getColumnCount() == 0 then x = self:getColumnCount() y = y - 1 end return x, y end
function Level:getRoomFromCoordinates(x, y) return self:getRoom(x + (y - 1) * self:getColumnCount()) end

function Level:getColumnCount() return self.__column_count end

function Level:setAllRoomsSeenStatusAs(seen)
	for k, v in pairs(self:getRooms()) do
		v:setAttribute("saw", seen)
	end
end

function Level:resetRoomsDatas()
	if not self.__rooms then self.__rooms = {} end
	
	for i = 1 - self.__column_count, getArrayLength(self.__starting_rooms_datas) - self.__column_count do
		local room_datas = {} for k, v in pairs(self.__starting_rooms_datas[i]) do room_datas[k] = v end
		local saw = self.__rooms[i] and self.__rooms[i]:getAttribute("saw") and (self:getLevelConfiguration():getDifficulty() <= 1)
		room_datas.saw = saw
		self.__rooms[i] = Room(room_datas)
	end
end

function Level:initialize()
	local roomInit
	
	self.__old_room = self.__starting_room
	self.__room_number = self.__starting_room
	self:resetRoomsDatas()
	
	for k, v in pairs(self:getRooms()) do
		roomInit = true
		roomInit = roomInit and v:initialize() if not roomInit then console:print("Error during room initialization\n", LogLevel.ERROR, "level.lua/Level:initialize") return {success = false, details = "room:initialize"} end
		roomInit = roomInit and v:setUnreachable() if not roomInit then console:print("Error during room 'unreachablization'\n", LogLevel.ERROR, "level.lua/Level:initialize") return {success = false, details = "room:setUnreachable"} end
		
		if not roomInit then return {success = false} end
	end
	
	self:getActiveRoom():refreshRoomNearEvents(self:getRoomNumber() % self:getColumnCount(),
		self:getRoom(self:getRoomNumber() - self:getColumnCount()), self:getRoom(self:getRoomNumber() + self:getColumnCount()),
		self:getRoom(self:getRoomNumber() - 1), self:getRoom(self:getRoomNumber() + 1))
	
	return {success = true}
end

function Level:__setupLevelState()
	stateManager:pushMainState("ig")
	stateManager:pushState("levels")
end
function Level:__setupLevelLoresState(loreState)
	self:__setupLevelState()
	stateManager:pushState("lores")
	stateManager:pushState(loreState)
	stateManager:pushState(self.__level_id)
end

function Level:printBeginningLore()
	self:__setupLevelLoresState("start")
	if self.__array_version == 2 then
		console:printLore(
			dictionary:translate(stateManager:getStatesStack(), "lore")
		)
	else
		if self.__lore_begin and self.__lore_begin ~= "" then console:printLore(self.__lore_begin) console:printLore("\n") end
	end
	stateManager:popMainState()
end

function Level:printEndingLore(death, objects)
	self:__setupLevelLoresState("end")
	
	if self.__array_version == 2 then
		local ret = self.__alternative_lore(death, objects)
		local state, alt = ret.state, ret.alt
		
		dictionary:setAlternative(stateManager:getStatesStack(), state, alt)
		
		console:printLore(
			dictionary:translate(stateManager:getStatesStack(), state)
		)
	else
		if self.__lore_end[death] and self.__lore_end[death] ~= "" then console:printLore(self.__lore_end[death]) console:printLore("\n") end
	end
	stateManager:popMainState()
	
	if self.__map_reveal(death, objects) then
		self:setAllRoomsSeenStatusAs(true)
	end
	return not death and self.__win_level(objects)
end

-- reverseMap - moves the cursor up to revert the minimap display
function Level:reverseMap(objects)
	if not self:getLevelConfiguration():doesDisplayMinimap() then return end
	
	if objects and objects:hasAnyPhysical() then
		if objects:getObject("key") then
			console:printLore("\27[A")
		end
		if objects:getObject("redkey") then
			console:printLore("\27[A")
		end
		if objects:getObject("sword") then
			console:printLore("\27[A")
		end
		console:printLore("\27[A")
	end
	console:printLore("\27[" .. min(self:getLevelConfiguration():getCamHeight(), floor(self:getMapSize() / self:getColumnCount())) * (getRoomDisplayWidth() - 1) + self:getLevelConfiguration():getMapYoffset() .. "A\27[J")
end

function Level:printLevelMap(is_ended, objects, doesDisplayAllMap)
	if not doesDisplayAllMap and not self:getLevelConfiguration():doesDisplayMinimap() then return LevelPrintingIgnored() end
	if     doesDisplayAllMap and not self:getLevelConfiguration():doesDisplayFullMap() then return LevelPrintingIgnored() end
	
	stateManager:pushMainState("ig")
	stateManager:pushState("map")
	
	console:printLore(dictionary:translate(stateManager:getStatesStack(), "legend"))
	if objects and objects:hasAnyPhysical() then
		if objects:getObject("key") then
			console:printLore(dictionary:translate(stateManager:getStatesStack(), "key"))
		end
		if objects:getObject("redkey") then
			console:printLore(dictionary:translate(stateManager:getStatesStack(), "redkey"))
		end
		if objects:getObject("sword") then
			console:printLore(dictionary:translate(stateManager:getStatesStack(), "sword"))
		end
		console:printLore("\n")
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
		yOffset = max(0, min(floor(self:getMapSize() / self:getColumnCount()) - camHeight, roomY - floor((camHeight - 1) / 2))) + 1
		maxXcoord = min(camWidth ,                           self:getColumnCount())  * (getRoomDisplayWidth()  - 1) + 1
		maxYcoord = min(camHeight, floor(self:getMapSize() / self:getColumnCount())) * (getRoomDisplayHeight() - 1) + 1
	else
		xOffset = 1
		yOffset = 1
		maxXcoord =                           self:getColumnCount()  * (getRoomDisplayWidth()  - 1) + 1
		maxYcoord = floor(self:getMapSize() / self:getColumnCount()) * (getRoomDisplayHeight() - 1) + 1
	end
	
	for curXcoord = 1, maxXcoord do console:printLore("\27[01;30;47;07m \27[00m") end console:printLore("\27[00m\27[0G")
	for curYcoord = 1, maxYcoord do console:printLore("\27[01;30;47;07m \27[00m\n") end console:printLore("\27[" .. maxYcoord .. "A")
	
	for curYcoord = 1, maxYcoord - 1, getRoomDisplayHeight() - 1 do
		for curXcoord = 1, maxXcoord - 1, getRoomDisplayWidth() - 1 do
			local roomX, roomY = (curXcoord - 1) / (getRoomDisplayWidth() - 1), (curYcoord - 1) / (getRoomDisplayHeight() - 1)
			local i = roomX + xOffset + (roomY + yOffset - 1) * self:getColumnCount()
			
			local ret = self:getRoomFromCoordinates(roomX + xOffset, roomY + yOffset):printRoom(objets, (i == self:getRoomNumber()) and not is_ended)
			
			if ret:iskind(RoomPrintingError) then
				stateManager:popMainState()
				return LevelPrintingErrored(ret)
			end
		end
		console:printLore("\27[" .. getRoomDisplayHeight() - 1 .. "B\27[G")
	end
	console:printLore("\27[00m\n\n")
	
	stateManager:popMainState()
	
	return LevelPrintingDone()
end

function Level:checkLevelEvents(is_ended, objects)
	local i = self:getRoomNumber()
	ret = self:getRoom(i):checkRoomEvents(is_ended, objects, i % self:getColumnCount(),
	                                      self:getRoom(i - self:getColumnCount()), self:getRoom(i + self:getColumnCount()), 
										  self:getRoom(i - 1), self:getRoom(i + 1), false, self:getLevelConfiguration():getDifficulty())
	is_ended = ret.ended
	objects = ret.objects
	while ret:isinstance(EventParsingResultRoomChanging) do
		if ret:isinstance(EventParsingResultRoomRestore) then
			self:restoreRoom()
		else
			if type(ret.room) == "number" then
			elseif ret.room == "up" then
				ret.room = self:getRoomNumber() - self:getColumnCount()
			elseif ret.room == "down" then
				ret.room = self:getRoomNumber() + self:getColumnCount()
			elseif ret.room == "left" then
				ret.room = self:getRoomNumber() - 1
			elseif ret.room == "right" then
				ret.room = self:getRoomNumber() + 1
			end
			self:setRoom(ret.room)
		end
		
		i = self:getRoomNumber()
		ret = self:getRoom(i):checkRoomEvents(is_ended, objects, i % self:getColumnCount(),
		                                      self:getRoom(i - self:getColumnCount()), self:getRoom(i + self:getColumnCount()), 
		                                      self:getRoom(i - 1), self:getRoom(i + 1), true, self:getLevelConfiguration():getDifficulty())
		is_ended = ret.ended
		objects = ret.objects
	end
	
	return ret
end

--[[ LevelManager - the level manager class [singleton]
	Holds a config and the levels
]]
local LevelManager = class(function(self, levelManagerConfig)
	self.__config = levelManagerConfig
	
	self:initialize()
end, Manager)

function LevelManager:getLevels() return self.__levels end
function LevelManager:getLevel(level) return self:getLevels()[level] end
function LevelManager:getActiveLevel() return self:getLevel(self.__level_number) end

function LevelManager:getLevelNumber() return self.__level_number         end
function LevelManager:setLevelNumber(value)   self.__level_number = value end

function LevelManager:removeLevels() self.__levels = {} self.__level_count, self.__test_level_count = 0, 0 end

function LevelManager:getConfig() return self.__config end

function LevelManager:initialize()
	self:removeLevels()
	
	self:initializeLevels()
	
	if self:getConfig():doLoadTestLevels() then
		self.__level_number = -1
	else
		self.__level_number = 1
	end
end

function LevelManager:addTestLevelInstance(level_instance)
	if not level_instance or not level_instance.isinstance or not level_instance:isinstance(Level) then
		console:print("Bad level_instance class", LogLevel.ERROR, "level.lua/LevelManager:addTestLevelInstance")
		return {success = false, reasontype = "check", opt = "Not a valid instance"}
	else
		self.__levels[self.__test_level_count - 1] = level_instance
		if not self.__levels[self.__level_count - 1].initialize_status.success then self.__levels[-self.__test_level_count] = nil return {success = false, opt = self.__levels[self.__level_count + 1].initialize_status.opt}
		else self.__level_count = self.__level_count - 1 return {success = true, id = -self.__test_level_count} end
	end
end

function LevelManager:addLevelInstance(level_instance)
	if not level_instance or not level_instance.isinstance or not level_instance:isinstance(Level) then
		console:print("Bad level_instance class", LogLevel.ERROR, "level.lua/LevelManager:addLevelInstance")
		return {success = false, reasontype = "check", opt = "Not a valid instance"}
	else
		self.__levels[self.__level_count + 1] = level_instance
		if not self.__levels[self.__level_count + 1].initialize_status.success then self.__levels[self.__level_count] = nil return {success = false, opt = self.__levels[self.__level_count + 1].initialize_status.opt}
		else self.__level_count = self.__level_count + 1 return {success = true, id = self.__level_count} end
	end
end

function LevelManager:addTestLevel(level_id, level_datas)
	if level_datas and level_datas["level_array_version"] == 2 then level_datas.__id = tostring(level_id)
	elseif not level_datas then level_datas = level_id end
	
	return self:addTestLevelInstance(Level(level_datas, self.__config:getLevelConfig()))
end

function LevelManager:addLevel(level_id, level_datas)
	if level_datas and level_datas["level_array_version"] == 2 then level_datas.__id = tostring(level_id)
	elseif not level_datas then level_datas = level_id end
	
	return self:addLevelInstance(Level(level_datas, self.__config:getLevelConfig()))
end

function LevelManager:initializeLevels()
	self:addLevel("starter", {["level_array_version"] = 2,
	    ["starting_room"] = 28,
	    ["column_count"] = 7,
	    ["rooms_datas"] = {[-6] = {},                                                                                                              [-5] = {},                                           [-4] = {},                                                        [-3] = {},                                           [-2] = {},                                                        [-1] = {},                                                         [0] = {},
	                       {exit = true, exit_dir = "left",            down = true,                               door = true, door_dir = "left"}, {                                     right = true}, {           down = true, left = true, right = true},              {                        left = true, right = true}, {                        left = true, right = true},              {                        left = true, right = true, sword = true}, {           down = true, left = true},
	                       {                                up = true,              right = true, monster = true},                                 {           down = true, left = true, right = true}, {up = true,              left = true, right = true},              {                        left = true},               {           down = true},                                         {           down = true,              right = true},               {up = true,              left = true},
	                       {                                           down = true, right = true},                                                 {up = true,              left = true},               {},                                                               {           down = true,              right = true}, {up = true,              left = true},                            {up = true, down = true,              right = true},               {           down = true, left = true},
	                       {                                up = true,              right = true},                                                 {                        left = true, right = true}, {                        left = true, right = true, key = true},  {up = true,              left = true, right = true}, {                        left = true, right = true, trap = true}, {up = true,              left = true, right = true},               {up = true,              left = true},
	                       {},                                                                                                                     {},                                                  {},                                                               {},                                                  {},                                                               {},                                                                {}},
		["map_reveal"] = function(dead, objects) return not dead  end,
		["win_level"]  = function(      objects) return true      end,
		["alternative_lore"] = function(dead, objects) if dead then return {state = "death", alt = "default"} else return {state = "victory", alt = "default"} end end
	})
	self:addLevel("ending", {["level_array_version"] = 1,
		["starting_room"] = 23,
		["column_count"] = 7,
		["rooms_datas"] = {[-6] = {},                                                                  [-5] = {},                                           [-4] = {},                                                          [-3] = {},                                                                                                                   [-2] = {},                                                                                             [-1] = {},                                                           [0] = {},
	                       {right = true,                             door = true, door_dir = "down"}, {           down = true, left = true},               {           down = true,              right = true},                {exit = true, exit_dir = "up",                         left = true,                           door = true, door_dir = "up"}, {},                                                                                                    {           down = true,                            monster = true}, {},
	                       {right = true,                 key = true, door = true, door_dir = "up"},   {up = true, down = true, left = true, right = true}, {up = true,              left = true},                              {                                                                   right = true},                                           {           down = true, left = true, right = true, sword = true},                                     {up = true, down = true, left = true, right = true},                 {left = true, trap = true},
	                       {},                                                                         {up = true, down = true,              right = true}, {                        left = true, right = true},                {                                         down = true, left = true, right = true, key = true},                               {up = true,              left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                       {},                                                                         {up = true, down = true,              right = true}, {                        left = true},                              {                              up = true,                           right = true},                                           {                        left = true, right = true},                                                   {up = true, down = true, left = true},                               {},
	                       {right = true, monster = true},                                             {up = true,              left = true, right = true}, {                        left = true, right = true, redkey = true}, {                                                      left = true, right = true},                                           {                        left = true,               sword = true, reddoor = true, reddoor_dir = "up"}, {up = true,                           right = true},                 {left = true, trap = true},
						   {},                                                                         {},                                                  {},                                                                 {},                                                                                                                          {},                                                                         {},                                                                                             {}},
	    ["lores"] = {
			"", -- Usually, you don't want anything for when you spawn in the maze.
			{"You walked along... an.. other corridor?   When you found yet another map. You continued along the corridor...\n...and you emerged to the surface! You are\n\nFREE!", "You died, even if this would've been the end anyways..."}
		}
	})
	
	add_contrib_nontest_levels(self)
	
	if self:getConfig():doLoadTestLevels() then
		self:addTestLevel("diff_test", {["level_array_version"] = 1, ["starting_room"] = 1, ["column_count"] = 3,
		    ["rooms_datas"] = {[-2] = {},                                               [-1] = {},                                               [0] = {},
		                       {right = true, key = true, redkey = true, sword = true}, {right = true, key = true, redkey = true, sword = true}, {exit = true, exit_dir = "right"},
		                       {},                                                      {},                                                      {}}
		})
		self:addTestLevel(-1, {["level_array_version"] = 1, ["starting_room"] = 4, ["column_count"] = 2, ["rooms_datas"] = {[-1] = {},                                                                                                                                                                  [0] = {},
		                                                                                                                 {exit = true, exit_dir = "left",                reddoor = true, reddoor_dir = "left", right = true, grave = true, deadlygrave = true, keyneeded = "key", exitdir = "down"}, {           down = true,             graveyard = true},
		                                                                                                                 {                                redkey = true},                                                                                                                            {up = true,              key = true},
		                                                                                                                 {},                                                                                                                                                                         {}}, ["lores"] = {"", ""} -- tests levels, no lores
		})
		self:addTestLevel(-2, {["level_array_version"] = 1, ["starting_room"] = 4, ["column_count"] = 2, ["rooms_datas"] = {[-1] = {},                                                                                              [0] = {},
		                                                                                                                 {exit = true, exit_dir = "left", reddoor = true, reddoor_dir = "left", door = true, door_dir = "left"}, {graveyard = true, down = true},
		                                                                                                                 {},                                                                                                     {up = true, key = true, redkey = true},
		                                                                                                                 {},                                                                                                     {}}, ["lores"] = {"", ""} -- tests levels, no lores
		})
		self:addTestLevel(-3, {["level_array_version"] = 1, ["starting_room"] = 1, ["column_count"] = 2, ["rooms_datas"] = {[-1] = {},                                                                                                                     [0] = {},
		                                                                                                                 {           down = true, right = true, redkey = true},                                                                         {exit = true, exit_dir = "up", left = true, reddoor = true, reddoor_dir = "up"},
		                                                                                                                 {up = true,                                           door = true, door_dir = "right", reddoor = true, reddoor_dir = "right"}, {},
		                                                                                                                 {},                                                                                                                            {}}, ["lores"] = {"", ""} -- tests levels, no lores
		})
		
		add_contrib_test_levels(self)
	end
end

-- levelManager - the LevelManager main singleton
levelManager = LevelManager(currentConfig:getLevelManagerConfig())
