local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local classmodule = load_module(import_prefix .. "class", true)

local FileState = enum(function(self, name, args)
	self.open  = args[1]
	self.read  = args[2]
	self.write = args[3]
	self.app   = args[5]
	self.bin   = args[4]
end, nil,
{closed = {false},
 openR   = {true, true,  false, false, false},
 openA   = {true, false, true,  false, true },
 openW   = {true, false, true,  false, false},
 openRA  = {true, true,  true,  false, true },
 openRW  = {true, true,  true,  false, false},
 openRB  = {true, true,  false, true,  false},
 openAB  = {true, false, true,  true,  true },
 openWB  = {true, false, true,  true,  false},
 openRAB = {true, true,  true,  true,  true },
 openRWB = {true, true,  true,  true,  false}
})

File = class(function(self, filename)
	self.__filename = filename
	self.__state = FileState.closed
end)

function File:canOpen(mode)
	if type(mode) == "table" then
		if mode.open then
			local mod = ""
				if mode.read  then mod = mod .. "r" end
				if mode.app   then mod = mod .. "a"
			elseif mode.write then mod = mod .. "w" end
				if mode.bin   then mod = mod .. "b" end
			
			mode = mod
		else
			return false
		end
	end
	return try(
		function() io.open(self.__filename, mode):close() return true end
	):catch(any_error, function(e) return false end)("file.lua/File:canOpen@mode=" .. tostring(mode))
end

function File:open(mode)
	if self.__file then self.__file:close() end
	
	if type(mode) == "string" then
		local read, write, bin, mod, fmode = false, false, false, "", "open"
		if     mode:find("r") then mod, fmode, read  = mod .. "r", fmode .. "R", true end
		if     mode:find("a") then mod, fmode, write = mod .. "a", fmode .. "A", true
		elseif mode:find("w") then mod, fmode, write = mod .. "w", fmode .. "W", true end
		if     mode:find("b") then mod, fmode, bin   = mod .. "b", fmode .. "B", true end
		
		if FileState[fmode] then
			local emsg, ecode
			self.__file, emsg, ecode = io.open(self.__filename, mod)
			
			if self.__file then
				self.__state = FileState[fmode]
				
				return true
			else
				load_module(import_prefix .. "console", true)
				
				console:print("Error while opening file " .. self.__filename .. " in " .. mod .. " mode (error code " .. tostring(ecode) .. ": " .. tostring(emsg) .. "\n", LogLevel.ERROR, "file.lua/File:open:(string)")
				return false
			end
		else
			load_module(import_prefix .. "console", true)
			
			console:print("Unknown opening mode " .. mode .. "\n", LogLevel.WARNING_DEV, "file.lua/File:open:(string)")
			return false
		end
	elseif type(mode) == "table" then
		self.__state = mode
		if mode.open then
			local mod = ""
			    if mode.read  then mod = mod .. "r" end
			    if mode.app   then mod = mod .. "a"
			elseif mode.write then mod = mod .. "w" end
			    if mode.bin   then mod = mod .. "b" end
			
			return self:open(mod)
		else
			self:close()
			return 0
		end
	else
		load_module(import_prefix .. "console")
		
		console:print("Unknown opening type " .. type(mode) .. "\n", LogLevel.ERROR, "file.lua/File:open")
	end
end

function File:close()
	self.__state = FileState.closed
	local _file = self.__file
	self.__file = nil
	return _file:close()
end

function File:__gc()
	if self.__state ~= FileState.closed then
		self:close()
	end
end

function File:readLine()
	local opened = false
	if not self.__state.read then
		opened = self.__state
		
		if self.__file then self:close() end
		
		if not self:open("r") then
			return nil
		end
	end
	
	local ret = self.__file:read()
	
	if opened then
		self:open(opened)
	end
	
	return ret
end

function File:getLines()
	if not self.__state.open then return function() return nil end end
	
	local function f(lines, lineno)
		local line = lines()
		if not line then return nil
		else if lineno then return lineno + 1, line else return 1, line end end
	end
	
	return f, self.__file:lines(), nil
end

