require("libsolvepnp")
require("solveSquare")

local Vec3 = require("Vector3")
local Qua = require("Quaternion")

function calTagPos(tag)
	-- tag is the information for a single tag, has:
		-- halfL = <a number>, the halfL of the box
		-- center = {x = xx, y = xx}
		-- corners = {
		--				1 = {x = xx, y = xx}
		--				2 = {x = xx, y = xx}
		--			}

									--[[ check corners
										for i = 1,4 do
											print("\t\ttagcorner",i,"x = ",tag.corners[i].x,
																	"y = ",tag.corners[i].y) 
										end
									--]]

	tag.corners.halfL = tag.halfL;
	res_cv = libsolvepnp.solvepnp(tag.corners)
	resSqu = solveSquare(	tag.corners,
							tag.halfL * 2,
							--{883.9614,883.9614,319.5000,179.5000},		-- ku kv u0 v0
							--{0.018433,0.16727,0,0,-1.548088})			-- distort para

							{939.001439,939.001439,320,240},		-- ku kv u0 v0       -- camera
							{-0.4117914,5.17498964,0,0,-17.7026842})			-- distort para

		--[[
			for libsolvepnp
			res has: 	translation x,y,z
						rotation x,y,z which is solvepnp returns

						rotation x,y,z means: x^2 + y^2 + z^2 = th
						and the (x,y,z)/th is the normalization axis

			-- expecting right hand (from z look down, x to y is counter-clock)
				-- but opencv is left hand, left to right should be converted in lua libsolvepnp
		--]]
		--[[
			for solveSqu
			res has: 	translation = <a vector>
						rotation = <a vector>means: the direction of the tag
						quaternion = <a quaternion>
		--]]

	--  transform res_cv.xyz into resCV.translation<a vector>
	---[[
	local x = res_cv.translation.x
	local y = res_cv.translation.y
	local z = res_cv.translation.z
	local resCV = {}
	resCV.translation = Vec3:create(x,y,z)
	--]]


	-- scale , not needed
	scale = 1
	resCV.translation = resCV.translation * scale
	resSqu.translation = resSqu.translation * scale


	--  transform res_cv.rotation.xyz into resCV.rotation and quaternion <a vector><a quaternion>
	---[[
	x = res_cv.rotation.x
	y = res_cv.rotation.y
	z = res_cv.rotation.z
	local th = math.sqrt(x * x + y * y + z * z)
	local rotqq = Qua:createFromRotation(x,y,z,th)
	resCV.quaternion = rotqq
	--]]

									--[[ check quaternion   rotation axis
										--print("CV's axis",Vec3:create(x,y,z):nor())
											-- in solveSqu.lua, give rotation the axis
										--print("Squ's axis v",resSqu.rotation)

										--print("CV's quaternion v",rotqq.v:nor())
										--print("Squ's quaternion v",resSqu.quaternion.v:nor())

										print("CV's  quaternion",rotqq)
										print("Squ's quaternion",resSqu.quaternion)

										--print("opencv th",th)
									--]]


	-- generate opencv's rotation direct
	local znor = Vec3:create(0,0,1)

	local dirCV = znor:rotatedby(resCV.quaternion)
	resCV.rotation = dirCV

	resSqu.rotation = znor:rotatedby(resSqu.quaternion)
		-- use qua to calc rotation again, 
		--so that if quaternion is wrong, we can see that explicitly


									--[[
										if resCV.rotation.z < 0 then
											print("rescv .rotation", resCV.rotation)
										else
											print("rescv .rotation", resCV.rotation,"============")
										end
										if resCV.rotation.z < 0 then
											print("ressqu.rotation", resSqu.rotation)
										else
											print("ressqu.rotation", resSqu.rotation,"============")
										end
									--]]
									--[[ print check the location
										print("CV's  dir",resCV.rotation)
											-- in solveSqu.lua, give rotation the axis
										print("Squ's dir",resSqu.rotation)

										print("solvepnp res loc:",resCV.translation)
										print("solveSqu res loc:",resSqu.translation)
										print("------")
									--]]

									--[[ print check the quaternion
										print("solvepnp res qua:",resCV.quaternion)
										print("solveSqu res qua:",resSqu.quaternion)

										print("solvepnp res dire:",resCV.rotation)
										print("solveSqu res dire:",resSqu.rotation)

										print("solvepnp res loc:",resCV.translation)
										print("solveSqu res loc:",resSqu.translation)

										print("------")
									--]]

									--[[
										print("\t\tin lua result: ",res.rotation.x)
										print("\t\tin lua result: ",res.rotation.y)
										print("\t\tin lua result: ",res.rotation.z)
										print("\t\tin lua result: ",res.translation.x)
										print("\t\tin lua result: ",res.translation.y)
										print("\t\tin lua result: ",res.translation.z)
									--]]
									--resSqu.quaternion = resCV.quaternion
	return resSqu
	--return resCV
end
