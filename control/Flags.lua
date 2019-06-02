--
--	Jackson Munsell
--	08/14/18
--	Flags.lua
--
--	Axis flags control script. Handles binding and accessing of flags
--

-- services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- Flag class
local FlagClass = {}
FlagClass.__index = function(tb, key)
	local val = rawget(tb, key)
	if val == nil then
		error(string.format('No flag exists by name \'%s\'', key))
	else
		return val
	end
end

-- Module
local Flags = {}

-- Bind flags
function Flags.BindFlags(self, flags)
	-- Create values to bind
	local folder = Instance.new('Folder', ReplicatedStorage)
	folder.Name = 'Flags'
	for key, val in pairs(flags) do
		local value = Instance.new('BoolValue', folder)
		value.Name = key
		value.Value = val
		value.Changed:connect(function(nval)
			-- Set
			flags[key] = nval

			-- Callbacks
			local callbacks = flags.__callbacks[key]
			if callbacks then
				for _, callback in pairs(callbacks) do
					callback(nval)
				end
			end
		end)
	end

	-- Set methods
	flags.__callbacks = {}
	flags.BindToFlagChanged = function(flag, func)
		local callbacks = flags.__callbacks[flag]
		if not callbacks then
			callbacks = {}
			flags.__callbacks = callbacks
		end
		table.insert(callbacks, func)
	end

	-- Set metatable
	setmetatable(flags, FlagClass)

	-- return flags
	return flags
end

-- return module
return Flags
