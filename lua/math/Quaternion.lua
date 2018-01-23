local Vec3 = require("Vector3")

local Quaternion = {CLASS = "Quaternion"}
Quaternion.__index = Quaternion

function Quaternion:create(x,y,z,w)
	local instance = {}
	setmetatable(instance,self)
	self.__index = self

	if type(x) == "table" and x.CLASS == "Vector3" then
		instance.v = x
		instance.w = y
		return instance
	end
	if 	type(x) == "number" and 
		type(y) == "number" and
		type(z) == "number" and
		type(w) == "number" then
		instance.v = Vec3:create(x,y,z)
		instance.w = w
		return instance
	end

	instance.v = Vec3:create(0,0,0)
	instance.w = 0
	return instance;
end

function Quaternion:createFrom4Vecs(_abc_o,_pqr_o,_abc,_pqr)
	-- give 4 vectors, rotation from the from the first two to last two
	local abc = _abc:nor()
	local pqr = _pqr:nor()
	local abc_o = _abc_o:nor()
	local pqr_o = _pqr_o:nor()

	local axis = (abc-abc_o) * (pqr - pqr_o)
	axis = axis:nor()

	local rot_o = abc_o - axis ^ abc * axis
	local rot_d = abc - axis ^ abc * axis
	rot_o = rot_o:nor()
	rot_d = rot_d:nor()
	local cos = rot_o ^ rot_d
	axis = rot_o * rot_d
	local th = math.acos(cos)

	local quater = self:createFromRotation(axis,th)
	return quater
end

function Quaternion:createFromRotation(x,y,z,th)
	local halfth
	local v
	if type(x) == "table" and x.CLASS == "Vector3" then
		halfth = y / 2
		v = x / x:len()
		v = x:nor()
		return self:create(v * math.sin(halfth),math.cos(halfth))
	end
	if 	type(x) == "number" and 
		type(y) == "number" and
		type(z) == "number" and
		type(th) == "number" then
		halfth = th / 2
		v = Vec3:create(x,y,z)
		v = v:nor()
		return self:create(v * math.sin(halfth),math.cos(halfth))
	end
	return self:create(0,0,0,0)
end

function Quaternion.__add(a,b)
	return Quaternion:create(a.v + b.v,a.w + b.w)
end

function Quaternion.__unm(b)
	return Quaternion:create(-b.v,-b.w)
end

function Quaternion.__sub(a,b)
	local c = -b
	return a + c 
end

function Quaternion.__mul(a,b)
	local tv = a.v * b.v + a.w * b.v + a.v * b.w
	local tw = a.w * b.w - a.v ^ b.v
	return Quaternion:create(tv,tw)
end

function Quaternion:squlen()
	return self.v:squlen() + self.w * self.w
end

function Quaternion:len()
	return math.sqrt(self:squlen())
end

--inverse
function Quaternion:inv()
	if self:len() ~= 0 then
		return Quaternion:create(-self.v/self:len(),self.w/self:len())
	end
	return Quaternion:create(0,0,0,0)
end

function Quaternion:__tostring()
	local c = "(" .. "(" .. self.v.x .. "," .. self.v.y .. "," .. self.v.z .. ")"
	c = c .. "," .. self.w .. ")"
	return c
end

-- returns a vector, is a is not a vector, returns a whatever it is
function Quaternion:toRotate(a)
	if type(a) == "table" and a.CLASS == "Vector3" then
		---[[
		local p = Quaternion:create(a,0)
		local res = self * p
		res = res * self:inv()
		local b = Vec3:create(res.v)
		--]]
		return b
	else
		print("In Quaternion:toRotate, para not a Vector3")
		return a
	end
end

return Quaternion
--function Quaternion
