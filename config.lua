local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local classmodule = load_module(import_prefix .. "class", true)
local filemodule = load_module(import_prefix .. "file", true)

local Configuration = abst_class(function(self, configDS)
	self.__listeners = {}
	
	self:updateConfig(configDS)
end)

--[[ addListener - add a listener to the configuration and get notified at each configuration update
	callback - function that takes as a parameter the updated configuration
]]
function Configuration:addListener(listener, callback)
	if not self.__listeners[listener] then self.__listeners[listener] = {} end
	table.insert(self.__listeners[listener], callback)
end
function Configuration:removeListener(listener)
	local ret = self.__listeners[listener] ~= nil
	self.__listeners[listener] = nil
	return ret
end

function Configuration:notifyListeners()
	for l, fs in pairs(self.__listeners) do
		for _, f in ipairs(fs) do
			f(l, self)
		end
	end
end

function Configuration:updateConfig(ds)
	if ds then self.__ds = ds end
	if not self.__ds or (self.__ds.__data.type == 'nil') then self.__ds = DataStream() end
	self:__updateSelf()
	self:notifyListeners()
end

Configuration:__addAbstract("__updateSelf")
Configuration:__addAbstract("_updateDS")

--[[ LevelConfig - the level configuration class.
	Holds whether the minimap should display, whether the map should be displayable,
	the minimap's size, the minimap printing height and the difficulty
	
	levelConfiguration - the level configuration table
]]
local LevelConfig = class(nil, Configuration)
LevelConfig:__implementAbstract("__updateSelf", function(self)
	self.__displayMinimap = self.__ds:getOrDefault("displayMinimap", true)
	self.__displayMap = self.__ds:getOrDefault("displayMap", true)
	
	self.__minimapViewingSize = self.__ds:getOrDefault("minimapViewingSize", {3, 3})
	self.__mapOffset = self.__ds:getOrDefault("mapOffset", {0, 7})
	
	self.__difficulty = self.__ds:getOrDefault("difficulty", 3)
end)
LevelConfig:__implementAbstract("_updateDS", function(self)
	self.__ds:set("displayMinimap", self.__displayMinimap, "boolean")
	self.__ds:set("displayMap", self.__displayMap, "boolean")
	
	self.__ds:set("minimapViewingSize", self.__minimapViewingSize, "array")
	self.__ds:set("mapOffset", self.__mapOffset, "array")
	
	self.__ds:set("difficulty", self.__difficulty, "number")
end)

function LevelConfig:doesDisplayMinimap() return self.__displayMinimap  end
function LevelConfig:doesDisplayFullMap() return self.__displayMap      end
function LevelConfig:getCamSize  () return self.__minimapViewingSize    end
function LevelConfig:getCamWidth () return self.__minimapViewingSize[1] end
function LevelConfig:getCamHeight() return self.__minimapViewingSize[2] end

function LevelConfig:getMapOffset () return self.__mapOffset    end
function LevelConfig:getMapXoffset() return self.__mapOffset[1] end
function LevelConfig:getMapYoffset() return self.__mapOffset[2] end

function LevelConfig:getDifficulty() return self.__difficulty end

--[[ LevelManagerConfig - the level manager configuration class.
	Holds whether to load test levels and a level (default) configuration
	
	levelManagerConfiguration - the level manager configuration table
	levelConfiguration - the default levels configuration table used on loading levels
]]
local LevelManagerConfig = class(nil, Configuration)
LevelManagerConfig:__implementAbstract("__updateSelf", function(self)
	if not self.__levelConfig then self.__levelConfig = LevelConfig(self.__ds:getAsDataStream("levelConfig"))
	else self.__levelConfig:updateConfig(self.__ds:getAsDataStream("levelConfig")) end
	
	self.__loadTestLevels = self.__ds:getOrDefault("loadTestLevels", false)
end)
LevelManagerConfig:__implementAbstract("_updateDS", function(self)
	self.__levelConfig:_updateDS()
	self.__ds:setSubDataStream("levelConfig", self.__levelConfig.__ds)
	
	self.__ds:set("loadTestLevels", self.__loadTestLevels, "boolean")
end)

function LevelManagerConfig:getLevelConfig() return self.__levelConfig end

function LevelManagerConfig:doLoadTestLevels() return self.__loadTestLevels end

