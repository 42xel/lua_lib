local graph = {}


--local sizekey = {}
local meta = {__index = graph}


function graph.new(Vl, El)
--V is supposed to be the set (as a list) of DIFFERENT keys, E the set (as a list) of edges, pairs of keys
--we'll make them as set
	local G = setmetatable({V = {}, E = {}}, meta)
	
	if math.type(Vl) == "integer" then
		for i = 1, Vl do
			G.V[i] = {}
			G.E[i] = {}
		end
	elseif Vl then
		for i, v in ipairs(Vl) do
			G.V[v] = {}
			G.E[v] = {}
		end
	end

	if El then
		for i, e in ipairs(El) do
			local edge = {}
			G.E[e[1]][e[2]] = edge
			G.E[e[2]][e[1]] = edge
		end
	end

	return G
end


function graph.new_oriented(Vl, El)
--V is supposed to be the set (as a list) of DIFFERENT keys, E the set (as a list) of edges, pairs of keys
--we'll make them as set
	local G = setmetatable({V = {}, E = {}, Erec = {}}, meta)

	if math.type(Vl) == "integer" then
		for i = 1, Vl do
			G.V[i] = {}
			G.E[i] = {}
			G.Erec[i] = {}
		end
	elseif Vl then
		for i, v in ipairs(Vl) do
			G.V[v] = {}
			G.E[v] = {}
			G.Erec[v] = {}
		end
	end

	if El then
		for i, e in ipairs(El) do
			local edge = {}
			G.E[e[1]][e[2]] = edge
			G.Erec[e[2]][e[1]] = edge
		end
	end

	return G
end


function graph.addV (G, v, ...)
	G.V[v] = {...}
	G.E[v] = {}
end
function graph.addE (G, e, ...)
	local edge = {...}
	G.E[e[1]][e[2]] = edge
	if G.Erec then
		G.Erec[e[2]][e[1]] = edge
	else
		G.E[e[2]][e[1]] = edge
	end
end

function graph.removeV (G, v)
	G.V[v] = nil
	if G.Erec then
		for k, _ in pairs(G.E[v]) do
			G.Erec[k][v] = nil
			G.E[v][k] = nil
		end
		G.E[v] = nil

		for k, _ in pairs(G.Erec[v]) do
			G.E[k][v] = nil
			G.Erec[v][k] = nil
		end
		G.Erec[v] = nil
	else
		for k, _ in pairs(G.E[v]) do
			G.E[k][v] = nil
			G.E[v][k] = nil
		end
		G.E[v] = nil
	end
end
function graph.removeE (G, e)
	G.E[e[1]][e[2]] = nil
	if G.Erec then
		G.Erec[e[2]][e[1]] = nil
	else
		G.E[e[2]][e[1]] = nil
	end
end


local alias = {insert = graph.addV, link = graph.addE, remove = graph.removeV, unlink = graph.removeE}

setmetatable(graph, {__index = alias})



function graph.arity(G, v)
	local r = 0
	for _, _ in pairs(G.E[v]) do
		r = r + 1
	end
	return r
end
function graph.arityrec(G, v)
	local r = 0
	for _, _ in pairs(G.Erec[v]) do
		r = r + 1
	end
	return r
end



if require"queue" then

	local dijmeta = {__tostring = function(t) return t[1] end}
	local dijprev = setmetatable({}, {__index = function (t, k)
			t[k] = {"dijkstra shortest path from " .. tostring(k) .. " previous node :"}
			return setmetatable(t[k], dijmeta)
		end})
	local dijlen = setmetatable({}, {__index = function (t, k)
			t[k] = {"dijkstra shortest path from " .. tostring(k) .. " length :"}
			return setmetatable(t[k], dijmeta)
		end})


	local heapmin = (require"queue").heap
	function graph.dijkstra (G, s, e, dkey, len, pr)
