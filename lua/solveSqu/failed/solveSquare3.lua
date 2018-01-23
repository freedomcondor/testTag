--print("path =",luaPath_gl)
--package.path = package.path .. luaPath_gl .. 'math/?.lua'
--package.path = package.path .. luaPath_ar .. 'math/?.lua'
-- math should add to package.path
Vec = require("Vector")
Vec3 = require("Vector3")
Mat = require("Matrix")
Qua = require("Quaternion")

require("solveQuad")

--[[
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
--]]

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

	-------------------------------------------------------------------------------
	-- solve equation dymatically--------------------------------------------------
	local A = Mat:create(8,9,
		-- 	x		y 		z		a		b		c		p		q		r
		{ {	-ku,	0,		u1-u0,	-ku,	0,		u1-u0,	-ku,	0,		u1-u0	},
		  {	0,		-kv,	v1-v0,	0,		-kv,	v1-v0,	0,		-kv,	v1-v0	},

		  {	-ku,	0,		u2-u0,	-ku,	0,		u2-u0,	ku,		0,	  -(u2-u0)	},
		  {	0,		-kv,	v2-v0,	0,		-kv,	v2-v0,	0,		kv,	  -(v2-v0)	},

	      {	-ku,	0,		u3-u0,	ku,		0,	  -(u3-u0),	ku,		0,	  -(u3-u0)	},
	      {	0,		-kv,	v3-v0,	0,		kv,	  -(v3-v0),	0,		kv,	  -(v3-v0)	},

		  {	-ku,	0,		u4-u0,	ku,		0,	  -(u4-u0),	-ku,	0,		u4-u0	},
    	  {	0,		-kv,	v4-v0,	0,		kv,	  -(v4-v0),	0,		-kv,	v4-v0	},
		})

	local B = A:exc(3,9,'col')
	B = B:dia()
	local x0 = -B[1][9]/B[1][1]
	local y0 = -B[2][9]/B[2][2]

	A = A:exc(6,7)
	A.n = 6

	A = A:exc(1,7,'col')
	A = A:exc(2,8,'col')
	A = A:exc(3,9,'col')
	--  p q r a b c x y z
	--A = A:exc(1,6,'col')
	--	z q r a b p x y z
	--A = A:exc(2,3,'col')
	--	z r q a b p x y z

	--local res1,exc,success = AB:tri()
	local res,exc,success = A:dia()
	local Ks = res:takeDia()
	local Xs = res:takeVec(7,"col")
	local Ys = res:takeVec(8,"col")
	local Zs = res:takeVec(9,"col")
	
	--[[ print check A and B
	print("A=",A)
	print("res1=",res1)
	print("res=",res)
	print("exc=",exc)
	print("success=",success)
	print("Ks = ",Ks)
	print("Xs = ",Xs)
	print("Ys = ",Ys)
	print("Zs = ",Zs)
	--]]
	---[[

	------------ no solution --------------------
	if success == false then
		-- to be filled
		return nil -- ?
	end
	---------------------------------------------

	local ax,ay,az,bx,by,bz,cx,cy,cz
	local px,py,pz,qx,qy,qz,rx,ry,rz

	px = -Xs[1]/Ks[1];	py = -Ys[1]/Ks[1];	pz = -Zs[1]/Ks[1]
	qx = -Xs[2]/Ks[2];	qy = -Ys[2]/Ks[2];	qz = -Zs[2]/Ks[2]
	rx = -Xs[3]/Ks[3];	ry = -Ys[3]/Ks[3];	rz = -Zs[3]/Ks[3]
	ax = -Xs[4]/Ks[4];	ay = -Ys[4]/Ks[4];	az = -Zs[4]/Ks[4]
	bx = -Xs[5]/Ks[5];	by = -Ys[5]/Ks[5];	bz = -Zs[5]/Ks[5]
	cx = -Xs[6]/Ks[6];	cy = -Ys[6]/Ks[6];	cz = -Zs[6]/Ks[6]
	-- now we have a,b,c,p,q,r to x y z
	--------- solve linar equation end ---------------------------------------

	local a1,b1,c1,d1,e1,f1
	local a2,b2,c2,d2,e2,f2

	--x^2	ap			bq				cr
	a1 = ax*px			+bx*qx			+cx*rx;
	--y^2
	b1 = ay*py			+by*qy			+cy*ry;
	--xy
	c1 = ax*py+ay*px	+bx*qy+by*qx	+cx*ry+cy*rx	
	--xz
	d1 = ax*pz+az*px	+bx*qz+bz*qx	+cx*rz+cz*rx
	--yz
	e1 = ay*pz+az*py	+by*qz+bz*qy 	+cy*rz+cz*ry
	--z^2
	f1 = az*pz			+bz*qz			+cz*rz

	local a3,b3,c3,d3,e3,f3
	local a4,b4,c4,d4,e4,f4
	--x^2	aa			bb				cc
	a3 = ax*ax			+bx*bx			+cx*cx;
	--y^2
	b3 = ay*ay			+by*by			+cy*cy;
	--xy
	c3 = ax*ay+ay*ax	+bx*by+by*bx	+cx*cy+cy*cx	
	--xz
	d3 = ax*az+az*ax	+bx*bz+bz*bx	+cx*cz+cz*cx
	--yz
	e3 = ay*az+az*ay	+by*bz+bz*by 	+cy*cz+cz*cy
	--z^2
	f3 = az*az			+bz*bz			+cz*cz

	--x^2	pp			qq				rr
	a4 = px*px			+qx*qx			+rx*rx;
	--y^2
	b4 = py*py			+qy*qy			+ry*ry;
	--xy
	c4 = px*py+py*px	+qx*qy+qy*qx	+rx*ry+ry*rx	
	--xz
	d4 = px*pz+pz*px	+qx*qz+qz*qx	+rx*rz+rz*rx
	--yz
	e4 = py*pz+pz*py	+qy*qz+qz*qy 	+ry*rz+rz*ry
	--z^2
	f4 = pz*pz			+qz*qz			+rz*rz

	a2 = a3-a4
	b2 = b3-b4
	c2 = c3-c4
	d2 = d3-d4
	e2 = e3-e4
	f2 = f3-f4

	local xz,yz
	xz,yz = solveQuad(	a1,b1,c1,d1,e1,f1,
						a2,b2,c2,d2,e2,f2,
						0.00001,x0,y0)

	print("xz,yz : ",xz,yz)
	local a5,b5,c5,d5,e5,f5
	--x^2
	a5 = a3 * xz * xz
	--y^2
	b5 = b3 * yz * yz
	--xy
	c5 = c3 * xz * yz
	--xz
	d5 = d3 * xz
	--yz
	e5 = e3 * yz
	--z^2
	f5 = f3 

	local x,y,z,a,b,c,p,q,r
	z = math.sqrt(hL^2/(a5+b5+c5+d5+e5+f5))
	x = xz * z
	y = yz * z

	return {translation = Vec3:create(-x,y,z), rotation = Vec3:create(), quaternion = Qua:create()}
end
