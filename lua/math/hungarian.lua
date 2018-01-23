-- table tool functions
----------------------------------------------------------------
-- copy tables
local function deepcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function copy(orig,n,m)
	local copy = {}
	for i = 1,n do
		copy[i] = {}
		for j = 1,m do
			copy[i][j] = orig[i][j] or 0
		end
	end
	return copy
end

-- get the size of a table, no matter square or not
local function getNM_Mat(Mat)
	--[[
	find the size of a Mat
	i.e.
		  M=4
		* * * *
	N=3	* * * *
		* * * *

	return 3,4
	--]]

	--Asserts
		--checked in for
		--presume Mat is like {{a,a},{a,a,a},{a,a}}

	local maxM = 0
	local i = 0
	for ii,v in ipairs(Mat) do
		i = ii
		if type(v) ~= "table" then return -1,-1 else
			for jj,t in ipairs(v) do j=jj end
			if j>maxM then maxM = j end
		end
	end
	return i,maxM
end

-- queue
----------------------------------------------------------------
local Queue = {}
Queue.__index = Queue
function Queue:create()
	local instance = {first = 1; last = 0}			
	setmetatable(instance, self)
	return instance
		--starts from 1	,  read from first,  add to next of last
		--		 first        		last  
		--       x   	x  x  x  x 	x 		(next)
end

function Queue:add(x)
	self.last = self.last + 1
	self[self.last] = x
end

function Queue:read()
	if self.first > self.last then return nil end
	local value = self[self.first]
	self[self.first] = nil
	self.first = self.first + 1
	return value
end

function Queue:isEmpty()
	if self.first > self.last 	then return true 
								else return false end
end

----------------------------------------------------------------

----------------------------------------------------------------
-- Hungarian starts
	-- for the algorithm, please refer to: https://www.topcoder.com/community/data-science/data-science-tutorials/assignment-problem-and-hungarian-algorithm/

local Hungarian = 
{
	-- a Hungarian should have these data
	costMat = {},
	N = 0,
	-- M = 0
		-- no M currently, consider only square

	maxMatch = 0,
	match_of_X = nil,
	match_of_Y = nil,
}
Hungarian.__index = Hungarian

function Hungarian:create(configuration)
	--Inherite
	local instance = {}
	setmetatable(instance,self)
	self.__index = self
		--the metatable of instance would be whoever owns this create
		--so you can :  a = Hungarian:create();  b = a:create();  grandfather-father-son

	--Asserts
		-- to be filled
		-- check in the following body
		-- maybe not square
		-- maybe the square lacks a corner (this matters, should fill in with 0, cannot be nil)
			-- with copy rather than deepcopy, can be nil
	
	-- Set costMat and size N
	--instance.costMat = deepcopy(configuration.costMat)
	local n,m = getNM_Mat(configuration.costMat)
	instance.costMat = copy(configuration.costMat,n,m)

	-- check and get N
	if n == -1 or m == -1 then
		print("invalid costMat")
		return nil
	end
	if n ~= m then
		print("non square")
		-- to be filled
		return nil
			-- temporarily
	end
	instance.N = n

	---------------- min or max problem ----------------
	if configuration.MAXorMIN == "MIN" then
		for i = 1,n do
			for j = 1,n do
				instance.costMat[i][j] = -instance.costMat[i][j] 
			end
		end
	end
	----------------------------------------------------

	-- Set labels and maxMatch
	instance.maxMatch = 0
	instance.match_of_X = {}
	instance.match_of_Y = {}

	--init lx,ly, which are the value labels of X and Y
	instance.lx = {}; instance.ly = {}
	--local i,j -- in lua this is not necessary, the i in for is local to for
	for i = 1,n do instance.ly[i] = 0 end
		--label of Y is all 0
	for i = 1,n do instance.lx[i] = instance.costMat[1][1] - 99999999999 end  -- set to -INF
		--lx is the max of his cost edges		-- for max problem
	for i = 1,n do 
		for j = 1,n do
			if instance.lx[i] < instance.costMat[i][j] then
				instance.lx[i] = instance.costMat[i][j]
			end
		end
	end
	--print("i = ",i) -- output nil -- proof that i is local to for

	return instance
end

------------------------------------------------------------------------------------------
function Hungarian:update_labels()
	local N = self.N
	local slack = self.slack
	local slackx = self.slackx

	local delta = slack[1] + 99999999  -- for max set as INF

	-- find the min delta among slack
	for y = 1,N do
		if self.T[y] ~= true and slack[y] < delta then	
			delta = slack[y]
		end
	end

										--debug------------------
										--print("delta = ",delta)

	-- update delta change
	for x = 1,N do
		if self.S[x] == true then
			self.lx[x] = self.lx[x] - delta		--max
		end
	end
	for y = 1,N do
		if self.T[y] == true then
			self.ly[x] = self.ly[x] + delta		--max
		end
	end

	-- update slack
	for y = 1,N do
		if self.T[y] ~= true then slack[y] = slack[y] - delta  end --max
	end
end

function Hungarian:add_to_tree(x,its_parent)
	self.S[x] = true
	self.parent_table[x] = its_parent
	
	-- update slack of this new x in S
	for y = 1,self.N do
		if (self.lx[x] + self.ly[y] - self.costMat[x][y] < self.slack[y]) then			--max
			self.slack[y] = self.lx[x] + self.ly[y] - self.costMat[x][y]		-- max
			self.slackx[y] = x
		end
	end
end
---The Augment-------------------------------------------------------------------------------

