cardinals = {}
cardinals["up"] = "north"
cardinals["down"] = "south"
cardinals["left"] = "east"
cardinals["right"] = "west"

require("class")

function sleep(s)
	local t0 = os.clock()
	while os.clock() - t0 <= s do end
end
function longsleep(s)
	local t0 = os.time()
	while os.time() - t0 <= s do end
end

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
function floor(a) return math.floor(a) end

function random(max) return math.random(max) end
function coinFlip() return random(2) == 2 end
function falseCoin(percent) return random(100) <= percent end

Watch = class(function()
	self.start = os.time()
end)

function Watch:watch()
	return os.time() - self.start
end

function Watch:stop()
	if not self.stop then self.stop = os.time() end
	return self.stop - self.start
end