function File:write(...)
	local opened = false
	if not self.__state.write then
		opened = self.__state
		
		if self.__file then self:close() end
		
		if not self:open("w") then
			return false
		end
	end
	
	self.__file:write(...)
	
	if opened then
		self:close()
		self:open(opened)
	end
	
	return true
end


DataStream = class(function(self)
	self.__data = {type = "object", val = {}}
end)

local function transform_value(val, datatype, from)
	if not datatype then datatype = type(val) end
	
	if datatype == "function" then
		if val == tostring then return {type = "typecast", val = val}
		elseif val == tonumber then return {type = "typecast", val = val}
		else error(UnimplementedCase("datatype == function", "transform_value(" .. from .. ")")) end
	elseif datatype == "boolsswitch" then
		return {type = datatype, val = val}
	elseif datatype == "typecast" then
		local fcn
		if val == "string" then fcn = tostring
		elseif val == "number" then fcn = tonumber
		elseif type(val) == "function" then fcn = val
		else error(UnimplementedCase(
			"datatype == typecast and val == " .. tostring(val), "transform_value(" .. from .. ")"
		)) end
		return {type = datatype, val = fcn}
	elseif datatype == "switchfunction" then
		if not val[1] or not val[2] then
			error(InvalidArgument(
				"val", "a switchfunction value must have two objects and a function", "transform_value(" .. from .. ")"
			))
		end
		for k, v in pairs(val) do if (k ~= 1) and (k ~= 2) and ((k ~= 3) or (type(v) ~= "function")) then
			error(InvalidArgument(
				"val", "a switchfunction value must have two objects and a function", "transform_value(" .. from .. ")"
			))
		end end
		local strfun = ""
		if getArrayLength(val[1]) > 0 then
			strfun = "local "
			for _, v in pairs(val[1]) do strfun = strfun .. v.name .. ", " end strfun = strfun:match("^(.+), $")
			strfun = strfun .. " = ...\n"
		end
		local curansw = 1
		local function parsenext(i)
			local v = val[1][i]
			if not v then
				local function litteral(v)
					if type(v) == "string" then return '"' .. v:gsub('"', "\\\"") .. '"'
					elseif type(v) == "number" then return tostring(v)
					else error(InvalidArgument(
						"str", "a return type was not recognized: " .. type(v), "transform_value(" .. from .. ")"
					)) end
				end
				strfun = strfun .. "return " .. litteral(val[2][curansw]) .. " "
				curansw = curansw + 1
			elseif v.type == "boolean" then
				strfun = strfun .. "if not " .. v.name .. " then " parsenext(i + 1)
				strfun = strfun .. "else " parsenext(i + 1)
				strfun = strfun .. "end "
			elseif v.type == "number-to-tristate" then
				strfun = strfun .. "if " .. v.name .. " <= " .. v.low .. " then " parsenext(i + 1)
				strfun = strfun .. "elseif " .. v.name .. " <= " .. v.high .. " then " parsenext(i + 1)
				strfun = strfun .. "else " parsenext(i + 1)
				strfun = strfun .. "end "
			else error(InvalidArgument(
				"val",
				"a switchfunction's first array must have a list of valid objects",
				"transform_value(" .. from .. ")"
			)) end
		end
		parsenext(1)
		if _VERSION == "Lua 5.1" then
			val[3] = loadstring(strfun)
		else
			val[3] = load(strfun)
		end
		for i, v in pairs(val[1]) do val[1][i] = transform_value(v, nil, from) end
		for i, v in pairs(val[2]) do val[2][i] = transform_value(v, nil, from) end
		val[1] = {type = "array", val = val[1]}
		val[2] = {type = "array", val = val[2]}
		val[3] = {type = " switchfunction function", val = val[3]}
		return {type = datatype, val = val}
	elseif datatype == "number" then
		return {type = datatype, val = tonumber(val)}
	elseif datatype == "string" then
		return {type = datatype, val = tostring(val)}
	elseif datatype == "boolean" then
		return {type = datatype, val = (val == true) or ((type(val) == "string") and (val ~= "false"))}
	elseif (datatype == "object") or (datatype == "array") or (datatype == "table") then
		if datatype == "table" then
			datatype = "array"
			for k, v in pairs(val) do
				if (type(k) ~= "number") or ((k ~= 1) and (val[k - 1] == nil)) then datatype = "object" break end
			end
		end
		if datatype == "array" then
			-- Do I want this?
			if val[1] and val[2] and (not val[3] or (type(val[3]) == "function")) then
				local ok = true
				for i, v in pairs(val) do
					if (i ~= 1) and (i ~= 2) and (i ~= 3) then
						ok = false
						break
					end
				end
				if ok then
					if (type(val[1]) == "table") and (type(val[2]) == "table") then
						for k, v in pairs(val[1]) do
							if not v.name or not v.type then
								ok = false
								break
							end
						end
						if ok then
							return transform_value(val, "switchfunction", from)
						end
					end
				end
			end
		end
		
		local va = {}
		for k, v in pairs(val) do
			va[k] = transform_value(v, nil, from)
		end
		return {type = datatype, val = va}
	else
		error(InvalidArgument("datatype", "unknown datatype " .. tostring(datatype), "transform_value(" .. from .. ")"))
	end
