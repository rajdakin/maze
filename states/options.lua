local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)states%.[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)
local classmodule = load_module(import_prefix .. "class", true)

local basechoicemodule = load_module(import_prefix .. "states.baseChoice", true)
local dictionarymodule = load_module(import_prefix .. "dictionary", true)
local configmodule = load_module(import_prefix .. "config", true)

local OptionsState = class(function(self)
	self.__lvMan = currentConfig:getLevelManagerConfig()
	self.__lv = self.__lvMan:getLevelConfig()
	self.__csole = currentConfig:getConsoleConfig()
	self.__opts = currentConfig:getOptions()
end, BaseChoiceState)

function OptionsState:onPush()
	self.__adv = false
end

OptionsState:__implementAbstract("runIteration", function(self)
	local menu = 5 -- menu = advanced
	
	local lang = dictionary:getActiveLangName()
	local dispMinimap = self.__lv:doesDisplayMinimap()
	if not self.__adv then
		console:printLore(dictionary:translate(stateManager:getStatesStack(), "display", lang, dispMinimap))
		
		menu = self:loopChoice(1, 7, "not_valid")
		if menu == nil then
			-- Also cancel the changes
			console:printLore('\n\n')
			currentConfig:updateConfig()
			return false
		end
		
		console:printLore('\n')
	end
	
	if menu == 1 then
		-- Language
		self.__opts:setLangIdx(dictionary:getNextLangIdx())
	elseif menu == 2 then
		-- EQC
		local altIdx = self.__opts:getEQCAlt()
		
		if altIdx == self.__opts:getEQCAltsCount() then
			altIdx = 1
		else
			altIdx = altIdx + 1
		end
		self.__opts:setEQCAlt(altIdx)
	elseif menu == 3 then
		-- Minimap
		self.__lv:setDisplayMinimap(not dispMinimap)
	elseif menu == 4 then
		-- Difficulty
		local diff = self.__lv:getDifficulty() + 1
		if diff > self.__lv:getMaxDifficulty() then diff = 1 end
		
		self.__lv:setDifficulty(diff)
	elseif menu == 5 then
		-- Advanced
		self.__adv = true
		stateManager:pushState("adv")
		
		local mmsz = self.__lv:getCamSize()
		local fullEnabled = self.__lv:doesDisplayFullMap()
		local vlen = self.__lv:getMapYoffset()
		local logLv = self.__csole:getLogLevel()
		local dev = self.__csole:isDeveloperMode()
		local dbgLv = self.__lvMan:doLoadTestLevels()
		
		console:printLore(dictionary:translate(
			stateManager:getStatesStack(),
			"display",
			mmsz[1], mmsz[2], fullEnabled, vlen - 4, LogLevel.level2log[logLv]:getLogText(), dev, dbgLv
		))
		
		menu = self:loopChoice(1, 7, "not_valid")
		if menu == nil then
			-- Up by one menu
			console:printLore('\n\n')
			stateManager:popState()
			self.__adv = false
			
			return true
		end
		
		console:printLore('\n')
		if menu == 1 then
			-- Minimap size
			mmsz[1] = mmsz[1] + 2
			-- Hard limit
			if mmsz[1] > 7 then
				mmsz[1] = 3
			end
			self.__lv:setCamSize({mmsz[1], mmsz[1]})
		elseif menu == 2 then
			-- Full map display?
			self.__lv:setDisplayFullMap(not fullEnabled)
		elseif menu == 3 then
			-- Legend size
			console:printLore('\n')
			
			stateManager:pushState("vchange")
			console:printLore(dictionary:translate(stateManager:getStatesStack(), "prompt"))
			local newlen = self:loopChoice(2, 19, "not_valid")
			stateManager:popState()
			
			console:printLore('\n')
			if newlen then
				self.__lv:setMapYoffset(newlen + 4)
			else
				console:printLore('\n')
			end
		elseif menu == 4 then
			-- Log level
			logLv = logLv + 1
			if logLv > self.__csole:getMaxLogLevel() then
				logLv = 0
			end
			self.__csole:setLogLevel(logLv)
		elseif menu == 5 then
			-- Developer mode
			self.__csole:setDevMode(not dev)
		elseif menu == 6 then
			-- Debug levels
			self.__lvMan:setLoadTestLevels(not dbgLv)
		elseif menu == 7 then
			-- Back
			self.__adv = false
		end
		
		stateManager:popState()
	elseif menu >= 6 then
		-- Quit and...
		if menu == 6 then
			-- ... cancel
			currentConfig:updateConfig()
		else
			-- ... save
			currentConfig:updateDataStream()
			currentConfig:writeConfig()
		end
		return false
	end
	
	return true
end)

optionsState = OptionsState()
