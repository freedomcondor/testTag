DEBUGGERVAR = {}
DEBUGGERVAR.firstenter = true
DEBUGGERVAR.step = false
DEBUGGERVAR.focalfunc = nil

DEBUGGERVAR.n_level = 0
DEBUGGERVAR.level = {}

DEBUGGERVAR.n_bp = 0
DEBUGGERVAR.breakpoint = {}

DEBUGGERVAR.n_list = 0
DEBUGGERVAR.list = {}

local f = io.open("config_debugger.lua","r")
if f ~= nil then
	f:close()
	dofile("config_debugger.lua")
end

luaPath_gl = ';../lua/'
luaPath_ar = ';../../lua/'
luaPath = '?.lua'
package.path = package.path .. luaPath_gl .. luaPath
package.path = package.path .. luaPath_ar .. luaPath

require("func")

if DEBUGGERVAR.firstenter == true then
	DEBUGGERVAR.step = "stepover"
else
	DEBUGGERVAR.step = false
end

function debugger(para)
	DEBUGGERVAR.focalfunc = "func"
	DEBUGGERVAR.n_level = 1
	DEBUGGERVAR.level[1] = "func"

	debug.sethook(step,"l")
	--dofile(mainfile)
	local res = func(para)
	return res
end

function step(event, line)
	local s = debug.getinfo(2)
	if s.short_src == "debugger.lua" then
		return nil
	end

	-- stop or not?
	if DEBUGGERVAR:stop(event, line, s) == false then
		return nil
	end

	-- show file
	local lines, n = fileReader(s.short_src)
	local window = 20
	if lines == nil then return nil end
	print("------------------------------------------------------")
	print("------------------------------------------------------")
	print(debug.traceback())
	print(s.short_src .. ":")
	print("-----------------------------------")
	showLines(lines, n, line, window, s.short_src)
	print("-----------------------------------")
	showList()
	print("-----------------------------------")

	-- get command
	repeat
		local c = io.read()
		local command, value = commandBind(c)
		--print(string.format("%s,%s,",command,value[1]))

		if command == "s" then
			DEBUGGERVAR.step = "stepin"
			return nil
		end
		if command == "n" or command == nil then
			DEBUGGERVAR.step = "stepover"
			--DEBUGGERVAR.focalfunc = s.short_src
			DEBUGGERVAR.focalfunc = s.name
			return nil
		end

		if command == "q" then
			os.exit()
		end

		if command == "c" or command == "r" then
			DEBUGGERVAR.step = false
			return nil
		end

		if command == "p" then
			local th, ta = tableBind(value[1])

			local var = getvarvalue(2,th)
			if type(var) == "table" then
				local str = th
				local cc = var
				for _,vv in ipairs(ta) do
					if cc == nil then break end
					str = str .. "." .. vv
					cc = cc[vv]
				end
				if str ~= value[1] then
					print(value[1],":",str,"=",cc)
				else
					print(str,"=",cc)
				end
			else
				print(value[1],"=",var)
			end
		end

		if command == "b" then
			if tonumber(value[1]) ~= nil then value[1] = tonumber(value[1]) end
			DEBUGGERVAR.n_bp = DEBUGGERVAR.n_bp + 1
			local bn = DEBUGGERVAR.n_bp
			DEBUGGERVAR.breakpoint[bn] = {file = s.short_src, line = value[1]}
			showLines(lines, n, line, window,s.short_src)

			showBreadpoints()
		end

		if command == "lb" then
			showBreadpoints()
		end
		
		if command == "db" then
			if value[1] == "all" then
				DEBUGGERVAR.n_bp = 0
				DEBUGGERVAR.breakpoint = {}
			elseif tonumber(value[1]) ~= nil then 
				value[1] = tonumber(value[1])
				if value[1] <= DEBUGGERVAR.n_bp then
					for i = value[1], DEBUGGERVAR.n_bp-1 do
						DEBUGGERVAR.breakpoint[i] = DEBUGGERVAR.breakpoint[i+1]
					end
					DEBUGGERVAR.breakpoint[DEBUGGERVAR.n_bp] = nil
					DEBUGGERVAR.n_bp = DEBUGGERVAR.n_bp - 1
				end
			end
			print("-----------------------------------")
			showBreadpoints()
			print("-----------------------------------")
		end

		if command == "addlist" or command == "al" then
			DEBUGGERVAR.n_list = DEBUGGERVAR.n_list + 1
			DEBUGGERVAR.list[DEBUGGERVAR.n_list] = value[1]
			print("-----------------------------------")
			showList()
			print("-----------------------------------")
		end
		if command == "deletelist" or command == "dl" then
			if value[1] == "all" then
				DEBUGGERVAR.n_list = 0
				DEBUGGERVAR.list = {}
			elseif tonumber(value[1]) ~= nil then 
				value[1] = tonumber(value[1])
				if value[1] <= DEBUGGERVAR.n_list then
					for i = value[1], DEBUGGERVAR.n_list-1 do
						DEBUGGERVAR.list[i] = DEBUGGERVAR.list[i+1]
					end
					DEBUGGERVAR.list[DEBUGGERVAR.n_list] = nil
					DEBUGGERVAR.n_list = DEBUGGERVAR.n_list - 1
				end
			end
			print("-----------------------------------")
			showList()
			print("-----------------------------------")
		end

		if command == "saveconfig" or command == "sc" then
			saveConfig()
			print("config saved")
		end
	until command == "s" or command == "n" or command == nil or command == "r"
	return nil
end

