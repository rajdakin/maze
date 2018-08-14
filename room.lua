local args = {...}
import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local dictionarymodule = require(import_prefix .. "dictionary")
local consolemodule = require(import_prefix .. "console")
local eventsmodule = require(import_prefix .. "events")
local classmodule = require(import_prefix .. "class")
local statemodule = require(import_prefix .. "state")

Room = class(function(self, room_datas)
	self.__datas = room_datas
end)

function Room:getAttribute(attributeName) return self.__datas[attributeName]         end
function Room:setAttribute(attributeName, value) self.__datas[attributeName] = value end

local list_data = {"exit", "up", "down", "left", "right", "monster", "sword", "key", "door", "trap", "redkey", "reddoor", "grave", "graveyard"}
local list_data_unreachable = {"saw"}
function Room:setUnreachable()
	local unreachable = true
	for k, v in pairs(list_data) do
		if self:getAttribute(v) then unreachable = false end
	end
	self:setAttribute("unreachable", unreachable)
	
	return true
end

function Room:initialize()
	for k, v in pairs(list_data) do
		if not self:getAttribute(v) then self:setAttribute(v, false) end
	end
	for k, v in pairs(list_data_unreachable) do
		if not self:getAttribute(v) then self:setAttribute(v, false) end
	end
	
	return true
end

function Room:canHear(event, position_in_row, up, down, left, right)
	return (up and up:getAttribute(event)) or (down and down:getAttribute(event))
	 or ((position_in_row ~= 1) and left and left:getAttribute(event))
	 or ((position_in_row ~= 0) and right and right:getAttribute(event))
end

function Room:unheared(event, position_in_row, up, down, left, right)
	return (up and up:getAttribute(event) and not up:getAttribute("saw")) or (down and down:getAttribute(event) and not down:getAttribute("saw"))
	 or ((position_in_row ~= 1) and left and left:getAttribute(event) and not left:getAttribute("saw"))
	 or ((position_in_row ~= 0) and right and right:getAttribute(event) and not right:getAttribute("saw"))
end

function Room:hasAccess(direction)
	return (self:getAttribute(direction)
	 or  (not self:getAttribute("door") and self:getAttribute("door_dir") == direction)
	 or  (not self:getAttribute("reddoor") and self:getAttribute("reddoor_dir") == direction)
	 or  (self:getAttribute("exitdir") == direction))
	 and (self:getAttribute("exit_dir") ~= direction)
end

function Room:canSee(event, position_in_row, up, down, left, right)
	return (self:hasAccess("up") and self:canHear(event, position_in_row, up))
	 or (self:hasAccess("down") and self:canHear(event, position_in_row, nil, down))
	 or (self:hasAccess("left") and self:canHear(event, position_in_row, nil, nil, left))
	 or (self:hasAccess("right") and self:canHear(event, position_in_row, nil, nil, nil, right))
end

function Room:unseen(event, position_in_row, up, down, left, right)
	return (self:hasAccess("up") and self:canHear(event, position_in_row, up) and not up:getAttribute("saw"))
	 or (self:hasAccess("down") and self:canHear(event, position_in_row, nil, down) and not down:getAttribute("saw"))
	 or (self:hasAccess("left") and self:canHear(event, position_in_row, nil, nil, left) and not left:getAttribute("saw"))
	 or (self:hasAccess("right") and self:canHear(event, position_in_row, nil, nil, nil, right) and not right:getAttribute("saw"))
end

