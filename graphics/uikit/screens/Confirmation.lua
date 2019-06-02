--
--	Jackson Munsell
--	05/22/19
--	Confirmation.lua
--
--	Confirmation gui class
--

-- boot
_G.axisboot()

-- includes
include '/axis/util/classutil'
include '/axis/graphics/uikit/components/Screen'

-- Module
local Confirmation = classutil.extend(Screen)
Confirmation.StaticGui = get('/res/gui/Confirmation')

-- Init
function Confirmation.Init(self)
	-- Super
	self.__super.Init(self)

	-- Connect
	self.result = nil
	self.container.ButtonYes.Activated:connect(function()
		self.result = true
	end)
	self.container.ButtonNo.Activated:connect(function()
		self.result = false
	end)

	-- Show
	self:Show()

	-- Wait for an answer
	repeat wait() until self.result ~= nil

	-- Destroy screen and return
	self:Destroy()
end

-- return module
return Confirmation
