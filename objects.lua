local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local contributionmodule = load_module(import_prefix .. "contribution", true)
local utilmodule = load_module(import_prefix .. "util", true)

local dictionarymodule = load_module(import_prefix .. "dictionary", true)
local consolemodule = load_module(import_prefix .. "console", true)
local classmodule = load_module(import_prefix .. "class", true)

--[[ Objects - the object manager class
	Holds values.
	Value types are: any lua type, "held"
	
	See also - Objects:initialize
	
	objKind - object group kind
]]
Objects = class(function(self, objKind)
	self:initialize(objKind)
end)

function Objects:hasObject    (object) return self.__added_objects[object] ~= nil end
function Objects:getObjectRaw (object) return self.__objects[object]         end
function Objects:setObjectRaw (object, value) self.__objects[object] = value end
function Objects:resetObject  (object)        self.__objects[object] = self.__added_objects[object].default end

function Objects:getObjectType(object) if self:hasObject   (object)                                    then return self.__added_objects[object].type else return nil   end end
function Objects:has          (object) if self:getObjectRaw(object) and self:getObjectRaw(object) ~= 0 then return true                              else return false end end

--[[
	getObject - return the requested object according to its type
	setObject - set    the requested object according to its type
	
	object type:
	- boolean: get returns true or false; set sets true or false
	- nil: get returns nil; set sets nil
	- string: get returns a string; set sets a string
	- number: get returns a number; set sets a number (defaults to 0)
	- held: get returns a number or false; set sets a number or false and sets alternatives accordingly (set on creating time)
]]
function Objects:getObject(object)
	if not self:hasObject(object) then return nil end
	
	local objRaw, objTyp = self:getObjectRaw(object), self:getObjectType(object)
	
	if objTyp == "boolean" then if objRaw then return true else return false end
	elseif objTyp == "nil" then return nil -- Shouldn't happen
	elseif objTyp == "string" then return tostring(objRaw)
	elseif objTyp == "number" then if tonumber(objRaw) then return tonumber(objRaw) else return 0 end
	elseif objTyp == "held" then if tonumber(objRaw) and (tonumber(objRaw) ~= 0) then return tonumber(objRaw) else return false end
	else return objRaw end
end
function Objects:setObject(object, value, ...)
	if not self:hasObject(object) then return self:addObject(object, value) end
	
	local obj = self.__added_objects[object]
	local objTyp = obj.type
	
	if objTyp == "boolean" then if value then value = true else value = false end
	elseif objTyp == "nil" then value = nil -- Shouldn't happen
	elseif objTyp == "string" then value = tostring(value)
	elseif objTyp == "number" then if tonumber(value) then value = tonumber(value) else value = 0 end
	elseif objTyp == "held" then
		local active
		if tonumber(value) and (tonumber(value) ~= 0) then
			value = tonumber(value)
			active = true
		elseif value then
			value = 1
			active = true
		else
			value = false
			active = false
		end
		local i = 1
		while obj.add[i] and obj.add[i + 1] and obj.add[i + 2] do
			dictionary:setAlternative(obj.add[i], tostring(obj.add[i + 1]), tostring(obj.add[i + 2](active, ...)))
			i = i + 3
		end
	end
	
	self:setObjectRaw(object, value)
end

-- hasAnyPhysical - returns whether any of the object of type "held" is at least one
function Objects:hasAnyPhysical()
	for k, v in pairs(self.__objects) do
		if self:getObjectType(k) == "held" and v then return true end
	end
	
	return false
end

--[[
	addObject - add the object object with the corresponding startValue and its optional type overriding, also set the alternatives re-set
	
	The alternatives re-set are the optional options and are grouped by three.
	The first option is the state. The second is the name. The third is a function that takes in whether there is an object, and output the new alternative.
]]
function Objects:addObject(object, startValue, typ, ...)
	if self:getObjectRaw(object) then console:print("Trying to re-add object " .. tostring(object) .. "\n", LogLevel.WARNING, "objects.lua/Objects:addObject") return end
	
	if not typ then typ = type(startValue) end
	
	self.__added_objects[object] = {default = startValue, type = typ, add = {...}}
	self.__objects[object] = startValue
end

--[[ initialize - The Objects initializer
	(Re)initializes the object with the corresponding object kind
	
	objKind - object group kind:
	- 1: standard physical objects (key, red key, sword)
	otherwise empty set
]]
function Objects:initialize(objKind)
	self.__objects = {}
	self.__added_objects = {}
	
	if objKind == 0 then -- Empty object
	elseif objKind == 1 then
		self:addObject("key", false, "held", {"ig"}, "key", function(set) return tostring(set) end, {"ig", "keydoors", "group", "key"}, "take", function(set, diff) if set then if diff <= 2 then return "easy" elseif diff >= 4 then return "false" else return "norm" end else return "true" end end)
		self:addObject("redkey", false, "held", {"ig"}, "redkey", function(set) return tostring(set) end, {"ig", "keydoors", "redgroup", "key"}, "take", function(set, diff) if set then if diff <= 2 then return "easy" elseif diff >= 4 then return "false" else return "norm" end else return "true" end end)
		self:addObject("sword", false, "held", {"ig"}, "sword", function(set) return tostring(set) end, {"ig", "sword"}, "take", function(set, diff) if set then if diff <= 2 then return "easy" elseif diff >= 4 then return "false" else return "norm" end else return "true" end end)
	end -- Line 130
end
