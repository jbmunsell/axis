--
--	Jackson Munsell
--	08/14/18
--	Analytics.lua
--
--	Axis analytics script 
--

-- boot
_G.axisboot()

-- Module
local Analytics = {}

-- Init
function Analytics.Init(self, gameKey, secretKey)
	-- Set member variables
	self.GAME_KEY = gameKey
	self.SECRET_KEY = secretKey

	-- Tables
	self.queue = {}

	-- Load up encoding modules
	self.encodingModules = {}
	-- TODO: Left off here copying from old init

	-- Ready
	self.ready = true
end

-- return module
return Analytics
