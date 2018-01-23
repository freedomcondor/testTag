Vec3 = require("Vector3")

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
	for i = 1, boxes.n do boxes[i].label = i end

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
	for i = 1,boxes.n do boxes.counted = nil end

												---[[
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
