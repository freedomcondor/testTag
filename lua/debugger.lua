debug.DEBUGGERVAR = {}
debug.DEBUGGERVAR.firstenter = true
debug.DEBUGGERVAR.step = false
debug.DEBUGGERVAR.focalfunc = nil
debug.DEBUGGERVAR.functionstop = nil
debug.DEBUGGERVAR.stepoverstack = 0

debug.DEBUGGERVAR.configfilename = "config_debugger.lua"
debug.DEBUGGERVAR.tracebackfilename = "traceback.txt"
debug.DEBUGGERVAR.tracebackfileswitch = false

debug.DEBUGGERVAR.level = {n = 0}
debug.DEBUGGERVAR.breakpoint = {n = 0}
debug.DEBUGGERVAR.list = {n = 0}

debug.DEBUGGERVAR.laststep = {}

local f = io.open(debug.DEBUGGERVAR.configfilename,"r")
if f ~= nil then
	f:close()
	dofile(debug.DEBUGGERVAR.configfilename)
end

debug.DEBUGGERVAR.focalfunc = nil

if debug.DEBUGGERVAR.firstenter == true then
	debug.DEBUGGERVAR.step = "stepover"
else
	debug.DEBUGGERVAR.step = false
end

--local tracef = io.open(debug.DEBUGGERVAR.tracebackfilename,"w")

------------------------------------------------------------------------
--   Hook Call and Return
------------------------------------------------------------------------

function debug.hookfunction(event, line)
	local targetlevel = 2
	if event == "call" then
		debug.hookcall(event, targetlevel + 1)
	elseif event == "return" then
		debug.hookreturn(event, targetlevel + 1)
	elseif event == "line" then
		debug.hookline(event, line, targetlevel + 1)
	end
end

function debug.doIstop(line,s)

	-- if a call stop or a return stop
	if debug.DEBUGGERVAR.functionstop == true then
		debug.DEBUGGERVAR.functionstop = nil
		return true
	end

	-- step in mode, always stop
	if debug.DEBUGGERVAR.step == "stepin" then
		return true
	end

	-- step over mode, stepoverstack == 0
	if debug.DEBUGGERVAR.step == "stepover" and
	   debug.DEBUGGERVAR.stepoverstack == 0 then
		return true
	end

	-- breakpoint
	for i = 1, debug.DEBUGGERVAR.breakpoint.n do
		if debug.DEBUGGERVAR.breakpoint[i].file == s.short_src and
		   debug.DEBUGGERVAR.breakpoint[i].line == line and
		   debug.DEBUGGERVAR.breakpoint[i].enable == true then
			return true
		end

		--[[ breakpoint on empty line
		if debug.DEBUGGERVAR.breakpoint[i].file == s.short_src and
		   debug.DEBUGGERVAR.breakpoint[i].file == debug.DEBUGGERVAR.laststep.file and
		   debug.DEBUGGERVAR.breakpoint[i].line > debug.DEBUGGERVAR.laststep.line and
		   debug.DEBUGGERVAR.breakpoint[i].line < line and
		   debug.DEBUGGERVAR.laststep.func == s.name then
			return true
		end
		--]]
	end

	return false
end

------------------------------------------------------------------------
--   Hook Call and Return
------------------------------------------------------------------------

function debug.hookcall(event, targetlevel)
	local s = debug.getinfo(targetlevel)
	-- add a level
		-- to be filled

	-- add stepoverstack
	debug.DEBUGGERVAR.stepoverstack = debug.DEBUGGERVAR.stepoverstack + 1

	-- update focal
	debug.DEBUGGERVAR.focalfunc = s.name

	-- check breakpoint
	local bp = debug.DEBUGGERVAR.breakpoint
	for i = 1, bp.n do
		if bp[i].line == s.name and
		   bp[i].enable == true then
			debug.DEBUGGERVAR.functionstop = true
		end
	end
end