end
local function transform_value_back(val)
	local datatype = val.type
	if datatype == "function" then
		return val.val
	elseif datatype == "boolsswitch" then
		return val.val
	elseif datatype == " switchfunction function" then
		return val.val
	elseif datatype == "switchfunction" then
		return val.val[3].val
	elseif datatype == "typecast" then
		return val.val
	elseif datatype == "number" then
		return tonumber(val.val)
	elseif datatype == "string" then
		return tostring(val.val)
	elseif datatype == "boolean" then
		return not not val.val
	elseif (datatype == "object") or (datatype == "array") then
		local va = {}
		for k, v in pairs(val.val) do
			va[k] = transform_value_back(v)
		end
		return va
	else
		error(InvalidArgument("val", "unknown datatype " .. tostring(datatype), "file.lua/transform_value_back(DataStream:get)"))
	end
end

function DataStream:setSubDataStream(key, subds)
	local invarg = function(a, b) error(InvalidArgument(a, b, "DataStream:setSubDataStream")) end
	
	key = tostring(key)
	if key:find(":") then invarg("key", "key must be a string not containing :") end
	
	local toint = function(v, name)
		local n = tonumber(v)
		if (n == nil) or (floor(n) ~= n) then
			error(InvalidArgument(name, tostring(v) .. " is not an integer", "DataStream:setSubDataStream.toint"))
		end
		return n
	end
	
	local data, lastgen = self.__data, false
	local keys = {}
	for k in string.gmatch(tostring(key), "[^%.]+") do
		if k:find("%[") then
			local first = true
			for i in string.gmatch(k, "[^%[%]]+") do
				if first then
					first = false
					table.insert(keys, i)
				else
					if i == "#next" then i = -1 else i = toint(i, "key") end
					table.insert(keys, i)
				end
			end
		else
			table.insert(keys, k)
		end
	end
	key = table.remove(keys)
	for i, k in ipairs(keys) do
		if type(k) == "number" then
			if k == -1 then k = #data.val + 1
			elseif (k ~= 1) and not data.val[k - 1] then invarg(
				"key", "the key leads to an array but its index is outside the possible range"
			) end
			if data.type ~= "array" then
				if not lastgen then
					invarg("key", "the key does not lead to an array")
				else
					data.type = "array"
				end
			end
		else
			if data.type ~= "object" then
				invarg("key", "the key does not lead to an object")
			end
		end
		lastgen = not data.val[k]
		if not data.val[k] then data.val[k] = {type = "object", val = {}} end
		data = data.val[k]
	end
	
	if (data.type == "array") and (type(key) ~= "number") then
		invarg("key", "the key lead to an array but " .. tostring(key) .. " is not an integer")
	end
	
	datatype = tostring(datatype)
	if type(key) == "number" then
		if lastgen then data.type = "array" end
		if data.type ~= "array" then invarg("key", "the key does not lead to an array") end
		if key == -1 then key = #data.val + 1
		elseif (key ~= 1) and not data.val[key - 1] then invarg(
			"key", "the key leads to an array but its index is outside the possible range"
		) end
	else
		if data.type ~= "object" then invarg("key", "the key does not lead to an object") end
	end
	
	local ctainer = true
	for k, v in pairs(subds.__data.val) do
		if (k ~= "_container") then ctainer = false end
	end
	if ctainer then
		subds = subds.__data.val._container
		if (subds.type == "switchfunction") or (subds.type == "array") then
			try(function()
				data.val[key] = transform_value(transform_value_back(subds), subds.type, "DataStream:setSubDataStream")
			end):catch(InvalidArgument, function(e) error(BundledError(
				InvalidArgument("subds", "invalid sub datastream", "DataStream:setSubDataStream"),
				e
			)) end)("DataStream:setSubDataStream>subds=_container")
		else
			data.val[key] = subds
		end
	else
		data.val[key] = subds.__data
	end
