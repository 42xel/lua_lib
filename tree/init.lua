local tree = {}

local meta, metachildren = {__index = tree}, {}

function metachildren.__call (t, n)
	for i, v in ipairs(t) do if v.node == n then
		return i, v
	end end
end

function tree.new(node)
	return setmetatable({node = node, children = setmetatable({}, metachildren)}, meta)
end

function tree.insert(parent, child)
--	local young = parent.children[#parent.children]
	table.insert(parent.children, child)
--	young.old = child
	child.parent = parent
--	child.young = young
end


function tree.abort(parent, child)
	local k
	if type(child) == "number" then
		k = child
		child = parent.children[k]
	elseif getmetatable(child == meta) then
		for i, v in ipairs(parent.children) do if v == child then
			k = i
		end end
	else
		k, child = parent.children(child)
	end

	child.parent = nil
	return table.remove(parent.children, k)
end

function tree.emancipate(child)
	local p = child.parent
	p:abort(child)
	return p
end

function tree.remove(parent, child)
	return child and tree.abort(parent, child) or tree.emancipate(parent)
end


function tree.root(T)		--aka ancestor
	while T.parent do
		T = T.parent
	end
	return T
end
function tree.heir(T)
	while T.children[1] do
		T = T.children[1]
	end
	return T
end




assert(require "queue", "tree module requires queue")
local fifo, lifo = (require "queue").fifo, (require "queue").lifo


local function tree_next(T, S)
	if #S == 0 then
		return
	end
	T = S:pop()
	for k, v in pairs(T.children) do
		S:push(v)
	end
	return S, T
end

function tree.breadth_first(T)
	return tree_next, T, fifo.new(T)
end

function tree.depth_first(T)
	return tree_next, T, lifo.new(T)
end

local function tree_nextsuffix (T, S)
	if #S == 0 then
		return
	end
	T = S:pop()
	local s
	s, T = table.unpack(T)

	if not T.parent then		--should be equivalent to previous T == T, the root, or s == 0 and (current) #S == 0. behaviour may differ if the structure of the tree is altered during the traversal, which, of course, is not recommended.
		return S, T
	end

	T = T.parent
	s = s + 1
	if T.children[S] then
		T = T.children[S]
		S:push{s, T}
		while T.children[1] do
			T = T.children[1]
			S:push{1, T}
		end
	end
	return S, T
end

function tree.suffix (T)
	local S = lifo.new({0, T})
	while T.children[1] do
		T = T.children[1]
		S:push{1, T}
	end
	return tree_nextsuffix, T, S
end

local alias = {
	depth_first = true,
	depth_first = true,
	suffix = true,
	prefix = tree.depth_first,
	breadth = tree.breadth_first,
	depth = tree.depth_first
}


setmetatable(tree, {__index = alias})	


meta.__pairs = tree.depth_first

return setmetatable({}, {__index = tree, __metatable = false, __newindex = function(t, k, v)
			--allow to change the default behavior of calling pairs on a tree
		if k == "pairs" and alias[v] then
			meta.__pairs = chgpairs[v]
		end
	end
})
