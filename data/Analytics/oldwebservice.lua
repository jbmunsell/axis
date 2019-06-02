--
--	Jackson Munsell
--	11/20/17
--	WebService.lua
--
--	Handles web-related requests
--

-- Path
local Path = require(game:GetService('ReplicatedStorage').SharedScripts.Path)()

-- includes
include '/server/Web/GameAnalytics'
include '/server/Network/Network'

include '/shared/Classes/Signal'

-- Core engine services
serve 'HttpService'
serve 'ScriptContext'
serve 'LocalizationService'

-- Module
local WebService = {}
WebService.DEV_GAME_KEY		= 'd5685179518110443a715f7b7cd115cb'
WebService.DEV_SECRET_KEY	= '855c0133083c049456596e265df2b90554efbb09'
WebService.LIVE_GAME_KEY	= '7d61a33a0b87705261d3d453eb2f9f11'
WebService.LIVE_SECRET_KEY	= '077a9d260d1461143b00b6c669dcb4ea4bef0308'

-- Boot
function WebService.boot()
	include '/server/Services/DataService'
end

-- Extend a table
local function extend(a, b)
	for k, v in pairs(b) do
		if type(v) == 'table' then
			a[k] = a[k] or {}
			extend(a[k], v)
		else
			a[k] = v
		end
	end
end

-- Init
function WebService.Init(self)
	-- Init analytics
	self.session_ids = {}
	self.session_nums = {}
	self.session_starts = {}
	if DataService.Flags.IS_DEVELOPMENT_ENVIRONMENT then
		GameAnalytics:Init(self.DEV_GAME_KEY, self.DEV_SECRET_KEY)
	else
		GameAnalytics:Init(self.LIVE_GAME_KEY, self.LIVE_SECRET_KEY)
	end

	-- Connect to script error
	ScriptContext.Error:connect(function(message, trace, sc)
		-- Push event
		self:SendErrorEvent('error', string.format('%s\n%s', message, trace))
	end)
end

-- Send error event
function WebService.SendErrorEvent(self, severity, message)
	GameAnalytics:SendEvent({
		category	= 'error',
		severity	= severity,
		message		= message,
	})
end

-- Submit server event
function WebService.GetSessionId(self, player)
	return self.session_ids[player.UserId]
end
function WebService.GetSessionNum(self, player)
	return self.session_nums[player.UserId]
end
function WebService.GetSessionStart(self, player)
	return self.session_starts[player.UserId]
end
function WebService.GetPlayerEventDefaults(self, player)
	return {
		user_id			= tostring(player.UserId),
		client_ts		= os.time(),
		session_id		= self:GetSessionId(player),
		session_num		= self:GetSessionNum(player),
		device			= LocalizationService.SystemLocaleId,
	}
end
function WebService.StartSession(self, player, sessionNum)
	-- Create a new session id
	log('starting player session')
	self.session_ids[player.UserId] = Path.generate_uuid()
	self.session_nums[player.UserId] = sessionNum
	self.session_starts[player.UserId] = os.time()
	self:SendPlayerSessionStartEvent(player)
end
function WebService.EndSession(self, player)
	log('ending player session')
	if not self:GetSessionStart(player) then return end
	self:SendPlayerSessionEndEvent(player)
end
function WebService.SendPlayerEvent(self, player, data)
	local event = self:GetPlayerEventDefaults(player); if not event then return end
	extend(event, data)
	GameAnalytics:SendEvent(event)
end

-- Specific player events
function WebService.SendPlayerSessionStartEvent(self, player)
	self:SendPlayerEvent(player, {
		category = 'user',
	})
end
function WebService.SendPlayerSessionEndEvent(self, player)
	self:SendPlayerEvent(player, {
		category	= 'session_end',
		length		= (os.time() - self:GetSessionStart(player)),
	})
end
function WebService.SendPlayerBusinessEvent(self, player, event_id, amount, transaction_num, cart_type)
	self:SendPlayerEvent(player, {
		category		= 'business',
		event_id		= event_id,
		amount			= amount,
		currency		= 'USD',
		transaction_num	= transaction_num,
		cart_type		= cart_type,
	})
end
function WebService.SendPlayerResourceEvent(self, player, flow_type, currency, amount, item_id)
	local event_id = string.format('%s:%s:%s', flow_type, currency, item_id)
	self:SendPlayerEvent(player, {
		category		= 'resource',
		event_id		= event_id,
		amount			= amount,
	})
end
function WebService.SendPlayerProgressionEvent(self, player, status, ...)
	local event_id = status
	for _, part in ipairs({...}) do
		event_id = event_id .. ':' .. part
	end
	self:SendPlayerEvent(player, {
		category	= 'progression',
		event_id	= event_id,
	})
end
function WebService.SendPlayerDesignEvent(self, player, ...)
	local event_id = ''
	for i, arg in ipairs({...}) do
		event_id = event_id .. (i == 1 and '' or ':') .. tostring(arg)
	end
	self:SendPlayerEvent(player, {
		category	= 'design',
		event_id	= event_id,
	})
end

-- Return service
return WebService