function debug.hookreturn(event, targetlevel)
	-- decrease a level
		-- to be filled

	-- decrease a stepoverstack
	if debug.DEBUGGERVAR.stepoverstack > 0 then
		debug.DEBUGGERVAR.stepoverstack = debug.DEBUGGERVAR.stepoverstack - 1
	end

	-- update focal
	local s = debug.getinfo(targetlevel)
	debug.DEBUGGERVAR.focalfunc = s.name

	-- if a function stop ?
	--debug.DEBUGGERVAR.functionstop = true
end

------------------------------------------------------------------------
--   Hook Line
------------------------------------------------------------------------

function debug.hookline(event, line, targetlevel)
	-- record traceback
	if debug.DEBUGGERVAR.tracebackfileswitch == true then
		local tracef = io.open(debug.DEBUGGERVAR.tracebackfilename,"w")
		tracef:write(debug.traceback())
		tracef:close()
	end

	-- do I stop?
	local s = debug.getinfo(targetlevel)
	if debug.doIstop(line,s) == false then
		debug.DEBUGGERVAR.laststep.file = s.short_src
		debug.DEBUGGERVAR.laststep.func = s.name
		debug.DEBUGGERVAR.laststep.line = line

		return nil
	end
	local window = debug.DEBUGGERVAR.window or 20

	-- I stop

	-- show trackback
	print("------------------------------------------------------")
	print("------------------------------------------------------")
	print(debug.traceback())

	-- show file
	print(s.short_src .. ":")
	print("-----------------------------------")
	debug.showFile(s.short_src, line, window)

	-- show list
	print("-----------------------------------")
	debug.showList(targetlevel+1)
	print("-----------------------------------")

	-- command
	repeat
		local c = io.read()
		local command, value = debug.commandBind(c)

		-- control --------------------------------------------
		if command == "s" then
			debug.DEBUGGERVAR.step = "stepin"
			--return nil
			break
		end
		if command == "n" or command == nil then
			debug.DEBUGGERVAR.step = "stepover"
			debug.DEBUGGERVAR.stepoverstack = 0
			--return nil
			break
		end

		if command == "q" then
			os.exit()
		end

		if command == "c" then
			debug.DEBUGGERVAR.step = false
			--return nil
			break
		end

		if command == "r" then
			for i = 1, debug.DEBUGGERVAR.breakpoint.n do
				debug.DEBUGGERVAR.breakpoint[i].enable = false
			end
			debug.DEBUGGERVAR.step = false
			break
		end

		-- show and list --------------------------------------
		if command == "p" then
			local str,cc = debug.getvaluefromstring(targetlevel+1,value[1])
			if str ~= value[1] then
				print(value[1],":",str,"=",cc)
			else
				print(str,"=",cc)
			end
		end

		if command == "addlist" or command == "al" then
			debug.DEBUGGERVAR.list.n = debug.DEBUGGERVAR.list.n+1
			debug.DEBUGGERVAR.list[debug.DEBUGGERVAR.list.n] = value[1]
			print("-----------------------------------")
			debug.showList(targetlevel+1)
			print("-----------------------------------")
		end

		if command == "deletelist" or command == "dl" then
			if value[1] == "all" then
				debug.DEBUGGERVAR.list = {n = 0}
			elseif tonumber(value[1]) ~= nil then 
				value[1] = tonumber(value[1])
				if value[1] <= debug.DEBUGGERVAR.list.n then
					for i = value[1], debug.DEBUGGERVAR.list.n-1 do
						debug.DEBUGGERVAR.list[i] = debug.DEBUGGERVAR.list[i+1]
					end
					debug.DEBUGGERVAR.list[debug.DEBUGGERVAR.list.n] = nil
					debug.DEBUGGERVAR.list.n = debug.DEBUGGERVAR.list.n - 1
				end
			end
			print("-----------------------------------")
			debug.showList(targetlevel + 1)
			print("-----------------------------------")
		end

		-- save config ----------------------------------------
		if command == "saveconfig" or command == "sc" then
			saveConfig()
			print("config saved")
		end

		-- break point ----------------------------------------
		if command == "b" then
			if tonumber(value[1]) ~= nil then value[1] = tonumber(value[1]) end
			debug.DEBUGGERVAR.breakpoint.n = debug.DEBUGGERVAR.breakpoint.n + 1
			local bn = debug.DEBUGGERVAR.breakpoint.n
			debug.DEBUGGERVAR.breakpoint[bn] = {file = s.short_src, line = value[1], enable = true}
			print("-----------------------------------")
			debug.showFile(s.short_src, line, window)
			print("-----------------------------------")
			debug.showBreakpoints()
			print("-----------------------------------")
		end

		if command == "lb" then
			debug.showBreakpoints()
		end

		if command == "eb" or command == "enablebreakpoint" then
			if tonumber(value[1]) ~= nil then 
				value[1] = tonumber(value[1])
				if value[1] <= debug.DEBUGGERVAR.breakpoint.n then
					debug.DEBUGGERVAR.breakpoint[value[1]].enable = true
				end
			end
			print("-----------------------------------")
			debug.showBreakpoints()
			print("-----------------------------------")
		end

		if command == "sb" or command == "suspendbreakpoint" then
			if tonumber(value[1]) ~= nil then 
				value[1] = tonumber(value[1])
				if value[1] <= debug.DEBUGGERVAR.breakpoint.n then
					debug.DEBUGGERVAR.breakpoint[value[1]].enable = false
				end
			end
			print("-----------------------------------")
			debug.showBreakpoints()
			print("-----------------------------------")
		end
		
		if command == "db" then
			if value[1] == "all" then
				debug.DEBUGGERVAR.breakpoint = {n = 0}
			elseif tonumber(value[1]) ~= nil then 
				value[1] = tonumber(value[1])
				if value[1] <= debug.DEBUGGERVAR.breakpoint.n then
					for i = value[1], debug.DEBUGGERVAR.breakpoint.n-1 do
						debug.DEBUGGERVAR.breakpoint[i] = debug.DEBUGGERVAR.breakpoint[i+1]
					end
					debug.DEBUGGERVAR.breakpoint[debug.DEBUGGERVAR.breakpoint.n] = nil
					debug.DEBUGGERVAR.breakpoint.n = debug.DEBUGGERVAR.breakpoint.n - 1
				end
			end
			print("-----------------------------------")
			debug.showBreakpoints()
			print("-----------------------------------")
		end
	until command == "s" or command == "n" or command == nil or command == "r"

	debug.DEBUGGERVAR.laststep.file = s.short_src
	debug.DEBUGGERVAR.laststep.func = s.name
	debug.DEBUGGERVAR.laststep.line = line

	return nil
