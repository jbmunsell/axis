--
--	Jackson Munsell
--	01/28/19
--	Network.lua
--
--	Basic network sockets api
--

-- services
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')

-- Module
local Network = {
	connections = {},
	SocketCreated = {
		connections = {},
		connect = function(self, func)
			table.insert(self.connections, func)
			return {
				disconnect = function()
					for i, connection in pairs(self.connections) do
						if connection == func then
							table.remove(self.connections, i)
							break
						end
					end
				end,
			}
		end,
		fire = function(self, ...)
			for _, connection in pairs(self.connections) do
				connection(...)
			end
		end,
	}
}

-- Init
-- 	Client only
function Network.Init(self)
	-- Client
	if RunService:IsClient() then
		-- Wait for socket
		local socket = Players.LocalPlayer:WaitForChild('socket')
		local event = socket:WaitForChild('event')
		local func = socket:WaitForChild('function')

		-- Connect
		event.OnClientEvent:connect(function(identifier, ...)
			local cons = self.connections[identifier]
			if cons then
				for _, process in pairs(cons) do
					process(...)
				end
			else
				warn('No client connection for identifier \'' .. identifier .. '\'')
			end
		end)
		func.OnClientInvoke = function(identifier, ...)
			local cons = self.connections[identifier]
			if cons then
				return cons[1](...)
			else
				warn('No client connection for identifier \'' .. identifier .. '\'')
			end
		end
	end
end

-- Create socket
-- 	Server only
function Network.CreateSocket(self, player)
	-- Server
	if RunService:IsServer() then
		-- Debounce
		if player:FindFirstChild('socket') then
			warn('Attempt to create socket for player that already has a socket')
			return
		end

		-- Create connections array
		self.connections[player] = {}

		-- Create socket folder
		local socket = Instance.new('Folder', player)
		socket.Name = 'socket'

		-- Create remotes
		local event = Instance.new('RemoteEvent', socket)
		local func = Instance.new('RemoteFunction', socket)
		event.Name = 'event'
		func.Name = 'function'

		-- Connect remotes
		event.OnServerEvent:connect(function(client, identifier, ...)
			if client ~= player then return end
			local cons = self.connections[player][identifier]
			if cons then
				for _, process in pairs(cons) do
					process(...)
				end
			else
				warn('No server connection for identifier \'' .. identifier .. '\'')
			end
		end)
		func.OnServerInvoke = function(client, identifier, ...)
			if client ~= player then return end
			local cons = self.connections[player][identifier]
			if cons then
				return cons[1](...)
			else
				warn('No server connection for identifier \'' .. identifier .. '\'')
			end
		end

		-- Fire
		self.SocketCreated:fire(player)
	end
end

-- Push
function Network.Push(self, ...)
	-- Client
	if RunService:IsClient() then
		-- Simple for client
		Players.LocalPlayer.socket.event:FireServer(...)
	elseif RunService:IsServer() then
		-- On the server, we have to handle potentially firing multiple clients at once
		local params = {...}
		local player = table.remove(params, 1)
		local identifier = table.remove(params, 1)

		-- Check for target type being a single client or a group of clients
		if type(player) == 'table' then
			for _, target in pairs(player) do
				target.socket.event:FireClient(target, identifier, unpack(params))
			end
		elseif type(player) == 'userdata' then
			player.socket.event:FireClient(player, identifier, unpack(params))
		else
			error('Invalid type passed to Network.Push \'' .. type(player) .. '\'')
		end
	end
end
function Network.Invoke(self, ...)
	-- Client
	if RunService:IsClient() then
		-- Extract client and forward to socket
		return Players.LocalPlayer.socket['function']:InvokeServer(...)
	elseif RunService:IsServer() then
		-- Extract client and forward to socket
		local params = {...}
		local player = table.remove(params, 1)
		if type(player) == 'userdata' then
			return player.socket['function']:InvokeClient(player, unpack(params))
		else
			error('Invalid type passed to Network.Push \'' .. type(player) .. '\'')
		end
	end
end

-- Connect
function Network.Connect(self, ...)
	-- Client
	if RunService:IsClient() then
		local identifier, process = ...
		if not self.connections[identifier] then
			self.connections[identifier] = {}
		end
		table.insert(self.connections[identifier], process)
		return {
			disconnect = function()
				for i, v in pairs(self.connections[identifier]) do
					if v == process then table.remove(self.connections[identifier], i) break end
				end
			end
		}
	elseif RunService:IsServer() then
		local player, identifier, process = ...
		if not self.connections[player][identifier] then
			self.connections[player][identifier] = {}
		end
		table.insert(self.connections[player][identifier], process)
		return {
			disconnect = function()
				for i, v in pairs(self.connections[player][identifier]) do
					if v == process then
						table.remove(self.connections[player][identifier], i)
						break
					end
				end
			end
		}
	end
end

-- return module
return Network