local KeyboardConfig = class(nil, Configuration)
KeyboardConfig:__implementAbstract("__updateSelf", function(self)
	self.__directions = self.__ds:getOrDefault("directions", {up = "u", down = "d", left = "l", right = "r"})
end)
KeyboardConfig:__implementAbstract("_updateDS", function(self)
	self.__ds:set("directions", self.__directions, "object")
end)

function KeyboardConfig:getDirectionsKey() return self.__directions end

function KeyboardConfig:getDirectionKey(dir)
	if type(dir) == "number" then
		if dir == 1 then dir = "up"
		elseif dir == 2 then dir = "right"
		elseif dir == 3 then dir = "down"
		elseif dir == 4 then dir = "left"
		end
	end
	
	ret = self.__directions[dir]
	if ret then return ret
	else return "#ERROR" end
end

--[[ ConsoleConfig - the console configuration class.
	Holds the log level (an integer between 0 and 4) and whether if it is in developer mode.
	
	levelConfiguration - the level configuration table
]]
local ConsoleConfig = class(nil, Configuration)
ConsoleConfig:__implementAbstract("__updateSelf", function(self)
	self.__logLevel = self.__ds:getOrDefault("logLevel", 2)
	self.__logLevel = min(max(floor(self.__logLevel), 0), 4)
	self.__developerMode = self.__ds:getOrDefault("developerMode", false)
end)
ConsoleConfig:__implementAbstract("_updateDS", function(self)
	self.__ds:set("logLevel", min(max(floor(self.__logLevel), 0), 4), "number")
	self.__ds:set("developerMode", self.__developerMode, "boolean")
end)

function ConsoleConfig:getLogLevel()             return self.__logLevel             end
function ConsoleConfig:isLogLevelValid(logLevel) return self.__logLevel >= logLevel end
function ConsoleConfig:isDeveloperMode()         return self.__developerMode        end

--[[ OptionsConfig - the options class.
	Holds the misc configs.
	
	options - the level configuration table
]]
local Options = class(nil, Configuration)
Options:__implementAbstract("__updateSelf", function(self)
	self.__eqc = self.__ds:getOrDefault("eqc", 1)
end)
Options:__implementAbstract("_updateDS", function(self)
	self.__ds:set("eqc", self.__eqc)
end)

function Options:getEQCAlts() return {"exit", "quit", "close", "term", "kill"} end
function Options:getEQCAltsCount() return 5 end

function Options:getEQCAlt() return self.__eqc end
function Options:setEQCAlt(alt) self.__eqc = alt self:notifyListeners() end

--[[ Config - the global configuration class [singleton]
	Holds the level manager, keyboard and console configurations.
	
	configuration - the global configuration
]]
local Config = class(function(self, filename)
	self.__ds = DataStream()
	
	self.__filename = filename
	
	self.configs = {
		levelManager = LevelManagerConfig,
		keyboard = KeyboardConfig,
		console = ConsoleConfig,
		options = Options
	}
	self:readConfig()
end)

function Config:getLevelManagerConfig() return self.__levelManagerConfig end
function Config:getKeyboardConfig() return self.__keyboardConfig end
function Config:getConsoleConfig() return self.__consoleConfig end
function Config:getOptions() return self.__optionsConfig end

function Config:readConfig()
	self.__ds:read(self.__filename)
	
	self:updateConfig()
end

function Config:writeConfig()
	if not self.__ds then
		self.__ds = DataStream()
		
		self.__ds:setSubDataStream("levelManager", self.__levelManagerConfig.__ds)
		self.__ds:setSubDataStream("keyboard", self.__keyboardConfig.__ds)
		self.__ds:setSubDataStream("console", self.__consoleConfig.__ds)
		self.__ds:setSubDataStream("options", self.__optionsConfig.__ds)
	end
	
	self.__ds:write(self.__filename)
end

function Config:updateConfig()
	for cfg, cls in pairs(self.configs) do
		local cfgName = "__" .. cfg .. "Config"
		if not self[cfgName] then self[cfgName] = cls(self.__ds:getAsDataStream(cfg, false))
		else self[cfgName]:updateConfig(self.__ds:getAsDataStream(cfg, false)) end
	end
end
function Config:updateDataStream()
	for cfg, _ in pairs(self.configs) do
		local cfgName = "__" .. cfg .. "Config"
		self[cfgName]:_updateDS()
		self.__ds:setSubDataStream(cfg, self[cfgName].__ds)
	end
end

-- currentConfig - the configuration singleton
currentConfig = Config("settings.cfg")
