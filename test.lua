--[[
number = 6

local number = 15
local function lucky()
	local i = number
  print("your lucky number: " .. i)
end

local lucky2 = load(string.dump(lucky, "", "b", {}))


local idx = 1
while true do
  local name, val = debug.getupvalue(lucky, idx)
  if not name then break end
  print(name, val)
  idx = idx + 1
end

--debug.upvaluejoin(lucky2, 1, lucky, 1)
debug.setupvalue(lucky2, 1, number)
debug.upvaluejoin(lucky2, 2, lucky, 2)

number = 10

local idx = 1
while true do
  local name, val = debug.getupvalue(lucky2, idx)
  if not name then break end
  print(name, val)
  idx = idx + 1
end

lucky()
lucky2()

--print(debug.upvaluejoin(lucky, 1, function () local number = print end, 1))
--]]


require "memoize"

--[
print "Fibonacci test"

function fibonacci (i)
	return i == 0 and 0
		or i == 1 and 1
		or fibonacci(i-1) + fibonacci(i-2)
end
print("non memoized :", fibonacci(36))

local f1 = memoize(fibonacci)
print("memoized fst call (36) :", f1(36))
print("memoized snd call (36) :", f1(36))
print("memoized call (35) :", f1(35))

local f2 = memoizerec(fibonacci)
print("recmemoized call (36) :", f2(36))
print("recmemoized call (5000) :", f2(5000))


local f3 = memoizestack(fibonacci, nil, 0)
print("stcmemoized call (36) :", f3(36))
print("stcmemoized call (5000) :", f3(5000))
--]


print "Triangle test"

local function triangle(x) --le local est à tester, récupérer l'auto référencement se fait différement selon le scope de la fonction
	return x == 0 and 0
		or x + triangle(x-1)
end
print("pcall(t)(5) :", pcall(triangle, 5) )
print("pcall(t)(1000000) :", pcall(triangle, 1000000) )
print("pcall(t)(1000000) :", pcall(triangle, 1000000) )

local t1 = memoize(triangle)
print("pcall(t1)(5) :", pcall(t1, 5))
print("pcall(t1)(1000000) :", pcall(t1, 1000000))
print("pcall(t1)(1000000) :", pcall(t1, 1000000))

local t2 = memoizerec(triangle)
print("pcall(t2)(5) :", pcall(t2, 5))
print("pcall(t2)(1000000) :", pcall(t2, 1000000))
print("pcall(t2)(1000000) :", pcall(t2, 1000000))

local t3 = memoizestack(triangle, nil, 0)
print("pcall(t3)(5) :", pcall(t3, 5))
print("pcall(t3)(100000) :", pcall(t3, 100000))
print("pcall(t3)(100000) :", pcall(t3, 100000))
--]]


print "test multinome"

local function sum(...)
	local function f(c, ...)
		if select("#", ...) == 0 then
			return c
		end
		return f(c + ..., select("2", ...))
	end
	return f(0, ...)
end

function multinome (...)
	if select("#", ...) == 0 then
		return 1
	end
	local a = ...
	if a == 0 then
		return multinome(select(2, ...))
	end
	return multinome (a - 1, select(2, ...)) * sum(...) // a
end
print("m () :", multinome())
print("m (3,4) :", multinome(3,4))
print("m (2,5,6) :", multinome (2,5,6))
print("m (35, 57, 8, 3, 9, 4) :", multinome (35, 57, 8, 3, 9, 4) )

local m1 = memoize(multinome)
print("m1 () :", m1())
print("m1 (3) :", m1(3))
print("m1 (3,4) :", m1(3,4))
print("m1 (2,5,6) :", m1 (2,5,6))
print("m1 (35, 57, 8, 3, 9, 4) :", m1 (35, 57, 8, 3, 9, 4) )

local m2 = memoizerec(multinome)
print("m2 () :", m2())
print("m2 (3) :", m2(3))
print("m2 (3,4) :", m2(3,4))
print("m2 (2,5,6) :", m2 (2,5,6))
print("m2 (35, 57, 8, 3, 9, 4) :", m2 (35, 57, 8, 3, 9, 4) )


local m3 = memoizestack(multinome, nil, 1)
print("m3 () :", m3())
print("m3 (3) :", m3(3))
print("m3 (3,4) :", m3 (3,4))
print("m3 (2,5,6) :", m3 (2,5,6))
print("m3 (35, 57, 8, 3, 9, 4) :", m3 (35, 57, 8, 3, 9, 4) )


print "test unary adder"	--counting nils and false, ignores the rest

local function add (...)
	if select("#", ...) ~= 0 then
		if ... then
			return add(select(2, ...))
		end
		return ..., add(select(2, ...))
	end
end

print"\n\ntesting add"
print(add())
print(add(true))
print(add(false))
print(add(nil))
print(add(nil, 1, "ba", false, nil, nil))
print(add({}, nil, 1, "ba", false, nil, nil))

local a1 = memoize(add)
print"\n\ntesting a1"
print(a1())
print(a1(true))
print(a1(false))
print(a1(nil))
print(a1(nil, 1, "ba", false, nil, nil))
print(a1({}, nil, 1, "ba", false, nil, nil))

local a2 = memoizerec(add)
print"\n\ntesting a2"
print(a2())
print(a2(true))
print(a2(false))
print(a2(nil))
print(a2(nil, 1, "ba", false, nil, nil))
print(a2({}, nil, 1, "ba", false, nil, nil))

local a3 = memoizestack(add, {})
print"\n\ntesting a3"
print(a3())
print(a3(true))
print(a3(false))
print(a3(nil))
print(a3(nil, 1, "ba", false, nil, nil))
print(a3({}, nil, 1, "ba", false, nil, nil))

