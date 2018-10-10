----------------------------------------------------------------------------
--
-- Weixu ZHU (Harry)
-- 	zhuweixu_harry@126.com
-- Version: 1.1
-- 			fixed : copied cubeDir when tracking boxes
--
----------------------------------------------------------------------------
Mat = require("Matrix")
Hungarian = require("hungarian")
-----------------------------------------------------------------------------
--  Tags
-----------------------------------------------------------------------------
function trackingTags(tags,tags_seeing,_threshold)
	local threshold = _threshold or 200 -- the unit should be pixel
	local inf = 999999999

	local maxN
	if tags.n > tags_seeing.n then
		maxN = tags.n
	else
		maxN = tags_seeing.n
	end

	local C = Mat:create(maxN,maxN)
		-- filled with 0s
	--[[
					tags_seeing.n
				* * * * * * * * * * * 
				*					*	tags.n
				*					*
				* * * * * * * * * * * 
	--]]

	-- set penalty matrix
	local dis,x1,y1,x2,y2
	for i = 1,tags.n do
		for j = 1,tags_seeing.n do
			dis = 0
			x1 = tags[i].center.x
			y1 = tags[i].center.y
			x2 = tags_seeing[j].center.x
			y2 = tags_seeing[j].center.y
			dis = dis + math.sqrt( (x1-x2)^2 + (y1-y2)^2 ) * 0.2

			for k = 1,4 do
				x1 = tags[i].corners[k].x
				y1 = tags[i].corners[k].y
				x2 = tags_seeing[j].corners[k].x
				y2 = tags_seeing[j].corners[k].y
				dis = dis + math.sqrt( (x1-x2)^2 + (y1-y2)^2 ) * 0.2
					-- 0.25 is weight, center is considered more important than corners
					-- 0.2 is weight, center is considered equally important as corners
			end
			if dis > threshold then
				C[i][j] = inf
			else
				C[i][j] = dis + 0.1 -- make sure it is not 0
			end
		end
	end

	local hun = Hungarian:create{costMat = C,MAXorMIN = "MIN"}
	hun:aug()

	local i = 1
	while i <= tags.n do
		-- match existing tags
		-- may have a match
		-- may lost it
		if C[i][hun.match_of_X[i]] > threshold or
		   C[i][hun.match_of_X[i]] == 0 then
			-- lost
			if tags[i].tracking == "lost" then
				tags[i].lostcount = tags[i].lostcount + 1
				if tags[i].lostcount >= 0 then
					tags[i].tracking = "abandon"
				end
			else
				tags[i].tracking = "lost"
				tags[i].lostcount = 0
			end
		else
			-- tracking
			tags[i].center.x = tags_seeing[hun.match_of_X[i]].center.x
			tags[i].center.y = tags_seeing[hun.match_of_X[i]].center.y
			for j = 1,4 do
				tags[i].corners[j].x = tags_seeing[hun.match_of_X[i]].corners[j].x
				tags[i].corners[j].y = tags_seeing[hun.match_of_X[i]].corners[j].y
			end

			tags[i].translation = tags_seeing[hun.match_of_X[i]].translation
			tags[i].rotation = tags_seeing[hun.match_of_X[i]].rotation
			tags[i].quaternion = tags_seeing[hun.match_of_X[i]].quaternion

			tags[i].trackcount = tags[i].trackcount + 1
			if tags[i].tracking == "lost" then
				tags[i].tracking = "found"
			else
				tags[i].tracking = "tracking"
			end
		end
		i = i + 1
	end

	local i = 1
	while i <= tags.n do
		if tags[i].tracking == "abandon" then
			-- abandon this
			-- and move the last one here to fill the position
			tags.label[tags[i].label] = nil
			tags[i] = nil
			tags[i] = tags[tags.n]
			tags[tags.n] = nil
			tags.n = tags.n - 1
			i = i - 1
		end
		i = i + 1
	end


	for j = 1, tags_seeing.n do
		if C[hun.match_of_Y[j]][j] > threshold or
		   C[hun.match_of_Y[j]][j] == 0 then
			-- new tags
			local i = tags.n + 1
			tags.n = tags.n + 1
			tags[i] = {	center = {x = 0, y = 0}, 
						corners = {{x = 0, y = 0},{x = 0, y = 0},{x = 0, y = 0},{x = 0, y = 0}}
			 		  }
			tags[i].center.x = tags_seeing[j].center.x
			tags[i].center.y = tags_seeing[j].center.y
			for k = 1,4 do
				tags[i].corners[k].x = tags_seeing[j].corners[k].x
				tags[i].corners[k].y = tags_seeing[j].corners[k].y
			end
			tags[i].translation = tags_seeing[j].translation
			tags[i].rotation = tags_seeing[j].rotation
			tags[i].quaternion = tags_seeing[j].quaternion

			tags[i].tracking = "new"
			tags[i].trackcount = 0
	
			local k = 1; while tags.label[k] ~= nil do k = k + 1 end
			tags[i].label = k
			tags.label[k] = true
		end
	end

													--[[
														print("tags.n",tags.n)
														i = 1; local count = 1
														while count <= tags.n do
															for j = 1, tags.n do
																if tags[j].label == i then
														  print("tag:",tags[j].label,tags[j].tracking,tags[j].trackcount)
														  		count = count + 1
														  		end
														    end
															i = i + 1
														end
													--]]
