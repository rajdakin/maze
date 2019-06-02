local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local utilmodule = require(import_prefix .. "util")
local classmodule = require(import_prefix .. "class")

local basemodule = require(import_prefix .. "states.base")

local PreGameState = class(function(self)
	self.__status = {popped = false}
end, BaseState)

function PreGameState:onPush()
	stateManager:pushMainState("game")
end

function PreGameState:onPoppedUpper(stateName, state)
	if stateName ~= "game" then return end
	self.__status = {popped = true, state = state, player =  state.__player, requested = state.__request}
end

function PreGameState:runIteration()
	if not self.__status.popped then
		console:print("No first iteration code for the pre-game state", LogLevel.WARNING_DEV, "states\\pregame.lua/PreGameState:runIteration")
		return false
	else
		if self.__status.requested then return false end
		
		local doNextLevel = levelManager:getActiveLevel():printEndingLore(self.__status.player.dead, self.__status.player.objects)
		console:printLore("The end!")
		sleep(1) console:printLore("\8.")
		sleep(1) console:printLore(".")
		sleep(1) console:printLore(".")
		sleep(2) console:printLore("\8\8\8?  ")
		
		if doNextLevel then
			levelManager:setLevelNumber(levelManager:getLevelNumber() + 1)
			end
			-- TODO: here is another place to add a live count
			if levelManager:getActiveLevel() then
				sleep(2) console:printLore("\8\8\8\8\8\8\8\8\8\8Not yet!  ")
				sleep(1)
				stateManager:pushMainState("game")
				return true
			else
				sleep(2) console:printLore("\8\8\8\8\8\8\8\8\8\8Yes it is!")
			end
		--end
	end
	
	return false
end

preGameState = PreGameState()
