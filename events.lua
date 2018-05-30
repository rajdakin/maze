import_prefix = ...
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") else import_prefix = "" end

local utilmodule = require(import_prefix .. "util")

local classmodule = require(import_prefix .. "class")

local Event = class(function(self, mainid, subid)
	self.__id = mainid
	self.__subid = subid
end)

function Event:iskind(clss)
	inst = clss()
	
	if inst.__id then
		if inst.__subid then return (inst.__id == self.__id) and (inst.__subid == self.__subid)
		elseif inst.__subids then return inst.isinst(self)
		else return inst.__id == self.__id
		end
	end
end

local EventParsingReturn = class(function(self, id, is_ended, objects)
	Event.__init(self, 0, id)
	self.ended = is_ended
	self.objects = objects
end, Event)

EventParsingReturnEnded = class(function(self, reason)
	EventParsingReturn.__init(self, -1)
	self.reason = reason
end, EventParsingReturn)
EventParsingReturnDone = class(function(self, objects)
	EventParsingReturn.__init(self, 0, false, objects)
end, EventParsingReturn)
EventParsingReturnExited = class(function(self, death)
	EventParsingReturn.__init(self, 1, true)
	self.dead = death
end, EventParsingReturn)
EventParsingReturnRoomChanging = class(function(self, new_room_position, objects)
	EventParsingReturn.__init(self, 2, false, objects)
	self.room = new_room_position
end, EventParsingReturn)
EventParsingReturnRoomRestore = class(function(self, objects)
	EventParsingReturn.__init(self, 3, false, objects)
end, EventParsingReturn)
