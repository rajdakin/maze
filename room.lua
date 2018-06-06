import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

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
end

function Room:initialize()
	for k, v in pairs(list_data) do
		if not self:getAttribute(v) then self:setAttribute(v, false) end
	end
end

function Room:canHear(event, position_in_row, up, down, left, right)
	return (up and up:getAttribute(event)) or (down and down:getAttribute(event))
	 or ((position_in_row ~= 1) and left and left:getAttribute(event)) or ((position_in_row ~= 0) and right and right:getAttribute(event))
end

function Room:hasAccess(direction)
	return self:getAttribute(direction)
	 or (not self:getAttribute("door") and self:getAttribute("dir_door") == direction)
	 or (not self:getAttribute("reddoor") and self:getAttribute("dir_reddoor") == direction)
end

function Room:canSee(event, position_in_row, up, down, left, right)
	return (self:hasAccess("up") and self:canHear(event, position_in_row, up))
	 or (self:hasAccess("down") and self:canHear(event, position_in_row, down))
	 or (self:hasAccess("left") and self:canHear(event, position_in_row, left))
	 or (self:hasAccess("right") and self:canHear(event, position_in_row, right))
end

local doorBGcolor = {["door"] = "44", ["reddoor"] = "41", ["grave"] = "45"}
function Room:printDoor(dir, doorType)
	if self:getAttribute(dir) then
		io.write(" ")
	elseif self:getAttribute("grave") then
		io.write("\27[01;33;" .. doorBGcolor["grave"] .. "m ")
	elseif (self:getAttribute(doorType) and (self:getAttribute("dir_" .. doorType) == dir)) then
		io.write("\27[01;33;" .. doorBGcolor[doorType] .. "m")
		if self:getAttribute("exit") and (self:getAttribute("dir_exit") == dir) then
			io.write("E")
		else
			io.write(" ")
		end
	elseif (not self:getAttribute(doorType)) and (self:getAttribute("dir_" .. doorType) == dir) then
		io.write("\27[42m ")
	else
		io.write("\27[01;30;41;07m ")
	end
	io.write("\27[00m")
end

function Room:printRoom(objects, isActiveRoom)
	io.write("\27[s")
	if not self:getAttribute("saw") then
		io.write("\27[C\27[s\27[B\27[01;30;47;07m?? \27[u\27[2B\27[01;30;47;07m?? \27[u\27[3B\27[01;30;47;07m   \27[u\27[2C\27[00m")
	else
		io.write("\27[01;30;41;07m \27[u\27[B")                   -- / Column one
		self:printDoor("left", "door")                            -- |
		io.write("\27[u\27[2B")                                   -- |
		self:printDoor("left", "reddoor")                         -- |
		io.write("\27[u\27[3B\27[01;30;41;07m \27[u\27[C\27[s")   -- -
		self:printDoor("up", "door")                              -- / Column two
		self:printDoor("up", "reddoor")                           -- + Column three
		io.write("\27[u\27[B")                                    -- |
		if self:getAttribute("unreachable") then                  -- |
			io.write("\27[01;30;41;07mUU\27[2D\27[BUU")           -- |
		else                                                      -- |
			if isActiveRoom then                                  -- |
				io.write("\27[43m")                               -- |
			end                                                   -- |
			if self:getAttribute("key") then                      -- |
				io.write("K")                                     -- |
			elseif self:getAttribute("near_key") then             -- |
				io.write("\27[02mK\27[22m")                       -- |
			else                                                  -- |
				io.write(" ")                                     -- |
			end                                                   -- |
			if self:getAttribute("redkey") then                   -- |
				io.write("k")                                     -- |
			elseif self:getAttribute("near_redkey") then          -- |
				io.write("\27[02mk\27[22m")                       -- |
			else                                                  -- |
				io.write(" ")                                     -- |
			end                                                   -- |
			io.write("\27[2D\27[B")                               -- |
			if self:getAttribute("sword") then                    -- |
				io.write("S")                                     -- |
			elseif self:getAttribute("near_sword") then           -- |
				io.write("\27[02mS\27[22m")                       -- |
			else                                                  -- |
				io.write(" ")                                     -- |
			end                                                   -- |
			if self:getAttribute("trap") then                     -- |
				io.write("T")                                     -- |
			elseif self:getAttribute("monster") then              -- |
				io.write("M")                                     -- |
			elseif self:getAttribute("near_monster") then         -- |
				io.write("\27[02mM\27[22m")                       -- |
			else                                                  -- |
				io.write(" ")                                     -- |
			end                                                   -- |
		end                                                       -- |
		io.write("\27[00m\27[2D\27[B")                            -- |
		self:printDoor("down", "door")                            -- |
		self:printDoor("down", "reddoor")                         -- -
		io.write("\27[u\27[2C\27[s\27[01;30;41;07m \27[u\27[B")   -- / Column four
		self:printDoor("right", "door")                           -- |
		io.write("\27[u\27[2B")                                   -- |
		self:printDoor("right", "reddoor")                        -- |
		io.write("\27[u\27[3B\27[01;30;41;07m \27[u\27[00m") -- -
	end
	return RoomPrintingDone()
