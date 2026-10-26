-- Loader: animated loading card, then an optional language picker.
-- Nexus:Load(options) yields until the user presses Continue and returns the chosen language.
local import = ...
local Util = import("Util")
local Maid = import("Maid")
local Theme = import("Theme")
local Components = import("Components")
local TweenService = game:GetService("TweenService")
local Create, Tween = Util.Create, Util.Tween

local CARD_W = 380
local LOAD_H = 232 -- card height while loading
local LANG_H = 282 -- card height on the language step (grows while the dropdown is open)
local GROUP_Y = 150

local Loader = {}
Loader.__index = Loader

--[[ options:
	Name             string    title                         (default "NEXUS")
	Subtitle         string    small accent text under the title
	Icon             string    "rbxassetid://..." or https URL to the logo
	Accent           Color3    accent colour
	Theme            table     palette overrides
	Steps            {string}  status lines shown while the bar fills
	Duration         number    seconds for the whole bar     (default 3)
	ReadyText        string    shown when the bar is full    (default "Ready")
	Languages        {string}  languages to choose from; omit to skip the language step
	DefaultLanguage  string    preselected language          (default: first one)
	LanguageTitle    string    heading above the dropdown    (default "Select language")
	LanguageLabel    string    label inside the dropdown     (default "Language")
	ContinueText     string    button text                   (default "Continue")
]]
function Loader.new(options)
	local self = setmetatable({}, Loader)
	self.Maid = Maid.new()
	self.Options = options
	self._phase = "loading"

	local overrides = options.Theme or {}
	if options.Accent then overrides.Accent = options.Accent end
	local T = Theme.new(overrides)
	self.Theme = T

	local languages = options.Languages
	local hasLanguages = type(languages) == "table" and #languages > 0
	self._defaultLanguage = hasLanguages and (options.DefaultLanguage or languages[1]) or nil

	local gui = Create("ScreenGui", {
		Name = "NexusLoader", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1000, IgnoreGuiInset = true,
	})
	Util.MountGui(gui)
	self.Gui = self.Maid:Give(gui)

	-- Dim backdrop (also swallows clicks while the loader is up)
	self._backdrop = Create("Frame", {
		Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
		BorderSizePixel = 0, Active = true, Parent = gui,
	})

	local card = Create("Frame", {
		Name = "Card", AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.5, -150), Size = UDim2.fromOffset(CARD_W, LOAD_H),
		BackgroundColor3 = T.Colors.Background, BackgroundTransparency = T.Transparency, BorderSizePixel = 0,
		ClipsDescendants = true, Parent = gui,
	})
	self._card = card
	self._scale = Create("UIScale", { Scale = 0.9, Parent = card })
	Util.Corner(card, 12)
	T:Bind(Util.Stroke(card, T.Colors.Accent, 1.5, 0.35), "Color", "Accent")
	Create("UIGradient", {
		Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(175, 195, 220)), Parent = card,
	})

	-- Logo (gentle pulse) + title
	local logo = Create("ImageLabel", {
		AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 18), Size = UDim2.fromOffset(60, 60),
		BackgroundTransparency = 1, Image = Util.GetAsset(options.Icon), ScaleType = Enum.ScaleType.Fit, Parent = card,
	})
	local logoScale = Create("UIScale", { Scale = 1, Parent = logo })
	local pulse = TweenService:Create(
		logoScale, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = 1.1 }
	)
	pulse:Play()
	self.Maid:Give(function() pulse:Cancel() end)

	Create("TextLabel", {
		Position = UDim2.fromOffset(0, 84), Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, Text = options.Name or "NEXUS",
		Font = Enum.Font.GothamBold, TextSize = 26, TextColor3 = T.Colors.Text, Parent = card,
	})
	local sub = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 114), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = options.Subtitle or "",
		Font = Enum.Font.GothamMedium, TextSize = 12, Parent = card,
	})
	T:Bind(sub, "TextColor3", "Accent")

	-- Loading group: status line, progress bar, percentage
	local loadGroup = Create("Frame", {
		Position = UDim2.fromOffset(20, GROUP_Y), Size = UDim2.new(1, -40, 0, 70), BackgroundTransparency = 1, Parent = card,
	})
	self._loadGroup = loadGroup
	self._statusLbl = Create("TextLabel", {
		Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamMedium, TextSize = 13,
		TextColor3 = T.Colors.SubText, Parent = loadGroup,
	})
	local track = Create("Frame", {
		Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = T.Colors.Surface,
		BorderSizePixel = 0, Parent = loadGroup,
	})
	Util.Corner(track, 3)
	local fill = Create("Frame", { Size = UDim2.fromScale(0, 1), BorderSizePixel = 0, Parent = track })
	Util.Corner(fill, 3)
	T:Bind(fill, "BackgroundColor3", "Accent")
	self._fill = fill
	local pct = Create("TextLabel", {
		Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "0%",
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Colors.Accent2, Parent = loadGroup,
	})
	self.Maid:Give(fill:GetPropertyChangedSignal("Size"):Connect(function()
		pct.Text = math.floor(fill.Size.X.Scale * 100 + 0.5) .. "%"
	end))

	-- Language group (hidden until the bar is full)
	if hasLanguages then
		local ctx = { Theme = T, Maid = self.Maid, Flags = {}, Window = self }
		local langGroup = Create("Frame", {
			Position = UDim2.fromOffset(20, GROUP_Y), Size = UDim2.new(1, -40, 0, 130), BackgroundTransparency = 1,
			Visible = false, Parent = card,
		})
		self._langGroup = langGroup
		Create("TextLabel", {
			Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, Text = string.upper(options.LanguageTitle or "Select language"),
			Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = T.Colors.Accent2, TextXAlignment = Enum.TextXAlignment.Left,
			Parent = langGroup,
		})

		local selected = self._defaultLanguage
		local cont = Components.Builders.Button(langGroup, {
			Name = options.ContinueText or "Continue",
			Callback = function() self:_finish(selected) end,
		}, ctx)
		cont.Frame.Position = UDim2.fromOffset(0, 76)

		local dd = Components.Builders.Dropdown(langGroup, {
			Name = options.LanguageLabel or "Language", Options = languages, Default = self._defaultLanguage,
			Callback = function(v) selected = v end,
		}, ctx)
		dd.Frame.Position = UDim2.fromOffset(0, 24)

		-- The dropdown grows downwards when opened: push the button and the card along with it.
		self.Maid:Give(dd.Frame:GetPropertyChangedSignal("Size"):Connect(function()
			if self._phase ~= "lang" then return end
			local extra = math.max(0, dd.Frame.Size.Y.Offset - 38)
			cont.Frame.Position = UDim2.fromOffset(0, 76 + extra)
			card.Size = UDim2.fromOffset(CARD_W, LANG_H + extra)
		end))
	end

	return self
