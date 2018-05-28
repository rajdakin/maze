import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

Room = class(function(self, room_datas)
	self.__datas = room_datas
end)

function Room:getAttribute(attributeName) return self.__datas[attributeName]         end
function Room:setAttribute(attributeName, value) self.__datas[attributeName] = value end

function Room:setUnreachable()
	self:setAttribute("unreachable", self.__datas == {})
end

local list_data = {"exit", "up", "down", "left", "right", "monster", "sword", "key", "door", "direction", "trap", "redkey", "reddoor", "grave", "graveorig", "saw"}
function Room:initialize()
	for k, v in pairs(list_data) do
		if not self:getAttribute(v) then self:setAttribute(v, false) end
	end
end

function Room:printRoom(objects, isActiveRoom, is_left_seen_status_true)
	if (self:getAttribute("left")
	  or (((not self:getAttribute("door")) and (self:getAttribute("dir_door") == "left"))
	  and ((not self:getAttribute("reddoor")) and (self:getAttribute("dir_reddoor") == "left")))
	  or (((not self:getAttribute("door")) and (self:getAttribute("dir_door") == "left"))
	  and ((not self:getAttribute("reddoor")) and (self:getAttribute("dir_reddoor") == nil)))
	  or (((not self:getAttribute("door")) and (self:getAttribute("dir_door") == nil))
	  and ((not self:getAttribute("reddoor")) and (self:getAttribute("dir_reddoor") == "left")))
	  or (self:getAttribute("grave") and (self:getAttribute("exitdir") == "left"))
	  or  self:getAttribute("graveorig"))
	 and (self:getAttribute("saw") or is_left_seen_status_true) then
		if self:getAttribute("graveorig") then
			io.write("\27[44;31m \27[00m")
		else
			io.write(" ")
		end
	else
		io.write("\27[01;30;41;07m \27[00m")
	end
	if isActiveRoom then
		io.write("\27[43m")
	end
	if self:getAttribute("saw") then
		if self:getAttribute("exit") then
			io.write("E")
		elseif self:getAttribute("sword") then
			io.write("s")
		elseif self:getAttribute("key") then
			io.write("c")
		elseif self:getAttribute("redkey") then
			io.write("C")
		elseif self:getAttribute("door") then
			io.write("d")
		elseif self:getAttribute("reddoor") then
			io.write("D")
		elseif self:getAttribute("grave") then
			io.write("G")
		elseif self:getAttribute("graveorig") then
			io.write("g")
		elseif self:getAttribute("monster") then
			io.write("\27[31mM\27[00m")
		elseif self:getAttribute("trap") then
			io.write("\27[31mT\27[00m")
		elseif self:getAttribute("unreachable") then
			io.write("\27[01;30;41;07mU\27[00m")
		else
			io.write(" ")
		end
	else
		io.write("\27[01;30;07;47m?\27[00m")
	end
	if isActiveRoom then
		io.write("\27[00m")
	end
end

