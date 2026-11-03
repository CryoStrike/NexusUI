-- Tab (sidebar tile + scrolling page) and Section (pill-titled group of components).
local import = ...
local Util = import("Util")
local Components = import("Components")
local Create, Tween = Util.Create, Util.Tween

----------------------------------------------------------------------- Section
local Section = {}
Section.__index = Section
Components.Extend(Section)

function Section.new(parent, name, ctx)
	local T = ctx.Theme
	local outer = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = parent,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = outer })

	-- Title: a neon outlined pill, as wide as its text
	local row = Create("Frame", { LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = outer })
	local chip = Create("TextLabel", {
		Name = "Title", Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 0.88, BorderSizePixel = 0,
		Text = Util.Upper(name or "SECTION"), Font = T.Fonts.Title, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Parent = row,
	})
	Util.Corner(chip, 10)
	Util.Padding(chip, 0, 14, 0, 14)
	T:Bind(chip, "BackgroundColor3", "Accent")
	T:Bind(chip, "TextColor3", "Accent")
	T:Bind(Util.Stroke(chip, T.Colors.Accent, 1.5, 0.2), "Color", "Accent")

	local holder = Create("Frame", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = outer,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	return setmetatable({ Frame = holder, Root = outer, Ctx = ctx }, Section)
end

function Section:Destroy() self.Root:Destroy() end

----------------------------------------------------------------------- Tab
local Tab = {}
Tab.__index = Tab
Components.Extend(Tab)

local LABEL_H, ICON_GAP = 16, 3

function Tab.new(window, name, icon)
	local ctx = window.Ctx
	local T = ctx.Theme
	local self = setmetatable({ Window = window, Name = name, Ctx = ctx, Active = false, Hover = false, Height = 62 }, Tab)

	-- Sidebar tile: rounded, neon outline, icon on top and the name below
	local btn = Create("TextButton", {
		Name = name, Size = UDim2.new(1, 0, 0, self.Height), BackgroundColor3 = T.Colors.Surface2, BackgroundTransparency = 0.45,
		AutoButtonColor = false, Text = "", BorderSizePixel = 0, LayoutOrder = #window.Tabs + 1, Parent = window._tabList,
	})
	Util.Corner(btn, 12)
	self.Stroke = Util.Stroke(btn, T.Colors.Stroke, 1.5, 0.35)
	self.Button = btn

	self.HasIcon = type(icon) == "string" and icon ~= ""
	if self.HasIcon then
		self.Icon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1,
			Image = Util.GetAsset(icon), ImageColor3 = T.Colors.Accent, Parent = btn,
		})
	end
	self.Label = Create("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0), BackgroundTransparency = 1, Text = Util.Upper(name), Font = T.Fonts.Title,
		TextColor3 = T.Colors.SubText, TextScaled = true, Parent = btn,
	})
	Create("UITextSizeConstraint", { MaxTextSize = self.HasIcon and 15 or 17, MinTextSize = 9, Parent = self.Label })

	self.Page = Create("ScrollingFrame", {
		Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 4, ScrollBarImageColor3 = T.Colors.Accent, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = window._pages,
	})
	Util.Padding(self.Page, 14, 16, 16, 16)
	Create("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Page })
	self.Frame = self.Page -- components can be added straight onto the tab

	self:_SetHeight(self.Height)
	self:_Apply(0)

	btn.MouseButton1Click:Connect(function() window:SelectTab(self) end)
	btn.MouseEnter:Connect(function() self.Hover = true self:_Apply(0.12) end)
	btn.MouseLeave:Connect(function() self.Hover = false self:_Apply(0.12) end)
	ctx.Maid:Give(T:Listen("Accent", function(c)
		self.Page.ScrollBarImageColor3 = c
		self:_Apply(0.25)
	end))
	return self
end

-- Lays out the icon and the label for a tile of height h.
function Tab:_SetHeight(h)
	self.Height = h
	self.Button.Size = UDim2.new(1, 0, 0, h)
	if self.HasIcon then
		local iconSize = math.clamp(math.floor(h * 0.42 + 0.5), 18, 30)
		local pad = math.max(3, math.floor((h - iconSize - LABEL_H - ICON_GAP) / 2))
		self.Icon.Size = UDim2.fromOffset(iconSize, iconSize)
		self.Icon.Position = UDim2.new(0.5, 0, 0, pad)
		self.Label.Position = UDim2.new(0.5, 0, 0, pad + iconSize + ICON_GAP)
		self.Label.Size = UDim2.new(1, -10, 0, LABEL_H)
	else
		self.Label.AnchorPoint = Vector2.new(0.5, 0.5)
		self.Label.Position = UDim2.fromScale(0.5, 0.5)
		self.Label.Size = UDim2.new(1, -10, 0, 22)
	end
end

-- Colours for the current state (selected / hovered / idle).
function Tab:_Apply(duration)
	local T = self.Ctx.Theme
	local C = T.Colors
	local goal
	if self.Active then
		goal = {
			stroke = { Color = C.Accent, Thickness = 2, Transparency = 0 },
			button = { BackgroundColor3 = C.Accent, BackgroundTransparency = 0.8 },
			label = { TextColor3 = C.Text },
			icon = { ImageColor3 = C.Accent },
		}
	elseif self.Hover then
		goal = {
			stroke = { Color = C.Accent:Lerp(C.Stroke, 0.5), Thickness = 1.5, Transparency = 0.1 },
			button = { BackgroundColor3 = C.Surface2, BackgroundTransparency = 0.3 },
			label = { TextColor3 = C.Text },
			icon = { ImageColor3 = C.Accent },
		}
	else
		goal = {
			stroke = { Color = C.Stroke, Thickness = 1.5, Transparency = 0.35 },
			button = { BackgroundColor3 = C.Surface2, BackgroundTransparency = 0.45 },
			label = { TextColor3 = C.SubText },
			icon = { ImageColor3 = C.Accent:Lerp(C.Surface, 0.45) },
		}
	end
	Tween(self.Stroke, goal.stroke, duration)
	Tween(self.Button, goal.button, duration)
	Tween(self.Label, goal.label, duration)
	if self.Icon then Tween(self.Icon, goal.icon, duration) end
end

function Tab:_SetActive(active)
	self.Active = active
	self.Page.Visible = active
	self:_Apply(0.15)
end

function Tab:AddSection(name)
	return Section.new(self.Page, name, self.Ctx)
end

return Tab
