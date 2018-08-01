cardinals = {}
cardinals["up"] = "north"
cardinals["down"] = "south"
cardinals["left"] = "east"
cardinals["right"] = "west"

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
