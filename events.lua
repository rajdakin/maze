local args = {...}
import_prefix = args[1]
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
		elseif inst.__subids then return (inst.__subids[self.__subid] ~= nil)
		else return inst.__id == self.__id
		end
	end
end

EventParsingResult = class(function(self, id, is_ended, objects)
	Event.__init(self, 0, id)
	self.ended = is_ended
	self.objects = objects
end, Event)

-- 0 is definite
eventParsingResultEndedReasons = {[-1] = "Internal error", [0] = "User request"}

EventParsingResultEnded = class(function(self, reasonId, reason_registering_string)
	EventParsingResult.__init(self, -1)
	self.reasonId = reasonId
	if reasonId then
		if not eventParsingResultEndedReasons[reasonId] then eventParsingResultEndedReasons[reasonId] = reason_registring_string end
		self.reason = eventParsingResultEndedReasons[reasonId]
	end
end, EventParsingResult)
EventParsingResultDone = class(function(self, objects)
	EventParsingResult.__init(self, 0, false, objects)
end, EventParsingResult)
EventParsingResultExited = class(function(self, death, objects)
	EventParsingResult.__init(self, 1, true, objects)
	self.dead = death
end, EventParsingResult)
EventParsingResultRoomChanging = class(function(self, new_room_position, objects)
	EventParsingResult.__init(self, 2, false, objects)
	self.room = new_room_position
end, EventParsingResult)
EventParsingResultRoomRestore = class(function(self, objects)
	EventParsingResult.__init(self, 3, false, objects)
end, EventParsingResult)


RoomPrintingResult = class(function(self, id)
	Event.__init(self, 1, id)
end, Event)

roomPrintingErrorSubIDs = {}
RoomPrintingError = class(function(self, id)
	if id then roomPrintingErrorSubIDs[id] = true end
	self.__subids = roomPrintingErrorSubIDs
end, RoomPrintingResult)
roomPrintingSuccessSubIDs = {}
RoomPrintingSuccess = class(function(self, id)
	roomPrintingSuccessSubIDs[id] = true
	self.__subids = roomPrintingSuccessSubIDs
end, RoomPrintingResult)

RoomPrintingErrorMalformedCall = class(function(self, reason)
	RoomPrintingError.__init(self, -1)
	if reason then self.reason = reason else self.reason = "" end
end, RoomPrintingError)
RoomPrintingDone = class(function(self)
	RoomPrintingSuccess.__init(self, 0)
end, RoomPrintingSuccess)


LevelInitializingResult = class(function(self)
	Event.__init(self, 2, nil)
end, Event)

levelInitializingErrorSubIDs = {}
LevelInitializingError = class(function(self, id)
	LevelInitializingResult.__init(self)
	levelInitializingErrorSubIDs[id] = true
	self.__subids = levelInitializingErrorSubIDs
end, LevelInitializingResult)
levelInitializingSuccessSubIDs = {}
LevelInitializingSuccess = class(function(self, id)
	LevelInitializingResult.__init(self)
	levelInitializingSuccessSubIDs[id] = true
	self.__subids = levelInitializingSuccessSubIDs
end, LevelInitializingResult)

LevelInitializingErrored = class(function(self, reason)
	LevelInitializingError.__init(self, -1)
	if reason then self.reason = reason else self.reason = "" end
end, LevelInitializingError)
LevelInitializingDone = class(function(self)
	LevelInitializingSuccess.__init(self, 1)
end, LevelInitializingSuccess)
LevelInitializingWarn = class(function(self, reason)
	LevelInitializingSuccess.__init(self, 2)
end, LevelInitializingSuccess)


LevelPrintingResult = class(function(self)
	Event.__init(self, 3, nil)
end, Event)

levelPrintingErrorSubIDs = {}
LevelPrintingError = class(function(self, id)
	LevelPrintingResult.__init(self)
	levelPrintingErrorSubIDs[id] = true
	self.__subids = levelPrintingErrorSubIDs
end, LevelPrintingResult)
levelPrintingSuccessSubIDs = {}
LevelPrintingSuccess = class(function(self, id)
	LevelPrintingResult.__init(self)
	levelPrintingSuccessSubIDs[id] = true
	self.__subids = levelPrintingSuccessSubIDs
end, LevelPrintingResult)

LevelPrintingErrored = class(function(self, reason)
	LevelPrintingError.__init(self, -1)
	if reason then self.reason = reason else self.reason = "" end
end, LevelPrintingError)
LevelPrintingDone = class(function(self)
	LevelPrintingSuccess.__init(self, 1)
end, LevelPrintingSuccess)

--EventParsingResult.__init = nil
--RoomPrintingResult.__init = nil
--LevelInitializingResult.__init = nil
--LevelPrintingResult.__init = nil