local doorBGcolor = {["door"] = "44", ["reddoor"] = "41", ["grave"] = "45", ["opengrave"] = "0"}
function Room:printDoor(dir, doorType)
	if self:getAttribute(dir) then
		console:printLore(" ")
	elseif self:getAttribute("exitdir") == dir then
		console:printLore("\27[01;33;" .. doorBGcolor["opengrave"] .. "m ")
	elseif (self:getAttribute("grave") and (dir == "right")) or (self:getAttribute("graveyard") and (dir == "left")) then
		console:printLore("\27[01;33;" .. doorBGcolor["grave"] .. "m ")
	elseif (self:getAttribute(doorType) and (self:getAttribute(doorType .. "_dir") == dir)) then
		if self:getAttribute("exit") and (self:getAttribute("exit_dir") == dir) then
			console:printLore("\27[01;33;" .. doorBGcolor[doorType] .. "mE")
		else
			console:printLore("\27[01;33;" .. doorBGcolor[doorType] .. "m ")
		end
	elseif (not self:getAttribute(doorType)) and (self:getAttribute(doorType .. "_dir") == dir) then
		console:printLore("\27[42m ")
	else
		console:printLore("\27[01;30;41;07m ")
	end
	console:printLore("\27[00m")
end

function Room:printRoom(objects, isActiveRoom)
	console:printLore("\27[s")
	if not self:getAttribute("saw") then
		console:printLore("\27[C\27[s\27[B\27[01;30;47;07m?? \27[u\27[2B\27[01;30;47;07m?? \27[u\27[3B\27[01;30;47;07m   \27[u\27[2C\27[00m")
	else
		console:printLore("\27[01;30;41;07m \27[u\27[B")                   -- / Column one
		self:printDoor("left", "door")                                     -- |
		console:printLore("\27[u\27[2B")                                   -- |
		self:printDoor("left", "reddoor")                                  -- |
		console:printLore("\27[u\27[3B\27[01;30;41;07m \27[u\27[C\27[s")   -- -
		self:printDoor("up", "door")                                       -- / Column two
		self:printDoor("up", "reddoor")                                    -- + Column three
		console:printLore("\27[u\27[B")                                    -- |
		if self:getAttribute("unreachable") then                           -- |
			console:printLore("\27[01;30;41;07mUU\27[2D\27[BUU")           -- |
		else                                                               -- |
			local pre = ""                                                 -- |
			if isActiveRoom then                                           -- |
				pre = "\27[43m"                                            -- |
			end                                                            -- |
			if self:getAttribute("key") then                               -- |
				console:printLore(pre .. "K")                              -- |
			elseif self:getAttribute("near_key") then                      -- |
				console:printLore(pre .. "\27[02mK\27[22m")                -- |
			else                                                           -- |
				console:printLore(pre .. " ")                              -- |
			end                                                            -- |
			if self:getAttribute("redkey") then                            -- |
				console:printLore(pre .. "k")                              -- |
			elseif self:getAttribute("near_redkey") then                   -- |
				console:printLore(pre .. "\27[02mk\27[22m")                -- |
			else                                                           -- |
				console:printLore(pre .. " ")                              -- |
			end                                                            -- |
			console:printLore(pre .. "\27[2D\27[B")                        -- |
			if self:getAttribute("sword") then                             -- |
				console:printLore(pre .. "S")                              -- |
			elseif self:getAttribute("near_sword") then                    -- |
				console:printLore(pre .. "\27[02mS\27[22m")                -- |
			else                                                           -- |
				console:printLore(pre .. " ")                              -- |
			end                                                            -- |
			if self:getAttribute("trap") then                              -- |
				console:printLore(pre .. "T")                              -- |
			elseif self:getAttribute("monster") then                       -- |
				console:printLore(pre .. "M")                              -- |
			elseif self:getAttribute("near_monster") then                  -- |
				console:printLore(pre .. "\27[02mM\27[22m")                -- |
			else                                                           -- |
				console:printLore(pre .. " ")                              -- |
			end                                                            -- |
		end                                                                -- |
		console:printLore("\27[00m\27[2D\27[B")                            -- |
		self:printDoor("down", "door")                                     -- |
		self:printDoor("down", "reddoor")                                  -- -
		console:printLore("\27[u\27[2C\27[s\27[01;30;41;07m \27[u\27[B")   -- / Column four
		self:printDoor("right", "door")                                    -- |
		console:printLore("\27[u\27[2B")                                   -- |
		self:printDoor("right", "reddoor")                                 -- |
		console:printLore("\27[u\27[3B\27[01;30;41;07m \27[u\27[00m")      -- -
	end
	return RoomPrintingDone()
