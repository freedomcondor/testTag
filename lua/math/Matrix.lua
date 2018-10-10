--------------------------------------------------------------------
--	Weixu ZHU (Harry)
--		zhuweixu_harry@126.com
--	Version: 1.1
--		fixed: Matrix link
--		added: Matrix reverse
--------------------------------------------------------------------
Vec = require("Vector")
local Matrix = {CLASS = "Matrix"}
Matrix.__index = Matrix

function Matrix:create(x,y,z)
	local instance = {}
	setmetatable(instance, self)
	self.__index = self

		--the metatable of instance would be whoever owns this create
			--so you can :  a = State:create();  b = a:create();  grandfather-father-son
	
	-- Asserts
	-- to be filled
		--[[			m
					-------------
				n	|			|
					|			|
					-------------

		--]] 

	-- (<a matrix>)
	if type(x) == "table" and x.CLASS == "Matrix" then
		instance.n = x.n	
		instance.m = x.m
		for i = 1,instance.n do
			instance[i] = {}
			for j = 1,instance.m do
				instance[i][j] = x[i][j] or 0
			end
		end
		return instance
	end

	-- (n,m,{})  give {}, if {} is nil, give 0
	if type(x) == "number" and type(y) == "number" then
		instance.n = x
		instance.m = y
		local temp = z or {}
		for i = 1,instance.n do
			instance[i] = {}
			local temp1 = temp[i] or {}
			for j = 1,instance.m do
				if z == "I" and i == j then
					instance[i][j] = 1
				else
					instance[i][j] = temp1[j] or 0
				end
			end
		end
		return instance
	end

	-- ( {{},{}} ) 
	if type(x) == "table" and type(x[1]) == "table" then
		local n = 0
		local m = 0
		for i,vi in ipairs(x) do
			n = i
			local mm = 0
			for j,vj in ipairs(vi) do
				mm = j
			end
			if mm > m then m = mm end
		end
		instance.n = n
		instance.m = m

		for i = 1,instance.n do
			instance[i] = {}
			for j = 1,instance.m do
				instance[i][j] = x[i][j] or 0
			end
		end
		return instance
	end
	
	print("matrix create: makes no sence")
	return nil
end

function Matrix.__add(a,b)
	if a.n ~= b.n or a.m ~= b.m then
		print("in Matrix + : makes no sense")
		return nil
	end
	local c = Matrix:create(a.n,a.m)
	for i = 1,a.n do
		for j = 1,a.m do
			c[i][j] = a[i][j] + b[i][j]
		end
	end

	return c
end

function Matrix.__unm(b)
	local c = Matrix:create(b.n,b.m)
	for i = 1,b.n do
		for j = 1,b.m do
			c[i][j] = -b[i][j]
		end
	end

	return c
end

function Matrix.__sub(a,b)
	if a.n ~= b.n or a.m ~= b.m then
		print("in Matrix + : makes no sense")
		return nil
	end
	local c = Matrix:create(-b)
	c = c + a

	return c
end

function Matrix.__mul(a,b)
	-- Matrix meet Vector
	if 	type(a) == "table" and a.CLASS == "Matrix" and 
		type(b) == "table" and b.CLASS == "Vector" then
		if a.m ~= b.n then
			print("in Matrix * : makes no sense")
			return nil
		end

		-- a n * m matrix * a m vector = a n vector

		local c = Vec:create(a.n)
		for i = 1, a.n do
			c[i] = 0
			for j = 1, a.m do
				c[i] = c[i] + a[i][j] * b[j]
			end
		end
		return c
	end

	-- Vec meet Matrix
		-- it would never happen because it will fall into vector's __mul
	if type(a) == "table" and a.CLASS == "Vector" and 
		type(b) == "table" and b.CLASS == "Matrix" then
		print("this case")
		if a.n ~= b.n then
			print("in Matrix * : makes no sense")
			return nil
		end
		
		-- a n vector * a n * m vector = a m vector

		local c = Vec:create(b.m)
		for i = 1,b.m do
			c[0] = 0
			for j = 1, a.n do
				c[i] = c[i] + a[i] * b[j][i]
			end
		end

		return c
	end

	-- Matrix meet Matrix
	if type(a) == "table" and a.CLASS == "Matrix" and 
		type(b) == "table" and b.CLASS == "Matrix" then
		if a.m ~= b.n then
			print("in Matrix * : makes no sense")
			return nil
		end
		
		-- a  n x k vector * a k * m vector = n m vector

		local c = Matrix:create(a.n,b.m)
		for i = 1,a.n do
			for j = 1,b.m do
				c[i][j] = 0
				for k = 1,a.m do
					c[i][j] = c[i][j] + a[i][k] * b[k][j]
				end
			end
		end
		return c
	end

	-- number
		-- to be filled
	if type(a) == "number" then
		local c = Matrix:create(b)
		for i = 1,b.n do
			for j = 1,b.m do
				c[i][j] = b[i][j] * a
			end
		end
		return c
	end

	if type(b) == "number" then
		local c = Matrix:create(a)
		for i = 1,a.n do
			for j = 1,a.m do
				c[i][j] = a[i][j] * b
			end
		end
		return c
	end

	print("in matrix * : nothing happened")
	return nil
