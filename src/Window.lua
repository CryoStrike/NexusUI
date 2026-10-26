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
	Resizable  boolean  show a resize grip in the bottom-right corner (default false)
	MinSize    Vector2  smallest size when resizing       (default 520 x 340)
	MaxSize    Vector2  largest size when resizing        (default viewport - 40)
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
	headerButton("–", -46, function() self:Minimize() end)
	Util.Draggable(header, main, self.Maid)

	-- Optional resize grip (bottom-right). The top-left corner stays put while resizing.
	if options.Resizable then
		local minSize = options.MinSize or Vector2.new(520, 340)
		local maxSize = options.MaxSize
		local grip = Create("TextButton", {
			Name = "ResizeGrip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -2, 1, -2), Size = UDim2.fromOffset(22, 22),
			BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 10, Parent = main,
		})
		local dots = {}
		for _, p in ipairs({ Vector2.new(14, 14), Vector2.new(8, 14), Vector2.new(14, 8) }) do
			local d = Create("Frame", {
				Position = UDim2.fromOffset(p.X, p.Y), Size = UDim2.fromOffset(3, 3), BackgroundColor3 = T.Colors.SubText,
				BorderSizePixel = 0, ZIndex = 11, Parent = grip,
			})
			Util.Corner(d, 2)
			table.insert(dots, d)
		end
		local function tint(color)
			for _, d in ipairs(dots) do Tween(d, { BackgroundColor3 = color }) end
		end

		local resizing, startMouse, startW, startH, startPos = false, nil, 0, 0, nil
		grip.MouseEnter:Connect(function() tint(T.Colors.Accent) end)
		grip.MouseLeave:Connect(function() if not resizing then tint(T.Colors.SubText) end end)
		grip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				resizing, startMouse = true, input.Position
				startW, startH, startPos = main.Size.X.Offset, main.Size.Y.Offset, main.Position
			end
		end)
		self.Maid:Give(UserInputService.InputChanged:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				local delta = input.Position - startMouse
				local cam2 = workspace.CurrentCamera
				local vp = cam2 and cam2.ViewportSize or Vector2.new(1920, 1080)
				local maxW = maxSize and maxSize.X or (vp.X - 40)
				local maxH = maxSize and maxSize.Y or (vp.Y - 40)
				local w = math.clamp(startW + delta.X, minSize.X, math.max(minSize.X, maxW))
				local h = math.clamp(startH + delta.Y, minSize.Y, math.max(minSize.Y, maxH))
				main.Size = UDim2.fromOffset(w, h)
				main.Position = UDim2.new(
					startPos.X.Scale, startPos.X.Offset + (w - startW) / 2,
					startPos.Y.Scale, startPos.Y.Offset + (h - startH) / 2
				)
			end
		end))
		self.Maid:Give(UserInputService.InputEnded:Connect(function(input)
			if resizing and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				resizing = false
				tint(T.Colors.SubText)
			end
		end))
	end

	self._pages = Create("Frame", {
		Position = UDim2.fromOffset(SIDEBAR_W, HEADER_H), Size = UDim2.new(1, -SIDEBAR_W, 1, -HEADER_H),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = main,
	})

	self.Notifier = Notifications.new(gui, T)

	-- Small pill shown while the window is minimised; click it to restore.
	local pill = Create("TextButton", {
		Name = "MinimizedPill", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 14), Size = UDim2.fromOffset(170, 34),
		BackgroundColor3 = T.Colors.Background, BackgroundTransparency = T.Transparency, BorderSizePixel = 0, AutoButtonColor = false,
		Text = (options.Name or "NEXUS") .. "  -  Open", Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = T.Colors.Text,
		Visible = false, ZIndex = 20, Parent = gui,
	})
	Util.Corner(pill, 17)
	T:Bind(Util.Stroke(pill, T.Colors.Accent, 1.5, 0.35), "Color", "Accent")
	pill.MouseEnter:Connect(function() Tween(pill, { BackgroundTransparency = 0 }) end)
	pill.MouseLeave:Connect(function() Tween(pill, { BackgroundTransparency = T.Transparency }) end)
	pill.MouseButton1Click:Connect(function() self:Toggle(true) end)
	self._pill = pill

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

-- Hide the window and show the small restore pill instead.
function Window:Minimize()
	self:Toggle(false)
	self.Minimized = true
	self._pill.Visible = true
end

function Window:Toggle(state)
	if state == nil then state = not self.Visible end
	self.Visible = state
	self.Minimized = false
	self._pill.Visible = false
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
