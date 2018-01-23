local Vector3 = {CLASS = "Vector3"}
Vector3.__index = Vector3

function Vector3:create(x,y,z)
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
		--the metatable of instance would be whoever owns this create
	      --so you can :  a = State:create();  b = a:create();  grandfather-father-son

	-- Asserts and add data
	if type(x) == "table" and x.CLASS == "Vector3" then
		instance.x = x.x
		instance.y = x.y
		instance.z = x.z
		return instance
	end
	if 	type(x) == "number" and
		type(y) == "number" and
		type(z) == "number" then
		instance.x = x
		instance.y = y
		instance.z = z
		return instance
	end

	if 	type(x) == "nil" and
		type(y) == "nil" and
		type(z) == "nil" then
		instance.x = 0
		instance.y = 0
		instance.z = 0
		return instance
	end
	
	-- If invalid, return (0,0,0)
		-- ? or just return nil ?
	print("Vector3 create invalid")
	instance.x = 0
	instance.y = 0
	instance.z = 0
	return instance
end

-------------------------------------------------------------------------
-- every operator below should not change the parameters, like a:nor() return a new Vector
-- for example if b = a:nor(), then a remains the same and b is a's normalization
-- rotation is also like this

-- c = a + b
function Vector3.__add(a,b)
	if 	type(a) == "table" and a.CLASS == "Vector3" and
		type(b) == "table" and b.CLASS == "Vector3" then
		local c = Vector3:create()
		c.x = a.x + b.x
		c.y = a.y + b.y
		c.z = a.z + b.z
		return c
	end
	return Vector3:create()
end

function Vector3.__unm(b)
	local c = Vector3:create(-b.x,-b.y,-b.z)
	return c
end

function Vector3.__sub(a,b)
	local c = Vector3:create(-b.x,-b.y,-b.z)
	c = c + a
	return c
end

-- the result of * is a Vector, cross multi of Vectors, or number multi like 5 * a
	-- for productive multi, see __pow
function Vector3.__mul(a,b)
	if 	type(a) == "table" and a.CLASS == "Vector3" and
		type(b) == "table" and b.CLASS == "Vector3" then
		local c = Vector3:create(	a.y * b.z - a.z * b.y,
									a.z * b.x - a.x * b.z,
									a.x * b.y - a.y * b.x
								)
		return c
	end
	if type(b) == "number" then
		local c = Vector3:create(a.x * b, a.y * b, a.z * b)
		return c
	end
	if type(a) == "number" then
		local c = Vector3:create(b.x * a, b.y * a, b.z * a)
		return c
	end
	return Vector3:create()
end

function Vector3.__div(a,b)
	if type(b) == "number" and b ~= 0 then
		return a * (1/b)
	end
	return Vector3:create()
end

-- the result of ^ is a number : productive multi, you can write a ^ a, or a ^ 2
function Vector3.__pow(a,b)
	if type(b) == "number" then
		if b == 2 then
			local c = a ^ a
			return c
		else
			print("In Vector__pow:it doesn't mean anything")
			return nil
		end
	end
	if type(b) == "table" and b.CLASS == "Vector3" then
		return a.x * b.x + a.y * b.y + a.z * b.z
	end
	return Vector3:create()
end

function Vector3.__eq(a,b)
	return a.x == b.x and a.y == b.y and a.z == b.z
end

--function Vector3.__lt(a,b)  <
--function Vector3.__le(a,b)  <=

-- remember to use : rather than .
-- actually it is the same as a ^ a or a ^ 2
function Vector3:squlen()
	return self.x * self.x + self.y * self.y + self.z * self.z
end

function Vector3:len()
	return math.sqrt(self:squlen())
end

-- Normalize to len == 1
function Vector3:nor()
	--return Vector3:create(self.x / self:len(), self.y / self:len(), self.z / self:len())
	return Vector3:create(self/self:len())
end
--function normalize
--function angle axis

function Vector3:__tostring()
	return "(" .. self.x .. "," .. self.y .. "," .. self.z .. ")"
end

-- need to require Quaternion to use this:
	-- should create a new Vector, don't change the self
function Vector3:rotatedby(q)
	if type(q) == "table" and q.CLASS == "Quaternion" then
		--self = Vec3:create(q:toRotate(self))
		return q:toRotate(self)
	else
		print("In Vector3:rotate, para not a Quaternion")
		return Vector3:create()
	end
end


return Vector3
