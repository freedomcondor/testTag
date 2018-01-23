Vec = require("Vector")
Vec3 = require("Vector3")
Mat = require("Matrix")

function almostZero(x,y)
	y = y or 3
	local t = x * (10^y)
	if -1<t and t<1 then
		return true
	else
		return false
	end
end
function solveDeg2(A,B,C)
	if A == 0 then
		return -C/B, nil
	end

	local delta = B^2-4*A*C

	--if delta == 0 then
	if delta < 0 then
		if almostZero(delta,3) then
			--print("deg2 : nearby solution, delta = ",delta)
			return -B/(2*A), -B/(2*A)
		end
		--print("deg2 : really no solution, delta = ",delta)
		return -B/(2*A), -B/(2*A) -- treat this as nearby solution
		--return nil, nil
	end
	--print("deg2 : has solution, delta = ",delta)

	--print("deg2 : good solution, delta = ",delta)
	local x1 = (-B + math.sqrt(delta)) / (2*A)
	local x2 = (-B - math.sqrt(delta)) / (2*A)
	return x1,x2
end

function solve7add1(L,ku,kv,u0,v0,u1,v1,u2,v2,u3,v3,u4,v4,flag)
	local A = Mat:create(8,9,
		--	x		y		z		a 		b       c       p       q       r
	    { {	-ku,    0,     u1-u0,	-ku,    0,      u1-u0,  -ku,    0,      u1-u0   },
		  { 0,      -kv,   v1-v0,	0,      -kv,    v1-v0,  0,      -kv,    v1-v0   },
		  { -ku,    0,     u2-u0,	-ku,    0,      u2-u0,  ku,     0,    -(u2-u0)  },
		  { 0,      -kv,   v2-v0,	0,      -kv,    v2-v0,  0,      kv,   -(v2-v0)  },
		  { -ku,    0,     u3-u0,	ku,     0,    -(u3-u0), ku,     0,    -(u3-u0)  },
		  { 0,      -kv,   v3-v0, 	0,      kv,   -(v3-v0), 0,      kv,   -(v3-v0)  },
		  { -ku,    0,     u4-u0, 	ku,     0,    -(u4-u0), -ku,    0,      u4-u0   },
		  { 0,      -kv,   v4-v0, 	0,      kv,   -(v4-v0), 0,      -kv,    v4-v0   },
		})

	--print("A = ",A)
	flag = flag or 8
	A = A:exc(flag,8)
	A[8] = nil
	A.n = 7

	--print("A = ",A)

	A = A:exc(3,8,"col")

	--print("A = ",A)

	--local B,_,success = A:tri()
	local B,_,success = A:dia()
	
	--print("B = ",B)

	if success == false then
		print("solve linar equation fail")
		return -1
	end

	local x_z = -B[1][8]/B[1][1];	x_r = -B[1][9]/B[1][1]
	local y_z = -B[2][8]/B[2][2];	y_r = -B[2][9]/B[2][2]
	local q_z = -B[3][8]/B[3][3];	q_r = -B[3][9]/B[3][3]
	local a_z = -B[4][8]/B[4][4];	a_r = -B[4][9]/B[4][4]
	local b_z = -B[5][8]/B[5][5];	b_r = -B[5][9]/B[5][5]
	local c_z = -B[6][8]/B[6][6];	c_r = -B[6][9]/B[6][6]
	local p_z = -B[7][8]/B[7][7];	p_r = -B[7][9]/B[7][7]
	local r_z

	-- ap + bq + cr == 0
	-- Kzz z^2 + Kzr zr + Krr r2
	local Kzz = a_z * p_z + b_z * q_z
	local Kzr = a_z*p_r + a_r*p_z + b_z*q_r + b_r*q_z + c_z
	local Krr = a_r * p_r + b_r * q_r +c_r

	--print(Kzz,Kzr,Krr)
	local r_z_res = {}
	r_z_res[1],r_z_res[2] = solveDeg2(Krr,Kzr,Kzz)
	--print("r_z1 = ",r_z_res[1])
	--print("r_z2 = ",r_z_res[2])

	--[[
	local z = {n = 0}
	for i = 1,2 do
	if r_z_res[i] ~= nil then
		x_z = x_z + x_r * r_z_res[i]
		y_z = y_z + y_r * r_z_res[i]
		a_z = a_z + a_r * r_z_res[i]
		b_z = b_z + b_r * r_z_res[i]
		c_z = c_z + c_r * r_z_res[i]
		p_z = p_z + p_r * r_z_res[i]
		q_z = q_z + q_r * r_z_res[i]
		local r_z = r_z_res[i]

		-- a2+b2+c2 = L2
		local L1 = a_z^2 + b_z^2 + c_z^2
		local L2 = p_z^2 + q_z^2 + r_z^2

		local z_res1 = math.sqrt(L^2/L1)
		local z_res2 = math.sqrt(L^2/L2)
		
		L1 = math.sqrt(L1) * z_res1^2
		L2 = math.sqrt(L2) * z_res2^2

		if(L2 - L1) ^ 2 < L^2 then
			--print("valid")
			z.n = z.n + 1
			z[z.n] = z_res1
			z.n = z.n + 1
			z[z.n] = z_res2
		else
			--print("invalid")
		end
	end
	end
	--]]

	local x,y,z,a,b,c,p,q,r

	local res = {}
	local z_res = {}
	for i = 1,2 do
		if r_z_res[i] ~= nil then
			x_z = x_z + x_r * r_z_res[i]
			y_z = y_z + y_r * r_z_res[i]
			a_z = a_z + a_r * r_z_res[i]
			b_z = b_z + b_r * r_z_res[i]
			c_z = c_z + c_r * r_z_res[i]
			p_z = p_z + p_r * r_z_res[i]
			q_z = q_z + q_r * r_z_res[i]
			r_z = r_z_res[i]
	
			local Labc = a_z^2 + b_z^2 + c_z^2
			z_res[i] = math.sqrt(L^2/Labc)
			
			x = x_z * z_res[i]
			y = y_z * z_res[i]
			a = a_z * z_res[i]
			b = b_z * z_res[i]
			c = c_z * z_res[i]
			p = p_z * z_res[i]
			q = q_z * z_res[i]
			r = r_z * z_res[i]
			z = z_res[i]

			res[i] = {	x = x,
						y = y,
						z = z,
						a = a,
						b = b,
						c = c,
						p = p,
						q = q,
						r = r,
					}
		end
	end

	local pqrerr1 = math.abs(res[1].p^2 + res[1].q^2 + res[1].r^2 - L^2)
	local pqrerr2 = math.abs(res[2].p^2 + res[2].q^2 + res[2].r^2 - L^2)
	res[1].err = pqrerr1
	res[2].err = pqrerr2
	if pqrerr1 > pqrerr2 then
		return res[2]
	else
		return res[1]
	end

	--[[
	print("print z :")
	for i = 1, z.n do
		print(i,z[i])
	end
	--]]

	

	--[[
	print("A = ",A)
	print("B = ",B)
	print("success = ",success)
	--]]
end
