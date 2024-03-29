local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local configmodule = load_module(import_prefix .. "config", true)
local classmodule = load_module(import_prefix .. "class", true)
local filemodule = load_module(import_prefix .. "file", false)

local OutputModeClass = class(function(self, is_auto_valid, is_out, is_CPC)
	self.__is_auto_valid = is_auto_valid
	self.__is_CPC = is_CPC -- is char per char
	self.__out = is_out
end)

function OutputModeClass:isValid() return self.__is_auto_valid end
function OutputModeClass:isCharPerChar() return self.__is_CPC end
function OutputModeClass:isErrorMode() return not self.__out end
function OutputModeClass:tostring() return "[" .. (self.__out and "OUT" or "ERR") .. "] " end
OutputModeClass.__tostring = OutputModeClass.tostring

--[[ OutputMode - the output mode enum
	The output mode is a speed (character-per-character or immediate display), an output "descriptor"
	(output or error) and whether it is automatically outputed regardless of configurations.
]]
local OutputMode = enum(function(self, name, args)
	OutputModeClass.__init(self, args[1], args[2], args[3])
end, OutputModeClass,
{SOUT  = {true,  true,  true }, -- Slow standard OUTput
 FOUT  = {true,  true,  false}, -- Fast standard OUTput
 SNOU  = {false, true,  true }, -- Slow (Non-auto) standard OUTput
 FNOU  = {false, true,  false}, -- Fast (Non-auto) standard OUTput
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
LogLevelClass.__tostring = LogLevelClass.getLogText

function LogLevelClass:getOutputMode(...) return self:__output_mode(...) end

function LogLevelClass:isValid(...)
	return self:getOutputMode(...):isValid()
	 or (currentConfig:getConsoleConfig():isLogLevelValid(self.__log_level)
	     and self.__config_check(currentConfig:getConsoleConfig()))
end

--[[ LogLevel - the log levels enum
	The log level contains a text description, a log level, a configuration check (used to check
	if the configuration is correct) and an output mode function
]]
LogLevel = enum(function(self, name, args)
	LogLevelClass.__init(self, args[1], args[2], args[3], args[4])
end, LogLevelClass,
{FATAL_ERROR = {"Fatal error",       0, function(config) return true                     end, function(args) return OutputMode.FATAL end},
 ERROR       = {"Error",             1, function(config) return true                     end, function(args)                             return OutputMode.FERR                                 end},
 WARNING     = {"Warning",           2, function(config) return true                     end, function(args)                             return OutputMode.FERR                                 end},
 WARNING_DEV = {"Developer warning", 2, function(config) return config:isDeveloperMode() end, function(args)                             return OutputMode.FERR                                 end},
 INFO        = {"Info",              3, function(config) return true                     end, function(args) if (args[2] == "fast") then return OutputMode.FNOU else return OutputMode.SNOU end end},
 LOG         = {"Log",               4, function(config) return true                     end, function(args)                             return OutputMode.FNOU                                 end}}
)
LogLevel.level2log = {
	[0] = LogLevel.FATAL_ERROR,
	[1] = LogLevel.ERROR,
	[2] = LogLevel.WARNING,
	[3] = LogLevel.INFO,
	[4] = LogLevel.LOG
}
do
	local maxLogLevel = currentConfig:getConsoleConfig():getMaxLogLevel()
	assert(LogLevel.level2log[maxLogLevel] and not LogLevel.level2log[maxLogLevel + 1],
		"Forgot to change the max log level in the config!")
end

--[[ Log - the log class
	Holds its own configuration: the log (that is always called), the output/error printing functions,
	two waits function (for slow output mode).
	
	config - the log configuration
]]
local Log = class(function(self, config)
	local log, out, err, pwait, gwait = config.log, config.out, config.err, config.pwait, config.gwait
	
	self.__log = log
	self.__out, self.__out_inv, self.__out_flush = out.print, out.print_inv, out.flush
	self.__err, self.__err_inv, self.__err_flush = err.print, err.print_inv, err.flush
	
	self.__precision_wait = pwait
	self.__global_wait    = gwait
end)

function Log:printString(string, is_output_mode, is_valid)
	if is_output_mode then
		if is_valid then self.__out    (string)
		else             self.__out_inv(string) end
	else
		if is_valid then self.__err    (string)
		else             self.__err_inv(string) end
	end
end

function Log:print(printable, level, module, valid_args, output_args)
	local output_mode = not level:getOutputMode(output_args):isErrorMode()
	if type(printable) == "string" then
		self:printString("[" .. level:getLogText() .. " in " .. module .. "] " .. printable, output_mode, level:isValid(valid_args))
		self.__log(tostring(level:getOutputMode(output_args)) .. "[" .. level:getLogText() .. " in " .. module .. "] " .. printable)
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
		self:printString("[" .. level:getLogText() .. " in " .. module .. "] " .. (objtostr(printable, ""):gmatch("\n(.*)")() or "") .. "\n", output_mode, level:isValid(valid_args))
		self.__log(tostring(level:getOutputMode(output_args)) .. "[" .. level:getLogText() .. " in " .. module .. "] " .. (objtostr(printable, ""):gmatch("\n(.*)")() or "") .. "\n")
	else
		self:print("Error with printable type in the print module\n", LogLevel.ERROR, "console.lua/Log:print")
	end
	self.__out_flush()
	self.__err_flush()
end

function Log:printLore(printable)
	if type(printable) == "string" then
		self:printString(printable, true, true)
	elseif type(printable) == "table" then
		local function objtostr(obj, prep)
			if type(obj) == "table" then
				if DataStream and obj.isinstance and obj:isinstance(DataStream) then
					obj = obj:get("")
				end
				local str = ""
				for k, v in pairs(obj) do
					if v == obj then str = str .. "\n" .. prep .. tostring(k) .. ": self"
					else str = str .. "\n" .. prep .. tostring(k) .. ":" .. objtostr(v, prep .. "  ") end
				end
				return str
			else
				return " " .. tostring(obj)
			end
		end
		self:printString((objtostr(printable, ""):gmatch("\n(.*)")() or "") .. "\n", true, true)
	else
		self:print("Error with printable type in the print (lore) module\n", LogLevel.ERROR, "util.lua/Log:printLore")
	end
	self.__out_flush()
	self.__err_flush()
end

--[[ Console - the console class [singleton]
	Holds a Log objet and an input function.
	
	consoleConfig - the console configuration
	logConfig - the log configuration
]]
local Console = class(function(self, consoleConfig, logConfig)
	if not logConfig then consoleConfig, logConfig = consoleConfig.consoleConfig, consoleConfig.logConfig end
	local input = consoleConfig.input
	self.__in = input
	
	if not logConfig.pwait then logConfig.pwait = sleep end if not logConfig.gwait then logConfig.gwait = longsleep end
	self.__log = Log(logConfig)
end)

function Console:read(...)
	local success, result = pcall(self.__in, ...)
	if not success then
		return {success = false, eos = error, returned = result}
	end
	
	if result then
		return {success = true, eos = false, returned = result}
	else
		return {success = true, eos = true, returned = nil}
	end
end

--[[
	Prints the printable with the corresponding level and module.
	Available printable types: string
]]
function Console:print(printable, level, module, valid_args, output_args)
	self.__log:print(printable, level, module, valid_args, output_args)
end

--[[
	Simply prints the printable.
	Available printable types: string
]]
function Console:printLore(printable)
	self.__log:printLore(printable)
end

-- console - the console singleton; see also rawconsole
console = Console({
	consoleConfig = {
		input = function(...) return io.read(...) end
	}, logConfig = {
		log = function(...) local file = File("maze.log") file:open("a") file:write(...) file:close() end,
		out = {print = function(...)                     io.write(...) io.write("\27[00m") end, print_inv = function(...) end, flush = function() io.flush() end},
		err = {print = function(...) io.write("\27[31m") io.write(...) io.write("\27[00m") end, print_inv = function(...) end, flush = function() io.flush() end}
	}
})
