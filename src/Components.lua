-- Components: every builder takes (parent, options, ctx) and returns an element table
-- exposing  .Value, :Set(), :Destroy(), .Frame.   ctx = { Theme, Maid, Flags, Window }
local import = ...
local Util = import("Util")
local Maid = import("Maid")
local Create, Tween, safe = Util.Create, Util.Tween, Util.SafeCall
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

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

----------------------------------------------------------------------- ColorPicker
-- A row with a colour swatch; clicking it opens: hue ring + saturation/brightness disc,
-- optional alpha bar, and hex / R / G / B inputs. Everything is plain Instances (no images),
-- so it works on every executor.
local CP = { DIAMETER = 200, THICKNESS = 22, DISC_R = 69, PANEL_W = 250, SEGMENTS = 120 }

-- Pointer position in the same coordinate space as GuiObject.AbsolutePosition (IgnoreGuiInset = true).
local function pointerPos(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		local inset = GuiService:GetGuiInset()
		return Vector2.new(input.Position.X + inset.X, input.Position.Y + inset.Y)
	end
	return UserInputService:GetMouseLocation()
end

-- "#RRGGBB", "RRGGBB", "#RGB" -> Color3 (or nil)
local function parseHex(text)
	text = tostring(text or ""):gsub("[#%s]", "")
	if #text == 3 then text = text:gsub("(%x)", "%1%1") end
	if #text ~= 6 or not text:match("^%x+$") then return nil end
	return Color3.fromRGB(tonumber(text:sub(1, 2), 16), tonumber(text:sub(3, 4), 16), tonumber(text:sub(5, 6), 16))
end

local function to255(c)
	return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)
end