end

function Loader:_resume(value)
	if self._resumed then return end
	self._resumed = true
	if self._thread then task.spawn(self._thread, value) end
end

-- Fade out, then clean up and hand the chosen language back to the caller of Run().
function Loader:_finish(language)
	if self._finished then return end
	self._finished = true
	self._result = language
	Tween(self._scale, { Scale = 0.9 }, 0.2)
	Tween(self._backdrop, { BackgroundTransparency = 1 }, 0.25)
	task.delay(0.28, function() self:Destroy() end)
end

function Loader:_sequence()
	local o = self.Options
	Tween(self._scale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	Tween(self._backdrop, { BackgroundTransparency = 0.45 }, 0.35)
	task.wait(0.4)

	local steps = (type(o.Steps) == "table" and #o.Steps > 0) and o.Steps or { "Initializing", "Loading modules", "Preparing interface" }
	local per = math.max(0.1, (o.Duration or 3) / #steps)
	for i, text in ipairs(steps) do
		if self._destroyed then return end
		self._status = text
		Tween(self._fill, { Size = UDim2.fromScale(i / #steps, 1) }, per * 0.85)
		task.wait(per)
	end
	if self._destroyed then return end

	self._status = nil
	self._statusLbl.Text = o.ReadyText or "Ready"
	task.wait(0.4)
	if self._destroyed then return end

	if not self._langGroup then
		self._result = nil
		return self:_finish(nil)
	end

	self._phase = "lang"
	self._loadGroup.Visible = false
	self._langGroup.Position = UDim2.fromOffset(20, GROUP_Y + 14)
	self._langGroup.Visible = true
	Tween(self._langGroup, { Position = UDim2.fromOffset(20, GROUP_Y) }, 0.3)
	Tween(self._card, { Size = UDim2.fromOffset(CARD_W, LANG_H) }, 0.3)
end

-- Animated "..." after the current status line.
function Loader:_animateStatus()
	local dots = 0
	while not self._destroyed and self._phase == "loading" do
		if self._status then
			dots = dots % 3 + 1
			self._statusLbl.Text = self._status .. string.rep(".", dots)
		end
		task.wait(0.3)
	end
end

-- Shows the loader and yields until it is finished. Returns the chosen language (or nil if closed early).
function Loader:Run()
	self._thread = coroutine.running()
	task.spawn(function()
		local ok, err = pcall(self._sequence, self)
		if not ok and not self._destroyed then
			warn("[Nexus] loader error: " .. tostring(err))
			self._result = self._defaultLanguage -- fall back so the hub can still open
			self:Destroy()
		end
	end)
	task.spawn(function() self:_animateStatus() end)
	return coroutine.yield()
end

function Loader:Destroy()
	if self._destroyed then return end
	self._destroyed = true
	self.Maid:Clean()
	self.Theme:Destroy()
	if self._onDestroy then self._onDestroy() end
	self:_resume(self._result)
end

return Loader
