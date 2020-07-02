local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)
local classmodule = load_module(import_prefix .. "class", true)

local basemodule = load_module(import_prefix .. "states.base", true)

BaseChoiceState = abst_class(nil, BaseState)
function BaseChoiceState:loopChoice(firstChoice, choicesCount, unlocalized_invalid)
	local menu = nil
	local function getMenuNo(menu)
		local num = tonumber(menu)
		return num and (floor(num) == num) and (num >= firstChoice) and (num <= choicesCount - firstChoice + 1) and num or nil
	end
	while not menu do
		local returned = console:read()
		local success, eos
		success, eos, menu = returned.success, returned.eos, returned.returned
		
		if not success then
			console:print("Input reading error (" .. menu .. ")\n", LogLevel.FATAL_ERROR, "states\\baseChoice.lua/ChoiceState:loopChoice@menu selection parsing")
			
			stateManager:crash()
			return nil
		elseif eos then
			console:print("EOS detected, exiting\n", LogLevel.LOG, "states\\baseChoice.lua/ChoiceState:loopChoice@menu selection parsing")
			
			return nil
		elseif not getMenuNo(menu) then
			console:printLore(
				dictionary:translate(stateManager:getStatesStack(), unlocalized_invalid, firstChoice, choicesCount - firstChoice + 1)
			)
		end
		menu = getMenuNo(menu)
	end
	
	return menu
end
