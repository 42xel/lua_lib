---------------------------------The sugar library----------------------

--to implement some sugar coated utilities




sugar = {}


-------------------------------------------sweetening file reading/writing---------------------------------------------------------


--basically, for google caode jam, each line consist of space separated integers

function GCJread(pattern, fun)
	fun = not pattern and not fun and tonumber or fun
	pattern = not pattern and "%g+" or pattern
	local r = {}
	for c in io.read():gmatch(pattern) do
		table.insert(r, fun and fun(c) or c)
	end
	return table.unpack(r)
end


function GCJwrite(...)
	return io.write(table.concat({...}, " "), "\n")
end


function GCJcase(t, ...)
	print("Case #" .. t .. ":", ...)
	return GCJwrite("Case #" .. t .. ":", ...)
end


function GCJreadablein(filter, name)
	local pos = io.input():seek()
	io.input():seek("set")

	local file
	if name then
		file = io.open(name, "w")
	else
		file = io.open("readablein.rin", "w")
	end

	io.input():seek("set", pos)

	local T = io.read()
	file:write(T, "\n")
	if filter == 0 then
		for t = 1, T do
			file:write("\nCase #" .. t .. ": ", io.read("L"))
		end
		if (io.read() or "") ~= "" then
			error ("wrong number of lines in io.input() (1 + " .. T .. " expected)\nYou might have not open the correct input, or there might be more than one line per test case", 2)
		end
	elseif type(filter) == "number" then
		for t = 1, T do
			local l = {GCJread"%g+"}
			file:write("\nCase #" .. t .. ": ", table.concat(l, " "), "\n")
			for n = 1, l[filter] do
				file:write(io.read("L"))
			end
		end
		if (io.read() or "") ~= "" then
			error ("wrong number of lines in io.input() (1 + sum of the " .. filter .. "-th expected)\nYou might have not open the correct input, or have provided incorrect informations about how to retrieve the number of line per test case.", 2)
		end
	elseif type(filter) == "function" then
		for t = 1, T do
			local l = io.read("L")
			file:write("\nCase #" .. t .. ": ", l, "\n")
			for n = 1, filter(l) do
				file:write(io.read("L"))
			end
		end
		if (io.read() or "") ~= "" then
			error ("wrong number of lines in io.input()\nYou might have not open the correct input, or have provided incorrect informations about how to retrieve the number of line per test case.", 2)
		end
	else
		error("bad argument #1 to 'GCJreadablein' (number expected, got " .. type(filter) .. ")", 2)
	end


	io.input():seek("set", pos)
	file:close()
	return
end
---------------------------------------------- sweetening the debug library -------------------------------------------------



sugar.d = {raw = {}}

--warps debug functions that takes a function as their first argument (does not work with threads), such that the functions directly calling them act as the corresponding debug function regarding stack level and error
for k, v in ipairs {"getinfo", "getlocal", "getupvalue", "setlocal", "setupvalue"} do
	sugar.d.raw[v] = function (f, ...)
		if tonumber(f) then
			f = f + 3
		end
		local p, n, v1, v2 = pcall(debug[v], f, ...)
		if p then
			return n, table.unpack({v1, v2})
		end
		error(n, 2)
	end
end
--ditto for upvaluejoin. Note that f1 and f2 has to be function, not number
function sugar.d.raw.upvaluejoin (f1, n1, f2, n2)
	local p, n, v = pcall(debug.upvaluejoin, f1, n1, f2, n2)
	if not p then
		error(n, 2)
	end
--upvaluejoin does not return anything
end