function Room:checkRoomEvents(is_ended, objects, room_position_in_row, caller)
	if self:getAttribute("sword") then
		io.write("You see a sword on a book, that says that this sword will self-disintegrate with its first target.\nYou turn the page and you read that you can only have one at a time and that if you take this one, every other sword will disintegrates.\n")
		if objects["sword"] then io.write("You do already have one. ") end
		io.write("Do you want to take this sword? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
		local reponse = io.read()
		if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
			objects["sword"] = true
			self:setAttribute("sword", false)
		end
	end
	if self:getAttribute("monster") then
		if objects["sword"] then
			print("You see a monster! Quick, you arm your weapon... the moment it runs toward you! Your sword kills him, but it disintegrates... You don't have a sword anymore.")
			objects["sword"] = false
			self:setAttribute("monster", false)
		else
			print("Yous see a monster, but, due to your lack of equipment, you don't have any weapon... While you try to escape, the monster catch you and eat you. You are DEAD!")
			objects["sword"] = false
			is_ended = true
			objects["key"] = false
			objects["redkey"] = false
		end
	end
	if self:getAttribute("key") then
		io.write("You see a key in a book. You can reach the key only by reading the book.")
		io.flush()
		sleep(0.5)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write("\8\8\8???, so you ")
		local i
		for i = 0, 1 do
			io.write("read it")
			io.flush()
			sleep(1)
			io.write(".")
			io.flush()
			sleep(1)
			io.write(".")
			io.flush()
			sleep(1)
			io.write(".")
			io.flush()
			sleep(1)
			io.write(" and ")
		end
		io.write("\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8                       \8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8\8")
		io.write(", and you see a part about the key:\n")
		io.flush()
		sleep(0.5)
		io.write("\"This key is destined to the first that will find it. But beware! This key has a unique usage, but persistant.")
		io.flush()
		sleep(1)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write(".")
		io.flush()
		sleep(0.5)
		io.write("\8\8\8?? \8")
		io.write("\nIf you insert it in a closed door and then you remove it, it will self-disintegrate.\nIf the door isn't locked, then you'll be able to remove it without worrying. One the door unlocked, remove the key and no one will be able to lock it again (with one exception).\nIf you lock a door...\"\nThen a lot of explanations.\n\"If you take this key, every other key you have will disintegrate.\"\n\n")
		if objects["key"] then io.write("You do already have a key. ") end
		io.write("Do you want to take it? " .. '"O" / "o" / "Y" / "y" for yes, anything else to cancel: ')
		io.flush()
		local reponse = io.read()
		if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
			objects["key"] = true
			self:setAttribute("key", false)
		end
	end
	if self:getAttribute("door") then
		if objects["key"] then
			if (not self:getAttribute("exit")) or (self:getAttribute("dir_exit") ~= self:getAttribute("dir_door")) then
				print("You see a door at the " .. cardinals[self:getAttribute("dir_door")] .. ", that you open with your key.\nBut when you release the key, the door is closing by itself!\nYou reopen it, but before that the door closes, you remove your key, and the door stay opened.\nThe key disintegrate. You don't have the key anymore.")
				objects["key"] = false
				self:setAttribute("door", false)
				if (self:getAttribute("dir_door") == "up") then
					caller:setAttribute(caller:getRoomNumber() - caller:getColumnCount(), "door", false)
					caller:setAttribute(caller:getRoomNumber() - caller:getColumnCount(), "dir_door", "down")
				elseif (self:getAttribute("dir_door") == "down") then
					caller:setAttribute(caller:getRoomNumber() + caller:getColumnCount(), "door", false)
					caller:setAttribute(caller:getRoomNumber() + caller:getColumnCount(), "dir_door", "up")
				elseif (self:getAttribute("dir_door") == "left") then
					caller:setAttribute(caller:getRoomNumber() - 1, "door", false)
					caller:setAttribute(caller:getRoomNumber() - 1, "dir_door", "right")
				elseif (self:getAttribute("dir_door") == "right") then
					caller:setAttribute(caller:getRoomNumber() + 1, "door", false)
					caller:setAttribute(caller:getRoomNumber() + 1, "dir_door", "left")
				else
					print("EXCEPTION.UNKNOWN_DOOR_DIR: " .. self:getAttribute("dir_door") .. " AT LINE #")
				end
			else
				print("You see the exit at the " .. cardinals[self:getAttribute("dir_exit")] .. "!\nQuick, you take your key and you open the exit door.\nYou survived against the monsters and the traps and you WON!")
				resetMaze()
				setRoomsAsSeen()
				is_ended = true
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
					caller:setAttribute(caller:getRoomNumber() - caller:getColumnCount(), "reddoor", false)
					caller:setAttribute(caller:getRoomNumber() - caller:getColumnCount(), "dir_reddoor", "down")
				elseif (self:getAttribute("dir_reddoor") == "down") then
					caller:setAttribute(caller:getRoomNumber() + caller:getColumnCount(), "reddoor", false)
					caller:setAttribute(caller:getRoomNumber() + caller:getColumnCount(), "dir_reddoor", "up")
				elseif (self:getAttribute("dir_reddoor") == "left") then
					caller:setAttribute(caller:getRoomNumber() - 1, "reddoor", false)
					caller:setAttribute(caller:getRoomNumber() - 1, "dir_reddoor", "right")
				elseif (self:getAttribute("dir_reddoor") == "right") then
					caller:setAttribute(caller:getRoomNumber() + 1, "reddoor", false)
					caller:setAttribute(caller:getRoomNumber() + 1, "dir_reddoor", "left")
				else
					print("EXCEPTION.UNKNOWN_REDDOOR_DIR: " .. self:getAttribute("dir_reddoor") .. " AT LINE #X")
				end
			else
				print("You see a door you don't want to approach at the " .. cardinals[self:getAttribute("dir_exit")] .. " blocking the exit!\nHopefully, you remember that you have a red key, of the same color than the door. You open the door and you exit this maze!\nYou survived against the monsters and the traps and you WON!")
				resetMaze()
				setRoomsAsSeen()
				is_ended = true
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
		is_ended = true
	end
	if not is_ended then
		if self:getAttribute("redkey") then
			io.write("You see a red")
			io.flush()
			sleep(1)
			io.write("\8\8\8wait, no")
			io.flush()
			sleep(1)
			io.write("\8\8\8\8\8\8\8\8bloody key in a book.\nIt says that this key already closed a door, and only it can reopen it.\n")
			if objects["redkey"] then
				print("You decided not to take it, as you already have one.")
			else
				io.write('Do you want to take it? "O"/"o"/"Y"/"y" means yes, anything else to cancel: ')
				local reponse = io.read()
				if (reponse == "O") or (reponse == "o") or (reponse == "Y") or (reponse == "y") then
					objects["redkey"] = true
					self:setAttribute("redkey", false)
				end
			end
		end
		if (caller:getRoomAttribute(caller:getRoomNumber() + 1, "key") and (not (room_position_in_row == 0))) or (caller:getRoomAttribute(caller:getRoomNumber() - 1, "key") and (not (room_position_in_row == 1))) or (caller:getRoomAttribute(caller:getRoomNumber() + caller:getColumnCount(), "key")) or (caller:getRoomAttribute(caller:getRoomNumber() - caller:getColumnCount(), "key")) then
			print("You briefly see a shining, but you couldn't say from where it comes from.")
		end
		if (caller:getRoomAttribute(caller:getRoomNumber() + 1, "redkey") and (not (room_position_in_row == 0))) or (caller:getRoomAttribute(caller:getRoomNumber() - 1, "redkey") and (not (room_position_in_row == 1))) or (caller:getRoomAttribute(caller:getRoomNumber() + caller:getColumnCount(), "redkey")) or (caller:getRoomAttribute(caller:getRoomNumber() - caller:getColumnCount(), "redkey")) then
			print("A deadly light?? questions you, but you couldn't say from where it comes from.")
		end
		if (caller:getRoomAttribute(caller:getRoomNumber() + 1, "sword") and (not (room_position_in_row == 0))) or (caller:getRoomAttribute(caller:getRoomNumber() - 1, "sword") and (not (room_position_in_row == 1))) or (caller:getRoomAttribute(caller:getRoomNumber() + caller:getColumnCount(), "sword")) or (caller:getRoomAttribute(caller:getRoomNumber() - caller:getColumnCount(), "sword")) then
			print("You briefly see a sharpened blade in a nearly room.")
		end
		if (caller:getRoomAttribute(caller:getRoomNumber() + 1, "monster") and (not (room_position_in_row == 0))) or (caller:getRoomAttribute(caller:getRoomNumber() - 1, "monster") and (not (room_position_in_row == 1))) or (caller:getRoomAttribute(caller:getRoomNumber() + caller:getColumnCount(), "monster")) or (caller:getRoomAttribute(caller:getRoomNumber() - caller:getColumnCount(), "monster")) then
			print("A terrifying scream chills your blood, but it is so powerful you can't tell where does it come from.")
		end
		if (caller:getRoomAttribute(caller:getRoomNumber() + 1, "exit") and (not (room_position_in_row == 0))) or (caller:getRoomAttribute(caller:getRoomNumber() - 1, "exit") and (not (room_position_in_row == 1))) or (caller:getRoomAttribute(caller:getRoomNumber() + caller:getColumnCount(), "exit")) or (caller:getRoomAttribute(caller:getRoomNumber() - caller:getColumnCount(), "exit")) then
			print("You hear the storm, then see a sunbeam! The exit is near this room...")
		end
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
				io.write(", so you open the grave's exit, located at the ")
				self:setAttribute("deadlygrave", false)
			else
				is_ended = true
				print("You DIE.\nYou could've exit if you had the ")
				if (self:getAttribute("keyneeded") == "key") then
					io.write("key")
				elseif (self:getAttribute("keyneeded") == "redkey") then
					io.write("red key")
				else
					io.write("EXCEPTION.UNKNOWN_KEY_VALUE: " .. self:getAttribute("keyneeded") .. " AT LINE #XX")
				end
				io.write(" of the exit located at the ")
			end
			print(cardinals[self:getAttribute("exitdir")] .. ".")
			if self:getAttribute("exitdir") == "up" then
				caller:setAttribute(caller:getRoomNumber() - caller:getColumnCount(), "down", true)
			elseif self:getAttribute("exitdir") == "down" then
				caller:setAttribute(caller:getRoomNumber() + caller:getColumnCount(), "up", true)
			elseif self:getAttribute("exitdir") == "left" then
				caller:setAttribute(caller:getRoomNumber() - 1, "right", true)
			elseif self:getAttribute("exitdir") == "right" then
				caller:setAttribute(caller:getRoomNumber() + 1, "left", true)
			else
				print("EXCEPTION.UNKNOWN_EXIT_DIR: " .. self:getAttribute("exitdir") .. " AT LINE #XXX")
			end
		end
		if self:getAttribute("graveorig") then
			io.write("After having walked across stairs, you see a room filled with skeletons.\nA grid is located on the ground and leads to another room.\nDo you want to continue and go donwstairs or go backwards ? (O / o / Y / y means go downstairs, everything else means go back): ")
			self:setAttribute("saw", true)
			local resultat = io.read()
			if (resultat == 'O') or (resultat == 'o') or (resultat == 'Y') or (resultat == 'y') then
				self:setRoom(caller:getRoomNumber() - 1)
				return self:checkLevelEvents(is_ended, objects)
			else
				self:restoreRoom()
				return self:checkLevelEvents(is_ended, objects)
			end
		end
	end
	return {is_ended, objects}
end
