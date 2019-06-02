--
--	Jackson Munsell
--	07/05/18
--	boot.lua
--
--	Boot module. This script is required at the top other scripts to dump functions into the module's function environment.
-- 		Any member of the boot module is automatically dumped into the function environment which calls the function returned by this
-- 		module script.
--

-- services
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')

-- Module
local boot = {}

-- Get local player
if RunService:IsClient() then
	boot.localPlayer = Players.LocalPlayer
end

-- Log functions
function boot._log(level, ...)
	local tag = getfenv(level).script.Name
	local args = {...}
	if #args == 0 then args = {'nil'} end
	local str = tostring(table.remove(args, 1))
	local l = string.format(str, unpack(args))
	print(string.format('[%s] %s', tag, l))
end
function boot.log(...)
	boot._log(3, ...)
end
function boot.whisper(...)
	local Flags = boot.get('/data/Flags')
	if not Flags then
		warn('Attempt to whisper with no explicit Flags object at /data/Flags')
		return
	else
		if require(Flags).VERBOSE then
			boot._log(3, ...)
		end
	end
end
function boot.warn(...)
	warn(string.format(...))
end
function boot.logtable(tb, tabs)
	tabs = tabs or 0
	for k, v in pairs(tb) do
		if type(v) ~= 'table' then
			print(string.format('%s[%s]: %s', string.rep('\t', tabs), tostring(k), tostring(v)))
		else
			print(string.format('%s[%s]', string.rep('\t', tabs), tostring(k)))
			boot.logtable(v, tabs + 1)
		end
	end
end

-- Fetching
function boot.get(path)
	-- Feel free to add project specific links here!
	local links = {
		['/axis']       = {_G.axisroot, ''},
		['/lib']        = {ReplicatedStorage, 'src/lib/'},
		['/enum']       = {ReplicatedStorage, 'src/enum/'},
		['/data']       = {ReplicatedStorage, 'src/data/'},
		['/res']        = {ReplicatedStorage, 'res/'},
		['/shared/src'] = {ReplicatedStorage, 'src/'},
		['/server/src'] = {ServerScriptService, 'src/'},
		['/client/src'] = {Players.LocalPlayer, 'PlayerScripts/src/'},
		['workspace']	= {workspace, ''},
	}
	if not path then
		boot.warn('No path supplied to \'get\'')
		return
	end
	local object
	for link, data in pairs(links) do
		if string.match(path, '^' .. link) then
			object = data[1]
			path = data[2] .. string.sub(path, string.len(link) + 2)
		end
	end
	if not object then
		error(string.format('No directory link found for path \'%s\'', path))
	end
	for segment in string.gmatch(path, '([^/%.]+)') do
		object = object:FindFirstChild(segment)
		if not object then
			boot.warn('No object found for path \'%s\'', path)
			break
		end
	end
	return object
end

-- Environment manipulation
function boot.serve(str)
	getfenv(2)[str] = game:GetService(str)
end
function boot.include(path)
	if string.match(path, '%*$') then
		local dir = boot.get(string.sub(path, 1, -2))
		for _, child in pairs(dir:GetChildren()) do
			if child:IsA('ModuleScript') then
				getfenv(2)[child.Name] = require(child)
			end
		end
		return
	end
	local module = boot.get(path)
	if module then
		getfenv(2)[module.Name] = require(module)
	else
		error(string.format('Bad path to include: %s', path))
	end
end

-- Instance manipulation
function boot.new(class, parent, props)
	local instance = Instance.new(class)
	if props then
		for k, v in pairs(props) do
			instance[k] = v
		end
	end
	instance.Parent = parent
	return instance
end
function boot.clone(object, parent, props)
	if type(object) == 'string' then
		object = boot.get(object)
	end
	if not object then
		boot.warn('Invalid parameter passed to \'clone\'')
		return
	end
	local thing = object:clone()
	if props then
		for k, v in pairs(props) do
			thing[k] = v
		end
	end
	thing.Parent = parent
	return thing
end

-- return boot
return function()
	-- Set global axis root
	_G.axisroot = script.Parent

	-- Set global axis boot
	_G.axisboot = function()
		local env = getfenv(2)
		for k, v in pairs(boot) do
			env[k] = v
		end
	end
end
