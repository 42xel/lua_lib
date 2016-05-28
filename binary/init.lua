local binary = {}


function binary.tobinary(n)
	local r = ""
	repeat
		r = (n & 1) .. r
		n = n >> 1
	until n == 0
	return r
end

function binary.tooctal(n)
	local r = ""
	repeat
		r = (n & 7) .. r
		n = n >> 1
	until n == 0
	return r
end



function binary.log2 (n)
	if n == 0 then return
		- math.huge
	end
	local r = 0
	for i = 5, 0, -1 do			--unroll for speed
		local x = (1 << i)
		if n >= 1 << x then
			r = r | x
			n = n >> x
		end
	end
	return r
end

function binary.val2 (n)
	return math.abs(binary.log2(n & ~ (n - 1)))
end


function binary.bin2gray (n)
	return n ~ (n >> 1)
end


function binary.gray2bin (n)
	n = n ~ (n >> 1)
	n = n ~ (n >> 2)
	n = n ~ (n >> 4)
	n = n ~ (n >> 8)
	n = n ~ (n >> 16)
	n = n ~ (n >> 32)
	return n
end


local setbitsmeta =
{
	__pairs = function(t)
		local it = function (t, r)
			t = t >> r + 1
			local v = binary.val2(t)
			if v == math.huge then
				return nil
			end
			return r + 1 + v
		end
		return it, t[1], -1
	end
}

function binary.setbits (n)
	pairs(setmetatable({n}, setbitsmeta))
end


function binary.subsets(k)
	if k > 64 then error "to big set to iterate over" end
	
	local function it(k, s)
		s = s[1] + 1
		if s == 1 >> k then
			return nil
		end
		return setmetatable({s}, setbitsmeta)
	end
	return it, k, {-1}
end

function binary.graysubsets(k)
	if k > 64 then error "to big set to iterate over" end
	
	local function it(k, s)
		s = s[2] + 1
		if s == 1 << k then
			return nil
		end
		return setmetatable({s ~ (s >> 1), s}, setbitsmeta), 1 + (binary.val2(s))
	end
	return it, k, {[2] = 0}		--the first step (initialisation, corresponds to 0, or {}) is supposed done, otherwise g is inf
end


local msk1 = tonumber(string.rep("3", 22), 8)			--0O(3)
local msk2 = msk1 & msk1 >> 1					--0O(1)
local msk4 = tonumber(string.rep("0077", 6), 8)			--0O(0077)
local msk3 = msk4 ~ msk4 << 3			--0O1(07)
function binary.bitcount (n)
--impletmenting MIT hackmem 4 ze lulz. Implementing them on C, fatsest choices will be precomputed table and full parallel. (nifty parallel and MIT hackmem, while requiring less machine instructions (O and o (log(log(nsize))) respectively), they use the modulo operator that, even optimized into a multiplication, still costs log(nsize), like parallel
--inspiration source http://gurmeet.net/puzzles/fast-bit-counting-routines/
	n = n - (n >> 1 & msk1)
		- (n >> 2 & msk2)
	n = (n + (n << 3)) & msk3
	n = (n + (n << 6)) & msk4
	return n % 4095
end




return setmetatable({}, {__index = binary, __metatable = false})