end
function DataStream:set(key, value, datatype)
	if not datatype then datatype = type(value) end
	
	local invarg = function(a, b) error(InvalidArgument(a, b, "DataStream:set")) end
	
	key = tostring(key)
	if key:find(":") then invarg("key", "key must be a string not containing :") end
	
	local toint = function(v, name)
		local n = tonumber(v)
		if (n == nil) or (floor(n) ~= n) then
			error(InvalidArgument(name, tostring(v) .. " is not an integer", "DataStream:set.toint"))
		end
		return n
	end
	
	local data, lastgen = self.__data, false
	local keys = {}
	for k in string.gmatch(tostring(key), "[^%.]+") do
		if k:find("%[") then
			local first = true
			for i in string.gmatch(k, "[^%[%]]+") do
				if first then
					first = false
					table.insert(keys, i)
				else
					if i == "#next" then i = -1 else i = toint(i, "key") end
					table.insert(keys, i)
				end
			end
		else
			table.insert(keys, k)
		end
	end
	key = table.remove(keys)
	for i, k in ipairs(keys) do
		if type(k) == "number" then
			if k == -1 then k = #data.val + 1
			elseif (k ~= 1) and not data.val[k - 1] then invarg(
				"key", "the key leads to an array but its index is outside the possible range"
			) end
			if data.type ~= "array" then
				if not lastgen then
					invarg("key", "the key does not lead to an array")
				else
					data.type = "array"
				end
			end
		else
			if data.type ~= "object" then
				invarg("key", "the key does not lead to an object")
			end
		end
		lastgen = not data.val[k]
		if not data.val[k] then data.val[k] = {type = "object", val = {}} end
		data = data.val[k]
	end
	
	if (data.type == "array") and (type(key) ~= "number") then
		invarg("key", "the key lead to an array but " .. tostring(key) .. " is not an integer")
	end
	
	datatype = tostring(datatype)
	if type(key) == "number" then
		if lastgen then data.type = "array" end
		if data.type ~= "array" then invarg("key", "the key does not lead to an array") end
		if key == -1 then key = #data.val + 1
		elseif (key ~= 1) and not data.val[key - 1] then invarg(
			"key", "the key leads to an array but its index is outside the possible range"
		) end
	else
		if data.type ~= "object" then invarg("key", "the key does not lead to an object") end
	end
	
	if datatype == "function" then
		if type(value) ~= "string" then data.val[key] = {type = datatype, val = value}
		else invarg("value", "value must be a function") end
	else
		data.val[key] = transform_value(value, datatype, "DataStream:setSubDataStream")
	end
end