end


------------------------------------------------------------------------
--   Command
------------------------------------------------------------------------

function debug.commandBind(c)
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

------------------------------------------------------------------------
--   Breakpoint
------------------------------------------------------------------------
function debug.showBreakpoints()
	print("breakpoints:")
	for i = 1, debug.DEBUGGERVAR.breakpoint.n do
		print(i,debug.DEBUGGERVAR.breakpoint[i].file,
				debug.DEBUGGERVAR.breakpoint[i].line,
				debug.DEBUGGERVAR.breakpoint[i].enable)
	end
end

------------------------------------------------------------------------
--   Vars
------------------------------------------------------------------------

function debug.showList(targetlevel)
	for i,v in ipairs(debug.DEBUGGERVAR.list) do
		local th, ta = debug.tableBind(v)

		local var = debug.getvarvalue(targetlevel+1,th)
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

function debug.getvaluefromstring(targetlevel, name)
	local th, ta = debug.tableBind(name)

	print(th)
	for _,pp in ipairs(ta) do print(pp) end

	local var = debug.getvarvalue(targetlevel+1,th)
	local str = th
	local cc = var
	if type(var) == "table" then
		for _,vv in ipairs(ta) do
			if cc == nil then break end
			str = str .. "." .. vv
			cc = cc[vv]
		end
	end
	return str,cc
