local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local consolemodule = load_module(import_prefix .. "console", true)
local classmodule = load_module(import_prefix .. "class", true)
local configmodule = load_module(import_prefix .. "config", function(e) end)

local comment = "#"

local id2lang = {}

--[[ Lang - the language class
	Holds any translation for the corresponding language
	
	See also - docs/lang.md
	
	lang_name - the displayable string of the lang name
	lang_id - the lang UID, used internally and while loading
	fallback_id - the lang fallback UID
]]
local Lang = class(function(self, lang_name, lang_id, fallback_id)
	self.__loadedLevels = {}
	
	if id2lang[lang_id] then
		console:print("Lang already defined: " .. lang_id .. "\n", LogLevel.ERROR, "dictionary.lua/Lang:(init)")
		for k, v in pairs(id2lang) do self[k] = v end
		return
	else
		id2lang[lang_id] = self
	end
	
	self.__lang_id = lang_id
	self.__lang_name = lang_name
	
	if fallback_id == nil then fallback_id = "en_US" end
	if lang_id ~= fallback_id then self.__fallback = fallback_id
	else                           self.__fallback = false       end
	
	self.__dict = {}
	self.__alt_dicts = {}
	local linecount = 0
	for line in io.lines(import_prefix .. "lang/" .. lang_id .. ".lgd") do
		linecount = linecount + 1
		
		if not line:find("^[ 	]*" .. comment) then
		local nwsline, repls = line:gsub("^%s+", ""):gsub("(%w[%w_%.%:]-)%s*= ?", "%1=", 1)
		if nwsline and (nwsline ~= "") and not nwsline:find("^" .. comment) then
			if repls == 0 then
				console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] Invalid states-key in `" .. nwsline .. "'\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
			elseif nwsline:find("=") then -- Should always be true, since we check for 1 substitution (which contains '=')
				local text_id, text = nwsline:gsub("=.*", "", 1), nwsline:gsub(".-=", "", 1)
				
				local err = false
				
				local dict = self.__dict
				while text_id:find("%.") do
					local dictdot = text_id:find("%.")
					local dictkey = text_id:sub(1, dictdot - 1)
					text_id = text_id:sub(dictdot + 1)
					
					if (not dictkey) or (dictkey == "") or (not text_id) or (text_id == "") then
						console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] Missing key before/after dot\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
						err = true
						break
					else
						if not dict[dictkey] then dict[dictkey] = {} end
						dict = dict[dictkey]
					end
				end
				
				-- The %c[]m is replaced by \27[[]m
				-- The %j    is replaced by \8
				-- The %l    is replaced by \n
				-- The %r    is replaced by \27[00m
				text = text
					:gsub("%%c([^m]+m)", "\27[%1" )
					:gsub("%%j",         "\8"     )
					:gsub("%%l",         "\n"     )
					:gsub("%%r",         "\27[00m")
				
				if err then
				elseif not text_id or text_id == "" then
					console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] No translation key\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
				elseif dict[text_id] and (type(dict[text_id]) ~= "table") then
					console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] Translation key defined twice\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
				elseif text_id:sub(1, 1) == " " then
					console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] The text ID begins with a reserved character\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
				elseif text_id:find(":") then
					local columnpos = text_id:find(":")
					local group_name, text_id = text_id:sub(1, columnpos - 1), text_id:sub(columnpos + 1)
					
					if not group_name or group_name == "" then
						console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] No group name\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
					elseif not text_id or text_id == "" then
						console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] No group key for group " .. group_name .. "\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
					else
						if not dict[group_name] then dict[group_name] = {[" active"] = text, [" default"] = "key", [" defarg"] = text_id, [" actid"] = text_id} end
						if not self.__alt_dicts[group_name] then self.__alt_dicts[group_name] = dict[group_name] end
						dict = dict[group_name]
						
						if dict[text_id] then
							console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] Translation key defined twice (group " .. group_name .. ")\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
						else
							dict[text_id] = text
						end
					end
				elseif dict[text_id] then
					if dict[text_id][" default"] == "string" then
						console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] Default translation already defined\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
					else
						dict[text_id][" default"] = "string"
						dict[text_id][" defarg"] = text
					end
				else
					dict[text_id] = text
				end
			else
				console:print("[Loading file " .. lang_id .. ".lgd, line " .. linecount .. " for lang " .. lang_name .. "] Missing association with ID `" .. nwsline .. "'\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
			end
		end end
	end
