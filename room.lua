import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local consolemodule = require(import_prefix .. "console")
local eventsmodule = require(import_prefix .. "events")
local classmodule = require(import_prefix .. "class")

Room = class(function(self, room_datas)
	self.__datas = room_datas
end)

function Room:getAttribute(attributeName) return self.__datas[attributeName]         end
function Room:setAttribute(attributeName, value) self.__datas[attributeName] = value end

local list_data = {"exit", "up", "down", "left", "right", "monster", "sword", "key", "door", "trap", "redkey", "reddoor", "grave", "graveorig", "saw"}
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
	
	return true
end

function Room:canHear(event, position_in_row, up, down, left, right)
	return (up and up:getAttribute(event)) or (down and down:getAttribute(event))
	 or ((position_in_row ~= 1) and left and left:getAttribute(event))
	 or ((position_in_row ~= 0) and right and right:getAttribute(event))
end

function Room:hasAccess(direction)
	return self:getAttribute(direction)
	 or (not self:getAttribute("door") and self:getAttribute("door_dir") == direction)
	 or (not self:getAttribute("reddoor") and self:getAttribute("reddoor_dir") == direction)
	 or (self:getAttribute("exitdir") == direction)
end

function Room:canSee(event, position_in_row, up, down, left, right)
	return (self:hasAccess("up") and self:canHear(event, position_in_row, up))
	 or (self:hasAccess("down") and self:canHear(event, position_in_row, nil, down))
	 or (self:hasAccess("left") and self:canHear(event, position_in_row, nil, nil, left))
	 or (self:hasAccess("right") and self:canHear(event, position_in_row, nil, nil, nil, right))
end

local doorBGcolor = {["door"] = "44", ["reddoor"] = "41", ["grave"] = "45", ["opengrave"] = "0"}
function Room:printDoor(dir, doorType)
	if self:getAttribute(dir) then
		console:printLore(" ")
	elseif self:getAttribute("exitdir") == dir then
		console:printLore("\27[01;33;" .. doorBGcolor["opengrave"] .. "m ")
	elseif (self:getAttribute("grave") and (dir == "right")) or (self:getAttribute("graveorig") and (dir == "left")) then
		console:printLore("\27[01;33;" .. doorBGcolor["grave"] .. "m ")
	elseif (self:getAttribute(doorType) and (self:getAttribute("dir_" .. doorType) == dir)) then
		console:printLore("\27[01;33;" .. doorBGcolor[doorType] .. "m")
		if self:getAttribute("exit") and (self:getAttribute("dir_exit") == dir) then
			console:printLore("E")
		else
			console:printLore(" ")
		end
	elseif (not self:getAttribute(doorType)) and (self:getAttribute("dir_" .. doorType) == dir) then
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
		self:printDoor("left", "door")                            -- |
		console:printLore("\27[u\27[2B")                                   -- |
		self:printDoor("left", "reddoor")                         -- |
		console:printLore("\27[u\27[3B\27[01;30;41;07m \27[u\27[C\27[s")   -- -
		self:printDoor("up", "door")                              -- / Column two
		self:printDoor("up", "reddoor")                           -- + Column three
		console:printLore("\27[u\27[B")                                    -- |
		if self:getAttribute("unreachable") then                  -- |
			console:printLore("\27[01;30;41;07mUU\27[2D\27[BUU")           -- |
		else                                                      -- |
			if isActiveRoom then                                  -- |
				console:printLore("\27[43m")                               -- |
			end                                                   -- |
			if self:getAttribute("key") then                      -- |
				console:printLore("K")                                     -- |
			elseif self:getAttribute("near_key") then             -- |
				console:printLore("\27[02mK\27[22m")                       -- |
			else                                                  -- |
				console:printLore(" ")                                     -- |
			end                                                   -- |
			if self:getAttribute("redkey") then                   -- |
				console:printLore("k")                                     -- |
			elseif self:getAttribute("near_redkey") then          -- |
				console:printLore("\27[02mk\27[22m")                       -- |
			else                                                  -- |
				console:printLore(" ")                                     -- |
			end                                                   -- |
			console:printLore("\27[2D\27[B")                               -- |
			if self:getAttribute("sword") then                    -- |
				console:printLore("S")                                     -- |
			elseif self:getAttribute("near_sword") then           -- |
				console:printLore("\27[02mS\27[22m")                       -- |
			else                                                  -- |
				console:printLore(" ")                                     -- |
			end                                                   -- |
			if self:getAttribute("trap") then                     -- |
				console:printLore("T")                                     -- |
			elseif self:getAttribute("monster") then              -- |
				console:printLore("M")                                     -- |
			elseif self:getAttribute("near_monster") then         -- |
				console:printLore("\27[02mM\27[22m")                       -- |
			else                                                  -- |
				console:printLore(" ")                                     -- |
			end                                                   -- |
		end                                                       -- |
		console:printLore("\27[00m\27[2D\27[B")                            -- |
		self:printDoor("down", "door")                            -- |
		self:printDoor("down", "reddoor")                         -- -
		console:printLore("\27[u\27[2C\27[s\27[01;30;41;07m \27[u\27[B")   -- / Column four
		self:printDoor("right", "door")                           -- |
		console:printLore("\27[u\27[2B")                                   -- |
		self:printDoor("right", "reddoor")                        -- |
		console:printLore("\27[u\27[3B\27[01;30;41;07m \27[u\27[00m") -- -
	end
	return RoomPrintingDone()