------------------------------------------------
function saveConfig()
	local f = io.open("config_debugger.lua","w")
	f:write(string.format("DEBUGGERVAR.firstenter = %s\n", DEBUGGERVAR.firstenter))
	f:write(string.format("DEBUGGERVAR.step = false\n"))
	f:write(string.format("DEBUGGERVAR.focalfunc = nil\n"))
	f:write(string.format("-------------- BreakPoints ------------\n"))
	f:write(string.format("DEBUGGERVAR.n_bp = %d\n",DEBUGGERVAR.n_bp))
	f:write(string.format("DEBUGGERVAR.breakpoint = {}\n"))
	for i = 1, DEBUGGERVAR.n_bp do
		if type(DEBUGGERVAR.breakpoint[i].line) == "number" then
			f:write(string.format(
					"DEBUGGERVAR.breakpoint[%d] = {file = \"%s\",line = %d}\n",
					i,DEBUGGERVAR.breakpoint[i].file,
					  DEBUGGERVAR.breakpoint[i].line))
		else
			f:write(string.format(
					"DEBUGGERVAR.breakpoint[%d] = {file = \"%s\",line = \"%s\"}\n",
					i,DEBUGGERVAR.breakpoint[i].file,
					  DEBUGGERVAR.breakpoint[i].line))
		end
	end

	f:write(string.format("-------------- Var List ------------\n"))
	f:write(string.format("DEBUGGERVAR.n_list = %d\n",DEBUGGERVAR.n_list))
	f:write(string.format("DEBUGGERVAR.list = {}\n"))
	for i = 1, DEBUGGERVAR.n_list do
		f:write(string.format(
				"DEBUGGERVAR.list[%d] = \"%s\"\n",
				i,DEBUGGERVAR.list[i]))
	end
	f:close()
end

function showList()
	for i,v in ipairs(DEBUGGERVAR.list) do
		local th, ta = tableBind(v)

		local var = getvarvalue(3,th)
		if type(var) == "table" then
			local str = th
			local cc = var
			for _,vv in ipairs(ta) do
				if cc == nil then break end
				str = str .. "." .. vv
				cc = cc[vv]
			end
			if str ~= v then
				print(i,v,":",str,"=",cc)
			else
				print(i,str,"=",cc)
			end
		else
			print(i,v,"=",var)
		end
	end
end
function DEBUGGERVAR:stop(event, line, deb)
	-- stop or not?
	--[[
	if DEBUGGERVAR.step == false then
		return false
	end
	--]]

	if DEBUGGERVAR.step == "stepin" then
		return true
	end
	if DEBUGGERVAR.step == "stepover" then
		local focal
		if deb.name == nil then
			focal = deb.short_src
		else
			focal = deb.name
		end
		if focal == DEBUGGERVAR.focalfunc then
			return true
		end
	end

	for i = 1, DEBUGGERVAR.n_bp do
		if deb.short_src == DEBUGGERVAR.breakpoint[i].file and
		   DEBUGGERVAR.breakpoint[i].line == line then
			return true
		end

		if DEBUGGERVAR.breakpoint[i].line == deb.name then
			if deb.linedefined + 1 == line then
				return true
			end
		end
	end

	return false
end

function showBreadpoints()
	print("breakpoints:")
	for i = 1, DEBUGGERVAR.n_bp do
		print(i,DEBUGGERVAR.breakpoint[i].file,
				DEBUGGERVAR.breakpoint[i].line)
	end
end

function tableBind(c)
	local head
	local arr = {}
	local i = 0
	for w in string.gmatch(c,"([^'.']+)") do
		i = i + 1
		if i == 1 then
			head = w
		else
			table.insert(arr,w)
		end
	end
	return head, arr
end

function commandBind(c)
	local command
	local arr = {}
	local i = 0
	for w in string.gmatch(c, "%S+") do
		i = i + 1
		if i == 1 then
			command = w
		else
			table.insert(arr,w)
		end
	end
	return command, arr
end

function getvarvalue (level, name)
	local value, found

	--print("name = ",name)

	-- try local variables
	local i = 1
	while true do
		local n, v = debug.getlocal(level+1, i)
		if not n then break end
		if n == name then
			value = v
			found = true
		end
		i = i + 1
	end
	if found then return value end

	-- try upvalues
	local func = debug.getinfo(level+1).func
	i = 1
	while true do
		local n, v = debug.getupvalue(func, i)
		if not n then break end
		if n == name then return v end
		i = i + 1
	end

	-- not found; get global
	return _ENV[name]
end

function fileReader(filename)
	local f = io.open(filename,"r")
	if f == nil then
		print("in filereader, no such file")
		return nil
	end

	local lines = {}
	local focal
	local i = 0
	local n = 0
	for focal in f:lines() do
		i = i + 1
		lines[i] = focal
		--print(focal)
	end
	n = i
	return lines, n
end

function showLines(lines, n, line, window, focalsrc)
	local page = math.floor((line-1) / window)
	local pagestart = page * window + 1
	local pageend = (page+1) * window
	for i = pagestart, pageend do
		if i > n then
			break
		end
		local str
		local bpflag = 0
		for j = 1, DEBUGGERVAR.n_bp do
			if focalsrc == DEBUGGERVAR.breakpoint[j].file and
			   i == DEBUGGERVAR.breakpoint[j].line then
				bpflag = 1
			end
		end
		if i == line and bpflag ~= 1 then
			str = "-->"
		elseif i == line and bpflag == 1 then
			str = "-*>"
		elseif i ~= line and bpflag == 1 then
			str = " * "
		else
			str = "   "
		end

		print(string.format("%s %3d",str,i), lines[i])
	end
end

--------------------------------------------------------------
--print(arg[1])
--debugger(arg[1])
--debugger(arg[1] or "main.lua")