--rewrite debug function of functions with a function and a local/upvalue index as first argument (does not work with threads). If the index is a number, equivalent to the regular debug function, if it is a string, it searches the corresponding index (normally, the last encountered, which should be the visible one for getlocal) if any (returns nil otherwise), performs the debug function and returns the index instead of the name of the variable, along with other results
for k, v in ipairs {"getlocal", "getupvalue", "setlocal", "setupvalue"} do
	sugar.d[v] = function (f, l, ...)
		if type(l) == "string" then
			local i, nparams, idx = 0, debug.getinfo(0,'u').nparams, 0
			while true do		--checking params for locals
				i = i + 1
				local n = sugar.d.raw["get" .. v:sub(4)](f, i)
				if n == l then
					idx = i
				elseif i >= nparams then
					break
				end
			end
			i = 0
			while true do		--checking varargs for locals
				i = i - 1
				n = sugar.d.raw["get" .. v:sub(4)](f, i)
				if n == l then
					idx = i
				elseif not n then
					break
				end
			end
			i = nparams
			while true do		--checking anything left
				i = i + 1
				n = sugar.d.raw["get" .. v:sub(4)](f, i)
				if n == l then
					idx = i
				elseif not n then
					break
				end
			end
			
			if idx == 0 then
				return nil
			end
			return idx, select(2, sugar.d.raw[v](f, idx, ...))
		else
			return sugar.d.raw[v](f, l)
		end
	end
end
function sugar.d.upvaluejoin(f1, l1, f2, l2)
--ditto for upvaluejoin. Note that f1 and f2 has to be function, not number
	if type(l1) == "string" then
		l1 = sugar.d.getupvalue(f1, l1)
	end
	if type(l2) == "string" then
		l2 = sugar.d.getupvalue(f2, l2)
	end
	sugar.d.raw.upvaluejoin (f1, n1, f2, n2)
--upvaluejoin does not return anything
end


