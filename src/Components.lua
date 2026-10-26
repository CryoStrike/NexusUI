-- Components: every builder takes (parent, options, ctx) and returns an element table
-- exposing  .Value, :Set(), :Destroy(), .Frame.   ctx = { Theme, Maid, Flags, Window }
local import = ...
local Util = import("Util")
local Maid = import("Maid")
local Create, Tween, safe = Util.Create, Util.Tween, Util.SafeCall
local UserInputService = game:GetService("UserInputService")

local B = {}

local function isPress(i)
	return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end
local function isMove(i)
	return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch
end

local function Item(ctx, parent, height)
	local T = ctx.Theme
	local f = Create("Frame", {
		Size = UDim2.new(1, 0, 0, height or 38),
		BackgroundColor3 = T.Colors.Surface2,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Parent = parent,
	})
	Util.Corner(f, 8)
	Util.Stroke(f, T.Colors.Stroke, 1, 0.65)
	return f
end

local function Label(ctx, parent, text, props)
	local p = {
		BackgroundTransparency = 1, Text = text or "", Font = Enum.Font.GothamMedium, TextSize = 14,
		TextColor3 = ctx.Theme.Colors.Text, TextXAlignment = Enum.TextXAlignment.Left, Parent = parent,
	}
	for k, v in pairs(props or {}) do p[k] = v end
	return Create("TextLabel", p)
end

-- Common finishing: Destroy(), flag registration, maid ownership.
local function Finish(ctx, o, el, frame, m)
	el.Frame = frame
	function el:Destroy()
		m:Clean()
		frame:Destroy()
		if o.Flag and ctx.Flags[o.Flag] == el then ctx.Flags[o.Flag] = nil end
	end
	ctx.Maid:Give(m)
	if o.Flag then ctx.Flags[o.Flag] = el end
	return el
end

local function snap(v, min, max, inc)
	v = math.clamp(v, min, max)
	if inc and inc > 0 then v = math.floor((v - min) / inc + 0.5) * inc + min end
	return math.clamp(v, min, max)
end

----------------------------------------------------------------------- Label
function B.Label(parent, o, ctx)
	local m = Maid.new()
	local row = Item(ctx, parent, 32)
	local lbl = Label(ctx, row, o.Text or o.Name or "", {
		Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0),
		TextColor3 = ctx.Theme.Colors.SubText, TextSize = 13, TextWrapped = true,
	})
	local el = { Value = lbl.Text }
	function el:Set(text) el.Value = text; lbl.Text = text end
	return Finish(ctx, o, el, row, m)
end

----------------------------------------------------------------------- Button
function B.Button(parent, o, ctx)
	local T, m = ctx.Theme, Maid.new()
	local btn = Create("TextButton", {
		Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = T.Colors.Surface2, BackgroundTransparency = 0.3,
		AutoButtonColor = false, Text = o.Name or "Button", Font = Enum.Font.GothamMedium, TextSize = 14,
		TextColor3 = T.Colors.Text, BorderSizePixel = 0, Parent = parent,
	})
	Util.Corner(btn, 8)
	local stroke = Util.Stroke(btn, T.Colors.Accent, 1, 0.5)
	m:Give(T:Bind(stroke, "Color", "Accent"))

	btn.MouseEnter:Connect(function() Tween(btn, { BackgroundColor3 = T.Colors.Accent, BackgroundTransparency = 0.7 }) end)
	btn.MouseLeave:Connect(function() Tween(btn, { BackgroundColor3 = T.Colors.Surface2, BackgroundTransparency = 0.3 }) end)
	btn.MouseButton1Down:Connect(function() Tween(btn, { BackgroundTransparency = 0.45 }, 0.08) end)
	btn.MouseButton1Up:Connect(function() Tween(btn, { BackgroundTransparency = 0.7 }, 0.08) end)
	btn.MouseButton1Click:Connect(function() safe(o.Callback) end)

	local el = { Value = nil }
	function el:Set(text) btn.Text = text end
	return Finish(ctx, o, el, btn, m)
end

----------------------------------------------------------------------- Toggle
function B.Toggle(parent, o, ctx)
	local T, m = ctx.Theme, Maid.new()
	local row = Item(ctx, parent, 38)
	Label(ctx, row, o.Name or "Toggle", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -70, 1, 0) })

	local track = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0), Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = T.Colors.Surface, BorderSizePixel = 0, Parent = row,
	})
	Util.Corner(track, 11)
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 3, 0.5, 0), Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track,
	})
	Util.Corner(knob, 8)
	local hit = Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })

	local el = { Value = o.Default == true }
	local function render(t)
		Tween(knob, { Position = el.Value and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0) }, t)
		Tween(track, { BackgroundColor3 = el.Value and T.Colors.Accent or T.Colors.Surface }, t)
	end
	function el:Set(v, silent)
		el.Value = v and true or false
		render()
		if not silent then safe(o.Callback, el.Value) end
	end
	render(0)
	hit.MouseButton1Click:Connect(function() el:Set(not el.Value) end)
	m:Give(T:Listen("Accent", function() render() end))
	return Finish(ctx, o, el, row, m)
