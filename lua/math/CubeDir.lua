Vec3 = require("Vector3")
local CubeDir = {CLASS = "CubeDir"}
CubeDir.__index = CubeDir

function CubeDir:create(d1,d2,d3,d4,d5,d6)
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
		--the metatable of instance would be whoever owns this create
	      --so you can :  a = State:create();  b = a:create();  grandfather-father-son

	-- Asserts and add data
	if type(d1) == "table" and d1.CLASS == "CubeDir" then
		instance[1] = Vec3:create(d1[1]):nor()
		instance[2] = Vec3:create(d1[2]):nor()
		instance[3] = Vec3:create(d1[3]):nor()
		instance[4] = Vec3:create(d1[4]):nor()
		instance[5] = Vec3:create(d1[5]):nor()
		instance[6] = Vec3:create(d1[6]):nor()
		return instance
	end
	if type(d1) == "table" and d1.CLASS == "Vector3" and
	   type(d2) == "table" and d2.CLASS == "Vector3" and
	   type(d3) == "table" and d3.CLASS == "Vector3" and
	   type(d4) == "table" and d4.CLASS == "Vector3" and
	   type(d5) == "table" and d5.CLASS == "Vector3" and
	   type(d6) == "table" and d6.CLASS == "Vector3" then
		instance[1] = Vec3:create(d1):nor()
		instance[2] = Vec3:create(d2):nor()
		instance[3] = Vec3:create(d3):nor()
		instance[4] = Vec3:create(d4):nor()
		instance[5] = Vec3:create(d5):nor()
		instance[6] = Vec3:create(d6):nor()
		return instance
	end

	if 	type(d1) == "nil" and
		type(d2) == "nil" and
		type(d3) == "nil" and
		type(d4) == "nil" and
		type(d5) == "nil" and
		type(d6) == "nil" then
		instance[1] = Vec3:create(1,0,0)
		instance[2] = Vec3:create(-1,0,0)
		instance[3] = Vec3:create(0,1,0)
		instance[4] = Vec3:create(0,-1,0)
		instance[5] = Vec3:create(0,0,1)
		instance[6] = Vec3:create(0,0,-1)
		return instance
	end
	
	-- If invalid, return (0,0,0)
		-- ? or just return nil ?
	print("CubeDir create invalid")
	instance[1] = Vec3:create(1,0,0)
	instance[2] = Vec3:create(-1,0,0)
	instance[3] = Vec3:create(0,1,0)
	instance[4] = Vec3:create(0,-1,0)
	instance[5] = Vec3:create(0,0,1)
	instance[6] = Vec3:create(0,0,-1)
	return instance
end

-------------------------------------------------------------------------
-- every operator below should not change the parameters, like a:nor() return a new Vector
-- for example if b = a:nor(), then a remains the same and b is a's normalization
-- rotation is also like this

function CubeDir.__eq(a,b)
	-- here == means closeto, within a certain threshold is considered equal
	threshold = math.sin(math.pi/180*10)
	if type(a) == "table" and a.CLASS == "CubeDir" and
	   type(b) == "table" and b.CLASS == "CubeDir" then
	   	local max,dis
	   	for i = 1,6 do
			max = 2
			for j = 1,6 do
				dis = (a[i] - b[j]):len()
				if dis < max then
					max = dis
				end
			end
			if max > threshold then
				return false
			end
		end
		return true
	else
		return false
	end
end

--function CubeDir.__lt(a,b)  <
--function CubeDir.__le(a,b)  <=

-- remember to use : rather than .
-- actually it is the same as a ^ a or a ^ 2

function CubeDir:__tostring()
	return "(" 	.. self[1]:__tostring() .. ",\n " 
				.. self[2]:__tostring() .. ",\n " 
				.. self[3]:__tostring() .. ",\n " 
				.. self[4]:__tostring() .. ",\n " 
				.. self[5]:__tostring() .. ",\n " 
				.. self[6]:__tostring() .. " )\n" 
end

-- need to require Quaternion to use this:
	-- should create a new Vector, don't change the self
function CubeDir:rotatedby(q)
	if type(q) == "table" and q.CLASS == "Quaternion" then
		--self = Vec3:create(q:toRotate(self))
		local c = CubeDir:create(self)
		--local c = self:create(self)
		for i = 1,6 do
			c[i] = q:toRotate(self[i])
		end
		return c
	else
		print("In CubeDir:rotate, para not a Quaternion")
		return CubeDir:create()
	end
end

return CubeDir
