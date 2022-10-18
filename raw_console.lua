local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local classmodule = load_module(import_prefix .. "class", true)

--[[ RawConsole -- a raw console output
	A limited version of the console that does not rely on the global configuration.
]]
local RawConsole = class(function(self, config)
	local out, err = config.out, config.err
	self.__out, self.__out_flush = out.print, out.flush
	self.__err, self.__err_flush = err.print, err.flush
end)

function RawConsole:printString(string, is_error)
	if is_error then
		self.__err(string)
	else
		self.__out(string)
	end
end
function RawConsole:print(printable, is_error, module)
	if type(printable) == "string" then
		self:printString("[RAW in " .. module .. "] " .. printable, is_error)
	elseif type(printable) == "table" then
		local function objtostr(obj, prep)
			if type(obj) == "table" then
				if DataStream and obj.isinstance and obj:isinstance(DataStream) then
					obj = obj:get("")
				end
				local str = ""
				for k, v in pairs(obj) do
					if v == obj then str = str .. "\n" .. prep .. k .. ": self"
					else str = str .. "\n" .. prep .. k .. ":" .. objtostr(v, prep .. "  ") end
				end
				return str
			else
				return " " .. tostring(obj)
			end
		end
		self:printString("[RAW in " .. module .. "] " .. (objtostr(printable, ""):gmatch("\n(.*)")() or "") .. "\n", is_error)
	else
		self:print("Error with printable type\n", true, "raw_console.lua/RawConsole:print")
	end
	self.__out_flush()
	self.__err_flush()
end

rawconsole = RawConsole({
	out = {print = function(...)                     io.write(...) io.write("\27[00m") end, flush = function() io.flush() end},
	err = {print = function(...) io.write("\27[31m") io.write(...) io.write("\27[00m") end, flush = function() io.flush() end}
})
