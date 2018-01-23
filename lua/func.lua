luaPath_gl = ';../lua/'
luaPath_ar = ';../../lua/'

luaPath = '?.lua'
solvepnpPath = 'solvepnp/build/?.so'
solveSquPath = 'solveSqu/?.lua'
mathPath = 'math/?.lua'

package.path = package.path .. luaPath_gl .. luaPath
package.cpath = package.cpath .. luaPath_gl .. solvepnpPath
package.path = package.path .. luaPath_gl .. solveSquPath
package.path = package.path .. luaPath_gl .. mathPath

package.path = package.path .. luaPath_ar .. luaPath
package.cpath = package.cpath .. luaPath_ar .. solvepnpPath
package.path = package.path .. luaPath_ar .. solveSquPath
package.path = package.path .. luaPath_ar .. mathPath

--require("calcTagPos")
--require("calcBoxPos")
--require("calcStructure")
require("calcPos")
require("tracking")
Vec3 = require("Vector3")

--require("debugger")

--[[
for every frame, build a taglist, which is a table, to lua
taglist, as the para of func
{
	timestamp = xxx
	n = <a number> the number of tags
	1 = <a table> which is a tag
	    {
   			center = {x = **, y = **}
			corners = <a table>
					{
						1 = {x = **, y = **}
						2
						3
						4
					}
		}
	2
	3
	4
	...
}
--]]

local halfTag = 0.012
local halfBox = 0.0275
local tags = {n = 0,label = {}}
local boxes = {n = 0,label = {}}
local structures = {n = 0,label = {}}
--[[
	for every tag or box, should have 
		location and rotation
		last step location and rotation
		a velocity
		a tracking status = tracking/lost/new
		label
--]]

function func(tags_seeing)
	--[[
	-- tagList has:
		{
			n
			1 = {center = {x,y}
				 corners = {1 = {x,y}
							2 = {x,y}
							3 = {x,y}
							4 = {x,y}
							}
				}
			2 = {}
			3 = {}
		}
	--]]

		-- expected unit is meter

	-- Calc position of tags ------------------------------------

	for i = 1, tags_seeing.n do
		tags_seeing[i].halfL = halfTag
		tags_seeing[i].camera_flag = tags_seeing.camera_flag
									--print("before calc")
		local pos = calTagPos(tags_seeing[i])
									--print("after calc")
			-- calTagPos returns a table (for each tag)
				-- {rotation = {x=,y=,z=}  <a vector> the direction vector of the tag, 
					-- seems to point outside the box
				--	translation = {x=,y=,z=} <a vector> the position of the the tag
				--	quaternion = {x,y,z,w} <a quaternion> the quaternion rotation of the tag
				-- }
		tags_seeing[i].rotation = pos.rotation
		tags_seeing[i].translation = pos.translation
		tags_seeing[i].quaternion = pos.quaternion
	end
	trackingTags(tags,tags_seeing)

	-- Calc postion of boxes ----------------------------------
									print("-----------------------------")
	tags.halfBox = halfBox
	local boxes_seeing = calcBoxPos(tags)
	trackingBoxes(boxes,boxes_seeing)
									print("after boxes, n = ",boxes.n)
	--[[
		boxes has
		{
			n
			1 = {
					translation
					rotation
					quaternion
					average

					nTags
					1 = <atag> {translation, rotation, quaternion}
					2
				}
		}
	--]]

	-- Calc structure ?
									print("-----------------------------")
	boxes_seeing.halfBox = halfBox
	boxes.halfBox = halfBox
	--local structures_seeing = calcStructure(boxes_seeing) 
	local structures_seeing = calcStructure(boxes) 
									print("structures n : ",structures_seeing.n)
								for i = 1, boxes.n do
									print("box",boxes[i].label,"its scale = ",boxes[i].groupscale)
								end
									print("-----------------------------")
									print("-----------------------------")

	--return {tags = tags_seeing,boxes = boxes_seeing}
	--return {tags = tags,boxes = boxes_seeing}
	return {tags = tags,boxes = boxes}
end
