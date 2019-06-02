--
--	Jackson Munsell
--	07/19/18
--	enumclass.lua
--
--	Enumeration class; errors if you try to access an invalid enum item
-- 	The reason this doesn't follow naming conventions is because if it were Enum, then it would clash with the roblox lua Enum objects
--

-- Module
local __enumclass = {}
__enumclass.__index = function(tb, key)
	local val = rawget(tb, key)
	if val then
		return val
	else
		error(string.format('Invalid enum item: \'%s\'', key))
	end
end

-- return __enumclass
return function(str)
	local tb = {}
	local i = 0
	for val in string.gmatch(str, '([%a_]+)') do
		tb[val] = i
		i = i + 1
	end
	return setmetatable(tb, __enumclass)
end
