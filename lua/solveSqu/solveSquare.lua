Vec = require("Vector")
Vec3 = require("Vector3")
--Mat = require("Matrix")
Qua = require("Quaternion")

require("solveQuad")

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

	--[[ print check
	print("ku = ",ku); print("kv = ",kv); print("u0 = ",u0); print("v0 = ",v0);
	print("u1 = ",u1); print("v1 = ",v1); print("u2 = ",u2); print("v2 = ",v2);
	print("u3 = ",u3); print("v3 = ",v3); print("u4 = ",u4); print("v4 = ",v4);
	--]]

	-- now we have ku kv u0 v0, and ux(1-4) vx(1-4), and L 
	----------------------------------------------------------
	-- trick starts

	-------------------------------------------------------------------------------------
	-- solve linar equation statically--------------------------------------------------
		-- to express all in c r z
		-- all left hand

	local c0 = -(u1*v2 - u2*v1 - u1*v3 + u3*v1 + u2*v4 - u4*v2 - u3*v4 + u4*v3)/
		    (u1*v2 - u2*v1 - u1*v4 + u2*v3 - u3*v2 + u4*v1 + u3*v4 - u4*v3)
	local r0 = -(	u1*v3 - u3*v1 - u1*v4 - u2*v3 + u3*v2 + u4*v1 + u2*v4 - u4*v2)/
		    (	u1*v2 - u2*v1 - u1*v4 + u2*v3 - u3*v2 + u4*v1 + u3*v4 - u4*v3)
		-- got a c/z and r/z proximately, for quadric solving later
	
	--  a b p q x y c r z
	--	6 rows left

	local Ks = Vec:create(6,{-2*ku,-2*kv,2*ku,2*kv,-2*ku,-2*kv})
	local Cs = Vec:create(6,
				{u3+u2-u0*2,v3+v2-v0*2,
				u2-u1,v2-v1,
				-u3+u1,-v3+v1})
	local Rs = Vec:create(6,
				{u3-u2,v3-v2,
				-u2-u1+u0*2,-v2-v1+v0*2,
				-u3+u1,-v3+v1})
	local Zs = Vec:create(6,
				{-u3+u2,-v3+v2,
				u2-u1,v2-v1,
				u3+u1-u0*2,v3+v1-v0*2})

	local ac,ar,az,bc,br,bz,xc,xr,xz
	local pc,pr,pz,qc,qr,qz,yc,yr,yz

	ac = -Cs[1]/Ks[1];	ar = -Rs[1]/Ks[1];	az = -Zs[1]/Ks[1]
	bc = -Cs[2]/Ks[2];	br = -Rs[2]/Ks[2];	bz = -Zs[2]/Ks[2]
	pc = -Cs[3]/Ks[3];	pr = -Rs[3]/Ks[3];	pz = -Zs[3]/Ks[3]
	qc = -Cs[4]/Ks[4];	qr = -Rs[4]/Ks[4];	qz = -Zs[4]/Ks[4]
	xc = -Cs[5]/Ks[5];	xr = -Rs[5]/Ks[5];	xz = -Zs[5]/Ks[5]
	yc = -Cs[6]/Ks[6];	yr = -Rs[6]/Ks[6];	yz = -Zs[6]/Ks[6]

	-- now we have x,y,a,b,p,q to c r z
	--------- solve linar equation end ---------------------------------------

	--------- solve double quadric equation ----
		-- we have two constrains:
		-- 		ap + bq + cr == 0 and
		--		a^2 + b^2 + c^2 == p^2 + q^2 + r^2 == hL^2
		-- expressed by c r z, we have two equations like:
		-- 		Ac^2 + Br^2 + Ccr + Dcz + Erz + Fz^2 == 0
		-- have c = cz * z,  r = rz * z, and eliminate z
		-- we have two:
		-- 		A1c^2 + B1r^2 + C1cr + D1c + E1r + F1 == 0
		-- 		A2c^2 + B2r^2 + C2cr + D2c + E2r + F2 == 0

	local a1,b1,c1,d1,e1,f1
	local a2,b2,c2,d2,e2,f2

	--c^2	ap			bq				cr
	a1 = ac*pc			+bc*qc			
	--r^2
	b1 = ar*pr			+br*qr			
	--cr
	c1 = ac*pr+ar*pc	+bc*qr+br*qc	+1
	--cz
	d1 = ac*pz+az*pc	+bc*qz+bz*qc	
	--rz
	e1 = ar*pz+az*pr	+br*qz+bz*qr 	
	--z^2
	f1 = az*pz			+bz*qz			

	local a3,b3,c3,d3,e3,f3
	local a4,b4,c4,d4,e4,f4
	--c^2	aa			bb				cc
	a3 = ac*ac			+bc*bc			+1;
	--r^2
	b3 = ar*ar			+br*br			
	--cr
	c3 = ac*ar+ar*ac	+bc*br+br*bc		
	--cz
	d3 = ac*az+az*ac	+bc*bz+bz*bc	
	--rz
	e3 = ar*az+az*ar	+br*bz+bz*br 	
	--z^2
	f3 = az*az			+bz*bz			

	--c^2	pp			qq				rr
	a4 = pc*pc			+qc*qc			;
	--r^2
	b4 = pr*pr			+qr*qr			+1;
	--cr
	c4 = pc*pr+pr*pc	+qc*qr+qr*qc		
	--cz
	d4 = pc*pz+pz*pc	+qc*qz+qz*qc	
	--rz
	e4 = pr*pz+pz*pr	+qr*qz+qz*qr 	
	--z^2
	f4 = pz*pz			+qz*qz			

	a2 = a3-a4
	b2 = b3-b4
	c2 = c3-c4
	d2 = d3-d4
	e2 = e3-e4
	f2 = f3-f4

	local cz,rz
												--print("before solving quad equations")
	cz,rz = solveQuad(	a1,b1,c1,d1,e1,f1,
						a2,b2,c2,d2,e2,f2,
						0.0000000001,c0,r0)
												--print("after solving quad equations")

	--- if failed
	if cz == nil or rz == nil then
		print("solve quad equations failed")
		return nil
	end

	local a5,b5,c5,d5,e5,f5
	--c^2
	a5 = a3 * cz * cz
	--r^2
	b5 = b3 * rz * rz
	--cr
	c5 = c3 * cz * rz
	--cz
	d5 = d3 * cz
	--rz
	e5 = e3 * rz
	--z^2
	f5 = f3 

	local x,y,z,a,b,c,p,q,r
	z = math.sqrt(hL^2/(a5+b5+c5+d5+e5+f5))

	c = cz * z
	r = rz * z
	x = xc * c + xr * r + xz * z
	y = yc * c + yr * r + yz * z
	a = ac * c + ar * r + az * z
	b = bc * c + br * r + bz * z
	p = pc * c + pr * r + pz * z
	q = qc * c + qr * r + qz * z

	-- got x y z a b c p q r
	-- left hand before
	--------------------------------------
	-- right hand below
	local loc = Vec3:create(-x,y,z)
	local abc = Vec3:create(-a,b,c)
	local pqr = Vec3:create(-p,q,r)
	local dir = abc * pqr		

	--[[ some thing wrong
		-- dir is supposed to point outside the tags/boxes
	if dir.z > 0 then
		local temp = abc
		abc = pqr
		pqr = temp
	end
	dir = abc * pqr
	--]]

	dir = dir:nor()

	--- Calc Quaternion
	abc = abc:nor()
	pqr = pqr:nor()
	local abc_o = Vec3:create(0,-1,0)
	local pqr_o = Vec3:create(1,0,0)

	--[[
	local axis = (abc - abc_o) * (pqr - pqr_o)
	axis = axis:nor()

	local rot_o = abc_o - axis ^ abc * axis
	local rot_d = abc - axis ^ abc * axis
	rot_o = rot_o:nor()
	rot_d = rot_d:nor()
	local cos = rot_o ^ rot_d
	axis = rot_o * rot_d
	local th = math.acos(cos)
	--]]

	--local quater = Qua:createFromRotation(axis,th)
	local quater = Qua:createFrom4Vecs(abc_o,pqr_o,abc,pqr)
	--- quaternion got ----------------
	-----------------------------------
	
	return {translation = loc, rotation = dir, quaternion = quater}
end
