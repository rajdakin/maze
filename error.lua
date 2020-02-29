local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local classmodule = require(import_prefix .. "class")

any_error = {}
local function tccall(self)
	local success, tret = pcall(self.__value.try)
	
	local caught = success
	if not success then
		local i, v
		for i, v in ipairs(self.__value.catch) do
			if (type(tret) == type(v.typ)) and ((type(tret) == "string" and tret:find(v.typ)) or (type(tret) == "table"
			  and type(tret.isinstance) == "function" and tret:isinstance(v.typ)))
			 or (v.typ == any_error) then
				caught = true
				tret = v.fcn(tret)
				break
			end
		end
	end
	
	local fret = self.__value.finally()
	
	if not caught then error(tret) end
	return {success, tret}, {fret}
end

local tcmeta = {
	__metatable = "Hidden metatable",
	__call = tccall
}

local function finally(self, fcn)
	self.catch = nil
	self.finally = nil
	
	self.__value.finally = fcn
	
	return self
end

local function catch(self, typ, fcn)
	table.insert(self.__value.catch, {typ = typ, fcn = fcn})
	
	return self
end

function try(fcn)
	ret = {
		catch = catch,
		finally = finally,
		
		__value = {
			try = fcn,
			catch = {},
			finally = function() end
		}
	}
	setmetatable(ret, tcmeta)
	
	return ret
end

--[[
	Try/catch/finally usage:
	
	try(function()
		...
	end):catch(error_type_or_substring_of_error_string_1, function(e)
		...
	end):catch(error_type_or_substring_of_error_string_2, function(e)
		...
	end):...:finally(function()
		...
	end)()
	
	The function in the `try` block will be executed first,
	then if it threw an error it checks whether it has a corresponding catch* (and executes it if necessary)
		in the order of the catch calls (there can be any number of catch)
	then it executes the `finally` block regardless of whether the `try`/`catch` succeeded or not
		(if a `catch` errors it will not be executed though)
	then if the error wasn't caught it propagates the error.
	It returns two tables, the first one is {[1] = success, [2] = ret} where success is true iff the `try` block didn't
		raise an exception and ret is the return value of the `try` or executed `catch` block
	and the second table ha its first element equal to the return value of the `finally` block.
	
	Note the use of the last `()`.
	
	* When the error is a string, it checks whether `err:find(substring_of_error_string)` is true
	  When it is a table, it checks whether `type(err.isinstance) == "function" and err:isinstance(error_type)` is true
]]

--[[ load_module - Load a module with error checking
	modname - module name
	onfail - function called when the module fails to load
	returns whether the module was successfully loaded
]]
function load_module(modname, onfail)
	if type(onfail) == "boolean" then local fail = onfail onfail = function(e)
		io.write("Failed loading module " .. modname .. "\n")
		if fail then error(e) else print(e) end
	end end
	
	local module_, _ = try(
		function() return require(import_prefix .. modname) end
	):catch("module '" .. modname .. "' not found", onfail)()
	
	return module_[1]
end