end

function debug.tableBind(c)
	local head
	local arr = {}
	local i = 0
	for w in string.gmatch(c,"([^%[.%]]+)") do
		i = i + 1
		if i == 1 then
			head = w
		else
			if tonumber(w) ~= nil then w = tonumber(w) end
			table.insert(arr,w)
		end
	end
	return head, arr
end

function debug.getvarvalue (level, name)
	local value, found

	--print("name = ",name)

	-- try local variables
	local i = 1
	while true do
		local n, v = debug.getlocal(level, i)
		if not n then break end
		if n == name then
			value = v
			found = true
		end
		i = i + 1
	end
	if found then return value end

	-- try upvalues
	local func = debug.getinfo(level).func
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


------------------------------------------------------------------------
--   show File
------------------------------------------------------------------------
function debug.showFile(filename, line, window)
	local lines, n = debug.fileReader(filename)

	local page = math.floor((line-1) / window)
	local pagestart = page * window + 1
	local pageend = (page+1) * window
	for i = pagestart, pageend do
		if i > n then
			break
		end
		local str
		local bpflag = 0
		for j = 1, debug.DEBUGGERVAR.breakpoint.n do
			if filename == debug.DEBUGGERVAR.breakpoint[j].file and
			   i == debug.DEBUGGERVAR.breakpoint[j].line then
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

function debug.fileReader(filename)
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

--------------------------------------------------------------------
--  SaveConfig
--------------------------------------------------------------------

function saveConfig()
	local f = io.open(debug.DEBUGGERVAR.configfilename,"w")
	f:write(string.format("debug.DEBUGGERVAR.firstenter = %s\n", debug.DEBUGGERVAR.firstenter))
	f:write(string.format("debug.DEBUGGERVAR.step = false\n"))
	f:write(string.format("debug.DEBUGGERVAR.focalfunc = nil\n"))
	f:write(string.format("-------------- BreakPoints ------------\n"))
	f:write(string.format("debug.DEBUGGERVAR.breakpoint = {n = %d}\n",
												debug.DEBUGGERVAR.breakpoint.n))
	for i = 1, debug.DEBUGGERVAR.breakpoint.n do
		if type(debug.DEBUGGERVAR.breakpoint[i].line) == "number" then
			f:write(string.format(
					"debug.DEBUGGERVAR.breakpoint[%d] = {file = \"%s\",line = %d, enable = %s}\n",
					i,debug.DEBUGGERVAR.breakpoint[i].file,
					  debug.DEBUGGERVAR.breakpoint[i].line,
					  debug.DEBUGGERVAR.breakpoint[i].enable))
		else
			f:write(string.format(
					"debug.DEBUGGERVAR.breakpoint[%d] = {file = \"%s\",line = \"%s\", enable = %s}\n",
					i,debug.DEBUGGERVAR.breakpoint[i].file,
					  debug.DEBUGGERVAR.breakpoint[i].line,
					  debug.DEBUGGERVAR.breakpoint[i].enable))
		end
	end

	f:write(string.format("-------------- Var List ------------\n"))
	f:write(string.format("debug.DEBUGGERVAR.list = {n = %d}\n",debug.DEBUGGERVAR.list.n))
	for i = 1, debug.DEBUGGERVAR.list.n do
		f:write(string.format(
				"debug.DEBUGGERVAR.list[%d] = \"%s\"\n",
				i,debug.DEBUGGERVAR.list[i]))
	end
	f:close()
end

--------------------------------------------------------------------
--------------------------------------------------------------------

debug.sethook(debug.hookfunction,"lcr")
