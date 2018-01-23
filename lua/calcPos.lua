--require("libsolvepnp")
require("solveSquare")
--require("solveSquare_dynamic")

local Vec3 = require("Vector3")
local Qua = require("Quaternion")
CubeDir = require("CubeDir")

------------------------------------------------------------------------------------------
--      Tags
------------------------------------------------------------------------------------------

function calTagPos(tag)
	-- tag is the information for a single tag, has:
		-- halfL = <a number>, the halfL of the box
		-- center = {x = xx, y = xx}
		-- corners = {
		--				1 = {x = xx, y = xx}
		--				2 = {x = xx, y = xx}
		--			}

	tag.corners.halfL = tag.halfL;
	--res_cv = libsolvepnp.solvepnp(tag.corners)
									--print("before solve")
	if tag.camera_flag == 1 then
		cam_para = {939.001439,939.001439,320,240}
		dis_para = {-0.4117914,5.17498964,0,0,-17.7026842}	
	else
		cam_para = {883.9614,883.9614,319.5000,179.5000}
		dis_para = {0.018433,0.16727,0,0,-1.548088}
	end

	resSqu = solveSquare(	tag.corners,
							tag.halfL * 2,
							cam_para,
							dis_para
						)

		--[[
			for libsolvepnp
			res has: 	translation x,y,z
						rotation x,y,z which is solvepnp returns

						rotation x,y,z means: x^2 + y^2 + z^2 = th
						and the (x,y,z)/th is the normalization axis

			-- expecting right hand (from z look down, x to y is counter-clock--)
				-- but opencv is left hand, left to right should be converted in lua libsolvepnp
		--]]
		--[[
			for solveSqu
			res has: 	translation = <a vector>
						rotation = <a vector>means: the direction of the tag
						quaternion = <a quaternion>
		--]]

	--  transform res_cv.xyz into resCV.translation<a vector>
	--[[
	local x = res_cv.translation.x
	local y = res_cv.translation.y
	local z = res_cv.translation.z
	local resCV = {}
	resCV.translation = Vec3:create(x,y,z)
	--]]


	-- scale , not needed
	scale = 1
	--resCV.translation = resCV.translation * scale
	resSqu.translation = resSqu.translation * scale


	--  transform res_cv.rotation.xyz into resCV.rotation and quaternion <a vector><a quaternion>
	--[[
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

	--[[
	local dirCV = znor:rotatedby(resCV.quaternion)
	resCV.rotation = dirCV
	--]]

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

------------------------------------------------------------------------------------------
--      Boxes
------------------------------------------------------------------------------------------

function calcBoxPos(pos)
	--[[
		calcBoxPos calculate the pos of the boxes from pos of tags

		pos contains tags information
			  has : {
						n
						halfBox = half the length of each side of the box
						1 = {	rotation = {x,y,z}	the direction vector
								translation			the location vector
								quaternion			the quaternion 
							}
						2
						3...
					}
		returns boxes
					{
						n
						1 = {rotation,translation,quaternion}
							-- currently average
						2
						3
					}
	--]]
	local halfBox = pos.halfBox
	local boxcenters = {n = pos.n}
	for i = 1, pos.n do
		boxcenters[i] = pos[i].translation - halfBox * (pos[i].rotation:nor())
	end
		-- boxcenters is the boxcenter for every tag

	local boxes = {n = 0}
	--[[
		boxes is supposed to have 
			= {	n
					1 = {	average = <vector>
							rotation = <vector>
							quaternion = <quaternion>
							cubeDir = {
										6 Vec3s, pointing 6 direction
									}

							nTags = x
							1 = tag = {translation, rotation, qua}
							2 = tag
						}
				}
	--]]
	local dis
	local flag
	for i = 1, pos.n do
	if pos[i].tracking ~= "lost" and pos[i].jumping ~= "jumping" then
		-- go through all the tags, focal tag is boxcenters[i]
		-- j should have a local?
		j = 1; flag = 0 
		while j <= boxes.n do
			-- go through all the known boxes
			dis = boxes[j].average - boxcenters[i]	
			if (dis:len() < halfBox*1.5) then								-- the threshold
				-- it mean this tag belongs to a known box, boxes[j]
				boxes[j].average = 	(boxes[j].average * boxes[j].nTags + boxcenters[i]) / 
									(boxes[j].nTags + 1)
				boxes[j].nTags = boxes[j].nTags + 1
				boxes[j][boxes[j].nTags] = pos[i]

				pos[i].box = boxes[j]
				pos[i].boxj = j

				flag = 1
				break
			end
			j = j + 1
		end
		if flag == 0 then
			-- it means this tag does not belong to any known boxes, create a new one
			boxes.n = boxes.n + 1
			boxes[boxes.n] = {	nTags = 1, 
								average = boxcenters[i],
								--rotation = pos[i].rotation,
								--quaternion = pos[i].quaternion,
								--translation = boxcenters[i] * 2 - pos[i].translation,
							 }
			boxes[boxes.n][1] = pos[i]

			pos[i].box = boxes[boxes.n]
			pos[i].boxj = boxes.n
		end
	end
	end

	---[[
	for i = 1, boxes.n do
		-- go through all the boxes, calc rotation and quaternion
		calcRotation(boxes[i])
		--print("rotation, = ",boxes[i].rotation)
		--print("quaternion = ",boxes[i].quaternion)
	end
	--]]

	return boxes
end

function calcRotation(box)
	--[[ box mean the box to be calculated
		nTags = x
		average = <vector>
		rotation = <vector>
		quaternion = <quaternion>
		1 = tag No. x
		2 = tag No. x
	--]]
	box.translation = box.average

	if (box.nTags == 1) then
	--if (box.nTags == 1) or (box.nTags == 2) or (box.nTags == 3)then
													--print("tags = 1")
		box.rotation = box[1].rotation
		box.quaternion = box[1].quaternion
	elseif (box.nTags == 2) then
													--print("tags = 2")
		local vec1 = box[1].rotation:nor()
		local vec2 = box[2].rotation:nor()
		local vec = (vec1 + vec2):nor()
		local side = (vec1 * vec2):nor()

										--print("middle, check",vec ^ side)
		local vec_o = Vec3:create(1,1,0)
		local side_o = Vec3:create(0,0,1)
										--print("quater",quater)
										--print("box1.qua",box[1].quaternion)
		box.quaternion = Qua:createFrom4Vecs(vec_o,side_o,vec,side)
										--print("quaternion",box.quaternion)
		box.rotation = Vec3:create(0,0,1):rotatedby(box.quaternion)
										--print("rotation",box.rotation)
													--print("tags = 2 end")
	elseif (box.nTags == 3) then
		local vec1 = box[1].rotation:nor()
		local vec2 = box[2].rotation:nor()
		local vec3 = box[3].rotation:nor()
		local vec = (vec1 + vec2 + vec3):nor()

		local side = vec1
		if vec2.x > side.x then side = vec2 end
		if vec3.x > side.x then side = vec3 end

		box.quaternion = Qua:createFrom4Vecs(Vec3:create(1,1,1),Vec3:create(0,0,1),
											 vec,				side)
		box.rotation = Vec3:create(0,0,1):rotatedby(box.quaternion)
	else
		print("that is incredible! you can see more than 3 dimension!")
	end
	
	  --[[
	local dir1 = Vec3:create(0,0,1):rotatedby(box.quaternion)
	local dir2 = Vec3:create(0,0,-1):rotatedby(box.quaternion)
	local dir3 = Vec3:create(0,1,0):rotatedby(box.quaternion)
	local dir4 = Vec3:create(0,-1,0):rotatedby(box.quaternion)
	local dir5 = Vec3:create(1,0,0):rotatedby(box.quaternion)
	local dir6 = Vec3:create(-1,0,0):rotatedby(box.quaternion)
	--]]

	local dir1 = Vec3:create(0,0,1)
	local dir2 = Vec3:create(0,0,-1)
	local dir3 = Vec3:create(0,1,0)
	local dir4 = Vec3:create(0,-1,0)
	local dir5 = Vec3:create(1,0,0)
	local dir6 = Vec3:create(-1,0,0)
	box.cubeDir = CubeDir:create(dir1,dir2,dir3,
							  dir4,dir5,dir6)
	box.cubeDir = box.cubeDir:rotatedby(box.quaternion)
end

------------------------------------------------------------------------------------------
--      Structures
------------------------------------------------------------------------------------------

function calcStructure(boxes)
	--[[
		boxes has
		{
			halfBox
			n
			1 = {
					translation
					rotation
					quaternion
					average

					nTags
					1 = <atag> {translation, rotation, quaternion}
					2

					neighbour = { n
								  1 = <other box>
								  2
								}
				}
		}
	--]]
	--for i = 1, boxes.n do boxes[i].label = i end

	linkBoxes(boxes)

												--[[
												for i = 1, boxes.n do
													print("neighbour of box",boxes[i].label)
													for j = 1, boxes[i].neighbour.n do
													  print("\tbox",boxes[i].neighbour[j].label)
													end
												end
												--]]

	local structures = {n = 0}
	for i = 1,boxes.n do
		if boxes[i].counted ~= true then
			structures.n = structures.n + 1
			structures[structures.n] = {nBoxes = 0}
			local focalStru = structures[structures.n]

			for i_boxes in iter_boxes(boxes,i) do
				focalStru.nBoxes = focalStru.nBoxes + 1
				focalStru[focalStru.nBoxes] = i_boxes
			end
		end
	end
	for i = 1,boxes.n do boxes[i].counted = nil end

	for i = 1, structures.n do
		for j = 1, structures[i].nBoxes do
			structures[i][j].groupscale = structures[i].nBoxes
		end
	end

											--[[
												for i = 1, structures.n do
													print("structure",i)
													for j = 1, structures[i].nBoxes do
														print("\tbox",structures[i][j].label)
													end
												end
												--]]
	return structures
end

function iter_boxes(boxes,i)
	local list = {}
	local n = 1
	list[n] = boxes[i]
	return function()
			while n > 0 do
				local fBox = list[n]
				if fBox.counted ~= true then
					fBox.counted = true
					return fBox
				else
					local flag = 0
					for i = 1,fBox.neighbour.n do
						if fBox.neighbour[i].counted ~= true then
							n = n + 1
							list[n] = fBox.neighbour[i]
							flag = 1
							break
						end
					end
					if flag == 0 then
						-- all neighbours of fBox is counted, throw fBox
						list[n] = nil
						n = n - 1
					end
				end
		    end
		   end
end

function linkBoxes(boxes)
	--[[
	for every boxes, add a neighbour table
		 neighbour = { n = xxx
					 	1 <box>
						2
						3}
	--]]
					
	local halfBox = boxes.halfBox

	for i = 1,boxes.n do
		-- go through all boxes
		boxes[i].neighbour = {n = 0}
		for j = 1, boxes.n do
			-- go through all possible neighbours
			if i ~= j then
								--print("structure[",j,"]",".nBoxes",structures[j].nBoxes)
				local disVec = boxes[j].translation - boxes[i].translation
				local dis = disVec:len()
				local err = halfBox * 0.7
				if dis < halfBox * 2 + err and dis > halfBox * 2 - err and
				   boxes[j].cubeDir == boxes[i].cubeDir then
					boxes[i].neighbour.n = boxes[i].neighbour.n + 1
					boxes[i].neighbour[boxes[i].neighbour.n] = boxes[j]
				end
			end
		end
	end
end