function DataStream:getAsDataStream(key, errorOnFailure)
	local fail = function(msg)
		if errorOnFailure then
			error(InvalidArgument("key", msg, "DataStream:getAsDataStream"))
		else
			return nil
		end
	end
	
	key = tostring(key)
	if key == "" then return self end
	if key:find(":") then return fail("key must be a string not containing ':'") end
	
	local toint = function(v, name)
		local n = tonumber(v)
		if (n == nil) or (floor(n) ~= n) then return fail("the index is not a number") end
		return n
	end
	
	local keys = {}
	for k in string.gmatch(tostring(key), "[^%.]+") do
		if k:find("%[") then
			local first = true
			for i in string.gmatch(k, "[^%[%]]+") do
				if first then
					table.insert(keys, i)
					first = false
				else
					local v = toint(i)
					if v == nil then return nil end
					table.insert(keys, v)
				end
			end
		else
			table.insert(keys, k)
		end
	end
	key = table.remove(keys)
	
	local data = self.__data
	if data == nil then
		if errorOnFailure then
			error(ErrorBase("the datastream doesn't contain anything!", "DataStream:getAsDataStream"))
		else
			return nil
		end
	end
	
	local t
	for _, v in ipairs(keys) do
		if type(v) == "number" then
			t = "array"
		else
			t = "object"
		end
		if data.type ~= t then
			return fail("the key does not lead to an " .. t)
		end
		
		data = data.val[v]
		if data == nil then
			return fail("the key does not lead to anything")
		end
	end
	
	if type(key) == "number" then
		if data.type ~= "array" then
			return fail("the key does not lead to an array")
		end
	else
		if errorOnFailure and (data.type ~= "object") then
			return fail("the key does not lead to an object")
		end
	end
	
	local ret = DataStream()
	if data.val and data.val[key] then ret.__data = deepcopy(data.val[key])
	else ret.__data = {type = "nil", val = nil} end
	return ret
end
function DataStream:get(key, errorOnFailure)
	local ds = self:getAsDataStream(key, errorOnFailure)
	if errorOnFailure then
		if ds and ds.__data then
			return transform_value_back(ds.__data)
		else
			error(UnknownError("Datastream or datastream data is nil", "file.lua/DataStream:get>errorOnFailure=true"))
		end
	else
		if ds then
			return ({
				try(differ(transform_value_back, ds.__data))
				 :catch(any_error, function(e) return nil end)("file.lua/DataSteam:get>errorOnFailure=false")})[1][2]
		else
			return nil
		end
	end
end

function DataStream:getOrDefault(key, default)
	ret = self:get(key, false)
	if ret == nil then return default
	else return ret end
end

