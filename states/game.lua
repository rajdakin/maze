local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local utilmodule = require(import_prefix .. "util")
local classmodule = require(import_prefix .. "class")

local basemodule = require(import_prefix .. "states.base")
local objectsmodule = require(import_prefix .. "objects")

local GameState = class(function(self)
	self.__player = {}
	self.__player.dead = true
	self.__player.objects = Objects(1)
	
	self.__game_ended = false
	
	self.__request = false
end, BaseState)

function GameState:resetMazeMap()
	if levelManager:getActiveLevel():getLevelConfiguration():getDifficulty() > 1 then
		levelManager:getActiveLevel():setAllRoomsSeenStatusAs(false)
	end
end

function GameState:onLevelInitialize()
	levelManager:getActiveLevel():initialize()
	self:resetMazeMap()
	
	self.__game_ended = false
	
	dictionary:resetAlternatives()
	dictionary:setAlternative({"ig"}, "help", tostring(levelManager:getActiveLevel():getLevelConfiguration():doesDisplayFullMap()))
	
	self.__player.dead = false
	self.__player.objects:initialize(1)
	
	levelManager:getActiveLevel():printBeginningLore()
end

function GameState:onPush()
	self:onLevelInitialize()
end

function GameState:runIteration()
	levelManager:getActiveLevel():setActiveRoomAttribute("saw", true)
	console:printLore("\n")
	
	stateManager:pushMainState("ig")
	
	local ret = levelManager:getActiveLevel():printLevelMap(self.__game_ended, self.__player.objects, false)
	if ret:iskind(LevelPrintingErrored) then
		console:printLore("\27[00m\n")
		console:print(ret.reason.reason, LogLevel.FATAL_ERROR, "states\\game.lua/GameState:runIteration@level printing")
		
		self.__request = true
		stateManager:crash()
		return false
	end
	
	console:printLore(dictionary:translate(stateManager:getStatesStack(), "prompt"))
	local returned = console:read()
	local success, eos, movement = returned.success, returned.eos, returned.returned
	if not success then
		self.__game_ended = true
		self.__player.dead = true
		
		console:print("Input reading error (" .. movement .. ")\n", LogLevel.FATAL_ERROR, "states\\game.lua/GameState:runIteration@level movement parsing")
		
		self.__request = true
		stateManager:crash()
		return false
	elseif eos then
		self.__game_ended = true
		self.__player.dead = true
		
		console:print("EOS detected, exiting\n", LogLevel.LOG, "states\\game.lua/GameState:runIteration@level movement parsing")
		
		self.__request = true
		stateManager:popMainState()
		return false
	end
	
	levelManager:getActiveLevel():reverseMap(objects)
	console:printLore("\n")
	
	local dirFunc = function(...) currentConfig:getKeyboardConfig():getDirectionKey(...) end
	
	local moveFunc = function(dir)
		stateManager:pushState("move")
		if levelManager:getActiveLevel():getActiveRoom():hasAccess(dir) then
			delta = 0
			if dir == "up" then delta = -levelManager:getActiveLevel():getColumnCount()
			elseif dir == "down" then delta = levelManager:getActiveLevel():getColumnCount()
			elseif dir == "left" then delta = -1
			elseif dir == "right" then delta = 1
			end
			levelManager:getActiveLevel():setRoom(
				levelManager:getActiveLevel():getRoomNumber() + delta
			)
			
			console:printLore(dictionary:translate(stateManager:getStatesStack(), dir))
		else
			console:printLore(dictionary:translate(stateManager:getStatesStack(), "fail"))
		end
		
		stateManager:popState()
	end
	
	if (movement == "") or (movement == "h") or (movement == "help") then
		console:printLore(
			dictionary:translate(stateManager:getStatesStack(), "help",
				dirFunc(1), dirFunc(3), dirFunc(4), dirFunc(2)
			)
		)
		
		stateManager:popMainState()
		return not self.__game_ended
	elseif (movement == dirFunc(1)) or (movement == '\27[A') then
		-- go up!
		moveFunc("up")
	elseif (movement == dirFunc(2)) or (movement == '\27[C') then
		-- go right!
		moveFunc("right")
	elseif (movement == dirFunc(3)) or (movement == '\27[B') then
		-- go down!
		moveFunc("down")
	elseif (movement == dirFunc(4)) or (movement == '\27[D') then
		-- go left!
		moveFunc("left")
	elseif (movement == "w?") or (movement == "w ") or (movement == "map") then
		-- print the map
		ret = levelManager:getActiveLevel():printLevelMap(self.__game_ended, self.__player.objects, true)
		if ret:iskind(LevelPrintingErrored) then
			console:printLore("\27[00m\n")
			console:print(ret.reason.reason, LogLevel.FATAL_ERROR, "states\\game.lua/GameState:runIteration@whole level printing")
			
			self.__request = true
			stateManager:crash()
			return false
		elseif ret:iskind(LevelPrintingIgnored) then
			console:printLore("\27[A")
		end
		
		stateManager:popMainState()
		return not self.__game_ended
	elseif (movement == "e") or (movement == "end") or (movement == "exit") or (movement == "q") or (movement == "quit") then
		self.__game_ended = true
		self.__player.dead = true
		
		stateManager:popMainState()
		return false
	elseif (movement == "w") or (movement == "wait") then
		stateManager:pushState("wait")
		
		console:printLore(dictionary:translate(stateManager:getStatesStack(), "lore"))
		
		stateManager:popState()
	elseif (movement == "suicide") then
		stateManager:pushState("suicide")
		
		console:printLore(dictionary:translate(stateManager:getStatesStack(), "lore"))
		
		self.__player.dead = true
		
		stateManager:popState()
		stateManager:popMainState()
		
		self:onLevelInitialize()
		return true
	else
		console:print(dictionary:translate(stateManager:getStatesStack(), "unknown_dir"))
		stateManager:popMainState()
		return not self.__game_ended
	end
	
	local ret = levelManager:getActiveLevel():checkLevelEvents(self.__game_ended, self.__player.objects)
	self.__game_ended = ret.game_ended
	self.__player.objects = ret.objects
	if ret:iskind(EventParsingResultEnded) then
		self.__player.dead = true
		
		console:print(ret.reason, LogLevel.FATAL_ERROR, "states\\game.lua/GameState:runIteration@room event(s) checking")
		self.__request = true
		stateManager:crash()
		return false
	elseif ret:iskind(EventParsingResultExited) then
		self.__player.dead = ret.dead
	end
	if self.__player.dead then self:resetMazeMap() end
	
	stateManager:popMainState()
	return not self.__game_ended
end

gameState = GameState()
