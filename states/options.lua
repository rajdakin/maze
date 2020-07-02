local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)
local classmodule = load_module(import_prefix .. "class", true)

local basechoicemodule = load_module(import_prefix .. "states.baseChoice", true)
local dictionarymodule = load_module(import_prefix .. "dictionary", false)
local configmodule = load_module(import_prefix .. "config", true)

if dictionarymodule and dictionary.addListenerToConfig then dictionary:addListenerToConfig(currentConfig:getOptions()) end

local OptionsState = class(function(self)
end, BaseChoiceState)

OptionsState:__implementAbstract("runIteration", function(self)
	console:printLore(
		dictionary:translate(stateManager:getStatesStack(), "display")
	)
	
	local menu = self:loopChoice(1, 1, "not_valid")
	if menu == nil then
		return false
	end
	
	console:printLore('\n')
	if menu == 1 then
		return false
	end
	
	return true
end)

optionsState = OptionsState()
