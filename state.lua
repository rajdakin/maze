local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local consolemodule = load_module(import_prefix .. "console", true)
local classmodule = load_module(import_prefix .. "class", true)

local basestatemodule = load_module(import_prefix .. "states.base", true)
local mainmenustatemodule = load_module(import_prefix .. "states.mainMenu", true)
local pregamestatemodule = load_module(import_prefix .. "states.pregame", true)
local gamestatemodule = load_module(import_prefix .. "states.game", true)
local optionsstatemodule = load_module(import_prefix .. "states.options", true)

--[[ StateManager - the state manager class [singleton]
	Holds a state stack
	
	main_state - the initial main state
]]
local StateManager = class(function(self, main_state)
	self.__exit = false
	
	self.__main_states, self.__main_count = {main_state}, 1
	self.__states, self.__count = {{main_state}}, 1
	
	self.__states_dict = {}
end)

function StateManager:mustExit() return self.__exit end

function StateManager:getStatesStack()     return self.__states[self.__main_count] end
function StateManager:getMainStatesStack() return self.__main_states               end

function StateManager:getStatesCount()     return self.__count      end
function StateManager:getMainStatesCount() return self.__main_count end

-- getState - returns the current state (as a class), or the main state if there is none registered
function StateManager:getState()
	local state = self:getMainStatesStack()[self:getMainStatesCount()]
	if self.__states_dict[state] then return self.__states_dict[state]
	--else return state end
	else return nil end
end

-- pushMainState - store the old main state and reset the stack to put the new main_state on top
function StateManager:pushMainState(main_state)
	if main_state == nil then return end
	
	self.__main_states[self.__main_count + 1] = main_state
	self.__main_count = self.__main_count + 1
	
	table.insert(self.__states, {self.__main_states[self.__main_count]})
	
	local state = self:getState()
	if state then state:onPush()
	else console:print("Pushed an unknown state: " .. main_state .. "\n", LogLevel.WARNING, "state.lua/StateManager:pushMainState") end
end

-- popMainState - restore the last stored main state
function StateManager:popMainState()
	if self.__main_count == 1 then self.__exit = true
	elseif self.__main_count == 0 then return nil end
	
	while self:getStatesStack()[2] do self:popState() end
	
	local main_state = self.__main_states[self.__main_count]
	
	local state = self:getState()
	if state then state:onPop()
	else console:print("Popped an unknown state: " .. main_state .. "\n", LogLevel.WARNING, "state.lua/StateManager:pushMainState") end
	
	self.__main_states[self.__main_count] = nil
	self.__main_count = self.__main_count - 1
	
	table.remove(self.__states)
	
	local topState = self:getState()
	if topState then topState:onPoppedUpper(main_state, state) end
	
	return main_state
end

function StateManager:pushState(state)
	if state == nil then return end
	
	self:getStatesStack()[self.__count + 1] = state
	self.__count = self.__count + 1
end

function StateManager:popState()
	if self.__count <= 1 then return nil end
	
	local state = self:getStatesStack()[self.__count]
	
	self:getStatesStack()[self.__count] = nil
	self.__count = self.__count - 1
	
	return state
end

-- registerState - register a state as stateName
function StateManager:registerState(state, stateName)
	if state and self.__states_dict[stateName] and self.__states_dict[stateName].pseudostate then self.__states_dict[stateName] = nil end
	
	if state and self.__states_dict[stateName] then console:print("Trying to re-register a state: " .. stateName .. "\n", LogLevel.WARNING_DEV, "state.lua/StateManager:registerState")
	elseif not state and not self.__states_dict[stateName] then console:print("Trying to remove inexistent state: " .. stateName .. "\n", LogLevel.WARNING_DEV, "state.lua/StateManager:registerState")
	elseif not state.isinstance or not state:isinstance(BaseState) then console:print("Trying to register a non-state object as state " .. stateName .. "\n", LogLevel.WARNING_DEV, "state.lua/StateManager:registerState")
	else
		self.__states_dict[stateName] = state
	end
end

--[[ registerPseudostate
	Register a pseudostate as name.
	Pseudostates are states that cannot be executed (they are not real states).
]]
function StateManager:registerPseudostate(name)
	local pseudostate = class(function(self) end, BaseState)
	pseudostate.pseudostate = true
	pseudostate:__implementAbstract("runIteration", abst_method("pseudostate " .. name .. " cannot be run"))
	self:registerState(pseudostate(), name)
end

--[[ runIteration
	Run a game/menu/... iteration.
]]
function StateManager:runIteration()
	local state = self:getState()
	if not state then return false end
	
	if state.pseudostate then return false end
	
	return state:runIteration()
end

--[[ runLoop
	Run the iterations loop
]]
function StateManager:runLoop()
	local catch = function(e)
		self.__exit = true
		self:crash("An iteration of the game loop crashed (" .. tostring(e) .. ")")
		return true
	end
	while not self:mustExit() do
		if not ({
			try(differ(self.runIteration, self)):catch(any_error, catch)("state.lua/StateManager:runLoop")
		})[1][2] then
			self:popMainState()
		end
	end
end

function StateManager:crash(msg)
	while self.__main_states[1] do
		self:popMainState()
	end
	error(msg or "Crash requested")
end
function StateManager:fastcrash()
	self.__states_dict = {}
	self.__main_states = {}
	self.__main_count = 0
	self.__states = {}
	self.__count = 0
	self.__exit = true
	error("Fast crash requested")
	return false
end

-- stateManager - the state manager singleton
stateManager = StateManager("mm")

stateManager:registerState(mainMenuState, "mm")
stateManager:registerState(optionsState, "options")
stateManager:registerState(preGameState, "gameWrapper")
stateManager:registerState(gameState, "game")

-- Register the in-game pseudostate
stateManager:registerPseudostate("ig")
