local import = ...
local Util = import("Util")
local Maid = import("Maid")
local Theme = import("Theme")
local Tab = import("Tab")
local Notifications = import("Notifications")
local UserInputService = game:GetService("UserInputService")
local Create, Tween = Util.Create, Util.Tween

local SIDEBAR_W, HEADER_H = 88, 52

local Window = {}
Window.__index = Window

--[[ options:
	Name       string   title text                      (default "NEXUS")
	Subtitle   string   small accent text under title
	Icon       string   "rbxassetid://..." or https URL to the logo
	Accent     Color3   accent colour
	Size       UDim2    offset size (clamped to the viewport)
	ToggleKey  Enum.KeyCode  show/hide key              (default RightShift)
	Theme      table    palette overrides { Background = Color3, ... }
]]
function Window.new(options)
	local self = setmetatable({}, Window)
	self.Maid = Maid.new()
	local overrides = options.Theme or {}
	if options.Accent then overrides.Accent = options.Accent end
	self.Theme = Theme.new(overrides)
	self.Flags, self.Tabs, self.Visible = {}, {}, true
	self.ToggleKey = options.ToggleKey or Enum.KeyCode.RightShift
	self.Ctx = { Theme = self.Theme, Maid = self.Maid, Flags = self.Flags, Window = self }
	local T = self.Theme

	local size = options.Size or UDim2.fromOffset(640, 430)
	local cam = workspace.CurrentCamera
	if cam then
		local vp = cam.ViewportSize
		size = UDim2.fromOffset(math.min(size.X.Offset, vp.X - 40), math.min(size.Y.Offset, vp.Y - 40))
	end

	local gui = Create("ScreenGui", {
		Name = "NexusUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999, IgnoreGuiInset = true,
	})
	Util.MountGui(gui)
	self.Gui = self.Maid:Give(gui)

	local main = Create("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size,
		BackgroundColor3 = T.Colors.Background, BackgroundTransparency = T.Transparency, BorderSizePixel = 0,
		ClipsDescendants = true, Parent = gui,
	})
	self._main = main
	self._scale = Create("UIScale", { Scale = 0.92, Parent = main })
	Util.Corner(main, 12)
	T:Bind(Util.Stroke(main, T.Colors.Accent, 1.5, 0.35), "Color", "Accent")
	Create("UIGradient", {
		Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 195, 220)), Parent = main,
	})

	-- Sidebar (logo + tab buttons)
	local sidebar = Create("Frame", {
		Size = UDim2.new(0, SIDEBAR_W, 1, 0), BackgroundColor3 = T.Colors.Surface, BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = main,
	})
	Create("Frame", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = T.Colors.Stroke, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = sidebar })
	Create("ImageLabel", {
		Name = "Logo", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(56, 56),
		BackgroundTransparency = 1, Image = Util.GetAsset(options.Icon), ScaleType = Enum.ScaleType.Fit, Parent = sidebar,
	})
	self._tabList = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 78), Size = UDim2.new(1, 0, 1, -78), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = sidebar,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self._tabList })

	-- Header (title + window buttons) - drag handle
	local header = Create("Frame", { Position = UDim2.fromOffset(SIDEBAR_W, 0), Size = UDim2.new(1, -SIDEBAR_W, 0, HEADER_H), BackgroundTransparency = 1, Parent = main })
	Create("TextLabel", {
		Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -110, 0, 26), BackgroundTransparency = 1, Text = options.Name or "NEXUS",
		Font = Enum.Font.GothamBold, TextSize = 24, TextColor3 = T.Colors.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
	})
	local sub = Create("TextLabel", {
		Position = UDim2.fromOffset(16, 32), Size = UDim2.new(1, -110, 0, 16), BackgroundTransparency = 1, Text = options.Subtitle or "",
		Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
	})
	T:Bind(sub, "TextColor3", "Accent")

	local function headerButton(text, offset, onClick)
		local b = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offset, 0.5, 0), Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = T.Colors.Surface2, BackgroundTransparency = 1, Text = text, Font = Enum.Font.GothamBold,
			TextSize = 18, TextColor3 = T.Colors.SubText, AutoButtonColor = false, BorderSizePixel = 0, Parent = header,
		})
		Util.Corner(b, 6)
		b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.4, TextColor3 = T.Colors.Text }) end)
		b.MouseLeave:Connect(function() Tween(b, { BackgroundTransparency = 1, TextColor3 = T.Colors.SubText }) end)
		b.MouseButton1Click:Connect(onClick)
	end
	headerButton("×", -12, function() self:Destroy() end)
	headerButton("–", -46, function() self:Toggle(false) end)
	Util.Draggable(header, main, self.Maid)

	self._pages = Create("Frame", {
		Position = UDim2.fromOffset(SIDEBAR_W, HEADER_H), Size = UDim2.new(1, -SIDEBAR_W, 1, -HEADER_H),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = main,
	})

	self.Notifier = Notifications.new(gui, T)

	self.Maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self.ToggleKey then self:Toggle() end
	end))

	Tween(self._scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
	return self
end

function Window:CreateTab(name, icon)
	local tab = Tab.new(self, name, icon)
	table.insert(self.Tabs, tab)
	if #self.Tabs == 1 then self:SelectTab(tab) end
	return tab
end

function Window:SelectTab(tab)
	for _, t in ipairs(self.Tabs) do t:_SetActive(t == tab) end
	self.ActiveTab = tab
end

function Window:Notify(options)
	self.Notifier:Notify(options)
end

function Window:SetAccent(color)
	self.Theme:Set("Accent", color)
end

function Window:SetToggleKey(key)
	if typeof(key) == "EnumItem" then self.ToggleKey = key end
end

function Window:Toggle(state)
	if state == nil then state = not self.Visible end
	self.Visible = state
	if state then
		self._main.Visible = true
		self._scale.Scale = 0.94
		Tween(self._scale, { Scale = 1 }, 0.2)
	else
		Tween(self._scale, { Scale = 0.94 }, 0.15).Completed:Once(function()
			if not self.Visible then self._main.Visible = false end
		end)
	end
end

function Window:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self.Maid:Clean()
	self.Theme:Destroy()
	table.clear(self.Flags)
	table.clear(self.Tabs)
	if self._onDestroy then self._onDestroy() end
end

return Window
