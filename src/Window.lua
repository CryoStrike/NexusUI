local import = ...
local Util = import("Util")
local Maid = import("Maid")
local Theme = import("Theme")
local Tab = import("Tab")
local Notifications = import("Notifications")
local UserInputService = game:GetService("UserInputService")
local Create, Tween = Util.Create, Util.Tween

-- Layout (design pixels)
local SIDEBAR_W = 112 -- left column: logo + category buttons
local MARGIN = 12     -- gap between the content panel and the window edge
local HEADER_H = 56   -- title row of the content panel
local FOOTER_H = 26   -- status line under the sidebar
local LOGO = 52

local Window = {}
Window.__index = Window

--[[ options:
	Name       string   title text                      (default "NEXUS")
	Subtitle   string   small accent text under title
	Icon       string   "rbxassetid://..." or https URL to the logo
	Accent     Color3   accent colour
	Size       UDim2    offset size (clamped to the viewport)
	ToggleKey  Enum.KeyCode  show/hide key              (default RightShift)
	Theme      table    palette overrides { Background = Color3, ..., Fonts = { Title = Enum.Font.X, Text = Enum.Font.Y } }
	Resizable  boolean  show a resize grip in the bottom-right corner (default false)
	MinSize    Vector2  smallest size when resizing       (default 520 x 340)
	MaxSize    Vector2  largest size when resizing        (default viewport - 40)
	TabHeight  number   fixed height of a category tile       (default: automatic, tiles share the sidebar height, 46-76)
	Footer     string   status line at the bottom-left (RichText allowed, e.g. 'STATUS: <font color="rgb(0,224,255)">ACTIVE</font>')
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
	self._tabHeight = options.TabHeight -- nil = automatic
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

	-- Window body: dark translucent glass. It does not clip, so glows can reach beyond the children.
	local main = Create("Frame", {
		Name = "Main", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = size,
		BackgroundColor3 = T.Colors.Background, BackgroundTransparency = T.Transparency, BorderSizePixel = 0, Parent = gui,
	})
	self._main = main
	self._scale = Create("UIScale", { Scale = 0.92, Parent = main })
	Util.Corner(main, 14)
	T:Bind(Util.Stroke(main, T.Colors.Accent, 1, 0.7), "Color", "Accent")
	Create("UIGradient", {
		Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 195, 215)), Parent = main,
	})

	-- Sidebar: logo + floating category buttons (see Tab.lua)
	Create("ImageLabel", {
		Name = "Logo", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0, SIDEBAR_W / 2 + 2, 0, MARGIN + 2), Size = UDim2.fromOffset(LOGO, LOGO),
		BackgroundTransparency = 1, Image = Util.GetAsset(options.Icon), ScaleType = Enum.ScaleType.Fit, Parent = main,
	})
	local listTop = MARGIN + 2 + LOGO + 10
	self._listTop = listTop
	self._tabList = Create("ScrollingFrame", {
		Name = "Categories", Position = UDim2.fromOffset(0, listTop), Size = UDim2.new(0, SIDEBAR_W, 1, -(listTop + FOOTER_H)),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = main,
	})
	T:Bind(self._tabList, "ScrollBarImageColor3", "Accent")
	Util.Padding(self._tabList, 6, 8, 6, 12)
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self._tabList })

	-- Status line (bottom-left)
	if type(options.Footer) == "string" and options.Footer ~= "" then
		Create("TextLabel", {
			Name = "Footer", Position = UDim2.new(0, 16, 1, -FOOTER_H), Size = UDim2.new(1, -64, 0, FOOTER_H), BackgroundTransparency = 1,
			Text = options.Footer, RichText = true, Font = T.Fonts.Text, TextSize = 13, TextColor3 = T.Colors.SubText,
			TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = main,
		})
	end

	-- Content panel: glowing neon border around the title row + the pages
	local holder = Create("Frame", {
		Name = "PanelHolder", Position = UDim2.fromOffset(SIDEBAR_W, MARGIN), Size = UDim2.new(1, -(SIDEBAR_W + MARGIN), 1, -(MARGIN + FOOTER_H)),
		BackgroundTransparency = 1, Parent = main,
	})
	self._glow = Util.Glow(holder, T, { Corner = 12, Layers = 4, Step = 3, Alpha = 0.8 })
	local panel = Create("Frame", {
		Name = "Panel", Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Colors.Surface, BackgroundTransparency = 0.25,
		BorderSizePixel = 0, ClipsDescendants = true, Parent = holder,
	})
	Util.Corner(panel, 12)
	T:Bind(Util.Stroke(panel, T.Colors.Accent, 2, 0.05), "Color", "Accent")

	-- Header (title + window buttons) - drag handle
	local header = Create("Frame", { Name = "Header", Size = UDim2.new(1, 0, 0, HEADER_H), BackgroundTransparency = 1, Parent = panel })
	Create("TextLabel", {
		Position = UDim2.fromOffset(18, 6), Size = UDim2.new(1, -110, 0, 30), BackgroundTransparency = 1, Text = options.Name or "NEXUS",
		Font = T.Fonts.Title, TextSize = 28, TextColor3 = T.Colors.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
	})
	local sub = Create("TextLabel", {
		Position = UDim2.fromOffset(18, 35), Size = UDim2.new(1, -110, 0, 16), BackgroundTransparency = 1, Text = Util.Upper(options.Subtitle or ""),
		Font = T.Fonts.Title, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
	})
	T:Bind(sub, "TextColor3", "Accent")
	local divider = Create("Frame", {
		Position = UDim2.new(0, 14, 0, HEADER_H), Size = UDim2.new(1, -28, 0, 1), BackgroundTransparency = 0.7, BorderSizePixel = 0, Parent = panel,
	})
	T:Bind(divider, "BackgroundColor3", "Accent")

	local function headerButton(text, offset, onClick)
		local b = Create("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, offset, 0.5, 0), Size = UDim2.fromOffset(30, 30),
			BackgroundColor3 = T.Colors.Accent, BackgroundTransparency = 1, Text = text, Font = T.Fonts.Title,
			TextSize = 22, TextColor3 = T.Colors.SubText, AutoButtonColor = false, BorderSizePixel = 0, Parent = header,
		})
		Util.Corner(b, 8)
		b.MouseEnter:Connect(function() Tween(b, { BackgroundTransparency = 0.8, TextColor3 = T.Colors.Text }) end)
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
			Name = "ResizeGrip", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -4, 1, -4), Size = UDim2.fromOffset(22, 22),
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
				self:_LayoutTabs()
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
		Name = "Pages", Position = UDim2.fromOffset(0, HEADER_H + 1), Size = UDim2.new(1, 0, 1, -(HEADER_H + 1)),
		BackgroundTransparency = 1, ClipsDescendants = true, Parent = panel,
	})

	self.Notifier = Notifications.new(gui, T)

	-- Small neon pill shown while the window is minimised; click it to restore.
	local pillHolder = Create("Frame", {
		Name = "MinimizedPill", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 16), Size = UDim2.fromOffset(180, 36),
		BackgroundTransparency = 1, Visible = false, ZIndex = 20, Parent = gui,
	})
	Util.Glow(pillHolder, T, { Corner = 18, Layers = 3, Step = 3, Alpha = 0.78 })
	local pill = Create("TextButton", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.Colors.Background, BackgroundTransparency = 0.15, BorderSizePixel = 0,
		AutoButtonColor = false, Text = Util.Upper(options.Name or "NEXUS") .. "  -  OPEN", Font = T.Fonts.Title, TextSize = 15,
		TextColor3 = T.Colors.Text, Parent = pillHolder,
	})
	Util.Corner(pill, 18)
	T:Bind(Util.Stroke(pill, T.Colors.Accent, 2, 0.05), "Color", "Accent")
	pill.MouseEnter:Connect(function() Tween(pill, { BackgroundTransparency = 0.4 }) end)
	pill.MouseLeave:Connect(function() Tween(pill, { BackgroundTransparency = 0.15 }) end)
	pill.MouseButton1Click:Connect(function() self:Toggle(true) end)
	self._pill = pillHolder

	self.Maid:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == self.ToggleKey then self:Toggle() end
	end))

	Tween(self._scale, { Scale = 1 }, 0.25, Enum.EasingStyle.Back)
	return self
end

-- Sidebar tile height: fixed (TabHeight) or shared out so all tiles fit without scrolling.
function Window:_LayoutTabs()
	local n = #self.Tabs
	if n == 0 then return end
	local h = self._tabHeight
	if not h then
		local avail = self._main.Size.Y.Offset - self._listTop - FOOTER_H - 12 - 6 * (n - 1)
		h = math.clamp(math.floor(avail / n), 46, 76)
	end
	for _, t in ipairs(self.Tabs) do t:_SetHeight(h) end
end

function Window:CreateTab(name, icon)
	local tab = Tab.new(self, name, icon)
	table.insert(self.Tabs, tab)
	self:_LayoutTabs()
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
