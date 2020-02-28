local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = (import_prefix):match("(.-)[^%.]+$") end
if not import_prefix then import_prefix = "" end

cardinals = {}
cardinals["up"] = "north"
cardinals["down"] = "south"
cardinals["left"] = "east"
cardinals["right"] = "west"

local classmodule = require(import_prefix .. "class")

--[[
	sleep - wait for s seconds. Inefficient for s > 2.
	longsleep - wait for s second. Inefficient for short periods.
]]
function sleep(s)
	local t0 = os.clock()
	while os.clock() - t0 <= s do end
end
function longsleep(s)
	local t0 = os.time()
	while os.time() - t0 <= s do end
end

-- getArrayLength - equivalent to #tbl but correct in all case (in case you are not entirely sure about #tbl)
function getArrayLength(tbl)
	local count = 0
	for _ in pairs(tbl) do
		count = count + 1
	end
	return count
end

function min(a, b) if a < b then return a else return b end end
function max(a, b) if a < b then return b else return a end end

local mathmodule = require("math")
inf = math.huge
function abs  (a) return math.abs  (a) end
function floor(a) return math.floor(a) end

--[[
	random - return a random integer from 1 to max
	coinFlip - randomly return true or false
	falseCoin - randomly return true or false, with true having percent% chance to be outputed
]]
function random(max) return math.random(max) end
function coinFlip() return random(2) == 2 end
function falseCoin(percent) return random(100) <= percent end

--[[ Watch - the watch class
	Holds a starting time and can be used to get a period
]]
Watch = class(function(self)
	self.start = os.time()
end)

-- watch - returns the time since initialization
function Watch:watch()
	return os.time() - self.start
end

-- stop - stop the watch if not already stopped then return the period from the start to stop
function Watch:stop()
	if not self.stop then self.stop = os.time() end
	return self.stop - self.start
end
