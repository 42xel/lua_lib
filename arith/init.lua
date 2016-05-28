local arith = {}


function arith.gcd(a, b)
	if b == 0 then
		return a
	end
	return arith.gcd(b, a % b)
end


function arith.log2 (a)
	local function src(high, low)
		if high <= low + 1 then
			return low
		end
		local m = (high + low) // 2
		if math.ult(a, 1 << m) then
			return src(m, low)
		else
			return src(high, m)
		end
	end
	return src(63, 0)
end

return setmetatable({}, {__index = arith, __metatable = false})

