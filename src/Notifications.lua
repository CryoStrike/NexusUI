local import = ...
local Util = import("Util")
local Create, Tween = Util.Create, Util.Tween

local Notifications = {}
Notifications.__index = Notifications

function Notifications.new(gui, theme)
	local self = setmetatable({ Theme = theme }, Notifications)
	self.Holder = Create("Frame", {
		Name = "Notifications", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.new(0, 300, 1, -32), BackgroundTransparency = 1, ZIndex = 50, Parent = gui,
	})
	Create("UIListLayout", {
		Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom, Parent = self.Holder,
	})
	return self
end

-- options: { Title, Content, Duration = 4, Type = "Info" | "Success" | "Warning" | "Error" }
function Notifications:Notify(options)
	options = options or {}
	local T = self.Theme
	local duration = options.Duration or 4
	local colors = { Info = T.Colors.Accent, Success = T.Colors.Success, Warning = T.Colors.Warning, Error = T.Colors.Danger }
	local color = colors[options.Type or "Info"] or T.Colors.Accent

	local wrapper = Create("Frame", {
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = self.Holder,
	})
	local card = Create("Frame", {
		Position = UDim2.new(1, 40, 0, 0), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = T.Colors.Background, BackgroundTransparency = 0.08, BorderSizePixel = 0, Parent = wrapper,
	})
	Util.Corner(card, 10)
	Util.Stroke(card, color, 1.2, 0.3)
	Util.Padding(card, 10, 12, 10, 12)
	Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	local function text(str, order, size, font, c)
		return Create("TextLabel", {
			LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Text = str, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Font = font, TextSize = size,
			TextColor3 = c, Parent = card,
		})
	end
	if options.Title then text(options.Title, 1, 15, Enum.Font.GothamBold, color) end
	if options.Content then text(options.Content, 2, 13, Enum.Font.Gotham, T.Colors.Text) end

	local bar = Create("Frame", { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 2), BackgroundColor3 = color, BorderSizePixel = 0, Parent = card })
	Util.Corner(bar, 1)

	Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back)
	Tween(bar, { Size = UDim2.new(0, 0, 0, 2) }, duration, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if not wrapper:IsDescendantOf(game) then return end
		local t = Tween(card, { Position = UDim2.new(1, 40, 0, 0) }, 0.25)
		t.Completed:Wait()
		if wrapper:IsDescendantOf(game) then wrapper:Destroy() end
	end)
end

return Notifications
