-- Theme: colour palette + listeners so the accent can change live.
local TweenService = game:GetService("TweenService")

local Theme = {}
Theme.__index = Theme

Theme.Defaults = {
	Background = Color3.fromRGB(8, 16, 28),
	Surface    = Color3.fromRGB(14, 26, 44),
	Surface2   = Color3.fromRGB(22, 40, 66),
	Stroke     = Color3.fromRGB(45, 95, 145),
	Text       = Color3.fromRGB(228, 238, 250),
	SubText    = Color3.fromRGB(125, 150, 182),
	Accent     = Color3.fromRGB(0, 170, 255),   -- electric blue
	Accent2    = Color3.fromRGB(230, 190, 100), -- gold (from the logo)
	Success    = Color3.fromRGB(80, 220, 140),
	Warning    = Color3.fromRGB(240, 190, 80),
	Danger     = Color3.fromRGB(255, 90, 100),
}

function Theme.new(overrides)
	local self = setmetatable({ Colors = {}, Transparency = 0.12, _listeners = {} }, Theme)
	for k, v in pairs(Theme.Defaults) do self.Colors[k] = v end
	for k, v in pairs(overrides or {}) do
		if typeof(v) == "Color3" then self.Colors[k] = v end
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
