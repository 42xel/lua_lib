local queue = {}


local key1, key2, key3, key4 = {}, {}, {}, {}





------------------------------------fifo and lifo piles--------------------------------
--tables already acts as lifo pile, so there are not a priority to implement

local fifo, lifo, pilemeta = {}, {}, {}

function fifo.new(...)
	return setmetatable ({start = 1, pend = select("#", ...), pile = {...}, kind = fifo}, pilemeta)
end
function lifo.new(...)
	return setmetatable ({start = 1, pend = select("#", ...), pile = {...}, kind = lifo}, pilemeta)
end


function fifo.push(P, v)
	P.pend = P.pend + 1
	P.pile[P.pend] = v
end
lifo.push = fifo.push

function fifo.pop(P)
	if #P == 0 then
		return
	end
	local v = P.pile[P.start]
	P.pile[P.start] = nil
	P.start = P.start + 1
	return v
end
function lifo.pop(P)
	if #P == 0 then
		return
	end
	local v = P.pile[P.pend]
	P.pile[P.pend] = nil
	P.pend = P.pend - 1
	return v
end

function fifo.peek(P)
	return P.pile[P.start]
end
function lifo.peek(P)
	return P.pile[P.pend]
end

function fifo.clear(P)
	P.start, P.pend, P.pile = 1, 0, {}		--have fun GC!
end
lifo.clear = fifo.clear



function pilemeta.__len (P)
	return 1 + P.pend - P.start
end

function pilemeta.__index (t, k)
	if type(k) == "number" then
		return t.pile[t.start + k - 1]
	else
		return t.kind[k]
	end
end

function pilemeta.__newindex ()
	error"fifo piles are proxy. To put elements in and out of them, use push and pop"
end


function pilemeta.__pairs(t)
	return t:pop(), t
end
--__pairs is awesome : it not only overwrite pairs in a pleasant way, it also hide any private key1 you may have stored in proxies
--by the way, pilemeta would be useable as it is for a lifo pile



-----------------------------------(double) linked list------------------------------------
local list, listmeta = {}, {}

local nillist = {}

function list.new(...)
	if select("#", ...) == 0 then
		return nillist
	end
	return setmetatable({hd = ..., tl = list.new(select(2, ...))}, listmeta)
end

function listmeta.__len (L, c)
	c = c or 0
	if L then
		return listmeta.__len (L.tl, 1 + c)
	end
	return 0
end

function listmeta.__concat (L1, L2)
	local l = L1
	if not l then
		return L2
	end
	while l.tl do
		l = l.tl
	end
	l.tl = L2
	return L1
end

function list.head(L)
	return L.hd
end
function list.tail(L)
	return L.tl
end
local function list_next(L, l)
	return l.tl, l.hd
end

function listmeta.__pairs(L)
	return list_next, L, L
end



-------------------------------------implementing heaps (min) -------------------------------------

local metaheapmin, heapmin, btree = {}, {}, key1

local function check(H)
	for k, v in pairs(H[btree]) do
		assert(H[v] == k, k .. " " .. v[1] .. " " .. H[v])
	end
end

local function percolateup(H, i)
	local k = H[btree][i]
	while i > 1 do
		local p = H[btree][i // 2]
		if k < p then
			H[btree][i], H[btree][i // 2] = p, k
			H[p] = i
			i = i // 2
		else
			break
		end
	end
	H[k] = i
	return i
end



--[[
local s = H[1][key1] .. " " .. H[1][1] .. ", " .. table.concat(H[1][2], " ") .. "\n"
for i = 2, #H do
s = s .. H[i][key1] .. " " .. H[i][1] .. ", " .. table.concat(H[i][2], " ") .. ", " .. tostring(H[i] >= H[i // 2]) .. "\n"
end
print("insert H ... :\n" .. s)
--]]


local function percolatedown(H, i)
	local k = H[btree][i]
	while 2 * i <= #H do
		local m = math.min(table.unpack{H[btree][2 * i], H[btree][2 * i + 1]})
		if k <= m then

			break
		elseif H[btree][2 * i] == m then
			H[btree][i], H[btree][2 * i] = m, k
			H[m] = i
			i = 2 * i
		else
			H[btree][i], H[btree][2 * i + 1] = m, k
			H[m] = i
			i = 2 * i + 1
		end
	end
	H[k] = i
	return i
end



function heapmin.insert(H, k)
	table.insert(H[btree], k)
	return percolateup(H, #H)
end

function heapmin.remove(H)
	if #H <= 1 then
		local r = table.remove(H[btree]) or false
		H[r] = nil
		return r
	end
	local r = H[btree][1]
	H[r] = nil
	H[btree][1] = table.remove(H[btree])
	percolatedown(H, 1)
	return r
end

function heapmin.set(H, x, k)
	x = H[x]
	H[btree][x] = k
	return percolateup(H, percolatedown(H, x))
end

function heapmin.new(...)
	local H = setmetatable({[btree] = {...}}, metaheapmin)
	for i = #H, 1, -1 do
		percolatedown(H, i)
	end
	return H
end

metaheapmin.__index = heapmin

metaheapmin.__pairs = function(H)
	return heapmin.remove, H
end

function metaheapmin.__len(t)
	return #t[btree]
end





--assignement of everything built here

queue.fifo = fifo
queue.lifo = lifo
queue.heap = heapmin
queue.list = list

return setmetatable({}, {__index = queue, __metatable = false})

