local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

--[[ StateManager - the state manager class [singleton]
	Holds a state stack
	
	main_state - the initial main state
]]
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

-- getState - alias for getStatesStack - [later returns a state class]
function StateManager:getState()
	return self:getStatesStack()
end

-- pushMainState - store the old main state and reset the stack to put the new main_state on top
function StateManager:pushMainState(main_state)
	if main_state == nil then return end
	
	self.__main_states[self.__main_count + 1] = {main_state}
	self.__main_count = self.__main_count + 1
	
	self.__states = self.__main_states[self.__main_count]
end

-- popMainState - restore the last stored main state
function StateManager:popMainState()
	if self.__main_count == 1 then self.__exit = true
	elseif self.__main_count == 0 then return nil end
	
	while self.__states[2] do self:popState() end
	
	local main_state = self.__main_states[self.__main_count]
	
	self.__main_states[self.__main_count] = nil
	self.__main_count = self.__main_count - 1
	
	self.__states = self.__main_states[self.__main_count]
	
	return main_state
end

function StateManager:pushState(state)
	if state == nil then return end
	
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

-- stateManager - the state manager singleton
stateManager = StateManager("mm")
