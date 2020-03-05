local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)
local classmodule = load_module(import_prefix .. "class", true)

local basemodule = load_module(import_prefix .. "states.base", true)

local MainMenuState = class(function(self)
end, BaseState)

function MainMenuState:runIteration()
	console:printLore(
		dictionary:translate(stateManager:getStatesStack(), "display")
	)
	
	local menu = nil
	local minMenu, maxMenu = 1, 2
	local function getMenuNo(menu)
		local num = tonumber(menu)
		return num and (floor(num) == num) and (num >= minMenu) and (num <= maxMenu) and num or nil
	end
	while not menu do
		local returned = console:read()
		local success, eos
		success, eos, menu = returned.success, returned.eos, returned.returned
		
		if not success then
			console:print("Input reading error (" .. menu .. ")\n", LogLevel.FATAL_ERROR, "states\\mainMenu.lua/MainMenuState:runIteration@menu selection parsing")
			
			stateManager:crash()
			return false
		elseif eos then
			console:print("EOS detected, exiting\n", LogLevel.LOG, "states\\mainMenu.lua/MainMenuState:runIteration@menu selection parsing")
			
			return false
		elseif not getMenuNo(menu) then
			console:printLore(
				dictionary:translate(stateManager:getStatesStack(), "not_valid", minMenu, maxMenu)
			)
		end
		menu = getMenuNo(menu)
	end
	
	console:printLore('\n')
	if menu == 1 then
		stateManager:pushMainState("gameWrapper")
		return true
	else
		stateManager:pushState("eqcmenu")
		console:printLore(
			dictionary:translate(stateManager:getStatesStack(), "confirm")
		)
		
		menu = nil
		while not menu do
			local returned = console:read()
			local success, eos
			success, eos, menu = returned.success, returned.eos, returned.returned
			
			if not success then
				console:print("Input reading error (" .. menu .. ")\n", LogLevel.FATAL_ERROR, "states\\mainMenu.lua/MainMenuState:runIteration@eqcmenu parsing")
				
				stateManager:crash()
				return false
			elseif eos then
				console:print("EOS detected, exiting\n", LogLevel.LOG, "states\\mainMenu.lua/MainMenuState:runIteration@eqcmenu parsing")
				
				return false
			else
				menu = tonumber(menu)
				menu = menu and ((menu == 1) or (menu == 2)) and menu
				if not menu then
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "not_valid", min_menu, max_menu)
					)
				end
			end
		end
		
		stateManager:popState()
		
		if menu == 2 then return true
		else return false end
	end
	
	return true
end

mainMenuState = MainMenuState()
