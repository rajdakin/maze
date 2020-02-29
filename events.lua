local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local classmodule = load_module(import_prefix .. "class", true)

--[[ Event - the events superclass
	
	mainid - event's type
	subid - event's subtype
]]
local Event = class(function(self, mainid, subid)
	self.__id = mainid
	self.__subid = subid
end)

function Event:iskind(clss)
	inst = clss()
	
	if inst.__id then
		if inst.__subid then return (inst.__id == self.__id) and (inst.__subid == self.__subid)
		elseif inst.__subids then return (inst.__id == self.__id) and inst.__subids[self.__subid]
		else return inst.__id == self.__id
		end
	end
end

--[[ EventParsingResult - room event parsing return type
	
	id - event subid
	is_ended - if the level is finished
	objects - the finishing objects
]]
EventParsingResult = class(function(self, id, is_ended, objects)
	Event.__init(self, 0, id)
	self.ended = is_ended
	self.objects = objects
end, Event)

-- 0 is definite
eventParsingResultEndedReasons = {[-1] = "Internal error", [0] = "User request"}

--[[
	EventParsingResultEnded - crashed due to reasonsStrings[reasonId] = reason_registering_string
	EventParsingResultDone - worked, no further details. objects -> finishing objects
	EventParsingResultExited - escaped. death -> has died, objects -> finishing objects
	EventParsingResultRoomChanging - changing room. new_room_position -> new room ID/relative position, objects -> finishing objects
	EventParsingResultRoomRestore - changing room to old room. objects -> finishing objects
]]
EventParsingResultEnded = class(function(self, reasonId, reason_registering_string)
	EventParsingResult.__init(self, -1, 0)
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
end, EventParsingResultRoomChanging)

--[[ RoomPrintingResult - room printing return type
	
	id - event subid
]]
RoomPrintingResult = class(function(self, id)
	Event.__init(self, 1, id)
end, Event)

--[[
	RoomPrintingError - error while printing room
	RoomPrintingSuccess - finished printing room
]]
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

--[[
	RoomPrintingErrorMalformedCall - error due to bad call to function: reason.
	RoomPrintingDone - finished.
]]
RoomPrintingErrorMalformedCall = class(function(self, reason)
	RoomPrintingError.__init(self, -1)
	if reason then self.reason = reason else self.reason = "" end
end, RoomPrintingError)
RoomPrintingDone = class(function(self)
	RoomPrintingSuccess.__init(self, 0)
end, RoomPrintingSuccess)

--[[ LevelPrintingResult - level printing return type
	
	id - event subid
]]
LevelPrintingResult = class(function(self, id)
	Event.__init(self, 2, id)
end, Event)

--[[
	LevelPrintingError - error while printing level
	LevelPrintingSuccess - finished printing level
]]
levelPrintingErrorSubIDs = {}
LevelPrintingError = class(function(self, id)
	LevelPrintingResult.__init(self, id)
	if id then levelPrintingErrorSubIDs[id] = true end
	self.__subids = levelPrintingErrorSubIDs
end, LevelPrintingResult)
levelPrintingSuccessSubIDs = {}
LevelPrintingSuccess = class(function(self, id)
	LevelPrintingResult.__init(self, id)
	if id then levelPrintingSuccessSubIDs[id] = true end
	self.__subids = levelPrintingSuccessSubIDs
end, LevelPrintingResult)

--[[
	LevelPrintingErrored - error: reason.
	LevelPrintingDone - finished.
	LevelPrintingIgnored - ignored due to bad configuration state.
]]
LevelPrintingErrored = class(function(self, reason)
	LevelPrintingError.__init(self, -1)
	if reason then self.reason = reason else self.reason = "" end
end, LevelPrintingError)
LevelPrintingDone = class(function(self)
	LevelPrintingSuccess.__init(self, 1)
end, LevelPrintingSuccess)
LevelPrintingIgnored = class(function(self)
	LevelPrintingSuccess.__init(self, 2)
end, LevelPrintingSuccess)

--EventParsingResult.__init = nil
--RoomPrintingResult.__init = nil
--LevelPrintingResult.__init = nil
