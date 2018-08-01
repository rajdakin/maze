import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

Manager = class(function(self, clss)
	self.__managed_class = clss
	
	self.__instances = {}
end)

function Manager:isClassManager(clss)
	return clss:isinstance(self.__managed_class)
end

function Manager:addInstance(...) table.insert(self.__instances, self.__managed_class(...)) return self:getSize() end

function Manager:getInstances() return self.__instances end
function Manager:getInstance(position) return self.__instances[position] end

function Manager:getSize() return #self.__instances end

function Manager:removeInstance(position)
	if self.__instances[position] then return table.remove(self.__instances, position)
	else return nil end	
end	

function Manager:removeAll() self.__instances = {} end
