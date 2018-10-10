------------------------------------------------------------------------------------------
--	Weixu ZHU (Harry)
--		zhuweixu_harry@126.com
--	Version 1.1
--		changed: delete one line from line 47
--		added: comments on tags rotation poining inside
--		fixed: calc boxcenters, from - to + , for rotation pointing inside
--	Version 1.2
--		added: calibration data for 320*240 ---- can be more accurate
--
------------------------------------------------------------------------------------------
require("solveSquare")

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
	if tag.camera_flag == 1 then		-- for PC test Camera
		cam_para = {939.001439,939.001439,320,240}
		dis_para = {-0.4117914,5.17498964,0,0,-17.7026842}	
	else								-- for robot Camera
		--cam_para = {305.4607,306.4607,160.0,120.0}	-- for 320*240
		--cam_para = {610.92145,610.92145,320.0,240.0}	-- for 640*480
		dis_para = {0,0,0,0,0}
		cam_para = {883.9614,883.9614,319.5000,179.5000}	-- for 640x360
		--dis_para = {0.018433,0.16727,0,0,-1.548088}
	end

	resSqu = solveSquare(	tag.corners,
							tag.halfL * 2,
							cam_para,
							dis_para
						)
		--[[
			res has: 	translation = <a vector>
						rotation = <a vector>means: the direction of the tag, pointing inside
						quaternion = <a quaternion>
		--]]

	return resSqu
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
		boxcenters[i] = pos[i].translation + halfBox * (pos[i].rotation:nor())	
			-- rotation pointing inside
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
							 }
			boxes[boxes.n][1] = pos[i]

			pos[i].box = boxes[boxes.n]
			pos[i].boxj = boxes.n
		end
	end
	end

	for i = 1, boxes.n do
		-- go through all the boxes, calc rotation and quaternion
		calcRotation(boxes[i])
	end

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
		box.rotation = box[1].rotation
		box.quaternion = box[1].quaternion
	elseif (box.nTags == 2) then
		local vec1 = box[1].rotation:nor()
		local vec2 = box[2].rotation:nor()
		local vec = (vec1 + vec2):nor()
		local side = (vec1 * vec2):nor()

		local vec_o = Vec3:create(1,1,0)
		local side_o = Vec3:create(0,0,1)
		box.quaternion = Qua:createFrom4Vecs(vec_o,side_o,vec,side)
		box.rotation = Vec3:create(0,0,1):rotatedby(box.quaternion)
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

	linkBoxes(boxes)

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
