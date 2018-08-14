local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local contributionmodule = require(import_prefix .. "contribution")
local utilmodule = require(import_prefix .. "util")

local dictionarymodule = require(import_prefix .. "dictionary")
local classmodule = require(import_prefix .. "class")

Objects = class(function(self, objKind)
	self:initialize(objKind)
end)

function Objects:hasObject    (object) return self.__added_objects[object] ~= nil end
function Objects:getObjectRaw (object) return self.__objects[object]         end
function Objects:setObjectRaw (object, value) self.__objects[object] = value end
function Objects:resetObject  (object)        self.__objects[object] = self.__added_objects[object].default end

function Objects:getObjectType(object) if self:hasObject   (object)                                    then return self.__added_objects[object].type else return nil   end end
function Objects:has          (object) if self:getObjectRaw(object) and self:getObjectRaw(object) ~= 0 then return true                              else return false end end

function Objects:getObject(object)
	if not self:hasObject(object) then return nil end
	
	local objRaw, objTyp = self:getObjectRaw(object), self:getObjectType(object)
	
	if objTyp == "boolean" then if objRaw then return true else return false end
	elseif objTyp == "nil" then return nil -- Shouldn't happen
	elseif objTyp == "string" then return tostring(objRaw)
	elseif objTyp == "held" then if tonumber(objRaw) then return tonumber(objRaw) else return false end
	elseif objTyp == "number" then if tonumber(objRaw) then return tonumber(objRaw) else return 0 end
	else return objRaw end
end
function Objects:setObject(object, value)
	if not self:hasObject(object) then return self:addObject(object, value) end
	
	local objTyp = self.__added_objects[object].type
	
	if objTyp == "boolean" then if value then value = true else value = false end
	elseif objTyp == "nil" then value = nil -- Shouldn't happen
	elseif objTyp == "string" then value = tostring(value)
	elseif objTyp == "held" then if tonumber(value) then value = tonumber(value) elseif value then value = 1 else value = false end
	elseif objTyp == "number" then if tonumber(value) then value = tonumber(value) else value = 0 end
	end
	
	self:setObjectRaw(object, value)
end

function Objects:hasAnyBool()
	for k, v in pairs(self.__objects) do
		if self:getObjectType(k) == "boolean" and v then return true end
	end
	
	return false
end

function Objects:addObject(object, startValue, typ)
	if not typ then typ = type(startValue) end
	
	self.__added_objects[object] = {default = startValue, type = typ}
	self.__objects[object] = startValue
end

function Objects:initialize(objKind)
	self.__objects = {}
	self.__added_objects = {}
	
	if objKind == 1 then
		self:addObject("key", false, "held")
		self:addObject("redkey", false, "held")
		self:addObject("sword", false, "held")
	end
end