function B.ColorPicker(parent, o, ctx)
	local T, m = ctx.Theme, Maid.new()
	local useAlpha = o.Alpha == true
	local D, TH, DISC_R, PW = CP.DIAMETER, CP.THICKNESS, CP.DISC_R, CP.PANEL_W
	local R_OUT = D / 2
	local R_MID = R_OUT - TH / 2
	local R_IN = R_OUT - TH
	-- The saturation/brightness square is inscribed in the disc, so every colour stays reachable.
	local T0 = (1 - math.sqrt(0.5)) / 2
	local T1 = 1 - T0
	local RANGE = T1 - T0

	local startColor = typeof(o.Default) == "Color3" and o.Default or Color3.fromRGB(255, 255, 255)
	local h, s, v = startColor:ToHSV()
	local alpha = math.clamp(tonumber(o.DefaultAlpha) or 1, 0, 1)

	local alphaY = 4 + D + 14
	local inputsY = useAlpha and (alphaY + 14 + 14) or (4 + D + 14)
	local panelH = inputsY + 28 + 4 + 14 + 8
	local openH = 44 + panelH

	local root = Item(ctx, parent, 38)
	root.ClipsDescendants = true
	Label(ctx, root, o.Name or "Color", { Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -90, 0, 38) })
	local swatch = Create("Frame", {
		AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -34, 0, 19), Size = UDim2.fromOffset(34, 20),
		BackgroundColor3 = startColor, BorderSizePixel = 0, Parent = root,
	})
	Util.Corner(swatch, 5)
	Util.Stroke(swatch, T.Colors.Stroke, 1, 0.4)
	local arrow = Label(ctx, root, "›", {
		AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.fromOffset(16, 38),
		TextXAlignment = Enum.TextXAlignment.Center, TextSize = 18, TextColor3 = T.Colors.Accent2, Rotation = 90,
	})
	local head = Create("TextButton", { Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1, Text = "", Parent = root })
	local panel = Create("Frame", {
		Position = UDim2.fromOffset(0, 44), Size = UDim2.new(1, 0, 0, panelH), BackgroundTransparency = 1, Parent = root,
	})

	local el = { Value = Color3.fromHSV(h, s, v), Alpha = alpha }
	local built = false
	local holder, discBase, hueKnob, svCursor, alphaHolder, alphaFill, alphaKnob, hexBox, rBox, gBox, bBox

	local function refresh()
		local c = Color3.fromHSV(h, s, v)
		el.Value, el.Alpha = c, alpha
		swatch.BackgroundColor3 = c
		swatch.BackgroundTransparency = useAlpha and (1 - alpha) or 0
		if not built then return end

		local pure = Color3.fromHSV(h, 1, 1)
		discBase.BackgroundColor3 = pure
		hueKnob.BackgroundColor3 = pure
		local ang = -2 * math.pi * h
		hueKnob.Position = UDim2.fromOffset(R_OUT + R_MID * math.cos(ang), R_OUT + R_MID * math.sin(ang))
		svCursor.Position = UDim2.fromScale(T0 + s * RANGE, T0 + (1 - v) * RANGE)
		if useAlpha then
			alphaFill.BackgroundColor3 = c
			alphaKnob.BackgroundColor3 = c
			alphaKnob.Position = UDim2.fromScale(alpha, 0.5)
		end

		local r, g, b = to255(c)
		local function put(box, text) if not box:IsFocused() then box.Text = text end end
		put(hexBox, string.format("%02X%02X%02X", r, g, b))
		put(rBox, tostring(r))
		put(gBox, tostring(g))
		put(bBox, tostring(b))
	end

	local function fire() safe(o.Callback, el.Value, el.Alpha) end
	local function commit() refresh(); fire() end

	-- Keep the old hue when the new colour has none (grey / black), so the ring does not jump.
	local function setColor(c)
		local nh, ns, nv = c:ToHSV()
		if ns > 0 and nv > 0 then h = nh end
		s, v = ns, nv
	end

	local function build()
		if built then return end
		built = true

		holder = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 4), Size = UDim2.fromOffset(D, D),
			BackgroundTransparency = 1, Parent = panel,
		})

		-- Hue ring: thin rotated segments, one colour each (hue grows counter-clockwise, red on the right)
		local segW = (2 * math.pi * R_MID / CP.SEGMENTS) * 1.6
		for i = 0, CP.SEGMENTS - 1 do
			local hh = i / CP.SEGMENTS
			local ang = -2 * math.pi * hh
			Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(R_OUT + R_MID * math.cos(ang), R_OUT + R_MID * math.sin(ang)),
				Size = UDim2.fromOffset(segW, TH), Rotation = math.deg(ang) - 90,
				BackgroundColor3 = Color3.fromHSV(hh, 1, 1), BorderSizePixel = 0, Parent = holder,
			})
		end

		-- Saturation (left -> right) / brightness (top -> bottom) disc with a white outline
		discBase = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(R_OUT, R_OUT), Size = UDim2.fromOffset(DISC_R * 2, DISC_R * 2),
			BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Parent = holder,
		})
		Util.Corner(discBase, DISC_R)
		Util.Stroke(discBase, Color3.new(1, 1, 1), 3, 0)
		local white = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = discBase })
		Util.Corner(white, DISC_R)
		Create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(T0, 0),
				NumberSequenceKeypoint.new(T1, 1), NumberSequenceKeypoint.new(1, 1),
			}),
			Parent = white,
		})
		local black = Create("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = discBase })
		Util.Corner(black, DISC_R)
		Create("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(T0, 1),
				NumberSequenceKeypoint.new(T1, 0), NumberSequenceKeypoint.new(1, 0),
			}),
			Parent = black,
		})

		svCursor = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), BackgroundTransparency = 1, ZIndex = 3, Parent = discBase,
		})
		Util.Corner(svCursor, 7)
		Util.Stroke(svCursor, Color3.new(1, 1, 1), 2, 0)
		local halo = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1, Parent = svCursor,
		})
		Util.Corner(halo, 9)
		Util.Stroke(halo, Color3.new(0, 0, 0), 1, 0.5)

		hueKnob = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = Color3.fromHSV(h, 1, 1),
			BorderSizePixel = 0, ZIndex = 3, Parent = holder,
		})
		Util.Corner(hueKnob, 11)
		Util.Stroke(hueKnob, Color3.new(1, 1, 1), 3, 0)

		local ringHit = Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = holder })

		-- Alpha bar (checkerboard + colour fading from transparent to opaque)
		local alphaHit
		if useAlpha then
			local aw = PW - 10
			alphaHolder = Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, alphaY), Size = UDim2.fromOffset(aw, 14),
				BackgroundTransparency = 1, Parent = panel,
			})
			local bar = Create("Frame", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(235, 235, 235), BorderSizePixel = 0,
				ClipsDescendants = true, Parent = alphaHolder,
			})
			Util.Corner(bar, 7)
			for row = 0, 1 do
				for col = 0, math.ceil(aw / 7) - 1 do
					if (row + col) % 2 == 1 then
						Create("Frame", {
							Position = UDim2.fromOffset(col * 7, row * 7), Size = UDim2.fromOffset(7, 7),
							BackgroundColor3 = Color3.fromRGB(170, 170, 170), BorderSizePixel = 0, Parent = bar,
						})
					end
				end
			end
			alphaFill = Create("Frame", {
				Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromHSV(h, s, v), BorderSizePixel = 0, ZIndex = 2, Parent = bar,
			})
			Util.Corner(alphaFill, 7)
			Create("UIGradient", { Transparency = NumberSequence.new(1, 0), Parent = alphaFill })
			alphaKnob = Create("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(18, 18), BackgroundColor3 = Color3.fromHSV(h, s, v),
				BorderSizePixel = 0, ZIndex = 4, Parent = alphaHolder,
			})
			Util.Corner(alphaKnob, 9)
			Util.Stroke(alphaKnob, Color3.new(1, 1, 1), 3, 0)
			alphaHit = Create("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 5, Parent = alphaHolder })
		end

		-- Hex / R / G / B inputs with captions underneath
		local row = Create("Frame", {
			AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, inputsY), Size = UDim2.fromOffset(PW, 46),
			BackgroundTransparency = 1, Parent = panel,
		})
		local function field(x, w, caption)
			local box = Create("TextBox", {
				Position = UDim2.fromOffset(x, 0), Size = UDim2.fromOffset(w, 28), BackgroundColor3 = T.Colors.Surface, BorderSizePixel = 0,
				Text = "", PlaceholderText = "", TextColor3 = T.Colors.Text, Font = Enum.Font.GothamMedium, TextSize = 12,
				ClearTextOnFocus = false, Parent = row,
			})
			Util.Corner(box, 6)
			local stroke = Util.Stroke(box, T.Colors.Stroke, 1, 0.5)
			box.Focused:Connect(function() Tween(stroke, { Color = T.Colors.Accent, Transparency = 0 }) end)
			box.FocusLost:Connect(function() Tween(stroke, { Color = T.Colors.Stroke, Transparency = 0.5 }) end)
			Create("TextLabel", {
				Position = UDim2.fromOffset(x, 32), Size = UDim2.fromOffset(w, 14), BackgroundTransparency = 1, Text = caption,
				Font = Enum.Font.GothamMedium, TextSize = 12, TextColor3 = T.Colors.SubText, Parent = row,
			})
			return box
		end
		hexBox, rBox, gBox, bBox = field(0, 76, "#"), field(82, 52, "R"), field(140, 52, "G"), field(198, 52, "B")

		hexBox.FocusLost:Connect(function()
			local c = parseHex(hexBox.Text)
			if c then setColor(c); commit() else refresh() end
		end)
		local function channel(box, index)
			box.FocusLost:Connect(function()
				local n = tonumber(box.Text)
				if not n then refresh() return end
				local r, g, b = to255(Color3.fromHSV(h, s, v))
				local ch = { r, g, b }
				ch[index] = math.clamp(math.floor(n + 0.5), 0, 255)
				setColor(Color3.fromRGB(ch[1], ch[2], ch[3]))
				commit()
			end)
		end
		channel(rBox, 1)
		channel(gBox, 2)
		channel(bBox, 3)

		-- Dragging: pressing on the ring picks the hue, pressing on the disc picks saturation / brightness
		local mode = nil -- "hue" | "sv" | "alpha"
		local function update(p)
			if mode == "alpha" then
				alpha = math.clamp((p.X - alphaHolder.AbsolutePosition.X) / math.max(alphaHolder.AbsoluteSize.X, 1), 0, 1)
			else
				local scale = holder.AbsoluteSize.X / D
				if scale <= 0 then return end
				local d = (p - (holder.AbsolutePosition + holder.AbsoluteSize / 2)) / scale -- offset from the centre, in design pixels
				if mode == "hue" then
					h = (-math.atan2(d.Y, d.X) / (2 * math.pi)) % 1
				elseif mode == "sv" then
					local nx, ny = d.X / (DISC_R * 2) + 0.5, d.Y / (DISC_R * 2) + 0.5
					local ox, oy = nx - 0.5, ny - 0.5
					local mag = math.sqrt(ox * ox + oy * oy)
					if mag > 0.5 then nx, ny = 0.5 + ox / mag * 0.5, 0.5 + oy / mag * 0.5 end
					s = math.clamp((nx - T0) / RANGE, 0, 1)
					v = 1 - math.clamp((ny - T0) / RANGE, 0, 1)
				end
			end
			commit()
		end

		ringHit.InputBegan:Connect(function(i)
			if not isPress(i) then return end
			local p = pointerPos(i)
			local scale = holder.AbsoluteSize.X / D
			if scale <= 0 then return end
			local dist = ((p - (holder.AbsolutePosition + holder.AbsoluteSize / 2)) / scale).Magnitude
			if dist >= R_IN - 4 and dist <= R_OUT + 6 then
				mode = "hue"
			elseif dist <= DISC_R + 8 then
				mode = "sv"
			else
				return
			end
			update(p)
		end)
		if alphaHit then
			alphaHit.InputBegan:Connect(function(i)
				if isPress(i) then mode = "alpha"; update(pointerPos(i)) end
			end)
		end
		m:Give(UserInputService.InputChanged:Connect(function(i)
			if mode and isMove(i) then update(pointerPos(i)) end
		end))
		m:Give(UserInputService.InputEnded:Connect(function(i)
			if mode and isPress(i) then mode = nil end
		end))
	end

	local open = false
	local function setOpen(state)
		open = state
		if state then build(); refresh() end
		Tween(root, { Size = UDim2.new(1, 0, 0, state and openH or 38) }, 0.2)
		Tween(arrow, { Rotation = state and 270 or 90 }, 0.2)
	end
	head.MouseButton1Click:Connect(function() setOpen(not open) end)

	-- Set(Color3 | "#RRGGBB", silent?)   SetAlpha(0..1, silent?)   Open(bool?)
	function el:Set(value, silent)
		local c = typeof(value) == "Color3" and value or parseHex(value)
		if not c then return end
		setColor(c)
		refresh()
		if not silent then fire() end
	end
	function el:SetAlpha(a, silent)
		alpha = math.clamp(tonumber(a) or 1, 0, 1)
		refresh()
		if not silent then fire() end
	end
	function el:Open(state) setOpen(state ~= false) end

	refresh()
	if o.Open == true then setOpen(true) end
	return Finish(ctx, o, el, root, m)
end

----------------------------------------------------------------------- Mixin
local Components = { Builders = B, Methods = {} }

for name, builder in pairs({
	Label = B.Label, Button = B.Button, Toggle = B.Toggle, Slider = B.Slider,
	Keybind = B.Keybind, Input = B.Input, Dropdown = B.Dropdown, ColorPicker = B.ColorPicker,
}) do
	Components.Methods["Add" .. name] = function(self, opts)
		return builder(self.Frame, opts or {}, self.Ctx)
	end
end

function Components.Extend(class)
	for k, v in pairs(Components.Methods) do class[k] = v end
end

return Components
