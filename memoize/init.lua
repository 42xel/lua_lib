local _nil, _parent, _key, _value = {}, {}, {}, {}

local meta = {}

local function metaget (t, mode, ...)
	if mode == nil then
		return nil
	end
	if select("#", ...) == 0 then
		if mode == "r" then
			return rawget(t, _value)
		end
		return t
	end

	local a = ...
	if a == nil then a = _nil end
	if mode == "r" then
		return metaget (t[a], mode, select(2,...))
		--if a is not in t, the nil returned by __index will replace mode

	elseif mode == "w" then
		local t2 = t[a]
		--if a is not in t, the nil returned by __index is ignored
		return metaget (t2, mode, select(2, ...))
	else
		error("invalide argument mode :" .. string.format("%q", mode) .. '\n try "r" or "w"')
	end
end
meta.__call = metaget

meta.__index = function (t, k)
local r = setmetatable({[_parent] = t, [_key] = k}, meta)
	return r, nil
	--the nil is used by metaget
	--to call the value stored at t[i1][i2], the following will work : t("r", i1, i2); t[i1][i2]("r")
	--t[i1][i2] will call a subtree, select(-1, t[i1][i2]) will be nil if it does not exist yet
end

meta.__newindex = function  (t, k, v)
	if k == "w" then
		if v == nil then
			v = _nil
		end
		t[_value] = v
	else
		if k == nil then
			k = _nil
		end
		
		if not rawget(t, _parent) then 
			rawset(t, k, v)
		else
			t[_parent][t[_key]] = setmetatable({[k] = v},meta)	--this propagates along all the not yet existant nodes
		end
	end
end
--to push the value v at t[i1][i2], the following will work : t("w", i1, i2)["w"] = v; t[i1][i2]["w"] = v

local function pack(...)	
	local r = {}
	local function f(...)
		if select("#", ...) == 0 then
			return 
		end
		local a = ...
		a = (a == nil and _nil
			or a)
		table.insert(r, a)
		return f(select(2, ...))
	end
	return r, f(...) -- in this order, f(...) should be nothing (not even nil)
end

local function unpack (t)
	if #t == 1 then
		local a = t[1]
		if a == _nil then
			a = nil
		end
		return a
	end
	
	local function f(...)
		if select("#", ...) == 0 then
			return
		end
		local a = ...
		if a == _nil then
			a = nil
		end
--		return f(i + 1, select(2, ...), a) --this should have been the proper way to do tail recursive mapliste, but if something is put after it, select(2, ...) only gives its first element (intuitive liste appending is not possible)
		return a, f(select(2, ...))		--the number of arguments will be limited by the stack size :'(
	end
	return f(table.unpack(t))
end



function memoizedum (fun, init)
	init = init or {}
	local mem = setmetatable({}, meta)
	for k, v in pairs(init) do
		mem("w", k)["w"] = pack(v)
	end
	return function (...)
		local r = mem("r", ...)
		if not r then
			r = pack(fun (...))
			mem("w", ...)["w"] = r
		end
		return unpack(r)
	end
end


function memoizerec (fun, init)
	init = init or {}
	local mem = setmetatable({}, meta)
	for k, v in pairs(init) do
		mem("w", k)["w"] = pack(v)
	end

	
	local f = load(string.dump(fun))

	local function mfun (...)
		local r = mem("r", ...)
		if not r then
			r = pack(f (...))
			mem("w", ...)["w"] = r
		end
		return unpack(r)
	end


	local idx, env, envidx, ref = 1
	while true do
		local name, value = debug.getupvalue(fun, idx)
		if not name then break end
		if value == fun then --fun is a recursive local function 
			ref = true
			debug.upvaluejoin(f, idx, function () return mfun end, 1)
--previously, to treat global function that refer to themself as a global value. it is not clean since such function is not really recursive : it calls whatever global function of their name : recursivity can easily and legally be manipulated, while genuine local recursive function cannot without the debug library. to make a genuine global recusive function, make it local, then give it a global name.
--		elseif name == "_ENV" and not ref then
--			env, envidx = value, idx
--			debug.upvaluejoin(f, idx, fun, idx)
		else
			debug.upvaluejoin(f, idx, fun, idx)
		end
		idx = idx + 1
	end

--[[	if env and not ref then
		local _env, b = setmetatable({}, {__index = env})
		for k,v in pairs(env) do
			if v == fun then --fun is a global function
				b, _env[k] = true, mfun
			end
		end
		if b then
			debug.upvaluejoin(f, envidx, function () return _env end, 1)
		end
	end
--]]
	return mfun
end


function memoizestack (fun, ...)
	local init, default = ..., nil
	if select ("#", ...) == 0 then
		error ("init must be provided (at least as a nil value)", 2)
	elseif select("#", ...) == 1 then
		if not init then
			error ("default_result is missing in memoizestack. If the absence of value is the default result, you have to provide init as an empty table", 2)
		else
			default = pack (select(2, next(init))) --it's ok, #... = 1
		end
	else
		default = pack (select(2, ...))
	end
	init = init or {}
	
	local mem, stack = setmetatable({}, meta), {}
	for k, v in pairs(init) do
		mem("w", k)["w"] = pack(v)
	end
	

	local f = load(string.dump(fun))

	local function iter ()
		local l = #stack
		local r = pack(f(unpack(stack[l])))
		if l == #stack then
			mem("w", unpack(table.remove(stack)))["w"] = r
		end
		return iter ()
	end

	local function dummy (...)
		local r = mem("r", ...)
		if not r then
			table.insert(stack, pack(...))
			return unpack(default)
		end
		return unpack(r)
	end

	local function mfun (...)
		local r = mem("r", ...)
		if r then
			return unpack(r)
		end
		stack[1] = pack(...)
		pcall(iter)
		--iter ends by unpacking nil, when the stack is empty
		return unpack(mem("r", ...))
	end


	local idx, env, envidx, ref = 1
	while true do
		local name, value = debug.getupvalue(fun, idx)
		if not name then break end
		if value == fun then
			ref = true
			debug.upvaluejoin(f, idx, function () return dummy end, 1)
--		elseif name == "_ENV" and not ref then
--			env, envidx = value, idx
--			debug.upvaluejoin(f, idx, fun, idx)
		else
			debug.upvaluejoin(f, idx, fun, idx)
		end
		idx = idx + 1
	end

--[[	if env and not ref then
		local _env, b = setmetatable({}, {__index = env})
		for k,v in pairs(env) do
			if v == fun then
				b, _env[k] = true, dummy
			end
		end
		if b then
			debug.upvaluejoin(f, envidx, function () return _env end, 1)
		end
	end
--]]
	return mfun
end