end

function Room:refreshRoomNearEvents(position_in_row, up, down, left, right)
	if self:canSee("key", position_in_row, up, down, left, right) then
		print("You briefly see a shining, but you couldn't say from where it comes from.")
		self:setAttribute("near_key", true)
	end
	if self:canSee("redkey", position_in_row, up, down, left, right) then
		print("A deadly light?? questions you, but you couldn't say from where it comes from.")
		self:setAttribute("near_redkey", true)
	end
	if self:canSee("sword", position_in_row, up, down, left, right) then
		print("You briefly see a sharpened blade in a nearly room.")
		self:setAttribute("near_sword", true)
	end
	if self:canHear("monster", position_in_row, up, down, left, right) then
		print("A terrifying scream chills your blood, but it is so powerful you can't tell where does it come from.")
		self:setAttribute("near_monster", true)
	end
	if self:canSee("exit", position_in_row, up, down, left, right) then
		print("You hear the storm, then see a sunbeam! The exit is near this room...")
		self:setAttribute("near_exit", true)
	elseif self:canHear("exit", position_in_row, up, down, left, right) then
		print("You can hear the storm! The exit is near this room...")
		self:setAttribute("near_exit", 1)
	end
end

function Room:checkRoomEvents(is_ended, objects, room_position_in_row, up, down, left, right)
	if self:getAttribute("sword") then
		io.write("You see a sword on a book, that says that this sword will self-disintegrate with its first target.\nYou turn the page and you read that you can only have one at a time and that if you take this one, every other sword will disintegrates.\n")
		if objects["sword"] then io.write("You do already have one. ") end
		io.write("Do you want to take this sword? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
		io.flush()
		local answer = io.read()
		if not answer then
			return EventParsingResultEnded("user's request")
		elseif (answer == "O") or (answer == "o") or (answer == "Y") or (answer == "y") then
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
			print("You see a monster! Quick, you arm your weapon... the moment it runs toward you! Your sword kills him, but it disintegrates... You don't have a sword anymore.")
			objects["sword"] = false
			self:setAttribute("monster", false)
		else
			print("Yous see a monster, but, due to your lack of equipment, you don't have any weapon... While you try to escape, the monster catch you and eat you. You are DEAD!")
			return EventParsingResultExited(true)
		end
		up:setAttribute("near_monster", false)
		down:setAttribute("near_monster", false)
		left:setAttribute("near_monster", false)
		right:setAttribute("near_monster", false)
	end
	if self:getAttribute("door") then
		if objects["key"] then
			if (not self:getAttribute("exit")) or (self:getAttribute("dir_exit") ~= self:getAttribute("dir_door")) then
				print("You see a door at the " .. cardinals[self:getAttribute("dir_door")] .. ", that you open with your key.\nBut when you release the key, the door is closing by itself!\nYou reopen it, but before that the door closes, you remove your key, and the door stay opened.\nThe key disintegrate. You don't have the key anymore.")
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
					print("EXCEPTION.UNKNOWN_DOOR_DIR: " .. self:getAttribute("dir_door") .. " AT LINE #")
				end
			else
				print("You see the exit at the " .. cardinals[self:getAttribute("dir_exit")] .. "!\nQuick, you take your key and you open the exit door.\nYou survived against the monsters and the traps and you WON!")
				return EventParsingResultExited(false)
			end
		else
			io.write("You see a door at the " .. cardinals[self:getAttribute("dir_door")])
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_door")) then
				io.write(" blocking the exit")
			end
			io.write(".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door doesn't open...\nYou cannot ")
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_door")) then
				io.write("exit the maze")
			else
				io.write("go to " .. cardinals[self:getAttribute("dir_door")])
			end
			print(".")
		end
	end
	if self:getAttribute("reddoor") then
		if objects["redkey"] then
			if (not self:getAttribute("exit")) or (self:getAttribute("dir_exit") ~= self:getAttribute("dir_reddoor")) then
				print("You see a door you don't want to approach at the " .. cardinals[self:getAttribute("dir_reddoor")] .. ".\nHopefully, you remember that you have a red key, of the same color than the door. You open the door.")
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
					print("EXCEPTION.UNKNOWN_REDDOOR_DIR: " .. self:getAttribute("dir_reddoor") .. " AT LINE #X")
				end
			else
				print("You see a door you don't want to approach at the " .. cardinals[self:getAttribute("dir_exit")] .. " blocking the exit!\nHopefully, you remember that you have a red key, of the same color than the door. You open the door and you exit this maze!\nYou survived against the monsters and the traps and you WON!")
				return EventParsingResultExited(false)
			end
		else
			io.write("You see a door you don't want to approach at the " .. cardinals[self:getAttribute("dir_reddoor")])
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_reddoor")) then
				io.write(" blocking the exit..")
			end
			io.write(".\nDue to your lack of equipment, you don't have the right key and despite all of your efforts, this door doesn't open...\nYou cannot ")
			if self:getAttribute("exit") and (self:getAttribute("dir_exit") == self:getAttribute("dir_reddoor")) then
				io.write("exit the maze..")
			else
				io.write("go to " .. cardinals[self:getAttribute("dir_reddoor")])
			end
			print(".")
		end
	end
	if self:getAttribute("trap") then
		print("You felt into a trap, and, with terrible pain, you DIE.")
		return EventParsingResultExited(true)
	end
	if not is_ended then
		if self:getAttribute("key") then
			io.write("You see a key in a book. You can reach the key only by reading the book.") io.flush()
			sleep(0.5) io.write(".") io.flush()
			sleep(0.5) io.write(".") io.flush()
			sleep(0.5) io.write("\8\8\8???, so you read it") io.flush()
			sleep(1)   io.write(".") io.flush()
			sleep(1)   io.write(".") io.flush()
			sleep(1)   io.write(".") io.flush()
			sleep(1)   io.write("\8\8\8   \8\8\8, and you see a part about the key:\n") io.flush()
			sleep(0.5) io.write("\"This key is destined to the first that will find it. But beware! This key has a unique usage, but persistant.") io.flush()
			sleep(1)   io.write(".") io.flush()
			sleep(0.5) io.write(".") io.flush()
			sleep(0.5) io.write("\8\8\8?? \8")
			io.write("\nIf you insert it in a closed door and then you remove it, it will self-disintegrate.\nIf the door isn't locked, then you'll be able to remove it without worrying. One the door unlocked, remove the key and no one will be able to lock it again (with one exception).\nIf you lock a door...\"\nThen a lot of explanations.\n\"If you take this key, every other key you have will disintegrate.\"\n\n")
			if objects["key"] then io.write("You do already have a key. ") end
			io.write("Do you want to take it? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
			io.flush()
			local answer = io.read()
			if not answer then
				return EventParsingResultEnded("user's request")
			elseif (answer == "O") or (answer == "o") or (answer == "Y") or (answer == "y") then
				objects["key"] = true
				self:setAttribute("key", false)
			end
			up:setAttribute("near_key", false)
			down:setAttribute("near_key", false)
			left:setAttribute("near_key", false)
			right:setAttribute("near_key", false)
		end
		if self:getAttribute("redkey") then
			io.write("You see a red") io.flush()
			sleep(1) io.write("\8\8\8wait, no") io.flush()
			sleep(1) io.write("\8\8\8\8\8\8\8\8bloody key in a book.\nIt says that this key already closed a door, and only it can reopen it.\n")
			if objects["redkey"] then
				print("You decided not to take it, as you already have one.")
			else
				io.write('Do you want to take it? "O"/"o"/"Y"/"y" means yes, anything else to cancel: ')
				io.flush()
				local answer = io.read()
				if not answer then
					return EventParsingResultEnded("user's request")
				elseif (answer == "O") or (answer == "o") or (answer == "Y") or (answer == "y") then
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
			io.write("You chose to enter the room underneath, but it appears to be a grave.\n")
			if (self:getAttribute("keyneeded") == "redkey") and (objects["redkey"] == true) or ((self:getAttribute("keyneeded") == "key") and (objects["key"] == true)) then
				io.write("Hopefully, you can exit it thanks to the ")
				if (self:getAttribute("keyneeded") == "redkey") and (objects["redkey"] == true) then
					io.write("red key")
					objects["redkey"] = false
				end
				if (self:getAttribute("keyneeded") == "key") and (objects["key"] == true) then
					io.write("key")
					objects["key"] = false
				else
					io.write("EXCEPTION.UNKNOWN_KEY_VALUE: " .. self:getAttribute("keyneeded") .. " AT LINE #XX")
				end
				print(", so you open the grave's exit, located at the " .. cardinals[self:getAttribute("exitdir")] .. ".")
				self:setAttribute("deadlygrave", false)
			else
				print("You DIE.\nYou could've exit if you had the ")
				if (self:getAttribute("keyneeded") == "key") then
					io.write("key")
				elseif (self:getAttribute("keyneeded") == "redkey") then
					io.write("red key")
				else
					io.write("EXCEPTION.UNKNOWN_KEY_VALUE: " .. self:getAttribute("keyneeded") .. " AT LINE #XX")
				end
				io.write(" of the exit located at the " .. cardinals[self:getAttribute("exitdir")] .. ".")
				return EventParsingResultExited(true)
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
				print("EXCEPTION.UNKNOWN_EXIT_DIR: " .. self:getAttribute("exitdir") .. " AT LINE #XXX")
			end
		end
		if self:getAttribute("graveorig") then
			self:setAttribute("saw", true)
			io.write("After having walked across stairs, you see a room filled with skeletons.\nA grid is located on the ground and leads to another room.\nDo you want to continue and go donwstairs or go backwards ? (O / o / Y / y means go downstairs, everything else means go back): ")
			io.flush()
			local answer = io.read()
			if not answer then
				return EventParsingResultEnded("user's request")
			elseif (answer == "O") or (answer == "o") or (answer == "Y") or (answer == "y") then
				return EventParsingResultRoomChanging("left", objects)
			else
				return EventParsingResultRoomRestore(objects)
			end
		end
	end
	if not is_ended then
		return EventParsingResultDone(objects)
	else
		return EventParsingResultExited("???")
	end
end

function getRoomDisplayWidth()
	return 4
end
function getRoomDisplayHeight()
	return 4
end
