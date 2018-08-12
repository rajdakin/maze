local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local configmodule = require(import_prefix .. "config")
local classmodule = require(import_prefix .. "class")

local OutputModeClass = class(function(self, is_auto_valid, is_out, is_CPC)
	self.__is_auto_valid = is_auto_valid
	self.__is_CPC = is_CPC -- is char per char
	self.__out = is_out
end)

function OutputModeClass:isValid() return self.__is_auto_valid end
function OutputModeClass:isCharPerChar() return self.__is_CPC end
function OutputModeClass:isErrorMode() return not self.__out end

local OutputMode = enum(function(self, name, ...)
	args = {...} args = args[1]
	OutputModeClass.__init(self, args[1], args[2], args[3])
end, OutputModeClass,
{SOUT  = {true,  true,  true }, -- Slow standard OUTput
 FOUT  = {true,  true,  false}, -- Fast standard OUTput
 SERR  = {false, false, true }, -- Slow standard ERRor output
 FERR  = {false, false, false}, -- Fast standard ERRor output
 FATAL = {true,  false, false}} -- FATAL error output
)

local LogLevelClass = class(function(self, log_text, log_level, config_check, output_mode)
	self.__log_text = log_text
	
	self.__log_level = log_level
	self.__config_check = config_check
	
	self.__output_mode = output_mode
end)

function LogLevelClass:getLogText() return self.__log_text end
function LogLevelClass:getOutputMode(...) return self:__output_mode(...) end

function LogLevelClass:isValid(...)
	return self:getOutputMode(...):isValid()
	 or (currentConfig:getConsoleConfig():isLogLevelValid(self.__log_level)
	     and self.__config_check(currentConfig:getConsoleConfig()))
end

LogLevel = enum(function(self, name, ...)
	args = {...} args = args[1]
	LogLevelClass.__init(self, args[1], args[2], args[3], args[4])
end, LogLevelClass,
{FATAL_ERROR = {"Fatal error",       0, function(config) return true                     end, function(...) args = {...} return OutputMode.FATAL end},
 ERROR       = {"Error",             1, function(config) return true                     end, function(...) args = {...}                             return OutputMode.FERR                                 end},
 WARNING     = {"Warning",           2, function(config) return true                     end, function(...) args = {...}                             return OutputMode.FERR                                 end},
 WARNING_DEV = {"Developer warning", 2, function(config) return config:isDeveloperMode() end, function(...) args = {...}                             return OutputMode.FERR                                 end},
 INFO        = {"Info",              3, function(config) return true                     end, function(...) args = {...} if (args[2] == "fast") then return OutputMode.FOUT else return OutputMode.SOUT end end},
 LOG         = {"Log",               4, function(config) return true                     end, function(...) args = {...}                             return OutputMode.FOUT                                 end}}
)

local Log = class(function(self, log, out, err, pwait, gwait)
	self.__out, self.__out_pre, self.__out_flush = out.print, out.print_pre, out.flush
	self.__err, self.__err_pre, self.__err_flush = err.print, err.print_pre, err.flush
	
	self.__precision_wait = pwait
	self.__global_wait    = gwait
end)

function Log:printString(string, is_output_mode, is_valid)
	if is_output_mode then
		self.__out_pre(string)
		if is_valid then self.__out(string) end
	else
		self.__err_pre(string)
		if is_valid then self.__err(string) end
	end
end

function Log:print(printable, level, module, valid_args, output_args)
	local output_mode = not level:getOutputMode(output_args):isErrorMode()
	if type(printable) == "string" then
		self:printString("[" .. level:getLogText() .. " in " .. module .. "] " .. printable, output_mode, level:isValid(valid_args))
	else
		self:print("Error with printable type in the print module\n", LogLevel.ERROR, "util.lua/Log:print")
	end
	self.__out_flush()
	self.__err_flush()
end

function Log:printLore(printable, output_args)
	if type(printable) == "string" then
		self:printString(printable, true, true)
	else
		self:print("Error with printable type in the print (lore) module\n", LogLevel.ERROR, "util.lua/Log:printLore")
	end
	self.__out_flush()
	self.__err_flush()
end

local Console = class(function(self, input, log, out, err)
	self.__in = input
	self.__log = Log(log, out, err, sleep, longsleep)
end)

function Console:read(...)
	success, result = pcall(self.__in, ...)
	if not success then
		return {success = false, eos = error, returned = result}
	end
	
	if result then
		return {success = true, eos = false, returned = result}
	else
		return {success = true, eos = true, returned = nil}
	end
end

function Console:print(printable, level, module, valid_args)
	self.__log:print(printable, level, module, valid_args)
end

function Console:printLore(printable)
	self.__log:printLore(printable)
end

console = Console(
	function(...) return io.read(...) end,
	function(...) end, -- This will always be called, no matter what type it is.
	{print = function(...) io.write(...) end, flush = function() io.flush() end},
	{print = function(...) io.write(...) end, flush = function() io.flush() end}
)
