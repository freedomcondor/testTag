--package.path = package.path .. luaPath_gl .. 'math/?.lua'
--package.path = package.path .. luaPath_ar .. 'math/?.lua'
-- math should add to package.path
Vec = require("Vector")
Vec3 = require("Vector3")
Mat = require("Matrix")
Qua = require("Quaternion")

require("solve7add1")

function sort(_set)
	local set = {n = _set.n}
	local n = _set.n
	for i = 1, n do
		set[i] = _set[i]
	end

	local t
	for i = 1 , n-1 do
		for j = i+1, n do
			if set[i] < set[j] then
				t = set[i]
				set[i] = set[j]
				set[j] = t
			end
		end
	end
	return set
end

function medianSet(set,y)
	y = y or 2
	local sorted = sort(set)
	local c = {n = math.ceil(sorted.n/y)}
	for i = 1,c.n do
		c[i] = sorted[math.ceil(set.n/2) - math.ceil(set.n/y) + i]
	end
	return c
end

function median(set)
	local sorted = sort(set)
	return sorted[sorted.n/2]
end
function average(set)
	local sum = 0
	for i = 1,set.n do
		sum = sum+set[i]
	end
	return sum/set.n
end

function solveSquare(_uv,_L,camera,distort)
	--[[
		uv[1] = {x = **, y = **}
		uv[2] = {x = **, y = **}
		uv[3] = {x = **, y = **}
		uv[4] = {x = **, y = **}

		L is a number to the side

		camera is a Matrix3/Matrix, or a {ku,kv,u0,v0}
	--]]

	---------------------- prepare -----------------------------
	local ku,kv,u0,v0
	local L = _L 
	local hL = _L / 2

	-- get ku,kv,u0,v0
	if type(camera) == "table" then
		if type(camera[1]) == "table" then
			ku = camera[1][1]
			kv = camera[2][2]
			u0 = camera[1][3]
			v0 = camera[2][3]
		else
			ku = camera[1]
			kv = camera[2]
			u0 = camera[3]
			v0 = camera[4]
		end
	else
		print("camera parameter wrong")
		return nil
	end
		--get ku,kv,u0,v0
	--[[
	print("ku = ",ku); print("kv = ",kv); print("u0 = ",u0); print("v0 = ",v0);
	--]]

	---------------------- undistort -----------------------------
	-- get uv from _uv
	local uv
	-- assert
	if type(_uv) == "table" then
		uv = {}
		if type(_uv[1]) == "table" then
			uv[1] = {x = _uv[1].x, y = _uv[1].y}
			uv[2] = {x = _uv[2].x, y = _uv[2].y}
			uv[3] = {x = _uv[3].x, y = _uv[3].y}
			uv[4] = {x = _uv[4].x, y = _uv[4].y}
		else
			uv[1] = {x = _uv[1], y = _uv[2]}
			uv[2] = {x = _uv[3], y = _uv[4]}
			uv[3] = {x = _uv[5], y = _uv[6]}
			uv[4] = {x = _uv[7], y = _uv[8]}
		end
	else
		print("points wrong")
		return nil
	end

	--[[ --print check
		for i = 1,4 do
			print("uv[",i,"]: x= ",uv[i].x,"y=",uv[i].y)
		end
	--]]

	-- undistort
		-- to be filled
	--if distort ~= nil then
	if type(distort) == "table" then
		local K1,K2,K3,K4,K5,K6,p,q
		K1 = distort[1] or 0
		K2 = distort[2] or 0
		p = distort[3] or 0
		q = distort[4] or 0
		K3 = distort[5] or 0
		K4 = distort[6] or 0
		K5 = distort[7] or 0
		K6 = distort[8] or 0

		local tx,ty,r2,DIS
		for i = 1,4 do
			tx = (uv[i].x - u0) / ku
			ty = (uv[i].y - v0) / kv
			r2 = tx^2 + ty^2
			DIS = 	(1 +  (K4 + (K5 + (K6) * r2) * r2) * r2) / 
					(1 +  (K1 + (K2 + (K3) * r2) * r2) * r2)
			tx = tx * DIS
			ty = ty * DIS
			--print("DIS = ",DIS)
			uv[i].x = tx * ku + u0
			uv[i].y = ty * kv + v0
		end
	end
		-- undistort get new uv, new camera
		-- solveSquare(newuv,L,newcamera)

	-------------------- after undistort -----------------------
	-- get u1v1 to u4v4 from undistorted uv
	local u1,v1,u2,v2,u3,v3,u4,v4
	-- assert
	if type(uv) == "table" then
		if type(uv[1]) == "table" then
			u1 = uv[1].x;   v1 = uv[1].y;
			u2 = uv[2].x;   v2 = uv[2].y;
			u3 = uv[3].x;   v3 = uv[3].y;
			u4 = uv[4].x;   v4 = uv[4].y;
		else
			u1 = uv[1];   v1 = uv[2];
			u2 = uv[3];   v2 = uv[4];
			u3 = uv[5];   v3 = uv[6];
			u4 = uv[7];   v4 = uv[8];
		end
	else
		print("points wrong")
		return nil
	end

	-- assert in case someone is nil
	ku = ku or 1; kv = kv or 1; u0 = u0 or 1; v0 = v0 or 1;
	u1 = u1 or 1; v1 = v1 or 1; u2 = u2 or 1; v2 = v2 or 1;
	u3 = u3 or 1; v3 = v3 or 1; u4 = u4 or 1; v4 = v4 or 1;

	--[[ fake a data to debug
	local ttt = 100
	u0 = 0; v0 = 0
	u1 = ttt; v1 = ttt
	u2 = ttt; v2 = -ttt
	u3 = -ttt; v3 = -ttt
	u4 = -ttt; v4 = ttt
	--]]

	--[[ print check
	print("ku = ",ku); print("kv = ",kv); print("u0 = ",u0); print("v0 = ",v0);
	print("u1 = ",u1); print("v1 = ",v1); print("u2 = ",u2); print("v2 = ",v2);
	print("u3 = ",u3); print("v3 = ",v3); print("u4 = ",u4); print("v4 = ",v4);
	--]]

	-- now we have ku kv u0 v0, and ux(1-4) vx(1-4), and L 
	----------------------------------------------------------
	-- trick starts

	local solve_res 
	local minerr = 9999999
	local z_res
	for i = 1,8 do
		solve_res = solve7add1(hL,	ku,kv,u0,v0,
								u1,v1,u2,v2,
								u3,v3,u4,v4,
							i)
		if solve_res.err < minerr then
			z_res = solve_res
			minerr = z_res.err
		end
	end
	------------------- method 2 ------------------
	--[[
	local z_set = {n = 0}
	local z_res
	---[[
	for i = 1,8 do
		z_res = solve7add1(hL,	ku,kv,u0,v0,
								u1,v1,u2,v2,
								u3,v3,u4,v4,
							i)
		for j = 1,z_res.n do
			z_set[z_set.n + j] = z_res[j]
		end
		z_set.n = z_set.n + z_res.n
	end
	--]]

	--z_set = medianSet(z_set,6)
	--[[
	print("---z set: ---",z_set.n)
	for i = 1,z_set.n do
		print("z = ",z_set[i])
	end
	--]]

	--local zz = median(z_set)
	--local zz = average(z_set)

	-------------------------------------------------------------------------------
	local a,b,c,p,q,r,x,y,z
	x = z_res.x
	y = z_res.y
	z = z_res.z
	a = z_res.a
	b = z_res.b
	c = z_res.c
	p = z_res.p
	q = z_res.q
	r = z_res.r
		-- because these are calculated from u and v, they are in left hand axis

	--------------------------------------------------------
	local loc = Vec3:create(-x,y,z)
	local abc = Vec3:create(-a,b,c)
	local pqr = Vec3:create(-p,q,r)

	-- ap + bq + cr = 0  right angle check
	local constrain = abc:nor() ^ pqr:nor()

		-- now we have loc, abc, pqr  in right hand
	--------------------------------------------------------

	abc = abc:nor()
	pqr = pqr:nor()
	-- calc rotation --------
	local abc_o = Vec3:create(1,0,0)
	local pqr_o = Vec3:create(0,1,0)
	local axis = (abc - abc_o) * (pqr - pqr_o)
	axis = axis:nor()

	--print("axis",axis)

	local rot_o = abc_o - axis ^ abc * axis
	local rot_d = abc - axis ^ abc * axis
	rot_o = rot_o:len()
	rot_d = rot_d:len()
	local cos = rot_o ^ rot_d
	local th = math.acos(cos)
	--print("th = ",th)

	local quater = Qua:createFromRotation(axis,th)

	--[[ print check
	print("z1 = ",z1)
	print("z2 = ",z2)
	print("constrain = ",constrain)

	print("loc = ",loc)
	print("abc = ",abc,"len = ",abc:len())
	print("pqr = ",pqr,"len = ",pqr:len())
	print("quater = ",quater)
	--]]

	local dir = abc * pqr
	dir = dir:nor()
	--local dir = abc 

	--return {translation = loc, rotation = dir, quaternion = dir}
	return {translation = loc, rotation = dir, quaternion = quater}
	--return {translation = loc, rotation = axis, quaternion = quater}
end