end

-----------------------------------------------------------------------------
--  Boxes
-----------------------------------------------------------------------------

function trackingBoxes(boxes,boxes_seeing)
	i = 1
	while i <= boxes.n do
	--for i = 1, boxes.n do
		-- abandon
		j = 1
		while j <= boxes[i].nTags do
			if boxes[i][j].tracking == "abandon" then
				boxes[i][j] = nil
				boxes[i][j] = boxes[i][boxes[i].nTags]
				boxes[i][boxes[i].nTags] = nil
				boxes[i].nTags = boxes[i].nTags - 1
				j = j - 1
			end
			j = j + 1
		end
		if boxes[i].nTags == 0 then
			boxes[i].tracking = "abandon"
		end
		-- match
		local flag = 0
		for j = 1, boxes[i].nTags do
			if boxes[i][j].tracking ~= "lost" then
				if boxes[i][j].box == nil or boxes[i][j].box.assigned == true then
					boxes[i].tracking = "abandon"
					break
				end
				local tempbox = boxes[i][j].box
				tempbox.assigned = true
				boxes[i].translation = boxes[i][j].box.translation
				boxes[i].rotation = boxes[i][j].box.rotation
				boxes[i].quaternion = boxes[i][j].box.quaternion
				boxes[i].cubeDir = boxes[i][j].box.cubeDir

				--keep lost tags
				local lostkeep = {n = 0}
				for k = 1, boxes[i].nTags do
					if boxes[i][k].tracking == "lost" then
						lostkeep.n = lostkeep.n + 1
						lostkeep[lostkeep.n] = boxes[i][k]
					end
				end

				--link the matching box in boxes_seeing to boxes
				boxes[i].nTags = boxes[i][j].box.nTags
				for k = 1, boxes[i].nTags do
					boxes[i][k] = tempbox[k]
					tempbox[k].box = nil
				end

				--link those lost tags
				for k = 1, lostkeep.n do
					boxes[i].nTags = boxes[i].nTags + 1
					boxes[i][boxes[i].nTags] = lostkeep[k]
				end

				flag = 1
				boxes[i].tracking = "tracking"
				boxes[i].trackcount = boxes[i].trackcount + 1
				break
			end
		end
		if flag == 0 and boxes[i].tracking ~= "abandon" then
			-- means there are tags but all tags are lost
			boxes[i].tracking = "lost"
		end

		if boxes[i].tracking == "abandon" then
			boxes.label[boxes[i].label] = nil
			boxes[i] = nil
			boxes[i] = boxes[boxes.n]
			boxes[boxes.n] = nil
			boxes.n = boxes.n - 1
			i = i - 1
		end

		i = i + 1
	end

	for i = 1, boxes_seeing.n do
		if boxes_seeing[i].assigned == nil then
			-- new box
			boxes.n = boxes.n + 1

			boxes[boxes.n] = {}
			boxes[boxes.n].translation = boxes_seeing[i].translation
			boxes[boxes.n].rotation = boxes_seeing[i].rotation
			boxes[boxes.n].quaternion = boxes_seeing[i].quaternion
			boxes[boxes.n].cubeDir = boxes_seeing[i].cubeDir

			boxes[boxes.n].nTags = boxes_seeing[i].nTags
			for k = 1, boxes_seeing[i].nTags do
				boxes[boxes.n][k] = boxes_seeing[i][k]
				boxes_seeing[i][k].box = nil
			end

			boxes_seeing[i].assigned = true
			boxes[boxes.n].tracking = "new"
			boxes[boxes.n].trackcount = 0

			local k = 1; while boxes.label[k] ~= nil do k = k + 1 end
			boxes[boxes.n].label = k
			boxes.label[k] = true
		end
	end
													--[[
														print("boxes.n",boxes.n)
														i = 1; local count = 1
														while count <= boxes.n do
															for j = 1, boxes.n do
																if boxes[j].label == i then
														  print("boxes:",boxes[j].label,boxes[j].tracking,boxes[j].trackcount)
														  		count = count + 1
														  		end
														    end
															i = i + 1
														end
													--]]

end