end

----------------------------------------------------------------------- Slider
function B.Slider(parent, o, ctx)
	local T, m = ctx.Theme, Maid.new()
	local min, max, inc = o.Min or 0, o.Max or 100, o.Increment or 1
	local suffix = o.Suffix or ""
	local row = Item(ctx, parent, 54)

	Label(ctx, row, o.Name or "Slider", { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(0.6, 0, 0, 22) })
	local valueLbl = Label(ctx, row, "", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 4), Size = UDim2.new(0.4, -12, 0, 22),
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.Colors.SubText, TextSize = 13,
	})

	local track = Create("Frame", {
		Position = UDim2.new(0, 12, 0, 36), Size = UDim2.new(1, -24, 0, 6),
		BackgroundColor3 = T.Colors.Surface, BorderSizePixel = 0, Parent = row,
	})
	Util.Corner(track, 3)
	local fill = Create("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
	Util.Corner(fill, 3)
	m:Give(T:Bind(fill, "BackgroundColor3", "Accent"))
	local knob = Create("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = track,
	})
	Util.Corner(knob, 7)
	local hit = Create("TextButton", {
		AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1, Text = "", Parent = track,
	})

	local el = { Value = snap(o.Default or min, min, max, inc) }
	local function render(animate)
		local a = (max == min) and 0 or (el.Value - min) / (max - min)
		local t = animate and 0.08 or 0
		Tween(fill, { Size = UDim2.fromScale(a, 1) }, t)
		Tween(knob, { Position = UDim2.new(a, 0, 0.5, 0) }, t)
		valueLbl.Text = tostring(el.Value) .. suffix
	end
	function el:Set(v, silent)
		v = snap(tonumber(v) or min, min, max, inc)
		if v == el.Value and not silent then return end
		el.Value = v
		render(true)
		if not silent then safe(o.Callback, v) end
	end
	render(false)

	local dragging = false
	local function fromX(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		el:Set(min + (max - min) * a)
	end
	hit.InputBegan:Connect(function(i) if isPress(i) then dragging = true; fromX(i.Position.X) end end)
	m:Give(UserInputService.InputChanged:Connect(function(i) if dragging and isMove(i) then fromX(i.Position.X) end end))
	m:Give(UserInputService.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end))
	return Finish(ctx, o, el, row, m)
end

----------------------------------------------------------------------- Keybind
function B.Keybind(parent, o, ctx)
	local T, m = ctx.Theme, Maid.new()
	local row = Item(ctx, parent, 38)
	Label(ctx, row, o.Name or "Keybind", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -120, 1, 0) })

	local btn = Create("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(96, 24),
		BackgroundColor3 = T.Colors.Surface, AutoButtonColor = false, Font = Enum.Font.GothamMedium, TextSize = 12,
		TextColor3 = T.Colors.Text, Text = "", BorderSizePixel = 0, Parent = row,
	})
	Util.Corner(btn, 6)

	local el = { Value = o.Default }
	local listening = false
	local function show() btn.Text = el.Value and el.Value.Name or "None" end
	show()

	function el:Set(key, silent)
		el.Value = key
		show()
		if not silent then safe(o.OnChanged, key) end
	end

	btn.MouseButton1Click:Connect(function()
		listening = true
		btn.Text = "..."
		Tween(btn, { TextColor3 = T.Colors.Accent })
	end)

	m:Give(UserInputService.InputBegan:Connect(function(input, processed)
		if listening then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				listening = false
				Tween(btn, { TextColor3 = T.Colors.Text })
				el:Set(input.KeyCode ~= Enum.KeyCode.Backspace and input.KeyCode or nil) -- Backspace clears
			end
			return
		end
		if not processed and el.Value and input.KeyCode == el.Value then
			safe(o.Callback, el.Value)
		end
	end))
	return Finish(ctx, o, el, row, m)
end

----------------------------------------------------------------------- TextInput
function B.Input(parent, o, ctx)
	local T, m = ctx.Theme, Maid.new()
	local row = Item(ctx, parent, 62)
	Label(ctx, row, o.Name or "Input", { Position = UDim2.fromOffset(12, 4), Size = UDim2.new(1, -24, 0, 22) })

	local box = Create("TextBox", {
		Position = UDim2.fromOffset(10, 30), Size = UDim2.new(1, -20, 0, 26), BackgroundColor3 = T.Colors.Surface,
		BorderSizePixel = 0, Text = o.Default or "", PlaceholderText = o.Placeholder or "Type here...",
		PlaceholderColor3 = T.Colors.SubText, TextColor3 = T.Colors.Text, Font = Enum.Font.Gotham, TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = o.ClearOnFocus == true, Parent = row,
	})
	Util.Corner(box, 6)
	Util.Padding(box, 0, 8, 0, 8)
	local stroke = Util.Stroke(box, T.Colors.Stroke, 1, 0.5)

	local el = { Value = box.Text }
	function el:Set(text, silent)
		box.Text = tostring(text); el.Value = box.Text
		if not silent then safe(o.Callback, el.Value, false) end
	end
	box.Focused:Connect(function() Tween(stroke, { Color = T.Colors.Accent, Transparency = 0 }) end)
	box.FocusLost:Connect(function(enter)
		Tween(stroke, { Color = T.Colors.Stroke, Transparency = 0.5 })
		el.Value = box.Text
		safe(o.Callback, el.Value, enter)
	end)
	return Finish(ctx, o, el, row, m)
