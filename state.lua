local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

local StateManager = class(function(self, main_state)
	self.__exit = false
	
	self.__main_states, self.__main_count = {main_state}, 1
	self.__states, self.__count = {main_state}, 1
end)

function StateManager:mustExit() return self.__exit end

function StateManager:getStatesStack()     return self.__states      end
function StateManager:getMainStatesStack() return self.__main_states end

function StateManager:getStatesCount()     return self.__count      end
function StateManager:getMainStatesCount() return self.__main_count end

function StateManager:getState()
	return self:getStatesStack()
end

function StateManager:pushMainState(main_state)
	self.__main_states[self.__main_count + 1] = {main_state}
	self.__main_count = self.__main_count + 1
	
	self.__states = self.__main_states[self.__main_count]
end

function StateManager:popMainState()
	if self.__main_count == 1 then self.__exit = true
	elseif slf.__main_count == 0 then return nil end
	
	while self.__states[2] do self:popState() end
	
	local main_state = self.__main_states[self.__main_count]
	
	self.__main_states[self.__main_count] = nil
	self.__main_count = self.__main_count - 1
	
	self.__states = self.__main_states[self.__main_count]
	
	return main_state
end

function StateManager:pushState(state)
	self.__states[self.__count + 1] = state
	self.__count = self.__count + 1
end

function StateManager:popState()
	if self.__count <= 1 then return nil end
	
	local state = self.__states[self.__count]
	
	self.__states[self.__count] = nil
	self.__count = self.__count - 1
	
	return state
end

stateManager = StateManager("mm")