end

function Room:refreshRoomNearEvents(position_in_row, up, down, left, right)
	if self:canSee("key", position_in_row, up, down, left, right) then
		console:printLore("You briefly see a shining, but you couldn't say from where it comes from.\n")
		self:setAttribute("near_key", true)
	end
	if self:canSee("redkey", position_in_row, up, down, left, right) then
		console:printLore("A deadly light?? questions you, but you couldn't say from where it comes from.\n")
		self:setAttribute("near_redkey", true)
	end
	if self:canSee("sword", position_in_row, up, down, left, right) then
		console:printLore("You briefly see a sharpened blade in a nearly room.\n")
		self:setAttribute("near_sword", true)
	end
	if self:canHear("monster", position_in_row, up, down, left, right) then
		console:printLore("A terrifying scream chills your blood, but it is so powerful you can't tell where does it come from.\n")
		self:setAttribute("near_monster", true)
	end
	if self:canSee("exit", position_in_row, up, down, left, right) then
		console:printLore("You hear the storm, then see a sunbeam! The exit is near this room...\n")
		self:setAttribute("near_exit", true)
	elseif self:canHear("exit", position_in_row, up, down, left, right) then
		console:printLore("You can hear the storm! The exit is near this room...\n")
		self:setAttribute("near_exit", 1)
	end
end