end

function Matrix.__eq(a,b)
	if a.n ~= b.n or a.m ~= b.m then
		return false
	end

	local T = true
	for i = 1,a.n do
		for j = 1,b.n do
			if a[i][j] ~= b[i][j] then
				T = false
				return false
			end
		end
	end

	return T
end

function Matrix:transpose()
	local c = Matrix:create(self.m,self.n)
	for i = 1, self.m do
		for j = 1, self.n do
			c[i][j] = self[j][i]
		end
	end

	return c
end

function Matrix:T()
	return self:transpose()
end

-- add vector
	-- a.addVec(<a vector>, 3, "column")  3 means addVec at row/column 3
function Matrix:addVector(x,y,z)
	return self:addVec(x,y,z)
end
function Matrix:addVec(x,y,z)
	if 	type(x) == "table" and x.CLASS == "Vector" and 
		type(y) == "number" then
		local c = Matrix:create(self)
		if z == "column" or z == "col" then
			c = c:T()
			c = c:addVec(x,y)
			c = c:T()
		else
			if x.n == self.m and y <= self.n then
				for i = 1, x.n do
					c[y][i] = c[y][i] + x[i]
				end
			else
				print("Matrix addVec: makes no sense")
				return nil
			end
		end
		return c
	end
	print("Matrix addVec: makes no sense")
	return nil
end

-- take vector
	-- a.takeVec(3, "column")  3 means take Vec at row/column 3 ,returns a vector
function Matrix:takeVector(y,z)
	return self:takeVec(y,z)
end
function Matrix:takeVec(y,z)
	if z == "column" or z == "col" then
		local temp = self:T()
		temp = temp:takeVec(y)
		return temp
	else
		if y <= self.n then
			return Vec:create(self[y])
		else
			print("Matrix takeVec: makes no sense")
			return nil
		end
	end
	print("Matrix takeVec: makes no sense")
	return nil
end

function Matrix:takeDia()
	return self:takeDiagonal()
end
function Matrix:takeDiagonal()
	local n
	if self.n > self.m then
		n = self.m
	else
		n = self.n
	end

	local c = Vec:create(n)
	for i = 1,n do
		c[i] = self[i][i]
	end
	return c
end

-- exchange row/col
function Matrix:exc(x,y,z)
	return self:exchange(x,y,z)
end
function Matrix:exchange(x,y,z)
	if z == "column" or z == "col" then
		local temp = self:T()
		temp = temp:exchange(x,y)
		return temp:T()
	end
	if type(x)~= "number" or x > self.n or
	   type(y)~= "number" or y > self.n then
	   	print("in Matrix exchange: index out of range")
		return nil
	end

	local c = Matrix:create(self)
	local v = c:takeVec(x)
	for j = 1,c.m do
		c[x][j] = c[y][j]
		c[y][j] = v[j]
	end
	return c
end

-- link Matrix   A:link(B,"col") = A|B
-- 				 A:link(B) = A
-- 				 			 B
function Matrix:link(y,z)
	local temp
	if z == "column" or z == "col" then
		if self.n == y.n then
			if type(y) == "table" and y.CLASS == "Vector" then
				temp = Matrix:create(y.n,1)
				temp = temp:addVec(y,1,"col")
			else
				temp = y
			end

			local c = Matrix:create(self)
			for i = 1, self.n do
				for j = 1, temp.m do
					c[i][j + c.m] = temp[i][j]
				end
			end
			c.m = c.m + temp.m
			return c
		else
			print("Matrix link : makes no sense code 1")
			return nil
		end
	else
		temp = self:T()
		local c = temp:link(y:T(),"column")
		return c:T()
	end
	print("Matrix link : makes no sense code 2")
	return nil
end

function almostZero(x,y)
	y = y or 5
	local t = x * (10^y)
	if -1 < t and t < 1 then
		return true
	else
		return false
	end
end

-- triangle
	--[[
		make a matrix looks like:
			* * * * *|* * * if m > n
			0 * * * *|
			0 0 * * *|
			0 0 0 * *|
			0 0 0 0 *|* * *
			---------+----
			0 0 0 0 0|
			0       0| 
			if n > m
	--]]