function DataStream:read(filename)
	local olddatas = self.__data
	self.__data = {}
	
	local file = File(filename)
	
	if not file:open(FileState.openR) then return {success = false, reas = "openfile", reason = "Cannot open file"} end
	
	local line = file:readLine()
	local version = line:gmatch("Version v?([0-9]+%.[0-9]+%.[0-9]+[%.-][0-9][0-9]+[abr])")()
	             or line:gmatch("Version v?([0-9]+%.[0-9]+%.[0-9]+[%.-][0-9][0-9]+%-pre[0-9]+)")()
	if not version then
		file:close()
		return {success = false, reas = "missingver", reason = "Missing version information"}
	end
	
	local build = version:gmatch("[0-9]+%.[0-9]+%.[0-9]+[%.-]([0-9][0-9]+)")()
	build = tonumber(build)
	if not build or (floor(build) ~= build) or (build < 1) then
		file:close()
		return {success = false, reas = "badbld", reason = "Invalid build number"}
	end
	if build > 1 then
		file:close()
		return {success = false, reas = "unkbld", reason = "Unknown build number"}
	end
	
	local lines = {}
	for i, l in file:getLines() do
		lines[i] = l
	end
	file:close()
	local lineIdx = 1
	local function getLine() lineIdx = lineIdx + 1 return lines[lineIdx - 1] end
	
	local innerblock = "  "
	local readObjects
	readObjects = {
		[1] = {
			readData = function(val, prefix)
				local type = val:gmatch("%w+")()
				if not type then error(InvalidArgument("val", "malformed line", "DataStream:read.readData_1")) end
				val = val:gmatch(type .. ": (.+)$")()
				if type == "object" then return readObjects[1].readObject(prefix .. innerblock)
				elseif type == "array" then return readObjects[1].readArray(prefix .. innerblock)
				elseif type == "switchfunction" then return readObjects[1].readSwFunArgs(prefix .. innerblock)
				else return transform_value(val, type, "DataStream:read") end
			end,
			readObject = function(prefix)
				local dat = {type = "object", val = {}}
				while true do
					local line = getLine()
					while line and line:find("^%s*$") do line = getLine() end
					if not line or not line:find("^" .. prefix .. "[^" .. innerblock:sub(1, 1) .. "]") then lineIdx = lineIdx - 1 return dat end
					line = line:gmatch(prefix .. "(.*)")()
					local key = line:gmatch("(.-):")()
					local val = line:gmatch(key .. ":%s*(.*)")()
					dat.val[key] = readObjects[1].readData(val, prefix)
				end
			end,
			readArray = function(prefix)
				local dat = {type = "array", val = {}}
				local idx = 1
				while true do
					local line = getLine()
					while line and line:find("^%s*$") do line = getLine() end
					if not line or not line:find("^" .. prefix .. "[^" .. innerblock:sub(1, 1) .. "]") then lineIdx = lineIdx - 1 return dat end
					line = line:gmatch(prefix .. "(.*)")()
					local val = line
					dat.val[idx] = readObjects[1].readData(val, prefix)
					idx = idx + 1
				end
			end,
			
			readSwFunArgs = function(prefix)
				local dat = {}
				
				local line = getLine()
				while line and line:find("^%s*$") do line = getLine() end
				if not line or not line:find("^" .. prefix .. "[^" .. innerblock:sub(1, 1) .. "]") then
					error(InvalidArgument("val", "malformed switchfunction", "DataStream:read.readSwFunArgs_1"))
				end
				line = line:gmatch(prefix .. "(.*)")()
				local val = line
				local type = val:gmatch("%w+")()
				if not type then error(InvalidArgument("val", "malformed line", "DataStream:read.readSwFunArgs_1")) end
				val = val:gmatch(type .. ": (.+)$")()
				if type == "array" then dat[1] = readObjects[1].readSwFunArgs1(prefix .. innerblock)
				else error(InvalidArgument("val", "malformed switchfunction", "DataStream:read.readSwFunArgs_1")) end
				
				local line = getLine()
				while line and line:find("^%s*$") do line = getLine() end
				if not line or not line:find("^" .. prefix .. "[^" .. prefix:sub(1, 1) .. "]") then
					error(InvalidArgument("val", "malformed switchfunction", "DataStream:read.readSwFunArgs_1"))
				end
				line = line:gmatch(prefix .. "(.*)")()
				local val = line
				local type = val:gmatch("%w+")()
				if not type then error(InvalidArgument("val", "malformed line", "DataStream:read.readSwFunArgs_1")) end
				val = val:gmatch(type .. ": (.+)$")()
				if type == "array" then dat[2] = readObjects[1].readSwFunArgs2(prefix .. innerblock)
				else error(InvalidArgument("val", "malformed switchfunction", "DataStream:read.readSwFunArgs_1")) end
				
				return transform_value(dat, "switchfunction", "DataStream:read.readSwFunArgs_1")
			end,
			readSwFunArgs1 = function(prefix)
				-- Array of "boolean" variables or "number-to-tristate" variables
				local dat = {}
				local idx = 1
				while true do
					local line = getLine()
					while line and line:find("^%s*$") do line = getLine() end
					if not line or not line:find("^" .. prefix .. "[^" .. prefix:sub(1, 1) .. "]") then lineIdx = lineIdx - 1 return dat end
					line = line:match(prefix .. "(.*)")
					
					local type = line:match("[%w%-]+")
					if not type then error(InvalidArgument("line", "malformed line", "DataStream:read.readSwFunArgs1_1")) end
					line = line:match(": (.+)$")
					if type == "boolean" then dat[idx] = {type = type, name = line}
					elseif type == "number-to-tristate" then
						local i = 1
						local ts = {"name", "low", "high"}
						dat[idx] = {type = type}
						for v,_ in line:gmatch("([^,]+)(,? ?)") do dat[idx][ts[i]] = v i = i + 1 end
					else error(InvalidArgument("line", "invalid data type", "DataStream:read.readSwFunArgs1_1")) end
					
					idx = idx + 1
				end
			end,
			readSwFunArgs2 = function(prefix)
				-- Array of "string"s or "number"s
				local dat = {}
				local idx = 1
				while true do
					local line = getLine()
					while line and line:find("^%s*$") do line = getLine() end
					if not line or not line:find("^" .. prefix .. "[^" .. prefix:sub(1, 1) .. "]") then lineIdx = lineIdx - 1 return dat end
					line = line:gmatch(prefix .. "(.*)")()
					local val = line
					
					local type = val:gmatch("%w+")()
					if not type then error(InvalidArgument("val", "malformed line", "DataStream:read.readSwFunArgs2_1")) end
					if (type ~= "string") and (type == "number") then
						error(InvalidArgument("val", "invalid data type", "DataStream:read.readSwFunArgs2_1"))
					end
					dat[idx] = val:gmatch(type .. ": (.+)$")()
					
					idx = idx + 1
				end
			end
		}
	}
	if build == 1 then
		local ret = ({try(function()
			self.__data = readObjects[1].readObject("")
			return nil
		end):catch(any_error, function(e)
			return BundledError(InvalidArgument("filename", "invalid file", "DataStream:read"), e)
		end)("DataStream:read>build=1")})[1]
		if not ret[1] then
			return {success = false, reas = ret[2]}
		else
			return {success = true}
		end
	end
