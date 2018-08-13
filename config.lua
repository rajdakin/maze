local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

local LevelConfig = class(function(self, levelConfiguration)
	self.__displayMinimap = levelConfiguration["minimapDisplay"]
	self.__minimapViewingSize = levelConfiguration["minimapViewingSize"]
	self.__mapOffset = {0, levelConfiguration["mapYoffset"]} -- used in the reverseMap function
end)

function LevelConfig:doesDisplayMinimap() return self.__displayMinimap  end
function LevelConfig:getCamSize  () return self.__minimapViewingSize    end
function LevelConfig:getCamWidth () return self.__minimapViewingSize[1] end
function LevelConfig:getCamHeight() return self.__minimapViewingSize[2] end

function LevelConfig:getMapOffset () return self.__mapOffset    end
function LevelConfig:getMapXoffset() return self.__mapOffset[1] end
function LevelConfig:getMapYoffset() return self.__mapOffset[2] end

local LevelManagerConfig = class(function(self, levelManagerConfiguration, levelConfiguration)
	self.__levelConfig = LevelConfig(levelConfiguration)
	
	self.__loadTestLevels = levelManagerConfiguration["loadTestLevels"]
end)

function LevelManagerConfig:getLevelConfig() return self.__levelConfig end

function LevelManagerConfig:doLoadTestLevels() return self.__loadTestLevels end


local ConsoleConfig = class(function(self, configuration)
	self.__logLevel = configuration["logLevel"]
	self.__developerMode = configuration["developerMode"]
end)

function ConsoleConfig:getLogLevel()             return self.__logLevel             end
function ConsoleConfig:isLogLevelValid(logLevel) return self.__logLevel >= logLevel end
function ConsoleConfig:isDeveloperMode()         return self.__developerMode        end

local Config = class(function(self, configuration)
	self.__levelManagerConfig = LevelManagerConfig(configuration["levelManagerConfiguration"], configuration["levelConfiguration"])
	self.__consoleConfig = ConsoleConfig(configuration["consoleConfiguration"])
end)

function Config:getLevelManagerConfig() return self.__levelManagerConfig end
function Config:getConsoleConfig() return self.__consoleConfig end

currentConfig = Config({
    ["levelManagerConfiguration"] = {["loadTestLevels"] = false},
    ["levelConfiguration"] = {["minimapDisplay"] = true,
                              ["minimapViewingSize"] = {3, 3},
                              ["mapYoffset"] = 7},
    ["consoleConfiguration"] = {["logLevel"] = 2,
                                ["developerMode"] = false}
})