end)

function Lang:addLevel(level_id)
	if self.__loadedLevels[level_id] then return end
	
	local file = io.open(import_prefix .. "lang/" .. level_id .. ".lld")
	if not file then return false end
	
	local linecount = 0
	for line in file:lines() do
		linecount = linecount + 1
		
		local nwsline = line:gsub("^%s+", ""):gsub("(%w[%w_%.%:]-)%s*= ?", "%1=", 1)
		if nwsline and nwsline ~= "" and not nwsline:find("^" .. comment) then
			if nwsline:find("=") then
				local text_lang, text_id, text = nwsline:gsub("%..*", "", 1), nwsline:gsub(".-%.", "", 1):gsub("=.*", "", 1), nwsline:gsub(".-=", "", 1)
				
				if text_lang == self.__lang_id then
					local err = false
					
					local dict = self.__dict
					for k, dictkey in pairs({"ig", "levels"}) do
						if not dict[dictkey] then dict[dictkey] = {} end
						dict = dict[dictkey]
					end
					while text_id:find("%.") do
						local dictdot = text_id:find("%.")
						local dictkey = text_id:sub(1, dictdot - 1)
						text_id = text_id:sub(dictdot + 1)
						
						if (not dictkey) or (dictkey == "") or (not text_id) or (text_id == "") then
							console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] Missing key before/after dot\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
							err = true
							break
						else
							if not dict[dictkey] then dict[dictkey] = {} end
							dict = dict[dictkey]
						end
					end
					for k, dictkey in pairs({level_id}) do
						if not dict[dictkey] then dict[dictkey] = {} end
						dict = dict[dictkey]
					end
					
					-- The %c[]m is replaced by \27[[]m
					-- The %j    is replaced by \8
					-- The %l    is replaced by \n
					-- The %r    is replaced by \27[00m
					text = text
						:gsub("%%c([^m]+m)", "\27[%1" )
						:gsub("%%j",         "\8"     )
						:gsub("%%l",         "\n"     )
						:gsub("%%r",         "\27[00m")
					
					if err then
					elseif not text_id or text_id == "" then
						console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] No translation key\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
					elseif dict[text_id] and (type(dict[text_id]) ~= "table") then
						console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] Translation key defined twice\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
					elseif text_id:sub(1, 1) == " " then
						console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] The text ID begins with a reserved character\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
					elseif text_id:find(":") then
						local columnpos = text_id:find(":")
						local group_name, text_id = text_id:sub(1, columnpos - 1), text_id:sub(columnpos + 1)
						
						if not group_name or group_name == "" then
							console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] No group name\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
						elseif not text_id or text_id == "" then
							console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] No group key for group " .. group_name .. "\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
						else
							if not dict[group_name] then dict[group_name] = {[" active"] = text, [" default"] = "key", [" defarg"] = text_id, [" actid"] = text_id} end
							if not self.__alt_dicts[group_name] then self.__alt_dicts[group_name] = dict[group_name] end
							dict = dict[group_name]
							
							if dict[text_id] then
								console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] Translation key defined twice (group " .. group_name .. ")\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
							else
								dict[text_id] = text
							end
						end
					elseif dict[text_id] then
						if dict[text_id][" default"] == "string" then
							console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] Default translation already defined\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
						else
							dict[text_id][" default"] = "string"
							dict[text_id][" defarg"] = text
						end
					else
						dict[text_id] = text
					end
				end
			else
				console:print("[Loading file " .. level_id .. ".lld, line " .. linecount .. " for lang " .. self.__lang_name .. "] Missing association with ID `" .. nwsline .. "'\n", LogLevel.WARNING, "dictionary.lua/Lang:(init):lang dictionary file parsing")
			end
		end
	end
	
	file:close()
	
	self.__loadedLevels[level_id] = true
	return true
end

function Lang:getName() return self.__lang_name end
function Lang:getID() return self.__lang_id end

