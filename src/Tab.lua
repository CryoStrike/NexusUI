-- Tab (sidebar button + scrolling page) and Section (titled group of components).
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
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = outer })
	Create("TextLabel", {
		LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = string.upper(name or "SECTION"),
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Colors.Accent2, TextXAlignment = Enum.TextXAlignment.Left, Parent = outer,
	})
	local holder = Create("Frame", {
		LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = outer,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	return setmetatable({ Frame = holder, Root = outer, Ctx = ctx }, Section)
end

function Section:Destroy() self.Root:Destroy() end

----------------------------------------------------------------------- Tab
local Tab = {}
Tab.__index = Tab
Components.Extend(Tab)

function Tab.new(window, name, icon)
	local ctx = window.Ctx
	local T = ctx.Theme
	local self = setmetatable({ Window = window, Name = name, Ctx = ctx, Active = false }, Tab)

	local btn = Create("TextButton", {
		Name = name, Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = T.Colors.Surface2, BackgroundTransparency = 1,
		AutoButtonColor = false, Text = "", BorderSizePixel = 0, Parent = window._tabList,
	})
	self.Button = btn
	self.Indicator = Create("Frame", { Size = UDim2.new(0, 3, 1, -16), Position = UDim2.fromOffset(0, 8), BorderSizePixel = 0, Visible = false, Parent = btn })
	Util.Corner(self.Indicator, 2)
	T:Bind(self.Indicator, "BackgroundColor3", "Accent")

	local hasIcon = type(icon) == "string" and icon ~= ""
	if hasIcon then
		self.Icon = Create("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 10), Size = UDim2.fromOffset(24, 24),
			BackgroundTransparency = 1, Image = Util.GetAsset(icon), ImageColor3 = T.Colors.SubText, Parent = btn,
		})
	end
	self.Label = Create("TextLabel", {
		BackgroundTransparency = 1, Text = name, Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.Colors.SubText,
		Position = hasIcon and UDim2.fromOffset(0, 38) or UDim2.new(), Size = hasIcon and UDim2.new(1, 0, 0, 18) or UDim2.fromScale(1, 1), Parent = btn,
	})

	self.Page = Create("ScrollingFrame", {
		Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
		ScrollBarThickness = 3, ScrollBarImageColor3 = T.Colors.Accent, CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = window._pages,
	})
	Util.Padding(self.Page, 6, 14, 14, 14)
	Create("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Page })
	self.Frame = self.Page -- components can be added straight onto the tab

	btn.MouseButton1Click:Connect(function() window:SelectTab(self) end)
	btn.MouseEnter:Connect(function() if not self.Active then Tween(btn, { BackgroundTransparency = 0.8 }) end end)
	btn.MouseLeave:Connect(function() if not self.Active then Tween(btn, { BackgroundTransparency = 1 }) end end)
	ctx.Maid:Give(T:Listen("Accent", function(c)
		self.Page.ScrollBarImageColor3 = c
		if self.Active then
			self.Label.TextColor3 = c
			if self.Icon then self.Icon.ImageColor3 = c end
		end
	end))
	return self
end

function Tab:_SetActive(active)
	local T = self.Ctx.Theme
	self.Active = active
	self.Page.Visible = active
	self.Indicator.Visible = active
	local c = active and T.Colors.Accent or T.Colors.SubText
	Tween(self.Label, { TextColor3 = c }, 0.15)
	if self.Icon then Tween(self.Icon, { ImageColor3 = c }, 0.15) end
	Tween(self.Button, { BackgroundTransparency = active and 0.55 or 1 }, 0.15)
end

function Tab:AddSection(name)
	return Section.new(self.Page, name, self.Ctx)
end

return Tab
