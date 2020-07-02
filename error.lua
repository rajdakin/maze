local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local classmodule = require(import_prefix .. "class")

--[[
	Some "standard" errors:
	- ErrorBase - a generic error class
	- UnknownError - an error due to a state theoretically inaccessible
	- StringError - a string error (thrown mainly by Lua)
	- UncaughtError - an uncaught error
	- BundledError - two or more errors budled together
	- InvalidArgument - an argument was given, but its type or value is incorrect
	+ UnimplementedCase - the state of the program leads to a yet-to-be-implemented case
	 - UnimplementedFunction - the function is not yet implemented
]]

ErrorBase = class(function(self, reasonstr, thrower)
	self.str = tostring(reasonstr)
	self.thrower = tostring(thrower)
end)
function ErrorBase:tostring(prepend)
	if type(prepend) ~= "string" then prepend = "" end
	return prepend .. "[In " .. self.thrower .. "] " .. self.str
end
function ErrorBase:__tostring()
	return self:tostring("")
end

UnknownError = class(nil, ErrorBase)

StringError = class(function(self, str)
	ErrorBase.__init(self, str, "Lua")
end, ErrorBase)
function StringError:tostring(prepend)
	if type(prepend) ~= "string" then prepend = "" end
	return prepend .. self.str
end

UncaughtError = class(function(self, old_error, new_thrower)
	ErrorBase.__init(self, "Uncaught error", new_thrower)
	if type(old_error) == "string" then old_error = StringError(old_error) end
	self.old_error = old_error
end, ErrorBase)
function UncaughtError:tostring(prepend)
	if type(prepend) ~= "string" then prepend = "" end
	return ErrorBase.tostring(self, prepend) .. "\n" .. self.old_error:tostring(prepend .. "  ")
end

BundledError = class(function(self, error1, error2)
	if type(error1) == "string" then error1 = StringError(error1) end
	if (type(error1) ~= "table") or not error1.isinstance or not error1:isinstance(ErrorBase) then
		error1 = InvalidArgument("error1", "cannot bundle two non-errors", "BundledError.__init") end
	if type(error2) == "string" then error2 = StringError(error2) end
	if (type(error2) ~= "table") or not error2.isinstance or not error2:isinstance(ErrorBase) then
		error2 = InvalidArgument("error2", "cannot bundle two non-errors", "BundledError.__init") end
	ErrorBase.__init(self, error1.str, error1.thrower)
	
	self.nberr = 0
	if error1:isinstance(BundledError) then self.errors = deepcopy(error1.errors) self.nberr = error1.nberr
	else self.errors = {error1} self.nberr = 1 end
	if error2:isinstance(BundledError) then
		for i, v in ipairs(self.errors) do
			local copy = deepcopy(v)
			setmetatable(copy, getmetatable(v))
			self.errors[i + self.nberr] = copy
		end
		self.nberr = self.nberr + error2.nberr
	else
		local copy = deepcopy(error2)
		setmetatable(copy, getmetatable(error2))
		table.insert(self.errors, copy)
		self.nberr = self.nberr + 1
	end
end, ErrorBase)
function BundledError:tostring(prepend)
	local ret = ""
	for i, v in ipairs(self.errors) do
		if ret ~= "" then ret = ret .. "\n" end ret = ret .. v:tostring(prepend)
	end
	return ret
end

InvalidArgument = class(function(self, argname, reason, thrower)
	ErrorBase.__init(self, "Invalid argument " .. tostring(argname) .. ": " .. reason, thrower)
end, ErrorBase)

UnimplementedCase = class(function(self, casename, thrower)
	ErrorBase.__init(self, tostring(casename) .. " is yet to be implemented", thrower)
end, ErrorBase)

UnimplementedFunction = class(function(self, funname)
	UnimplementedCase.__init(self, "The function " .. tostring(funname), tostring(funname))
end, UnimplementedCase)

--[[
	any_error - object to pass to the catch function to catch every possible error
	any_error_of - object of objects to pass to the catch function to catch every possible error of a given type
]]
any_error = {}
any_error_of = {table = {}, string = {}, number = {}}
local function tccall(self, origin)
	local success, tret = pcall(self.__value.try)
	local caught = success
	if not success then
		for i, v in ipairs(self.__value.catch) do
			if (type(tret) == type(v.typ)) and (((type(tret) == "string") and tret:find(v.typ)) or ((type(tret) == "table")
			  and (type(tret.isinstance) == "function") and tret:isinstance(v.typ)))
			 or (v.typ == any_error) or (v.typ == any_error_of[type(tret)]) then
				caught = true
				tret = v.fcn(tret)
				break
			end
		end
	end
	
	local fret = self.__value.finally()
	
	if not caught then error(UncaughtError(tret, origin or "try-catch block")) end
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
	end)(optional_location_string)
	
	The function in the `try` block will be executed first,
	then if it threw an error it checks whether it has a corresponding catch* (and executes it if necessary)
		in the order of the catch calls (there can be any number of catch)
	then it executes the `finally` block regardless of whether the `try`/`catch` succeeded or not
		(if a `catch` errors it will not be executed though)
	then if the error wasn't caught it propagates the error.
	It returns two tables, the first one is {[1] = success, [2] = ret} where success is true if the `try` block didn't
		raise an exception and ret is the return value of the `try` or executed `catch` block
	and the second table has its first element equal to the return value of the `finally` block.
	
	Note the use of the last `()`.
	
	* When the error is a string, it checks whether `err:find(substring_of_error_string)` is true
	  When it is a table, it checks whether `type(err.isinstance) == "function" and err:isinstance(error_type)` is true
]]

-- printAnyError - print every error thrown by a call to the function in a "beautiful" way
function printAnyError(fun, printFun)
	if (type(printFun) ~= "function") -- Not a function
		and ((type(printFun) ~= "table") -- Not a table, or
			or (type(getmetatable(printFun)) ~= "table") -- Unavailable/undefined metatable, or
			or (type(getmetatable(printFun).__call) ~= "function")) then -- Uncallable table
		printFun = print
	end
	local function printTable(t, p, tbls)
		if type(t) ~= "table" then return tostring(t) end
		for i, v in pairs(tbls) do if v == t then return "backref #" .. tostring(i) end end
		table.insert(tbls, t)
		local ret = ""
		for k, v in pairs(t) do
			if ret ~= "" then ret = ret .. "\n" .. p end
			ret = ret .. tostring(k) .. ":\t" .. printTable(v, p .. "\t", tbls)
		end
		return ret
	end
	
	return ({
		try(fun):
		catch(ErrorBase, function(e)
			printFun(tostring(e))
		end):catch(any_error_of.table, function(e)
			printFun(printTable(e, "", {}))
		end):catch(any_error, function(e)
			printFun(tostring(e))
		end)()
	})[1]
end

--[[ load_module - Load a module with error checking
	modname - module name
	onfail - function called when the module fails to load
	returns whether the module was successfully loaded and the return value of the module
]]
function load_module(modname, onfail)
	if type(onfail) == "boolean" then local fail = onfail onfail = function(e)
		io.stderr:write("Failed loading module " .. modname .. "\n")
		if fail then error(UncaughtError(e)) else print(e) end
	end end
	
	local module_, _ = try(
		function() return require(import_prefix .. modname) end
	):catch("module '" .. modname .. "' not found", onfail)("module '" .. modname .. "' loading")
	
	return module_[1], module_[2]
end
