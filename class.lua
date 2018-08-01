-- Source from http://lua-users.org/wiki/SimpleLuaClasses

function class(init, base)
	local c = {} -- the class table
	
	if type(base) == 'table' then
		for k, v in pairs(base) do
			c[k] = v
		end
		
		c._base = base
	end
	
	c.__index = c
	
	-- constructor (class metatable)
	local mt = {}
	mt.__call = function (class_tbl, ...)
		local obj = {} -- the new class instance
		
		setmetatable(obj, c)
		
		local ret
		if init then
			init(obj, ...)
		elseif class_tbl.__init then
			class_tbl.__init(obj, ...)
		elseif base and base.__init then
			base.init(obj, ...)
		end
		
		return obj
	end
	
	if init then c.__init = init
	elseif not init and base then c.__init = base.__init end
	
	c.isinstance = function(self, clss)
		local m = getmetatable(self)
		while m do
			if m == clss then return true end
			m = m._base
		end
		return false
	end
	
	setmetatable(c, mt)
	
	return c
end

---- End

function enum(init, base, instances)
	local c = {} -- the class table
	
	if type(base) == 'table' then
		for k, v in pairs(base)
		do
			c[k] = v
		end
		
		c._base = base
	end
	
	c.__index = c
	
	-- constructor (class metatable)
	local mt = {}
	instanciate = function (class_tbl, name, ...)
		local obj = {} -- the new class instance
		
		setmetatable(obj, c)
		
		if init then
			init(obj, name, ...)
		elseif class_tbl.__init then
			class_tbl.__init(obj, name, ...)
		elseif base and base.__init then
			base.init(obj, name, ...)
		end
		
		return obj
	end
	
	if init then c.__init = init
	elseif not init and base then c.__init = base.__init end
	
	c.isinstance = function(self, clss)
		local m = getmetatable(self)
		while m do
			if m == clss then return true end
			m = m._base
		end
		return false
	end
	
	setmetatable(c, mt)
	
	for k, v in pairs(instances) do
		c[k] = instanciate(c, k, v)
	end
	
	return c
end
