local args = {...}
local import_prefix = args[1]
if import_prefix then import_prefix = import_prefix:match("^(.-)[^%.]+$") end
if not import_prefix then local_prefix = args[1] end

local errormodule = require(import_prefix .. "error")

local utilmodule = load_module(import_prefix .. "util", true)

local classmodule = load_module(import_prefix .. "class", true)

Map = class(function(self, level)
	self.__grid = {}
	self.__width = level:getColumnCount()
	self.__height = floor(level:getMapSize() / self.__width)
	
	local x, y
	for x = 1, self.__width do
		self.__grid[x] = {}

		for y = 1, self.__height do
			local room = level:getRoomFromCoordinates(x, y)

			self.__grid[x][y] = {
				up = room:hasAccess("up"),
				down = room:hasAccess("down"),
				left = room:hasAccess("left"),
				right = room:hasAccess("right")
			}
			if room:getAttribute("unreachable") or room:getAttribute("safezone") then
				self.__grid[x][y].weight = -1
			elseif room:getAttribute("trap") then
				self.__grid[x][y].weight = 4
			elseif room:getAttribute("monster") then
				self.__grid[x][y].weight = 2
			elseif room:getAttribute("redkey")
			 or room:getAttribute("reddoor") or room:getAttribute("reddoor_dir")
			 or room:getAttribute("graveyard") then
				self.__grid[x][y].weight = 0
			else
				self.__grid[x][y].weight = 1
			end
		end
	end
end)

--[[ Astar - an A* algorithm
	Uses the A* algorithm to create a path from point (xbeg, ybeg) to (xend, yend).
	Return nil or a table of {x: x, y: y} objects (representing the path)
]]
function Map:Astar(xbeg, ybeg, xend, yend)
	-- Invalid coords?
	if  (xbeg <= 0) or (xbeg > self.__width)
	 or (xend <= 0) or (xend > self.__width)
	 or (ybeg <= 0) or (ybeg > self.__height)
	 or (yend <= 0) or (yend > self.__height) then
		return nil
	end
	
	local x, y, path, node, nodes
	nodes = {}
	node = {}
	path = {
		--minCost  = {val = inf, col = xbeg},
		--minCost2 = {val = inf, col = 1},
	}
	for x = 1, self.__width do
		node[x] = {}
		path[x] = {
			--minCost = {val = inf, line = 1}
		}
		
		for y = 1, self.__height do
			path[x][y] = {
				gcost = inf,
				hcost = abs(x - xend) + abs(y - yend),
				visited = false,
				parent = nil
			}
			if (x == xend) and (y == yend) then
				path[x][y].gcost = 0
				--path[x].minCost = {val = path[x][y].hcost, line = y}
				--path.minCost.val = path[x].minCost.val
			end
			
			node[x][y] = {
				p = path[x][y],
				g = self.__grid[x][y],
				w = self.__grid[x][y].weight,
				x = x, y = y
			}
			
			table.insert(nodes, node[x][y])
		end
	end
	for x = 1, self.__width do
		for y = 1, self.__height do
			if y ~= 1                 then node[x][y].up    = node[x][y - 1]
			else node[x][y].up    = {p = {gcost = inf, hcost = inf}, g = {weight = 0}} end
			if y ~= self.__height then node[x][y].down  = node[x][y + 1]
			else node[x][y].down  = {p = {gcost = inf, hcost = inf}, g = {weight = 0}} end
			if x ~= 1                 then node[x][y].left  = node[x - 1][y]
			else node[x][y].left  = {p = {gcost = inf, hcost = inf}, g = {weight = 0}} end
			if x ~= self.__width  then node[x][y].right = node[x + 1][y]
			else node[x][y].right = {p = {gcost = inf, hcost = inf}, g = {weight = 0}} end
		end
	end
	
	local gcost
	table.sort(nodes, function(a, b) return a.p.gcost + a.p.hcost < b.p.gcost + b.p.hcost end)
	while nodes[1].gcost ~= inf do
		node = nodes[1]
		x = node.x
		y = node.y
		
		if (x == xbeg) and (y == ybeg) then
			local path = {{x = xbeg, y = ybeg}}
			while node.parent do
				node = node.parent
				table.insert(path, {x = node.x, y = node.y})
			end
			
			return path
		end
		
		node.p.visited = true
		
		-- xmin = path.minCost.val
		-- xmin2 = path.minCost2.val
		-- ymin = path[x].minCost.val
		
		if node.g.up and (node.up.w >= 0) and (node.up.p.gcost > node.p.gcost + node.up.w) then
			node.up.p.gcost = node.p.gcost + node.up.w
			node.up.parent = node
		end
		if node.g.down and (node.down.w >= 0) and (node.down.p.gcost > node.p.gcost + node.down.w) then
			node.down.p.gcost = node.p.gcost + node.down.w
			node.down.parent = node
		end
		if node.g.left and (node.left.w >= 0) and (node.left.p.gcost > node.p.gcost + node.left.w) then
			node.left.p.gcost = node.p.gcost + node.left.w
			node.left.parent = node
		end
		if node.g.right and (node.right.w >= 0) and (node.right.p.gcost > node.p.gcost + node.right.w) then
			node.right.p.gcost = node.p.gcost + node.right.w
			node.right.parent = node
		end
		
		nodes[1] = nodes[#nodes]
		table.remove(nodes)
		table.sort(nodes, function(a, b) return a.p.gcost + a.p.hcost < b.p.gcost + b.p.hcost end)
	end
	
	return nil
end