function Hungarian:aug()
	--[[
		for someone not be matched in X:
			1. try to find all his augmenting tree, 
				if a path is found, goto the end, change the match and recur aug() 
			2. if all the augmenting tree is set and no path found, update label
			3. keep finding, should find some new edges, if not, this is the answer
	--]]

	-- OK already?
	if (self.maxMatch == self.N) then return 0 end
	local N = self.N
		-- write self.N everytime could be annoying, use N directly

	---------------------------------------------------------------------
	-- Start to Build tree ----------------------------------------------
		-- using S,T,
		-- and a queue ?? 
			--the use of the queue is xxxxx
		-- a slack for find the min delta quickly

	----Find a single x and Init everything--------------

	-- Init everything
	self.S = {}
	self.T = {}
	self.parent_table = {}
	local S = self.S		-- frequently used, so no need of self.xx every time
	local T = self.T
	local parent_table = self.parent_table
	local queue = Queue:create()
	local root 

	-- find a single x
	for x = 1,N do
		if self.match_of_X[x] == nil then
			queue:add(x)
			root = x
			parent_table[x] = -2
			S[x] = true
			break
		end
	end
		--must find a single x, or function should have returned checking maxMatch
	
	-- init slack
		-- slack is used for store the mini delta for each y
		-- slackx is used for store to which x this mini delta is achieved
	self.slack = {} self.slackx = {}
	local slack = self.slack 
	local slackx = self.slackx

	for y = 1,N do 
		slack[y] = self.lx[root] + self.ly[root] - self.costMat[root][y] end		-- max
	for y = 1,N do slackx[y] = root end

	-----Start to find------------------------------------

										--------debug---------------
										--print("start to find,root is",root)
										--io.read()

	local edgex = nil		-- used for record the edge if a good path is found
	local edgey = nil
	local flag = 0	--flag = 1 mean found a good path
	while true do

										--------debug---------------
										--print("queue is Empty",queue:isEmpty())
										--io.read()

		-- search every x in queue
		while queue:isEmpty() == false do
			x = queue:read()
										--------debug---------------
										--print("focal x",x)
										--io.read()
			-- for this new x, search all its edges
			flag = 0	--flag = 1 mean found a good path
			for y = 1,N do
										--------debug---------------
										--print("focal y",y)
										--io.read()
				-- search y, find a edge of equality between this new x and a new y (not in T)
				if self.costMat[x][y] == self.lx[x] + self.ly[y] and T[y] ~= true then
					-- don't write T[y] == false, because T[y] == nil initially
										--------debug---------------
										--print("focal y is equal")
										--io.read()
					-- check is this y assigned? if not means a good path found
					if self.match_of_Y[y] == nil then 
										--------debug---------------
										--print("a path found")
										--io.read()
						edgex = x; edgey = y
						flag = 1; break 
					end  
						-- a good path found, jump out of for y(search for y) 

					-- y is assigned, add the x of this y to tree
					T[y] = true
					queue:add(self.match_of_Y[y])
					--S[x] = true   -- this is done in add_to_tree
					self:add_to_tree(self.match_of_Y[y],x)
				end
			end	-- end of for y

			if flag == 1 then break end
				-- a good path found jump out of while queue)
				-- else next x in queue
		end	-- end of queue searching (while queue:isEmpty)

										--------debug---------------
										--print("test")
		if flag == 1 then break end
			-- a good path found jump out of this x searching
			-- else means we have searched every x in S
			--    			tree is built
			--				need to change label next
		
		self:update_labels()
	
										------debug------------------
										--[[
										---self:add_to_tree(2,1)
										--self:add_to_tree(3,1)
										print("parent_table:")	
										for x = 1,N do
											print(parent_table[x])	
										end

										print("slack_table:")	
										for x = 1,N do
											print(slack[x])	
										end

										print("lx_table:")	
										for x = 1,N do
											print(self.lx[x])	
										end
										print("ly_table:")	
										for y = 1,N do
											print(self.ly[y])	
										end
										--]]
										----------------------------
		queue = nil; queue = Queue:create()
		flag = 0
		for y = 1,N do
			if T[y] ~= true and slack[y] == 0 then
				-- means a new equal edge is found, a new Y
				if self.match_of_Y[y] == nil then
					-- this Y is single, record and break
										-----------------------------
										--print("new edge found after changing label")
										--io.read()
										-----------------------------

					x = slackx[y]
					flag = 1
					edgex = x; edgey = y
					break
				else
					-- this Y is not single, add to tree
					T[y] = true
					if S[self.match_of_Y[y]] == nil then
						queue:add(self.match_of_Y[y])
						self:add_to_tree(self.match_of_Y[y],slackx[y])
					end
				end
			end
		end

		if flag == 1 then break end
		-- if a good path found, jump out, otherwise keep searching x
	end	-- end of x searching (while true)

	if flag == 1 then  -- a good path
		self.maxMatch = self.maxMatch + 1

										----------------------------
										--print("edgex edgey = ",edgex,edgey)
										--io.read()

		------ change the path -------
		local px = edgex
		local py = edgey
		local temp
		while px ~= -2 do
			temp = self.match_of_X[px]
			self.match_of_Y[py] = px
			self.match_of_X[px] = py
			py = temp
			px = parent_table[px]
		end
		-------------------------------
										----debug-------------------------
										--[[
										print("match table X")
										for x = 1,N do
											print(self.match_of_X[x])	
										end
										print("match table Y")
										for y = 1,N do
											print(self.match_of_Y[y])	
										end
										--]]
										----------------------------------
		self:aug()
	end

	-- if it comes here, that means all the possibility is tried and no other edges can be add,
	-- then it is the end, match table is what we got
end	--end of function aug

return Hungarian