function Lang:translate(state, str, origin, ...)
	if not origin then origin = self end
	
	local function pure()
		local dicts = {self.__dict}
		
		local max_pos = 1
		
		while state[max_pos] and (type(dicts[max_pos][state[max_pos]]) == "table") do
			dicts[max_pos + 1] = dicts[max_pos][state[max_pos]]
			max_pos = max_pos + 1
		end
		
		local pos
		
		for pos = max_pos, 1, -1 do
			if dicts[pos][str] then
				local value = dicts[pos][str]
				
				if type(value) == "string" then
					return value
				elseif (type(value) == "table") and value[" active"] then
					if value[" default"] == "nil" then
						-- Value was fallbacked
						self.__dict[str] = {[" active"] = self.__fallback:translate(state, str, origin), [" default"] = "nil"}
						return self.__dict[str][" active"]
					else
						return value[" active"]
					end
				end
			end
		end
		
		if self.__fallback then
			self.__dict[str] = {[" active"] = self.__fallback:translate(state, str, origin), [" default"] = "nil"}
			return self.__dict[str][" active"]
		else
			local strtmp = "" for k, v in pairs(state) do strtmp = strtmp .. v .. "." end
			self.__dict[str] = strtmp .. str
			return self.__dict[str]
		end
	end
	
	local newstr = pure()
	
	-- Insert other translations before parsing arguments?
	while newstr:find("%%I") do
		local text = newstr:sub(newstr:find("%%I") + 2)
		text = text:gsub("[	 ].*", "")
		
		if text == "" then
			console:print("Insertion value needed with %I", LogLevel.WARNING, "dictionary.lua/Lang:translate:(%I parsing)")
			newstr = newstr:gsub("%%I[ 	]?", "I", 1)
		elseif text:find(":") then
			console:print("Bad insertion value '" .. text .. "': alternatives are unsupported", LogLevel.WARNING, "dictionary.lua/Lang:translate:(%I parsing)")
			newstr = newstr:gsub("%%I(.-)[ 	]?", "%1", 1)
		else
			local spos, epos = newstr:find("%%I"), newstr:find("%%I") + text:len() + 2
			
			local states, stcount = {}, 0
			while text:find("%.") do
				states[stcount + 1], text = text:sub(1, text:find("%.") - 1), text:sub(text:find("%.") + 1)
				stcount = stcount + 1
			end
			
			local success, ret = pcall(origin.translate, origin, states, text, origin)
			
			if success then
				newstr = newstr:gsub("%%I[^	 ]+.", ret:gsub("%%", "%%%%"), 1)
			else
				local strtmp = "" for k, v in pairs(state) do strtmp = strtmp .. v .. "." end
				console:print("Error while translating '" .. newstr:sub(spos + 2, epos - 1) .. "' for string '" .. strtmp .. str .. "' (probably a stack overflow: infinite translation loop)\n", LogLevel.ERROR, "dictionary.lua/Lang:translate:(%I parsing)")
				console:print(ret, LogLevel.ERROR, "dictionary.lua/Lang:translate:(%I parsing)") console:printLore("\n")
				newstr = newstr:gsub("%%I[^	 ]+.", "Ie", 1)
			end
		end
	end
	
	local args, argp = {...}, 1
	local finstr = ""
	local st = newstr:find("%%")
	while st and (args[argp] ~= nil) do
		local typ = newstr:sub(st + 1, st + 1)
		finstr = finstr .. newstr:sub(1, st - 1)
		
		if typ == "s" then     -- The simple string
			finstr = finstr .. tostring(args[argp])
		elseif typ == "b" then -- on or off
			if args[argp] then
				finstr = finstr .. "on"
			else
				finstr = finstr .. "off"
			end
		elseif typ == "B" then -- On or Off
			if args[argp] then
				finstr = finstr .. "On"
			else
				finstr = finstr .. "Off"
			end
		elseif typ == "y" then -- yes or no
			if args[argp] then
				finstr = finstr .. "yes"
			else
				finstr = finstr .. "no"
			end
		elseif typ == "Y" then -- Yes or No
			if args[argp] then
				finstr = finstr .. "Yes"
			else
				finstr = finstr .. "No"
			end
		elseif typ == "n" then -- A number or ?
			if type(args[argp]) == "number" then
				finstr = finstr .. tostring(args[argp])
			elseif tonumber(args[argp]) then
				finstr = finstr .. tostring(tonumber(args[argp]))
			else
				finstr = finstr .. "?"
			end
		elseif typ == "%" then -- Escaped %
			finstr = finstr .. "%"
			argp = argp - 1
		else
			console:print("Unknown replacement type: " .. typ .. "\n", LogLevel.WARNING, "dictionary.lua/Lang:translate")
			finstr = finstr .. typ
		end
		
		newstr = newstr:sub(st + 2)
		argp = argp + 1
		
		st = newstr:find("%%")
	end
	
	finstr = finstr .. newstr
	return finstr
