import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

local LevelConfig = class(function(self, mapViewingSize)
	self.__mapViewingSize = mapViewingSize
end)

function LevelConfig:getCamWidth () return self.__mapViewingSize[1] end
function LevelConfig:getCamHeight() return self.__mapViewingSize[2] end

local Config = class(function(self, mapViewingSize)
	self.__levelConfig = LevelConfig(mapViewingSize)
end)

function Config:getLevelConfig() return self.__levelConfig end

currentConfig = Config({3, 3})
