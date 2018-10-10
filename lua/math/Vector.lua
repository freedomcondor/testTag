local Vector = {CLASS = "Vector"}
Vector.__index = Vector

function Vector:create(x,y)
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
		--the metatable of instance would be whoever owns this create
	      --so you can :  a = State:create();  b = a:create();  grandfather-father-son

	-- Asserts and add data
	if type(x) == "table" and x.CLASS == "Vector" then
		for i = 1,x.n do
			instance[i] = x[i]
		end
		instance.n = x.n
		return instance
	end
	if type(x) == "table" and x.CLASS ~= "Vector" then
		local n = nil
		for i,v in ipairs(x) do
			n = i
			instance[i] = v
		end
		instance.n = n
		return instance
	end

	if 	type(x) == "number" then
		instance.n = x
		local temp = y or {}
		for i = 1,x do
			instance[i] = temp[i] or 0
		end
		return instance
	end
	
	-- If invalid, return (0,0,0)
		-- ? or just return nil ?
	print("Vector create invalid")

	return instance
end

-------------------------------------------------------------------------
-- every operator below should not change the parameters, like a:nor() return a new Vector
-- for example if b = a:nor(), then a remains the same and b is a's normalization
-- rotation is also like this

-- c = a + b
function Vector.__add(a,b)
	if 	type(a) == "table" and a.CLASS == "Vector" and
		type(b) == "table" and b.CLASS == "Vector" then
		if a.n ~= b.n then
			print("in vector + : different dimension")
			return nil
		end
		local c = Vector:create(a.n)
		for i = 1,a.n do
			c[i] = a[i] + b[i]
		end
		return c
	end
	return Vector:create()
end

function Vector.__unm(b)
	-- assert?
	local c = Vector:create(b.n)
	for i = 1,b.n do
		c[i] = -b[i]
	end
	return c
end

function Vector.__sub(a,b)
	local c = Vector:create(-b)
	c = c + a
	return c
end

-- the result of * is a Vector, cross multi of Vectors, or number multi like 5 * a
	-- for productive multi, see __pow
function Vector.__mul(a,b)
	if 	type(a) == "table" and a.CLASS == "Vector" and
		type(b) == "table" and b.CLASS == "Vector" and
		a.n == 3 and b.n == 3	then
		local c = Vector:create{	a[2] * b[3] - a[3] * b[2],
									a[3] * b[1] - a[1] * b[3],
									a[1] * b[2] - a[2] * b[1],
								}
		return c
	end
	if type(b) == "number" then
		local c = Vector:create(a.n)
		for i = 1,a.n do
			c[i] = a[i] * b
		end
		return c
	end
	if type(a) == "number" then
		local c = Vector:create(b.n)
		for i = 1,b.n do
			c[i] = a * b[i]
		end
		return c
	end

	print("in vector * : makes no sense")

	return nil
end

function Vector.__div(a,b)
	if type(b) == "number" and b ~= 0 then
		return a * (1/b)
	end
	print("in vector / : makes no sense")
	return nil
end

-- the result of ^ is a number : productive multi, you can write a ^ a, or a ^ 2
function Vector.__pow(a,b)
	if type(b) == "number" then
		if b == 2 then
			local c = a ^ a
			return c
		else
			print("In Vector__pow:it doesn't mean anything")
			return nil
		end
	end
	if 	type(a) == "table" and a.CLASS == "Vector" and
		type(b) == "table" and b.CLASS == "Vector" and
											a.n == b.n then
		local c = 0
		for i = 1, a.n do
			c = c + a[i] * b[i]
		end
		
		return c
	end
	print("in vector ^ : makes no sense")
	return nil
end

function Vector.__eq(a,b)
	if 	type(a) == "table" and a.CLASS == "Vector" and
		type(b) == "table" and b.CLASS == "Vector" and
											a.n == b.n then
		local c = true
		for i = 1, a.n do
			if a[i] ~= b[i] then
				c = false
				return false
			end
		end
		return c
	else
		return false
	end
end

--function Vector.__lt(a,b)  <
--function Vector.__le(a,b)  <=

-- remember to use : rather than .
-- actually it is the same as a ^ a or a ^ 2
function Vector:squlen()
	local c = 0
	for i = 1, self.n do
		c = c + self[i] * self[i]
	end
	return c
end

function Vector:len()
	return math.sqrt(self:squlen())
end

-- Normalize to len == 1
function Vector:nor()
	--return Vector:create(self.x / self:len(), self.y / self:len(), self.z / self:len())
	return Vector:create(self/self:len())
end
--function normalize
--function angle axis

function Vector:__tostring()
	local c = "("
	for i = 1, self.n-1 do
		c = c .. self[i] .. ","
	end
	c = c .. self[self.n] .. "),n="
	c = c .. self.n

	return c
end

-- need to require Quaternion to use this:
	-- should create a new Vector, don't change the self
--[[
function Vector:rotatedby(q)
	if type(q) == "table" and q.CLASS == "Quaternion" then
		--self = Vec3:create(q:toRotate(self))
		return q:toRotate(self)
	else
		print("In Vector:rotate, para not a Quaternion")
		return Vector:create()
	end
end
--]]

return Vector
