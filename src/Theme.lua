-- Theme: colour palette + fonts + listeners so the accent can change live.
local TweenService = game:GetService("TweenService")

local Theme = {}
Theme.__index = Theme

-- Neon cyan on dark glass (matches the Translucid reference look).
Theme.Defaults = {
	Background = Color3.fromRGB(6, 15, 24),
	Surface    = Color3.fromRGB(10, 28, 42),
	Surface2   = Color3.fromRGB(13, 38, 54),
	Stroke     = Color3.fromRGB(28, 100, 128),
	Text       = Color3.fromRGB(228, 246, 255),
	SubText    = Color3.fromRGB(125, 170, 190),
	Accent     = Color3.fromRGB(0, 224, 255),    -- neon cyan
	Accent2    = Color3.fromRGB(120, 236, 255),  -- light cyan (secondary highlights)
	Success    = Color3.fromRGB(70, 235, 150),
	Warning    = Color3.fromRGB(255, 205, 90),
	Danger     = Color3.fromRGB(255, 95, 110),
}

-- Fonts, with a safe fallback if this Roblox version does not know the font.
--   Title : tab names, section pills, buttons, window title      (techy, squared)
--   Text  : labels, values, body text                            (clean, slightly condensed)
local function pick(name, fallback)
	local ok, font = pcall(function() return Enum.Font[name] end)
	return (ok and font) or fallback
end
Theme.DefaultFonts = {
	Title = pick("Sarpanch", Enum.Font.GothamBold),
	Text = pick("TitilliumWeb", Enum.Font.GothamMedium),
}

-- overrides: { Background = Color3, ..., Fonts = { Title = Enum.Font.X, Text = Enum.Font.Y } }
function Theme.new(overrides)
	local self = setmetatable({ Colors = {}, Fonts = {}, Transparency = 0.18, _listeners = {} }, Theme)
	for k, v in pairs(Theme.Defaults) do self.Colors[k] = v end
	for k, v in pairs(Theme.DefaultFonts) do self.Fonts[k] = v end
	for k, v in pairs(overrides or {}) do
		if typeof(v) == "Color3" then
			self.Colors[k] = v
		elseif k == "Fonts" and type(v) == "table" then
			for fontKey, font in pairs(v) do
				if typeof(font) == "EnumItem" then self.Fonts[fontKey] = font end
			end
		end
	end
	return self
end

-- Calls fn(newColor) whenever `key` changes. Returns a destroyable entry.
function Theme:Listen(key, fn)
	local entry = { Key = key, Fn = fn }
	function entry.Destroy()
		local i = table.find(self._listeners, entry)
		if i then table.remove(self._listeners, i) end
	end
	table.insert(self._listeners, entry)
	return entry
end

-- Sets inst[prop] to the colour now and keeps it in sync.
function Theme:Bind(inst, prop, key)
	inst[prop] = self.Colors[key]
	return self:Listen(key, function(color)
		TweenService:Create(inst, TweenInfo.new(0.25), { [prop] = color }):Play()
	end)
end

function Theme:Set(key, color)
	self.Colors[key] = color
	for _, entry in ipairs(table.clone(self._listeners)) do
		if entry.Key == key then
			local ok, err = pcall(entry.Fn, color)
			if not ok then warn("[Nexus] theme listener error: " .. tostring(err)) end
		end
	end
end

function Theme:Destroy()
	table.clear(self._listeners)
end

return Theme