end

--[[
	Note: serialize functions at your own risk!
	(There is a pretty high probability this will crash,
	  either at save time or load time due to invalid serialization.)
]]
function DataStream:write(filename)
	local lines = {}
	local innerblock = "  "
	
	table.insert(lines, "Version 1.0.0.01b")
	table.insert(lines, "")
	
	local objectConverter
	objectConverter = {
		[1] = {
			convertData = function(dat, prefix, pref2)
				local datatype = dat.type
				if datatype == "object" then
					table.insert(lines, prefix .. (pref2 or "") .. datatype .. (pref2 and "" or ":"))
					objectConverter[1].convertObject(dat.val, prefix .. innerblock)
				elseif datatype == "array" then
					table.insert(lines, prefix .. (pref2 or "") .. datatype .. (pref2 and "" or ":"))
					objectConverter[1].convertArray(dat.val, prefix .. innerblock)
				elseif datatype == "switchfunction" then
					table.insert(lines, prefix .. (pref2 or "") .. datatype .. (pref2 and "" or ":"))
					objectConverter[1].convertArray({dat.val[1], dat.val[2]}, prefix .. innerblock)
				elseif datatype == "typecast" then
					dat = ({
						[tostring] = "typecast: string",
						[tonumber] = "typecast: number"
					})[dat.val]
					if dat then table.insert(lines, prefix .. (pref2 or "") .. dat)
					else error(InvalidArgument(
						"dat", "dat is not a known typecast", "DataStream:set.objectConverter[1].convertData"
					)) end
				elseif (datatype == "boolean") or (datatype == "number") or (datatype == "string") then
					table.insert(lines, prefix .. (pref2 or "") .. datatype .. ": " .. tostring(dat.val))
				else
					error(InvalidArgument(
						"dat",
						"unknown data type " .. tostring(datatype),
						"DataStream:set.objectConverter[1].convertData"
					))
				end
			end,
			convertObject = function(obj, prefix)
				for k, v in pairs(obj) do
					objectConverter[1].convertData(v, prefix, tostring(k) .. ": ")
					if prefix == "" then table.insert(lines, "") end
				end
			end,
			convertArray = function(obj, prefix)
				for i, v in ipairs(obj) do
					objectConverter[1].convertData(v, prefix)
				end
			end
		}
	}
	objectConverter[1].convertObject(self.__data.val, "")
	
	local text = ""
	for i, l in ipairs(lines) do
		text = text .. l .. "\n"
	end
	text = text:gmatch("(.*)\n")()
	
	local file = File(filename)
	file:open("w")
	file:write(text)
	file:close()
end
