Vec3 = require("Vector3")
Qua = require("Quaternion")
CubeDir = require("CubeDir")

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
		-- go through all the tags, focal tag is boxcenters[i]
		-- j should have a local?
		j = 1; flag = 0 
		while j <= boxes.n do
			-- go through all the known boxes
			dis = boxes[j].average - boxcenters[i]	
			if (dis:len() < halfBox) then								-- the threshold
				-- it mean this tag belongs to a known box, boxes[j]
				boxes[j].average = 	(boxes[j].average * boxes[j].nTags + boxcenters[i]) / 
									(boxes[j].nTags + 1)
				boxes[j].nTags = boxes[j].nTags + 1
				boxes[j][boxes[j].nTags] = pos[i]

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