function Room:checkRoomEvents(is_ended, objects, room_position_in_row, up, down, left, right)
	if self:getAttribute("sword") then
		console:printLore("You see a sword on a book, that says that this sword will self-disintegrate with its first target.\nYou turn the page and you read that you can only have one at a time and that if you take this one, every other sword will disintegrates.\n")
		if objects["sword"] then console:printLore("You do already have one. ") end
		console:printLore("Do you want to take this sword? " .. '"Y" / "y" for yes, anything else to cancel: ')
		local returned = console:read()
		local success, eos, answer = returned.success, returned.eos, returned.returned
		if not success then
			return EventParsingResultEnded(-1)
		elseif not answer then
			return EventParsingResultEnded(0)
		elseif (answer == "Y") or (answer == "y") then
			objects["sword"] = true
			self:setAttribute("sword", false)
		end
		up:setAttribute("near_sword", false)
		down:setAttribute("near_sword", false)
		left:setAttribute("near_sword", false)
		right:setAttribute("near_sword", false)
	end
	if self:getAttribute("monster") then
		if objects["sword"] then
			console:printLore("You see a monster! Quick, you arm your weapon... the moment it runs toward you! Your sword kills him, but it disintegrates... You don't have a sword anymore.\n")
			objects["sword"] = false
			self:setAttribute("monster", false)
		else
			console:printLore("Yous see a monster, but, due to your lack of equipment, you don't have any weapon... While you try to escape, the monster catch you and eat you. You are DEAD!\n")
			return EventParsingResultExited(true, objects)
		end
		up:setAttribute("near_monster", false)
		down:setAttribute("near_monster", false)
		left:setAttribute("near_monster", false)
		right:setAttribute("near_monster", false)
	end
	if self:getAttribute("door") then
		if objects["key"] then
			if (not self:getAttribute("exit")) or (self:getAttribute("dir_exit") ~= self:getAttribute("dir_door")) then
				console:printLore("You see a door at the " .. cardinals[self:getAttribute("dir_door")] .. ", that you open with your key.\nBut when you release the key, the door is closing by itself!\nYou reopen it, but before that the door closes, you remove your key, and the door stay opened.\nThe key disintegrate. You don't have the key anymore.\n")
				objects["key"] = false
				self:setAttribute("door", false)
				if (self:getAttribute("dir_door") == "up") then
					up:setAttribute("door", false)
					up:setAttribute("dir_door", "down")
				elseif (self:getAttribute("dir_door") == "down") then
					down:setAttribute("door", false)
					down:setAttribute("dir_door", "up")
				elseif (self:getAttribute("dir_door") == "left") then
					left:setAttribute("door", false)
					left:setAttribute("dir_door", "right")
				elseif (self:getAttribute("dir_door") == "right") then
					right:setAttribute("door", false)
					right:setAttribute("dir_door", "left")
				else
					console:print("Unknown door direction: " .. tostring(self:getAttribute("dir_door")) .. "\n", LogLevel.ERROR, "room.lua/Room:checkRoomEvents(door)")
				end
			else
				console:printLore("You see the exit at the " .. cardinals[self:getAttribute("dir_exit")] .. "!\nQuick, you take your key and you open the exit door.\n\n") --You survived against the monsters and the traps and you WON!")
				return EventParsingResultExited(false, objects)
			end
		else
			console:printLore("You see a door at the " .. cardinals[self:getAttribute("dir_door")])
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_door")) then
				console:printLore(" blocking the exit")
			end
			console:printLore(".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door doesn't open...\nYou cannot ")
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_door")) then
				console:printLore("exit the maze")
			else
				console:printLore("go to " .. cardinals[self:getAttribute("dir_door")])
			end
			console:printLore(".\n")
		end
	end
	if self:getAttribute("reddoor") then
		if objects["redkey"] then
			if (not self:getAttribute("exit")) or (self:getAttribute("dir_exit") ~= self:getAttribute("dir_reddoor")) then
				console:printLore("You see a door you don't want to approach at the " .. cardinals[self:getAttribute("dir_reddoor")] .. ".\nHopefully, you remember that you have a red key, of the same color than the door. You open the door.\n")
				objects["redkey"] = false
				self:setAttribute("reddoor", false)
				if (self:getAttribute("dir_reddoor") == "up") then
					up:setAttribute("reddoor", false)
					up:setAttribute("dir_reddoor", "down")
				elseif (self:getAttribute("dir_reddoor") == "down") then
					down:setAttribute("reddoor", false)
					down:setAttribute("dir_reddoor", "up")
				elseif (self:getAttribute("dir_reddoor") == "left") then
					left:setAttribute("reddoor", false)
					left:setAttribute("dir_reddoor", "right")
				elseif (self:getAttribute("dir_reddoor") == "right") then
					right:setAttribute("reddoor", false)
					right:setAttribute("dir_reddoor", "left")
				else
					console:print("Unknown red door direction: " .. tostring(self:getAttribute("dir_reddoor")) .. "\n", LogLevel.ERROR, "room.lua/Room:checkRoomEvents(reddoor)")
				end
			else
				console:printLore("You see a door you don't want to approach at the " .. cardinals[self:getAttribute("dir_exit")] .. " blocking the exit!\nHopefully, you remember that you have a red key, of the same color than the door. You open the door and you exit this maze!\n\n") --You survived against the monsters and the traps and you WON!")
				return EventParsingResultExited(false, objects)
			end
		else
			console:printLore("You see a door you don't want to approach at the " .. cardinals[self:getAttribute("dir_reddoor")])
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_reddoor")) then
				console:printLore(" blocking the exit..")
			end
			console:printLore(".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door doesn't open...\nYou cannot ")
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_reddoor")) then
				console:printLore("exit the maze..")
			else
				console:printLore("go to " .. cardinals[self:getAttribute("dir_reddoor")])
			end
			console:printLore(".\n")
		end
	end
	if self:getAttribute("exit") and (self:getAttribute("dir_exit") ~= self:getAttribute("dir_door")) and (self:getAttribute("dir_exit") ~= self:getAttribute("dir_reddoor")) then
		console:printLore("You reached the exit. Fortunately enough, it is simply an open door with " .. '"EXIT"' .. " written on it, so you can simply walk outside.\nYou walk through that door and you exit the maze!")
	end
	if self:getAttribute("trap") then
		console:printLore("You felt into a trap, and, with terrible pain, you DIE.\n")
		return EventParsingResultExited(true, objects)
	end
	if not is_ended then
		if self:getAttribute("key") then
			console:printLore("You see a key in a book. You can reach the key only by reading the book.")
			sleep(0.5) console:printLore(".")
			sleep(0.5) console:printLore(".")
			sleep(0.5) console:printLore("\8\8\8???, so you read it")
			sleep(1)   console:printLore(".")
			sleep(1)   console:printLore(".")
			sleep(1)   console:printLore(".")
			sleep(1)   console:printLore("\8\8\8   \8\8\8, and you see a part about the key:\n")
			sleep(0.5) console:printLore("\"This key is destined to the first that will find it. But beware! This key has a unique usage, but persistant.")
			sleep(1)   console:printLore(".")
			sleep(0.5) console:printLore(".")
			sleep(0.5) console:printLore("\8\8\8?? \8")
			console:printLore("\nIf you insert it in a closed door and then you remove it, it will self-disintegrate.\nIf the door isn't locked, then you'll be able to remove it without worrying. Once the door unlocked, remove the key and no one will be able to lock it again (with one exception).\nIf you lock a door...\"\nThen a lot of explanations.\n\"If you take this key, every other key you have will disintegrate.\"\n\n")
			if objects["key"] then console:printLore("You do already have a key. ") end
			
			console:printLore("Do you want to take it? " .. '"Y" / "y" for yes, anything else to cancel: ')
			local returned = console:read()
			local success, eos, answer = returned.success, returned.eos, returned.returned
			if not success then
				return EventParsingResultEnded(-1)
			elseif not answer then
				return EventParsingResultEnded(0)
			elseif (answer == "Y") or (answer == "y") then
				objects["key"] = true
				self:setAttribute("key", false)
			end
			up:setAttribute("near_key", false)
			down:setAttribute("near_key", false)
			left:setAttribute("near_key", false)
			right:setAttribute("near_key", false)
		end
		if self:getAttribute("redkey") then
			console:printLore("You see a red")
			sleep(1) console:printLore("\8\8\8wait, no")
			sleep(1) console:printLore("\8\8\8\8\8\8\8\8bloody key in a book.\nIt says that this key already closed a door, and only it can reopen it.\n")
			if objects["redkey"] then
				console:printLore("You decided not to take it, as you already have one.\n")
			else
				console:printLore('Do you want to take it? "Y" / "y" means yes, anything else to cancel: ')
				local returned = console:read()
				local success, eos, answer = returned.success, returned.eos, returned.returned
				if not success then
					return EventParsingResultEnded(-1)
				elseif not answer then
					return EventParsingResultEnded(0)
				elseif (answer == "Y") or (answer == "y") then
					objects["redkey"] = true
					self:setAttribute("redkey", false)
				end
			end
			up:setAttribute("near_redkey", false)
			down:setAttribute("near_redkey", false)
			left:setAttribute("near_redkey", false)
			right:setAttribute("near_redkey", false)
		end
		self:refreshRoomNearEvents(room_position_in_row, up, down, left, right)
		if self:getAttribute("grave") and self:getAttribute("deadlygrave") then
			console:printLore("You chose to enter the room underneath, but it appears to be a grave.\n")
			if objects[self:getAttribute("keyneeded")] then
				console:printLore("Hopefully, you can exit it thanks to the ")
				if (self:getAttribute("keyneeded") == "redkey") and (objects["redkey"] == true) then
					console:printLore("red key")
					objects["redkey"] = false
				end
				if (self:getAttribute("keyneeded") == "key") and (objects["key"] == true) then
					console:printLore("key")
					objects["key"] = false
				else
					console:print("Unknown key value: " .. tostring(self:getAttribute("keyneeded")) .. "\n", LogLevel.ERROR, "room.lua/Room:checkRoomEvents(deadlygraveexitable1)")
				end
				console:printLore(", so you open the grave's exit, located at the " .. cardinals[self:getAttribute("exitdir")] .. ".\n")
				self:setAttribute("deadlygrave", false)
			else
				console:printLore("You DIE.\nYou could've exit if you had the ")
				if (self:getAttribute("keyneeded") == "key") then
					console:printLore("key")
				elseif (self:getAttribute("keyneeded") == "redkey") then
					console:printLore("red key")
				else
					console:print("Unknown key value: " .. tostring(self:getAttribute("keyneeded")) .. "\n", LogLevel.ERROR, "room.lua/Room:checkRoomEvents(deadlygraveexitable2)")
				end
				console:printLore(" of the exit located at the " .. cardinals[self:getAttribute("exitdir")] .. ".")
				return EventParsingResultExited(true, objects)
			end
			if self:getAttribute("exitdir") == "up" then
				up:setAttribute("down", true)
			elseif self:getAttribute("exitdir") == "down" then
				down:setAttribute("up", true)
			elseif self:getAttribute("exitdir") == "left" then
				left:setAttribute("right", true)
			elseif self:getAttribute("exitdir") == "right" then
				right:setAttribute("left", true)
			else
				console:print("Unknown exit direction: " .. tostring(self:getAttribute("exitdir")) .. "\n", LogLevel.ERROR, "room.lua/Room:checkRoomEvents(deadlygraveexitable3)")
			end
		end
		if self:getAttribute("graveorig") then
			self:setAttribute("saw", true)
			console:printLore("After having walked across stairs, you see a room filled with skeletons.\nA grid is located on the ground and leads to another room.\nDo you want to continue and go donwstairs or go backwards ? (" .. '"Y" / "y"' .. " means go downstairs, everything else means go back): ")
			local returned = console:read()
			local success, eos, answer = returned.success, returned.eos, returned.returned
			if not success then
				return EventParsingResultEnded(-1)
			elseif not answer then
				return EventParsingResultEnded(0)
			elseif (answer == "Y") or (answer == "y") then
				return EventParsingResultRoomChanging("left", objects)
			else
				return EventParsingResultRoomRestore(objects)
			end
		end
	end
	if not is_ended then
		return EventParsingResultDone(objects)
	else
		return EventParsingResultExited("???", objects)
	end
end

function getRoomDisplayWidth()
	return 4
end
function getRoomDisplayHeight()
	return 4
end
