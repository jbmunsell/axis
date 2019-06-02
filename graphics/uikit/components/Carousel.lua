--
--	Jackson Munsell
--	07/28/18
--	Carousel.lua
--
--	Carousel gui class functionality module
--

-- services
local ReplicatedStorage = game:GetService('ReplicatedStorage')

-- includes
local classutil = require(_G.axisroot.util.classutil)
local tableutil = require(_G.axisroot.util.tableutil)

-- Module
local Carousel = classutil.newclass()

-- Init
function Carousel.Init(self, parent, data)
	-- Set
	self.parent = parent

	-- Construct
	self:Construct()
	self:Connect()

	-- Set data
	self:SetData(data)
end

-- Construct
function Carousel.Construct(self)
	-- Find way over to components
	local path = {
		'res',
		'gui',
		'components',
		'carousel',
	}

	-- Get components folder
	local object = ReplicatedStorage
	for _, c in pairs(path) do
		object = object:FindFirstChild(c)
		if not object then
			error('Could not find carousel components')
		end
	end

	-- Copy components into parent
	for _, component in pairs(object:GetChildren()) do
		local tcom = component:clone()
		tcom.Parent = self.parent
	end
end
function Carousel.SetArrowSizeFactor(self, f)
	local arrow_left = self.parent:FindFirstChild('ArrowLeft')
	local arrow_right = self.parent:FindFirstChild('ArrowRight')
	if arrow_left and arrow_right then
		for _, arrow in pairs({arrow_left, arrow_right}) do
			arrow.Size = UDim2.new(f, 0, f, 0)
		end
	end
end

-- Connect
function Carousel.Connect(self)
	-- Get stuff
	local arrow_left = self.parent:FindFirstChild('ArrowLeft')
	local arrow_right = self.parent:FindFirstChild('ArrowRight')
	if not arrow_left or not arrow_right then
		error('Arrows not found in parent')
	end

	-- Connect
	arrow_left.Activated:connect(function() self:ShiftLeft() end)
	arrow_right.Activated:connect(function() self:ShiftRight() end)
end

-- Set data
function Carousel.SetData(self, data)
	-- Assert
	if type(data) ~= 'table' then
		error(string.format('Invalid argument #1 to Carousel.SetData; table expected, got %s', type(data)))
	end

	-- Set
	self.data = data
	self:SelectIndex(1)
end
function Carousel.SetSelectionChangedCallback(self, func)
	if type(func) ~= 'function' then
		error(string.format('Invalid argument #1 to Carousel.SetSelectionChangedCallback; function expected, got %s', type(func)))
	end
	self.SelectionChanged = func
	self:SelectionChanged(self.data[self.index])
end
function Carousel.GetSelection(self)
	return self.data[self.index]
end

-- Select index
function Carousel.SelectIndex(self, index)
	-- Assert
	if not self.data then
		error('Attempt to set index with no data set')
	end

	-- Wrap index
	self.index = ((index - 1) % #self.data) + 1

	-- Grab thing
	if self.SelectionChanged then
		self:SelectionChanged(self.data[self.index])
	end
end
function Carousel.SelectRandomIndex(self)
	self:SelectIndex(math.random(1, #self.data))
end
function Carousel.SelectItem(self, item)
	local index = tableutil.getkey(self.data, item)
	if index then
		self:SelectIndex(index)
	else
		error('Attempt to select an item that isn\'t part of the carousel\'s data')
	end
end
function Carousel.ShiftRight(self)
	self:SelectIndex(self.index + 1)
end
function Carousel.ShiftLeft(self)
	self:SelectIndex(self.index - 1)
end

-- return module
return Carousel