function Matrix:tri()
	return self:triangle()
end
function Matrix:triangle()
	-- should have a para to indicate threshold for almostZero 
		--triangle(thres)
		--	almostZero(xx,thres)
	local c = Matrix:create(self)
	local v
	local n
	if c.m > c.n then n = c.n
				 else n = c.m end
		-- stop at the min of m and n
			--if n > m, we should still stop at row m, not row n
	
	local excMark = Mat:create(self.n,1)
	for i = 1, self.n do excMark[i][1] = i end

	local success = true

	for i = 1, n do
		local flag = 1
		--if (c[i][i] == 0) then
		if almostZero(c[i][i]) then
			--print("a zero!")
			flag = 0
			for j = i+1, c.n do
				if almostZero(c[j][i]) == false then
				--if c[j][i] ~= 0 then
					c = c:exc(i,j)
					excMark = excMark:exc(i,j)
					flag = 1
					break
				end
			end
		end
		v = c:takeVec(i)
		if (flag == 1) then
			for j = i+1, c.n do
				c = c:addVec(-v * (c[j][i] / c[i][i]),j)
			end
		else
			success = false
		end
		--print("tri check, step",i,":",c)
	end

	--print(success)
	return c, excMark:takeVec(1,"col"), success
end

-- diagonal
	--[[
		make a matrix looks like:
			* 0 0 0 0|* * * if m > n
			0 * 0 0 0|
			0 0 * 0 0|
			0 0 0 * 0|
			0 0 0 0 *|* * *
			---------+----
			0 0 0 0 0|
			0       0| 
			if n > m
	--]]
function Matrix:dia()
	return self:diagonal()
end
function Matrix:diagonal()
	-- should have a para to indicate threshold for almostZero 
		--triangle(thres)
		--	almostZero(xx,thres)
	local c,excMark,success = self:triangle()
	local v
	local n

	local exctemp = Mat:create(self.n,1)
	excMark = exctemp:addVector(excMark,1,"col")

	if c.m > c.n then n = c.n
				 else n = c.m end
		-- stop at the min of m and n
			--if n > m, we should still stop at row m, not row n

	for ii = 1, n do
		local i = n + 1 - ii
		v = c:takeVec(i)
		for jj = 1, i-1 do
			local j = i - jj
			--if (c[i][i] ~= 0) then
			if almostZero(c[i][i]) == false then
				c = c:addVec(-v * (c[j][i] / c[i][i]),j)
			end
		end
	end
	return c,excMark:takeVector(1,"col"),success
end

-- |A|
function Matrix:A()
	return self:determinant()
end
function Matrix:determinant()
	local A = 0;
	A = A + self[1][1] * (self[2][2] * self[3][3] - self[2][3] * self[3][2])
	A = A + self[1][2] * (self[2][3] * self[3][1] - self[3][2] * self[2][1])
	A = A + self[1][3] * (self[2][1] * self[3][2] - self[2][2] * self[3][1])
	return A
end

function Matrix:unit()
	local c = Mat:create(self.n, self.m)
	local n = self.n
	if self.n > self.m then n = self.m end
	for i = 1, n do
		c[i][i] = 1
	end
	return c
end

function Matrix:reverse()
	if self.n ~= self.m then
		print("Matrix reverse make no sense!")
		return 0
	end
	local c = self:link(self:unit(),"col")
	c = c:diagonal()
	for i = 1, c.n do
		local temp = c[i][i]
		for j = 1, c.m do
			c[i][j] = c[i][j] / temp
		end
	end
	local d = Matrix:create(c.n,c.n)
	for i = 1, c.n do
		for j = 1, c.n do
			d[i][j] = c[i][j + c.n]
		end
	end
	return d
end

---------------------------------------  TO DO
-- to be filled:
-- function A*
-----------------------------------------------
function Matrix:__tostring()
	local str = "\t\n"
	for i = 1, self.n do
		if i == 1 then str = str .. "\t[[" else str = str .. "\t [" end
		for j = 1, self.m do
			---[[
			if self[i][j] % 1 ~= 0 then -- not a integer
				str = str .. string.format("%7.3f",self[i][j])-- .. "\t"
			else						-- a integer
				str = str .. string.format("%7d",self[i][j])-- .. "\t"
			end
			--]]
			--str = str .. self[i][j] .. '\t'
			--str = str .. string.format("%3e",self[i][j]) .. '\t'
			if j ~= self.m  then str = str .. ","
							else str = str .. "]" end
		end
		if i == self.n then str = str .. "]" else str = str .. " \n" end
	end
	local str = str .. " n = " .. self.n .. "," .. "m = " .. self.m .. "\n"

	return str
end

return Matrix