end

function Lang:resetAlternative(alt)
	local function resetAlt(tbl)
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				if v[" default"] then
					if v[" default"] == "key" then
						v[" active"] = v[v[" defarg"]]
					elseif v[" default"] == "string" then
						v[" active"] = v[" defarg"]
					elseif v[" default"] == "nil" then
						tbl[k] = nil
					else
						console:print("Unknown default type: " .. v[" default"] .. "\n", LogLevel.WARNING_DEV, "dictionary.lua/Lang:resetAlternative:resetTable")
					end
				else
					resetAlt(v)
				end
			end
		end
	end
	
	local function resetNils(tbl)
		for k, v in pairs(tbl) do
			if type(v) == "table" then
				if v[" default"] == "nil" then
					tbl[k] = nil
				else
					resetNils(v)
				end
			end
		end
	end
	
	if alt and self.__alt_dicts[alt] then
		console:print("Warning: resetting a single alternative (" .. tostring(alt) .. ") may be unstable\n", LogLevel.LOG, "dictionary.lua/Lang:resetAlternative")
		resetAlt(self.__alt_dicts[alt])
	elseif alt == " nil" then
		resetNils(self.__dict)
	elseif alt and self.__dict[alt] then
		resetAlt(self.__dict[alt])
	else
		resetAlt(self.__dict)
	end
end

function Lang:getAlternative(state, str)
	local statestr = "" for k, v in pairs(state) do statestr = statestr .. v .. "." end
	
	self:resetAlternative(" nil")
	
	if not self.__alt_dicts[str] then
		if self.__fallback then return self.__fallback:getAlternative(state, str)
		else return false end
	end
	
	local dicts = {self.__dict}
	
	local max_pos = 1
	
	while state[max_pos] and (type(dicts[max_pos][state[max_pos]]) == "table") do
		dicts[max_pos + 1] = dicts[max_pos][state[max_pos]]
		max_pos = max_pos + 1
	end
	
	local pos
	
	for pos = max_pos, 1, -1 do
		if dicts[pos][str] then
			if type(dicts[pos][str]) == "table" then
				return dicts[pos][str][" actid"]
			else
				console:print("Trying to get alternative while being a string (" .. statestr .. str .. ")\n", LogLevel.WARNING_DEV, "dictionary.lua/Lang:getAlternative")
				return " "
			end
		end
	end
	
	if self.__fallback then
		return self.__fallback:getAlternative(state, str)
	else
		return " "
	end
end

function Lang:setAlternative(state, str, newUnlocalized)
	local statestr = "" for k, v in pairs(state) do statestr = statestr .. v .. "." end
	
	self:resetAlternative(" nil")
	
	if not self.__alt_dicts[str] then
		if self.__fallback then return self.__fallback:setAlternative(state, str, newUnlocalized)
		else return false end
	end
	
	local dicts = {self.__dict}
	
	local max_pos = 1
	
	while state[max_pos] and (type(dicts[max_pos][state[max_pos]]) == "table") do
		dicts[max_pos + 1] = dicts[max_pos][state[max_pos]]
		max_pos = max_pos + 1
	end
	
	local pos
	
	for pos = max_pos, 1, -1 do
		if dicts[pos][str] then
			if type(dicts[pos][str]) == "table" then
				if dicts[pos][str][newUnlocalized] then
					dicts[pos][str][" active"] = dicts[pos][str][newUnlocalized]
					dicts[pos][str][" actid"] = newUnlocalized
					
					return true
				else
					console:print("Trying to set alternative while not having the alternative (" .. self.__lang_id .. "/" .. statestr .. str .. ":" .. newUnlocalized .. ")\n", LogLevel.INFO, "dictionary.lua/Lang:setAlternative")
					return 0
				end
			else
				console:print("Trying to set alternative while being a string (" .. statestr .. str .. ")\n", LogLevel.WARNING_DEV, "dictionary.lua/Lang:setAlternative")
			end
		end
	end
	
	if self.__fallback then
		return self.__fallback:setAlternative(state, str, newUnlocalized)
	else
		return false
	end
