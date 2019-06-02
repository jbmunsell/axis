--
--	Jackson Munsell
--	07/26/18
--	Screen.lua
--
--	Screen class module script
--

-- services
local Players = game:GetService('Players')

-- includes
local classutil = require(_G.axisroot.util.classutil)

-- Module
local Screen = classutil.newclass()

-- Init
function Screen.Init(self)
	-- Get
	if not self.StaticGui then
		error('Screen class has no StaticGui property')
	end

	-- Clone
	self.gui = self.StaticGui:clone()
	self.gui.Enabled = false
	self.gui.Parent = Players.LocalPlayer:WaitForChild('PlayerGui')

	-- Access children
	self.container = self.gui:FindFirstChild('Container')
	self.components = self.gui:FindFirstChild('Components')
	self.frame = self.container and self.container:FindFirstChild('Frame')
end

-- Show
function Screen.Show(self)
	self.gui.Enabled = true
end
function Screen.Hide(self)
	self.gui.Enabled = false
end

-- Destroy
function Screen.Destroy(self)
	-- Debounce
	if self.destroyed then return end
	self.destroyed = true

	-- Destroy screen
	if self.gui then
		self.gui:Destroy()
	end
end

-- return module
return Screen
