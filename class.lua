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
	c._abstract = false
	
	-- constructor (class metatable)
	local mt = {}
	mt.__call = function (class_tbl, ...)
		local obj = {} -- the new class instance
		
		setmetatable(obj, c)
		
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
	
	c.__implementAbstract = function(clss, methodName, func)
		clss[methodName] = func
	end
	
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

-- Abstract class
function abst_class(init, base)
	local c = {} -- the class table
	
	if type(base) == 'table' then
		for k, v in pairs(base) do
			c[k] = v
		end
		
		c._base = base
	end
	
	c.__index = c
	c._abstract = true
	
	-- constructor (class metatable)
	local mt = {}
	mt.__call = function (class_tbl, ...)
		local obj = {} -- the new class instance
		
		setmetatable(obj, c)
		
		class_tbl.__init(obj, ...)
		
		return obj
	end
	
	if init then c.__init = init
	elseif not init and base then c.__init = base.__init end
	
	c.__oinit = c.__init
	c.__init = function(obj, ...)
		if getmetatable(obj)._abstract then
			error("Cannot instanciate an abstract class")
		end
		
		if init then
			init(obj, ...)
		elseif c.__oinit then
			c.__oinit(obj, ...)
		elseif base and base.__init then
			base.init(obj, ...)
		end
	end
	
	c.__implementAbstract = function(clss, methodName, func)
		clss[methodName] = func
	end
	c.__addAbstract = function(clss, methodName, msg)
		clss[methodName] = abst_method(msg)
	end
	
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

-- Abstract method
function abst_method(msg)
	return function(...)
		if msg then
			error("Unimplemented abstract function (" .. msg .. ")")
		else
			error("Unimplemented abstract function")
		end
	end
end

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