end

function Room:refreshRoomNearEvents(position_in_row, up, down, left, right)
	if self:unseen("key", position_in_row, up, down, left, right) then
		self:setAttribute("near_key", true)
	else
		self:setAttribute("near_key", false)
	end
	if self:unseen("redkey", position_in_row, up, down, left, right) then
		self:setAttribute("near_redkey", true)
	else
		self:setAttribute("near_redkey", false)
	end
	if self:unseen("sword", position_in_row, up, down, left, right) then
		self:setAttribute("near_sword", true)
	else
		self:setAttribute("near_sword", false)
	end
	if self:unheared("monster", position_in_row, up, down, left, right) then
		self:setAttribute("near_monster", true)
	else
		self:setAttribute("near_monster", false)
	end
	if self:unseen("exit", position_in_row, up, down, left, right) then
		self:setAttribute("near_exit", "visible")
	elseif self:unheared("exit", position_in_row, up, down, left, right) then
		self:setAttribute("near_exit", "hearable")
	elseif self:canHear("exit", position_in_row, up, down, left, right) then
		self:setAttribute("near_exit", "near")
	else
		self:setAttribute("near_exit", "far")
	end
end

function Room:checkRoomEvents(is_ended, objects, room_position_in_row, up, down, left, right, moved_from_elsewhere, difficulty)
	self:setAttribute("saw", true)
	
	local function createEvents()
		self:refreshRoomNearEvents(room_position_in_row, up, down, left, right)
		
		if moved_from_elsewhere then
			stateManager:pushState("moving")
			
			if self:getAttribute("grave") then
				stateManager:pushState("grave")
				
				if self:getAttribute("deadlygrave") then
					stateManager:pushState("deadly")
					
					local key = self:getAttribute("keyneeded")
					stateManager:pushState(key)
					
					if self:getAttribute(key) then
						console:printLore(
							dictionary:translate(stateManager:getStatesStack(), "dynamic")
						)
						
						self:setAttribute("deadlygrave", false)
						
						up:setAttribute("near_" .. key, false)
						down:setAttribute("near_" .. key, false)
						left:setAttribute("near_" .. key, false)
						right:setAttribute("near_" .. key, false)
						
						up:setAttribute("__n" .. key, false)
						down:setAttribute("__n" .. key, false)
						left:setAttribute("__n" .. key, false)
						right:setAttribute("__n" .. key, false)
						
						self:setAttribute(key, false)
					elseif objects:has(key) then
						console:printLore(
							dictionary:translate(stateManager:getStatesStack(), "inventory")
						)
						
						self:setAttribute("deadlygrave", false)
						
						if self:getAttribute("exitdir") == "up" then
							up:setAttribute("down", true)
						elseif self:getAttribute("exitdir") == "down" then
							down:setAttribute("up", true)
						elseif self:getAttribute("exitdir") == "left" then
							left:setAttribute("right", true)
						elseif self:getAttribute("exitdir") == "right" then
							right:setAttribute("left", true)
						else
							console:print("Unknown grave's exit directon (opening the other size): " .. self:getAttribute("exitdir"), LogLevel.WARNING_DEV, "room.lua/Room:checkRoomEvents:createEvents")
						end
						
						objects:setObject(key, false)
					elseif (key == "key") or (key == "redkey") then
						console:printLore(
							dictionary:translate(stateManager:getStatesStack(), "locked")
						)
						
						return EventParsingResultExited(true, objects)
					else
						console:printLore(
							dictionary:translate(stateManager:getStatesStack(), "unknown",
								key)
						)
					end
					
					stateManager:popState()
					stateManager:popState()
				else
					console:printLore(
						dictionary(stateManager:getStatesStack(), "normal")
					)
				end
				
				self:setAttribute("grave", false)
				
				stateManager:popState()
			end
			
			stateManager:popState()
		end
		
		if self:getAttribute("monster") then
			stateManager:pushState("monster")
			
			up:setAttribute("near_monster", false)
			down:setAttribute("near_monster", false)
			left:setAttribute("near_monster", false)
			right:setAttribute("near_monster", false)
			
			up:setAttribute("__nmonster", false)
			down:setAttribute("__nmonster", false)
			left:setAttribute("__nmonster", false)
			right:setAttribute("__nmonster", false)
			
			if objects:has("sword") then
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "sword")
				)
				
				objects:setObject("sword", false)
				self:setAttribute("monster", false)
				stateManager:popState()
			else
				if self:getAttribute("sword") then
					stateManager:pushState("room_sword")
					
					up:setAttribute("near_sword", false)
					down:setAttribute("near_sword", false)
					left:setAttribute("near_sword", false)
					right:setAttribute("near_sword", false)
					
					up:setAttribute("__nsword", false)
					down:setAttribute("__nsword", false)
					left:setAttribute("__nsword", false)
					right:setAttribute("__nsword", false)
					
					local canReachSword = falseCoin(85)
					
					if canReachSword then
						stateManager:pushState("reach")
						
						console:printLore(
							dictionary.translate(stateManager:getStatesStack(), "lore") .. dictionary.translate(stateManager:getStatesStack(), "confirm")
						)
						
						local watch, time = Watch(), 0
						
						local returned = console:read()
						time = watch.stop()
						
						local success, eos, answer = returned.success, returned.eos, returned.returned
						if not success then
							return EventParsingResultEnded(-1)
						elseif not answer then
							return EventParsingResultEnded(0)
						elseif (answer == "Y") or (answer == "y") then
							if time < 4 then
								console:printLore(
									dictionary:translate(stateManager:getStatesStack(), "grabbed")
								)
								
								self:setAttribute("sword", false)
								self:setAttribute("monster", false)
							else
								console:printLore(
									dictionary:translate(stateManager:getStatesStack(), "timeout")
								)
								
								return EventParsingResultExited(true, objects)
							end
						else
							console:printLore(
								dictionary:translate(stateManager:getStatesStack(), "cancel")
							)
							
							return EventParsingResultExited(true, objects)
						end
						
						stateManager:popState()
					else
						local eventid, event = random(4), "fail"
						if eventid == 1 then
							event = "rock"
						elseif eventid == 2 then
							event = "side_stitch"
						elseif eventid == 3 then
							event = "frozen"
						elseif eventid == 4 then
							event = "slow"
						end
						dictionary:setAlternative(stateManager:getStatesStack(), "fail", event)
						
						console:printLore(
							dictionary:translate(stateManager:getStatesStack(), "fail")
						)
						
						dictionary:setAlternative(stateManager:getStatesStack(), "fail", "fail")
						
						return EventParsingResultExited(true, objects)
					end
					
					stateManager:popState()
				else
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "no_sword")
					)
					
					return EventParsingResultExited(true, objects)
				end
			end
			
			stateManager:popState()
		end
		if self:getAttribute("trap") then
			stateManager:pushState("trap")
			
			if self:getAttribute("trap_type") then
				local tt = self:getAttribute("trap_type")
				
				if tt == "fall" then
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "fall")
					)
					
					return EventParsingResultRoomChanging(self:getAttribute("trap_arg"))
				elseif tt == "kill" then
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "kill")
					)
					
					return EventParsingResultExited(true, objects)
				else
					console:print("Unknown trap type " .. tostring(tt) .. "\n", LogLevel.ERROR "room.lua/Room:checkRoomEvents:(trap)")
					
					return EventParsingResultExited(true, objects)
				end
			else
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "kill")
				)
				
				return EventParsingResultExited(true, objects)
			end
			
			stateManager:popState()
		end
		
		local function checkKeyDoor(prefix)
			local exit_pushed = false
			if self:getAttribute("exit") and (self:getAttribute("exit_dir") == self:getAttribute(prefix .. "door_dir")) then
				stateManager:pushState("exit")
				exit_pushed = true
			end
			
			stateManager:pushState(prefix .. "group")
			
			if self:getAttribute(prefix .. "door") and (self:getAttribute(prefix .. "key") or objects:has(prefix .. "key")) then
				stateManager:pushState("kd")
				
				local dynamic = self:getAttribute(prefix .. "key")
				if dynamic then
					stateManager:pushState("dynamic")
				else
					stateManager:pushState("inventory")
				end
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "openable",
						dictionary:translate(stateManager:getStatesStack(), tostring(self:getAttribute(prefix .. "door_dir")))
					) .. dictionary:translate(stateManager:getStatesStack(), "confirm")
				)
				
				local returned = console:read()
				local success, eos, answer = returned.success, returned.eos, returned.returned
				if not success then
					return EventParsingResultEnded(-1)
				elseif not answer then
					return EventParsingResultEnded(0)
				elseif (answer == "Y") or (answer == "y") then
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "open",
							dictionary:translate(stateManager:getStatesStack(), tostring(self:getAttribute(prefix .. "door_dir"))))
					)
					
					self:setAttribute(prefix .. "door", false)
					
					if self:getAttribute(prefix .. "door_dir") == "up" then
						up:setAttribute(prefix .. "door", false)
						up:setAttribute(prefix .. "door_dir", "down")
					elseif self:getAttribute(prefix .. "door_dir") == "down" then
						down:setAttribute(prefix .. "door", false)
						down:setAttribute(prefix .. "door_dir", "up")
					elseif self:getAttribute(prefix .. "door_dir") == "left" then
						left:setAttribute(prefix .. "door", false)
						left:setAttribute(prefix .. "door_dir", "right")
					elseif self:getAttribute(prefix .. "door_dir") == "right" then
						right:setAttribute(prefix .. "door", false)
						right:setAttribute(prefix .. "door_dir", "left")
					else
						console:print("Unknown door dir (opening the other size): " .. self:getAttribute(prefix .. "door_dir"), LogLevel.WARNING_DEV, "room.lua/Room:checkRoomEvents:createEvents:checkKeyDoor")
					end
					
					if self:getAttribute(prefix .. "key") then
						self:setAttribute(prefix .. "key", false)
						up:setAttribute("near_" .. prefix .. "key", false)
						down:setAttribute("near_" .. prefix .. "key", false)
						left:setAttribute("near_" .. prefix .. "key", false)
						right:setAttribute("near_" .. prefix .. "key", false)
						
						up:setAttribute("__n" .. prefix .. "key", false)
						down:setAttribute("__n" .. prefix .. "key", false)
						left:setAttribute("__n" .. prefix .. "key", false)
						right:setAttribute("__n" .. prefix .. "key", false)
					else
						objects:setObject(prefix .. "key", false)
					end
				else
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "keepclose")
					)
				end
				
				stateManager:popState()
				stateManager:popState()
			elseif self:getAttribute(prefix .. "door") then
				stateManager:pushState("door")
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "locked",
						dictionary:translate(stateManager:getStatesStack(), tostring(self:getAttribute(prefix .. "door_dir"))))
				)
				
				stateManager:popState()
			end
			
			if self:getAttribute(prefix .. "key") then
				stateManager:pushState("key")
				
				up:setAttribute("near_" .. prefix .. "key", false)
				down:setAttribute("near_" .. prefix .. "key", false)
				left:setAttribute("near_" .. prefix .. "key", false)
				right:setAttribute("near_" .. prefix .. "key", false)
				
				up:setAttribute("__n" .. prefix .. "key", false)
				down:setAttribute("__n" .. prefix .. "key", false)
				left:setAttribute("__n" .. prefix .. "key", false)
				right:setAttribute("__n" .. prefix .. "key", false)
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "lore",
						dictionary:translate(stateManager:getStatesStack(), prefix .. "key")
					) .. dictionary:translate(stateManager:getStatesStack(), "confirm")
				)
				
				local returned = console:read()
				local success, eos, answer = returned.success, returned.eos, returned.returned
				if not success then
					return EventParsingResultEnded(-1)
				elseif not answer then
					return EventParsingResultEnded(0)
				elseif (answer == "Y") or (answer == "y") then
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "take")
					)
					
					local hasKey = objects:has(prefix .. "key")
					if difficulty == 4 then
						self:setAttribute(prefix .. "key", false)
						
						objects:setObject(prefix .. "key", not hasKey, difficulty)
					elseif difficulty == 3 then
						self:setAttribute(prefix .. "key", false)
						
						if hasKey then
							dictionary:setAlternative(stateManager:getStatesStack(), "take", "false")
						else
							objects:setObject(prefix .. "key", true, difficulty)
						end
					else
						if hasKey then
							dictionary:setAlternative(stateManager:getStatesStack(), "take", "false")
						else
							self:setAttribute(prefix .. "key", false)
							
							objects:setObject(prefix .. "key", true, difficulty)
						end
					end
				else
					console:printLore(
						dictionary:translate(stateManager:getStatesStack(), "leave")
					)
				end
				
				stateManager:popState()
			end
			
			stateManager:popState()
			
			if exit_pushed then
				stateManager:popState()
			end
		end
		
		if self:getAttribute("exit") then
			up:setAttribute("near_exit", false)
			down:setAttribute("near_exit", false)
			left:setAttribute("near_exit", false)
			right:setAttribute("near_exit", false)
			
			up:setAttribute("__nexit", false)
			down:setAttribute("__nexit", false)
			left:setAttribute("__nexit", false)
			right:setAttribute("__nexit", false)
			
			if (self:getAttribute("door_dir") ~= self:getAttribute("exit_dir") or not self:getAttribute("door"))
			 and (self:getAttribute("reddoor_dir") ~= self:getAttribute("exit_dir") or not self:getAttribute("reddoor")) then
				dictionary:setAlternative(stateManager:getStatesStack(), "exit", "open")
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "exit")
				)
				
				return EventParsingResultExited(false, objects)
			end
		end
		
		stateManager:pushState("keydoors")
		local chkFcnRet
		chkFcnRet = checkKeyDoor("") if chkFcnRet then return chkFcnRet end
		chkFcnRet = checkKeyDoor("red") if chkFcnRet then return chkFcnRet end
		stateManager:popState()
		
		if self:getAttribute("exit")
		 and (self:getAttribute("door_dir") ~= self:getAttribute("exit_dir") or not self:getAttribute("door"))
		 and (self:getAttribute("reddoor_dir") ~= self:getAttribute("exit_dir") or not self:getAttribute("reddoor")) then
			if self:getAttribute("exit")
			 and (self:getAttribute("door_dir") ~= self:getAttribute("exit_dir"))
			 and (self:getAttribute("reddoor_dir") ~= self:getAttribute("exit_dir")) then
				dictionary:setAlternative(stateManager:getStatesStack(), "exit", "opened")
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "exit")
				)
			end
			
			return EventParsingResultExited(false, objects)
		end
		
		if self:getAttribute("sword") then
			stateManager:pushState("sword")
			
			up:setAttribute("near_sword", false)
			down:setAttribute("near_sword", false)
			left:setAttribute("near_sword", false)
			right:setAttribute("near_sword", false)
			
			up:setAttribute("__nsword", false)
			down:setAttribute("__nsword", false)
			left:setAttribute("__nsword", false)
			right:setAttribute("__nsword", false)
			
			console:printLore(
				dictionary:translate(stateManager:getStatesStack(), "lore",
					dictionary:translate(stateManager:getStatesStack(), "sword")
				) .. dictionary:translate(stateManager:getStatesStack(), "confirm")
			)
			
			local returned = console:read()
			local success, eos, answer = returned.success, returned.eos, returned.returned
			if not success then
				return EventParsingResultEnded(-1)
			elseif not answer then
				return EventParsingResultEnded(0)
			elseif (answer == "Y") or (answer == "y") then
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "take")
				)
				
				local hasSword = objects:has("sword")
				if difficulty == 4 then
					self:setAttribute("sword", false)
					
					objects:setObject("sword", not hasSword, difficulty)
				elseif difficulty == 3 then
					self:setAttribute("sword", false)
					
					if not hasSword then
						objects:setObject("sword", true, difficulty)
					end
				else
					if not hasSword then
						self:setAttribute("sword", false)
						
						objects:setObject("sword", true, difficulty)
					end
				end
			else
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "leave")
				)
			end
			
			stateManager:popState()
		end
		
		stateManager:pushState("near")
		if self:getAttribute("near_sword") ~= self:getAttribute("__nsword") then
			if self:getAttribute("__nsword") ~= nil or self:getAttribute("near_sword") then
				dictionary:setAlternative(stateManager:getStatesStack(), "sword", tostring(self:getAttribute("near_sword")))
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "sword")
				)
			end
			
			self:setAttribute("__nsword", self:getAttribute("near_sword"))
		end
		if self:getAttribute("near_key") ~= self:getAttribute("__nkey") then
			if self:getAttribute("__nkey") ~= nil or self:getAttribute("near_key") then
				dictionary:setAlternative(stateManager:getStatesStack(), "key", tostring(self:getAttribute("near_key")))
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "key")
				)
			end
			
			self:setAttribute("__nkey", self:getAttribute("near_key"))
		end
		if self:getAttribute("near_redkey") ~= self:getAttribute("__nredkey") then
			if self:getAttribute("__nredkey") ~= nil or self:getAttribute("near_redkey") then
				dictionary:setAlternative(stateManager:getStatesStack(), "redkey", tostring(self:getAttribute("near_redkey")))
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "redkey")
				)
			end
			
			self:setAttribute("__nredkey", self:getAttribute("near_redkey"))
		end
		if self:getAttribute("near_monster") ~= self:getAttribute("__nmonster") then
			if self:getAttribute("__nmonster") ~= nil or self:getAttribute("near_monster") then
				dictionary:setAlternative(stateManager:getStatesStack(), "monster", tostring(self:getAttribute("near_monster")))
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "monster")
				)
			end
			
			self:setAttribute("__nmonster", self:getAttribute("near_monster"))
		end
		if self:getAttribute("near_exit") ~= self:getAttribute("__nexit") then
			if self:getAttribute("__nexit") ~= nil or self:getAttribute("near_exit") ~= "far" then
				dictionary:setAlternative(stateManager:getStatesStack(), "exit", self:getAttribute("near_exit"))
				
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "exit")
				)
			end
			
			self:setAttribute("__nexit", self:getAttribute("near_exit"))
		end
		stateManager:popState()
		
		if self:getAttribute("graveyard") then
			stateManager:pushState("graveyard")
			
			console:printLore(
				dictionary:translate(stateManager:getStatesStack(), "lore") .. dictionary:translate(stateManager:getStatesStack(), "confirm")
			)
			
			local returned = console:read()
			local success, eos, answer = returned.success, returned.eos, returned.returned
			if not success then
				return EventParsingResultEnded(-1)
			elseif not answer then
				return EventParsingResultEnded(0)
			elseif (answer == "Y") or (answer == "y") then
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "go")
				)
				
				local dir = self:getAttribute("grave_dir")
				if not dir then dir = "left" end
				
				return EventParsingResultRoomChanging(dir, objects)
			else
				console:printLore(
					dictionary:translate(stateManager:getStatesStack(), "cancel")
				)
				
				return EventParsingResultRoomRestore(objects)
			end
			
			stateManager:popState()
		end
		
		return EventParsingResultDone(objects)
	end
	
	stateManager:pushMainState("ig")
	local ret = createEvents()
	stateManager:popMainState()
	return ret
end

function getRoomDisplayWidth()
	return 4
end
function getRoomDisplayHeight()
	return 4
end
