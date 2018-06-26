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
		elseif inst.__subids then return (inst.__subids[self.__subid] ~= nil)
		else return inst.__id == self.__id
		end
	end
end

local EventParsingResult = class(function(self, id, is_ended, objects)
	Event.__init(self, 0, id)
	self.ended = is_ended
	self.objects = objects
end, Event)

-- 0 is definite
eventParsingResultEndedReasons = {[0] = "User request"}

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


local RoomPrintingResult = class(function(self, id)
	Event.__init(self, 1, id)
end, Event)

printingErrorSubIDs = {}
RoomPrintingError = class(function(self, id)
	if id then printingErrorSubIDs[id] = true end
	self.__subids = printingErrorSubIDs
end, RoomPrintingResult)
printingSuccessSubIDs = {}
RoomPrintingSuccess = class(function(self, id)
	printingSuccessSubIDs[id] = true
	self.__subids = printingSuccessSubIDs
end, RoomPrintingResult)

RoomPrintingErrorMalformedCall = class(function(self, reason)
	RoomPrintingError.__init(self, -1)
	if reason then self.reason = reason else self.reason = "No column to write in was passed as argument!" end
end, RoomPrintingError)
RoomPrintingDone = class(function(self)
	RoomPrintingSuccess.__init(self, 0)
end, RoomPrintingSuccess)

local LevelPrintingResult = class(function(self, id)
	Event.__init(self, 1, id)
end, Event)

printingErrorSubIDs = {}
LevelPrintingError = class(function(self, id)
	printingErrorSubIDs[id] = true
	self.__subids = printingErrorSubIDs
end, LevelPrintingResult)
printingSuccessSubIDs = {}
LevelPrintingSuccess = class(function(self, id)
	printingSuccessSubIDs[id] = true
	self.__subids = printingSuccessSubIDs
end, LevelPrintingResult)

LevelPrintingErrored = class(function(self, reason)
	LevelPrintingError.__init(self, -1)
	self.reason = reason
end, LevelPrintingError)
LevelPrintingDone = class(function(self)
	LevelPrintingSuccess.__init(self, 0)
end, LevelPrintingSuccess)