end

-- langs - the registered langs
local langs = {
	{id = "en_US", name = "English ('Merica)", fallback = false},
	{id = "en_GB", name = "Serious english (Great Britain)"}
}

--[[ Dictionary - the dictionary class [singleton]
	Holds all registered langs and the active lang UID
]]
local Dictionary = class(function(self)
	self.__active_id = 1
	self.__active_lang = langs[self.__active_id].id
	
	self.__langs = {}
	for k, lang in pairs(langs) do
		if not self.__langs[lang.id] then self.__langs[lang.id] = Lang(lang.name, lang.id, lang.fallback) end
	end
end)

--[[
	getActiveLangIdx - get the active lang index
	getNextLangID    - get the next   lang index
	getActiveLangName - get the active lange name
]]
function Dictionary:_setActiveLang(lang)    self.__active_lang = lang end
function Dictionary:_getActiveLang() return self.__active_lang end
function Dictionary:_setLangIdx(id)      self.__active_id = id self:_setActiveLang(langs[id].id) end
function Dictionary:getActiveLangIdx() return self.__active_id end
function Dictionary:getNextLangIdx() return langs[self:getActiveLangIdx() + 1] and self:getActiveLangIdx() + 1 or 1 end
function Dictionary:getActiveLangName() return self.__langs[self:_getActiveLang()]:getName() end

-- translate - translates the string str in state state, using the active lang
function Dictionary:translate(state, str, ...) return self.__langs[self:_getActiveLang()]:translate(state, str, nil, ...) end

-- resetAlternatives - reset every alternatives in every langs
function Dictionary:resetAlternatives(alt)
	for k, lang in pairs(self.__langs) do
		lang:resetAlternative(alt)
	end
end

-- getAlternative - get the alternative for the string str in state state
function Dictionary:getAlternative(state, str)
	local ret
	
	ret = self.__langs[self:_getActiveLang()]:getAlternative(state, str)
	for k, lang in pairs(self.__langs) do
		if k ~= self:_getActiveLang() then lang:getAlternative(state, str) end
	end
	
	return ret
end

-- setAlternative - set the alternative for the string str in state state to newUnlocalized
function Dictionary:setAlternative(state, str, newUnlocalized)
	local ret
	
	ret = self.__langs[self:_getActiveLang()]:setAlternative(state, str, newUnlocalized)
	for k, lang in pairs(self.__langs) do
		if k ~= self:_getActiveLang() then lang:setAlternative(state, str, newUnlocalized) end
	end
	
	return ret
end

function Dictionary:addLevel(level_id)
	for lang_id, lang in pairs(self.__langs) do
		lang:addLevel(level_id)
	end
end

-- dictionary - the dictionary singleton
dictionary = Dictionary()

--[[
	The langs post-init, used to validate/invalidate the fallbacks
]]
for lang_id, lang in pairs(id2lang) do
	if lang.__fallback then
		if not id2lang[lang.__fallback] then console:print("No lang fallback for lang " .. lang:getName() .. " (" .. lang:getID() .. "), should have been " .. lang.__fallback .. "\n", LogLevel.WARNING, "dictionary.lua/Lang:(post init)") lang.__fallback = false
		else lang.__fallback = id2lang[lang.__fallback] end
	end
end

-- missing config, add helper function
function dictionary:addListenerToConfig(cfg)
	dictionary.addListenerToConfig = nil
	
	local function addCallback(cb, c)
		c:addListener(dictionary, cb)
		cb(dictionary, c)
	end
	
	addCallback(function(self, cfg)
		self:setAlternative({"mm"}, "eqc", cfg:getEQCAlts()[cfg:getEQCAlt()])
		self:_setLangIdx(cfg:getLangIdx())
	end, cfg:getOptions())
	addCallback(function(self, cfg)
		self:setAlternative({"options", "difficulty"}, "value", tostring(cfg:getDifficulty()))
	end, cfg:getLevelManagerConfig():getLevelConfig())
end
if configmodule then
	-- config has been successfully loaded, use helper function immediately
	dictionary:addListenerToConfig(currentConfig)
end