end

----------------------------------------------------------------------- Dropdown
function B.Dropdown(parent, o, ctx)
	local T, m = ctx.Theme, Maid.new()
	local multi = o.Multi == true
	local options = o.Options or {}
	local selected = {} -- multi: set of chosen options
	local current = nil -- single: chosen option
	local open = false

	local root = Item(ctx, parent, 38)
	root.ClipsDescendants = true
	Label(ctx, root, o.Name or "Dropdown", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(0.45, 0, 0, 38) })
	local valueLbl = Label(ctx, root, "", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -30, 0, 0), Size = UDim2.new(0.5, -30, 0, 38),
		TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = T.Colors.SubText, TextSize = 13, TextTruncate = Enum.TextTruncate.AtEnd,
	})
	local arrow = Label(ctx, root, "›", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.fromOffset(16, 38),
		TextXAlignment = Enum.TextXAlignment.Center, TextSize = 18, TextColor3 = T.Colors.Accent2, Rotation = 90,
	})
	local head = Create("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "", Parent = root })

	local list = Create("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 42), Size = UDim2.new(1, -16, 0, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
		ScrollBarThickness = 2, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Parent = root,
	})
	Create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local el = { Value = multi and {} or nil }

	local function isSelected(opt) return multi and selected[opt] == true or current == opt end
	local function refresh()
		for _, b in ipairs(list:GetChildren()) do
			if b:IsA("TextButton") then
				Tween(b, { TextColor3 = isSelected(b:GetAttribute("Option")) and T.Colors.Accent or T.Colors.Text })
			end
		end
		if multi then
			local out = {}
			for _, opt in ipairs(options) do if selected[opt] then table.insert(out, tostring(opt)) end end
			el.Value = table.clone(out)
			valueLbl.Text = #out > 0 and table.concat(out, ", ") or "None"
		else
			el.Value = current
			valueLbl.Text = current ~= nil and tostring(current) or "None"
		end
	end

	local function listHeight() return math.min(#options * 28, 140) end
	local function setOpen(state)
		open = state
		local h = open and (38 + 4 + listHeight() + 6) or 38
		list.Size = UDim2.new(1, -16, 0, listHeight())
		Tween(root, { Size = UDim2.new(1, 0, 0, h) }, 0.2)
		Tween(arrow, { Rotation = open and 270 or 90 }, 0.2)
	end

	local function build()
		for _, c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
		for i, opt in ipairs(options) do
			local b = Create("TextButton", {
				LayoutOrder = i, Size = UDim2.new(1, 0, 0, 26), BackgroundColor3 = T.Colors.Surface, BackgroundTransparency = 0.4,
				AutoButtonColor = false, Text = tostring(opt), Font = Enum.Font.GothamMedium, TextSize = 13,
				TextColor3 = T.Colors.Text, BorderSizePixel = 0, Parent = list,
			})
			b:SetAttribute("Option", opt)
			Util.Corner(b, 6)
			b.MouseButton1Click:Connect(function()
				if multi then
					selected[opt] = not selected[opt] or nil
					refresh()
					safe(o.Callback, el.Value)
				else
					current = opt
					refresh()
					setOpen(false)
					safe(o.Callback, current)
				end
			end)
		end
		refresh()
		if open then setOpen(true) end
	end

	function el:Set(v, silent)
		if multi then
			selected = {}
			for _, opt in ipairs(type(v) == "table" and v or {}) do selected[opt] = true end
		else
			current = v
		end
		refresh()
		if not silent then safe(o.Callback, el.Value) end
	end
	function el:SetOptions(newOptions)
		options = newOptions or {}
		build()
	end

	if multi then for _, opt in ipairs(o.Default or {}) do selected[opt] = true end else current = o.Default end
	build()
	head.MouseButton1Click:Connect(function() setOpen(not open) end)
	return Finish(ctx, o, el, root, m)
end

----------------------------------------------------------------------- Mixin
local Components = { Builders = B, Methods = {} }

for name, builder in pairs({
	Label = B.Label, Button = B.Button, Toggle = B.Toggle, Slider = B.Slider,
	Keybind = B.Keybind, Input = B.Input, Dropdown = B.Dropdown,
}) do
	Components.Methods["Add" .. name] = function(self, opts)
		return builder(self.Frame, opts or {}, self.Ctx)
	end
end

function Components.Extend(class)
	for k, v in pairs(Components.Methods) do class[k] = v end
end

return Components