--dijkstra (G, s, [e, [dkey, [prev]]])
--will search shortest path from s. The distance between two adjacent points is assumed to be in the field dkey (default 1) of the edge connecting them.
--If e is provided, it will stop once it reaches e and return the distance between s and e as a first result value and a list as a secundary result : the path between s and e.
--If len is provided or e isn't, the algorithm will keep a trace of the length of the shortest path found* between s and a vertex v, either in G.V[v][len] if provided, in G.V[v][dijlen[s]] otherwise.
--If prev is provided or if e isn't, the algorithm will keep a trace of the shortest path found* from s to a vertex v, by storing the key of the previous vertex along the shortest path, either in G.V[v][prev] if provided, in G.V[v][dijprev[s]] otherwise.
--*in the two last cases, if e is provided, the trace keept is guaranted to be right only when dist(s, v) < dist(s, e).
--if e is not provided, then the output is the two keys len and prev, or their possible replacement dijlen[s] and dijprev[s].
--Despite the fact that this algorithm makes it 'easy' to use several times to compute shortest paths from several sources, you might want to implement (Floyd-Warshall) for that kind of use.

--initialization
		local prev = pr or dijprev[s]
		dkey = dkey or 1


		local D = setmetatable({[s] = 0}, {__index = function () return math.huge end})
		local meta = {__lt = function (a, b) return D[a[1]] < D[b[1]] end,
			__le = function (a, b) return D[a[1]] <= D[b[1]] end
		}

		local Q, C = {}, {}
		for v, val in pairs(G.V) do
			C[v] = setmetatable({v}, meta)
			table.insert(Q, C[v])
		end
		Q = heapmin.new(table.unpack(Q))
		

--main loop
		for a in pairs(Q) do
			a = a[1]
			local Da = D[a]

			if a == e then
				break
			end

			for b, d in pairs(G.E[a]) do
				if D[b] > Da + d[dkey] then
					D[b] = Da + d[dkey]
					G.V[b][prev] = a
					Q:set(C[b], C[b])
				end
			end
		end
		

--We've done the hard work, just check what was asked
		if len or not e then
			len = len or dijlen[s]
			
			for k, v in pairs(G.V) do
				v[len] = D[k]
			end
		end

		if e then
			local r
			
			if not pr then
				r = {}
				local p, i = {e}, G.V[e][prev]
				while i do
					table.insert(p, i)
					i = G.V[p[#p]][prev]
				end

				while p[1] do
					table.insert(r, table.remove(p))
				end
				for k, v in pairs(G.V) do
					v[prev] = nil
				end
			end
			return table.unpack{D[e], r}
		else
			return len, prev
		end
	end


end



function graph.maxmatch(G)
	local M = graph.new()
	for k, v in pairs(G.V) do
		M:addV(k)
	end

	local function search (o)
		if next(M.E[o]) then return end
		local l = {o}
		while l[1] do
			local x = l[#l]
			if #l % 2 == 1 then
				local y
				while x do
					y = next(G.E[x], y)
					if y then
						if not M.V[y][o] then
							table.insert(l, y)
							if not next(M.E[y]) then
--								for k, v in pairs(M.V) do
--									v[o] = nil
--								end
								return l
							end
							M.V[y][o] = true
							break
						end
					else
						table.remove(l)
						y = table.remove(l)
						x = l[#l]
					end
				end
			else
				local n = next(M.E[x])
				if not n then
					print("G :")
					for k, v in pairs(G.E) do
						if k(1) ~= "_" then
							for kk, vv in pairs(v) do
								print(k, kk)
							end
						end
					end
					print("M :")
					for k, v in pairs(M.E) do
						if k(1) ~= "_" then
							for kk, vv in pairs(v) do
								print(k, kk)
							end
						end
					end
					print("l :")
					for _, v in ipairs(l) do
						print(v)
					end
				end
				assert(n)

				M.V[n][o] = true
				table.insert(l, n)
			end
		end
	end
	
	function augment(o)
		if o then
			local x, y = table.remove(o), table.remove(o)
			M:addE{x, y}
			while #o > 0 do
				x = table.remove(o)
				M:removeE{y, x}
				y = table.remove(o)
				M:addE{x, y}
			end
		end
	end
		

	for v, _ in pairs(G.V) do if not next(M.E[v]) then
		augment(search(v))
	end end

	for v, _ in pairs(M.V) do
		M.V[v] = {}
	end

	return M
end


local unionfind = assert(require "unionfind", "graph module requires unionfind for connected components finding")

function graph.connectcomp(G)
	local U = {}
	for v in pairs (G.V) do
		table.insert(U, v)
	end
	U = unionfind.newsgton(table.unpack(U))

	for e1, v in pairs(G.E) do
		for e2 in pairs(v) do
			U:union(e1, e2)
		end
	end
	return U
end



return setmetatable({}, {__index = graph, __metatable = false})
