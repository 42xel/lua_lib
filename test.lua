require "sugar"

print(sugar.type(1))
print(sugar.type(1.5))
print(sugar.type("un"))
print(sugar.type({}))
print(sugar.type(setmetatable))
print(sugar.type(setmetatable({}, {})))
print(sugar.type(setmetatable({}, {__type = "type_prso"})))



print(sugar.serialize({1, "2", "trois"}))

p = "bla"

local p = 4

a = 7

local function f (n)
	if n == 0 then 
		return 1
	end
	print(f, sugar.d.getlocal(2, "n"))
	return a * f((n - 1) % p)
end




f2 = sugar.copy(f)

print(f, f(6))

print(f2, f2(6))

t = {{},{},{}}
table.insert(t[1], t[2])
table.insert(t[2], t[3])
table.insert(t[3], t[1])

t2 = sugar.copy(t)

print(t)
print(t[1], t[1][1], t[1][1][1], t[1][1][1][1])
print(t[1], t[2], t[3])
print()

print(t2)
print(t2[1], t2[1][1], t2[1][1][1], t2[1][1][1][1])
print(t2[1], t2[2], t2[3])
print()

local function f3()
	print(_LOCAL.p)
	print(_LOCAL(0)().p)
	local p = 9
	print(sugar.d.getlocalup(1, "p"))
	print(sugar.d.getlocalup(2, "p"))
	print(_LOCAL(0).p)
	print(_LOCAL(0)(1).p)
end

f3()

debug.debug()

--sugar.d.debug()
