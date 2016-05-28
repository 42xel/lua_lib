local unionfind, sizekey = {}, {}


local tree = require "tree" or error ("unionfind module requires tree", 2)


local meta = {__index = unionfind}
function meta.__len (t)
	return t[sizekey]
end


local metaset = {__len = function(t) return t.size end}

local function setnew(v)
	local r = {rank = 0, size = 1}
	local t = tree.new(r)
	r.tree = t
	return setmetatable(r, metaset)
end


local tree_depth = tree.new(1):depth()

local function setnex(A, S)
	local el
	S, el = tree_depth (A.tree, S)
	if not S then
		return
	end
	el:emancipate()
	A.tree:insert(el)
	return S, el.node
end

function metaset.__pairs(set)
	local _, _, state = set.tree:depth()
	return setnex, set, state
end



function unionfind.newsgton(...)
--input is the list of elements
	local r, i = {}, {...}
	r[sizekey] = #i
	for _, v in ipairs (i) do
		r[v] = setnew(v).tree
	end
	return setmetatable(r, meta)
end


function unionfind.new(...)
--input is the list of sets, given as the list of their elements
	local r, i = {}, {...}
	r[sizekey] = #i
	for _, l in ipairs (i) do
		local c, s = l[1]
		s = setnew(c)
		r[c] = s.tree
		s.size = #l
		if s.size > 1 then
			s.rank, s = 1, s.tree
			for k = 2, #l do
				r[l[k]] = tree.new()
				s:insert(r[l[k]])
			end
		end
	end
	return setmetatable(r, meta)
end


function unionfind.insert(u, fst, ...)
--add a disjoint set
	u[sizekey] = u[sizekey] + 1
	local s = setnew(fst)
	u[fst] = s.tree
	s.size = 1 + select("#", ...)
	for _, v in ipairs{...} do
		u[v] = tree.new()
		s.tree:insert(u[v])
	end
	return s
end





function unionfind.find (u, a)
	a = u[a]
	local r = a:root()
	while a.parent do
		a = a:emancipate(), r:insert(a)			--Aurélien, ULM représente, master of the snippet
	end
	return r.node
end

function unionfind.union (u, a, b)
	a, b = u:find (a), u:find (b)
	if a ~= b then
		if a.rank == b.rank then
			a.rank = a.rank + 1
		elseif a.rank < b.rank then
			a, b = b, a
		end
		a.tree:insert(b.tree)
		b.tree.node = nil			--so that (the set) b can be cleaned by the GC
		a.size = a.size + b.size
		u[sizekey] = u[sizekey] - 1
	end
	
	return a
end


return setmetatable({}, {__index = unionfind, __metatable = false})