--get and setfenv. Note that it is not as powerfull as pre 5.2 version, as f cannot refer to an active function of the stack, but must refer to a value function (and it's maybe better that way)
function sugar.d.getfenv(f) return select(2, sugar.d.getupvalue(f, "_ENV")) or _G end --not really usefull

function sugar.d.setfenv(f, env)
	sugar.d.raw.setupvalue (f, "_ENV", env)
	return f
end



--a global empty table that acts as if it contained local variables, in an _ENV style.
--_LOCAL(i) returns that table for stack level i (_LOCAL(0) acts as _LOCAL) and _LOCAL() researches the visible local variable (from zero)
local localkey = {}
local localupmeta
local localmeta = {
	__index = function (t,k)
		return select(-1, sugar.d.getlocal(2 + t[localkey], k))		--1 or 2 + t[localkey]?? (tail call)
	end,
	__newindex = function(t, k, v)
		sugar.d.setlocal(1 + t[localkey], k, v)
	end
}

localmeta.__call = function (t, i)
	if i ~= nil then
		return setmetatable({[localkey] = t[localkey] + i}, localmeta)
	end
	return setmetatable({[localkey] = t[localkey]}, localupmeta)
end

--the result of _LOCAL(). _LOCAL(i) acts as _LOCAL, so _LOCAL(2)(-5)() still is valid (though will most likely raise error, _LOCAL(-2) being the limit), however _LOCAL()() is not

--returns the index, the value and the stack level, if any, of a visible local variable. note that f has to be a number.
function sugar.d.getlocalup(f, l)
	f = f + 1
	while debug.getinfo(f, "S") do
		local _, r = sugar.d.getlocal(f, l)
		if _ then
			return f - 1, _, r
		end
		f = f + 1
	end
end
--sets the value and returns the index and the stack level, if any, of a visible local variable
function sugar.d.setlocalup(f, l, v)
	f = f + 1
	while debug.getinfo(f, "S") do
		local _ = sugar.d.setlocal(f, l, v)
		if _ then
			return f - 1, _
		end
		f  = f + 1
	end
end

localupmeta = {
	__index = function (t, k)
		return select(-1, sugar.d.getlocalup(2 + t[localkey], k))		--1 or 2 + t[localkey]?? (tail call)
	end,
	__newindex = function (t, k, v)
		sugar.d.setlocalup(1 + t[localkey], k, v)
	end
}

_LOCAL = setmetatable({[localkey] = 0}, localmeta)

	


--rewritte the debug.debug() function so that local value are accessible (the visible one)
--function sugar.d.debug()
--end



----------------------------------------- sweetenining strings -------------------------------

--alow, among others, using s(i) for the i-th character and s(i,j) for s:sub(i,j); on by default. sugar.sweetstring (b) turns in on/off if b is true/false respectively, and toggles if b is not provided
local bstring, stringmeta, string = false, getmetatable"", string
local stringswmeta = {}

--s(...) returns various substrings of s
stringswmeta.__call = function (s, ...)
	local a1, a2, a3 = ...
	local typ = type(a1)
	if typ == "number" then
		a2 = a2 or a1
		return s:sub(a1, a2)
	elseif typ == "string" then
		if type(a2) == "number" or "nil" then
			return s:match(a1, a2)
		else
			return s:gsub(a1, a2, a3)
		end
	else
		error(select(2, pcall(s, ...)), 2) --errors properly
	end
end


--implementing octal and binary

local function sugar_tonumber (s)
	if s:sub(1, 1) == "0" then
--octal or binary
		if s:sub(2, 2):lower() == "b" then
			return tonumber(s:sub(3), 2)
		elseif s:sub(2, 2):lower() == "o" then
--octal
			return tonumber(s:sub(3), 8)
		else
--useless? (due to coercission)
			return tonumber(s, 8)
		end
	else
		return tonumber(s)
	end
end


function stringswmeta.__add (a, b)
	return sugar_tonumber(a) + sugar_tonumber(b)
end
function stringswmeta.__sub (a, b)
	return sugar_tonumber(a) - sugar_tonumber(b)
end
function stringswmeta.__mul (a, b)
	return sugar_tonumber(a) * sugar_tonumber(b)
end
function stringswmeta.__div (a, b)
	return sugar_tonumber(a) / sugar_tonumber(b)
end
function stringswmeta.__mod (a, b)
	return sugar_tonumber(a) % sugar_tonumber(b)
end
function stringswmeta.__pow (a, b)
	return sugar_tonumber(a) ^ sugar_tonumber(b)
end
function stringswmeta.__unm (a)
	return - sugar_tonumber(a)
end
function stringswmeta.__idiv (a, b)
	return sugar_tonumber(a) // sugar_tonumber(b)
end
function stringswmeta.__band (a, b)
	return sugar_tonumber(a) & sugar_tonumber(b)
end
function stringswmeta.__bor (a, b)
	return sugar_tonumber(a) | sugar_tonumber(b)
end
function stringswmeta.__bxor (a, b)
	return sugar_tonumber(a) ~ sugar_tonumber(b)
end
function stringswmeta.__bnot (a)
	return ~ sugar_tonumber(a)
end
function stringswmeta.__shl (a, n)
	return sugar_tonumber(a) << sugar_tonumber(n)
end
function stringswmeta.__shr (a, n)
	return sugar_tonumber(a) >> sugar_tonumber(n)
end


function sugar.sweetstring (b)
	if b == "?" then
		return bstring
	elseif b == nil then
		b = not bstring
	end
	if b then
		for k, v in pairs(stringswmeta) do
			stringmeta[k] = v
		end
	else
		for k, v in pairs(stringswmeta) do
			stringmeta[k] = nil
		end
	end
	bstring = not (not (b))
	return bstring
end

sugar.sweetstring (1)

---------------------------sweetening misc------------------

local oldtype = type
function sugar.type(x)
	local r = oldtype(x)
	if r ~= "table" then
		return math.type(x) or r
	end
	local m = getmetatable(x)
	if not typ or not rawget(m, "__type") then
		return "table"
	end
	local typ = rawget(m, "__type")		--it's how regular metamethods work
	if oldtype(typ) == "string" then
		return typ
	else
		return typ(x)
	end
end

local type = sugar.type



