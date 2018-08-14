local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local consolemodule = require(import_prefix .. "console")
local classmodule = require(import_prefix .. "class")

local comment = {str = "#", len = 1}

id2lang = {}
local Lang = class(function(self, lang_name, lang_id, fallback_id)
	if id2lang[lang_id] then
		console:print("Lang already defined: " .. lang_id .. "\n", LogLevel.ERROR, "dictionary.lua/Lang:(init)")
		for k, v in pairs(id2lang) do self[k] = v end
		return
	else
		id2lang[lang_id] = self
	end
	
	self.__lang_id = lang_id
	self.__lang_name = lang_name
	
	if fallback_id ~= nil then fallback_id = "en_US" end
	if lang_id ~= fallback_id then self.__fallback = fallback_id
	else                           self.__fallback = false       end
	
	self.__dict = {}
	self.__alt_dicts = {}
	local linecount = 0
	for line in io.lines(import_prefix .. "lang/" .. lang_id .. ".lgd") do
		linecount = linecount + 1
		
		-- File parsing: one line = one instruction, except when empty
		nwsline = line:gsub("^%s+", ""):gsub("(%g[%w_%.%:]-)%s*= ?", "%1=", 1)
		if nwsline and nwsline ~= "" and nwsline:sub(1, comment.len) ~= comment.str then
			if nwsline:find("=") then
				-- Line is an ID -> text instruction
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
					else
						if not dict[dictkey] then dict[dictkey] = {} end
						dict = dict[dictkey]
					end
				end
				
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
		end
	end
end)

function Lang:getName() return self.__lang_name end
function Lang:getID() return self.__lang_id end

function Lang:translate(state, str, ...)
	local function pure()
		local dicts = {self.__dict}
		
		local max_pos = 1
		
		while state[max_pos] do
			if type(dicts[max_pos][state[max_pos]]) == "table" then
				dicts[max_pos + 1] = dicts[max_pos][state[max_pos]]
				max_pos = max_pos + 1
			else
				break
			end
		end
		
		local pos
		
		for pos = max_pos, 1, -1 do
			if dicts[pos][str] then
				local value = dicts[pos][str]
				
				if type(value) == "string" then
					return value
				elseif (type(value) == "table") and value[" active"] then
					return value[" active"]
				elseif (type(value) == "table") then
				end
			end
		end
		
		if self.__fallback then
			self.__dict[str] = self.__fallback:translate(state, str)
		else
			local strtmp = "" for k, v in pairs(state) do strtmp = strtmp .. v .. "." end
			self.__dict[str] = strtmp .. str .. "\n"
		end
		return self.__dict[str]
	end
	
	local str = pure()
	
	local args, argp = {...}, 1
	while str:find("%%[^%%]") and args[argp] do
		local typ = str:gsub(".-%%([^%%]).*", "%1")
		
		if typ == "s" then                                      -- The pure string
			str = str:gsub("%%s", args[argp], 1)
		elseif typ == "b" then                                  -- on or off
			if args[argp] then
				str = str:gsub("%%b", "on", 1)
			else
				str = str:gsub("%%b", "off", 1)
			end
		elseif typ == "B" then                                  -- On or Off
			if args[argp] then
				str = str:gsub("%%b", "On", 1)
			else
				str = str:gsub("%%b", "Off", 1)
			end
		elseif typ == "y" then                                  -- yes or no
			if args[argp] then
				str = str:gsub("%%y", "yes", 1)
			else
				str = str:gsub("%%y", "no", 1)
			end
		elseif typ == "Y" then                                  -- Yes or No
			if args[argp] then
				str = str:gsub("%%y", "Yes", 1)
			else
				str = str:gsub("%%y", "No", 1)
			end
		elseif typ == "n" then                                  -- A number or ?
			if type(args[argp]) == "number" then
				str = str:gsub("%%n", tostring(args[argp]), 1)
			elseif tonumber(args[argp]) then
				str = str:gsub("%%n", args[argp], 1)
			else
				str = str:gsub("%%n", "?", 1)
			end
		else
			console:print("Unknown replacement type: " .. typ .. "\n", LogLevel.WARNING, "dictionary.lua/Lang:translate")
			str = str:gsub("%%(.)", "%1", 1)
		end
		
		argp = argp + 1
	end
	
	str = str:gsub("%%%%", "%%")
	return str
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
						v[" active"] = nil
					else
						console:print("Unknown default type: " .. v[" default"] .. "\n", LogLevel.WARNING_DEV, "dictionary.lua/Lang:resetAlternative:resetTable")
					end
				else
					resetAlt(v)
				end
			end
		end
	end
	
	if alt and self.__alt_dicts[alt] then
		console:print("Warning: resetting a single alternative (" .. tostring(alt) .. ") may be unstable\n", LogLevel.LOG, "dictionary.lua/Lang:resetAlternative")
		resetAlt(self.__alt_dicts[alt])
	else
		resetAlt(self.__dict)
	end
end

function Lang:setAlternative(state, str, newUnlocalized)
	local statestr = "" for k, v in pairs(state) do statestr = statestr .. v .. "." end
	
	if not self.__alt_dicts[str] then
		if self.__fallback then return self.__fallback:setAlternative(state, str, newUnlocalized)
		else return false end
	end
	
	--if self.__alt_dicts[str][" actid"] == newUnlocalized then
	--	return true
	--elseif self.__alt_dicts[str][newUnlocalized] then
	--	self.__alt_dicts[str][" active"] = self.__alt_dicts[str][newUnlocalized]
	--	self.__alt_dicts[str][" actid"] = newUnlocalized
	--end
	
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

local langs = {{id = "en_US", name = "English (America)"}, {id = "en_GB", name = "Serious english (Great Britain)"}}
local Dictionary = class(function(self)
	self.__active_lang = langs[1].id
	
	self.__langs = {}
	for k, lang in pairs(langs) do
		if not self.__langs[lang_id] then self.__langs[lang.id] = Lang(lang.name, lang.id, lang,fallback) end
	end
end)

function Dictionary:setActiveLang(lang)    self.__active_lang = lang end
function Dictionary:getActiveLang() return self.__active_lang end

function Dictionary:translate(state, str, ...) return self.__langs[self.__active_lang]:translate(state, str, ...) end

function Dictionary:resetAlternatives()
	for k, lang in pairs(self.__langs) do
		lang:resetAlternative()
	end
end

function Dictionary:setAlternative(state, str, newUnlocalized)
	local ret
	
	ret = self.__langs[self.__active_lang]:setAlternative(state, str, newUnlocalized)
	for k, lang in pairs(self.__langs) do
		if k ~= self.__active_lang then lang:setAlternative(state, str, newUnlocalized) end
	end
	
	return ret
end

dictionary = Dictionary()

for lang_id, lang in pairs(id2lang) do
	if lang.__fallback then
		if not id2lang[lang.__fallback] then console:print("No lang fallback for lang " .. lang:getName() .. " (" .. lang:getID() .. "), should have been " .. lang.__fallback .. "\n", LogLevel.WARNING, "dictionary.lua/Lang:(post init)") lang.__fallback = false
		else lang.__fallback = id2lang[lang.__fallback] end
	end
end
