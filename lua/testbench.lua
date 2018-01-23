require("debugger")
require("func")

input = io.open('../data/exp-11-passed.dat','r')
if input == nil then print("file not exist"); os.exit() end

n = input:read("*n")
while n ~= nil do
	-- read a frame
	local tags = {}
	tags.n = n

	for i = 1 , n do
		local x = input:read("*n")
		local c = input:read(1)
		local y = input:read("*n")
		local c = input:read(1)

		tags[i] = {}
		tags[i].center = {}
		tags[i].center.x = x
		tags[i].center.y = y

		tags[i].corners = {}
		for j = 1, 4 do
			local x = input:read("*n")
			local c = input:read(1)
			local y = input:read("*n")
			local c = input:read(1)

			tags[i].corners[j] = {}
			tags[i].corners[j].x = x
			tags[i].corners[j].y = y
		end
	end
	-- tags constructed

	if tags.n ~= 0 then
		res = func(tags)

		for i = 1, res.tags.n do
			print(res.tags[i].rotation)
		end
	end
	
	n = input:read("*n")
end
input:close()
