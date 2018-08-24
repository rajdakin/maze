local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

--[[ LevelConfig - the level configuration class.
	Holds whether the minimap should display, whether the map should be displayable,
	the minimap's size, the minimap printing height and the difficulty
	
	levelConfiguration - the level configuration table
]]
local LevelConfig = class(function(self, levelConfiguration)
	self.__displayMinimap = levelConfiguration["minimapDisplay"]
	self.__displayMap = levelConfiguration["mapDisplayable"]
	self.__minimapViewingSize = levelConfiguration["minimapViewingSize"]
	self.__mapOffset = {0, levelConfiguration["mapYoffset"]}
	
	self.__difficulty = levelConfiguration["difficulty"]
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
local LevelManagerConfig = class(function(self, levelManagerConfiguration, levelConfiguration)
	self.__levelConfig = LevelConfig(levelConfiguration)
	
	self.__loadTestLevels = levelManagerConfiguration["loadTestLevels"]
end)

function LevelManagerConfig:getLevelConfig() return self.__levelConfig end

function LevelManagerConfig:doLoadTestLevels() return self.__loadTestLevels end

--[[ ConsoleConfig - the console configuration class.
	Holds the log level (an integer between 0 and 4) and whether if it is in developer mode.
	
	levelConfiguration - the level configuration table
]]
local ConsoleConfig = class(function(self, consoleConfiguration)
	self.__logLevel = math.min(math.max(math.floor(consoleConfiguration["logLevel"]), 0), 4)
	self.__developerMode = consoleConfiguration["developerMode"]
end)

function ConsoleConfig:getLogLevel()             return self.__logLevel             end
function ConsoleConfig:isLogLevelValid(logLevel) return self.__logLevel >= logLevel end
function ConsoleConfig:isDeveloperMode()         return self.__developerMode        end

--[[ Config - the global configuration class [singleton]
	Holds the level manager configuration and the console configuration.
	
	configuration - the global configuration
]]
local Config = class(function(self, configuration)
	self.__levelManagerConfig = LevelManagerConfig(configuration["levelManagerConfiguration"], configuration["levelConfiguration"])
	self.__consoleConfig = ConsoleConfig(configuration["consoleConfiguration"])
end)

function Config:getLevelManagerConfig() return self.__levelManagerConfig end
function Config:getConsoleConfig() return self.__consoleConfig end

-- currentConfig - the configuration singleton
currentConfig = Config({
    ["levelManagerConfiguration"] = {["loadTestLevels"] = false},
    ["levelConfiguration"] = {["minimapDisplay"] = true,
                              ["minimapViewingSize"] = {3, 3},
                              ["mapDisplayable"] = true,
                              ["mapYoffset"] = 7,
                              ["difficulty"] = 3},
    ["consoleConfiguration"] = {["logLevel"] = 2,
                                ["developerMode"] = false}
})
