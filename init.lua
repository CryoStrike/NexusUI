--[[
	NEXUS UI  -  Translucid Theme
	Loader / entry point.

	Usage:
		local Nexus = loadstring(game:HttpGet("https://raw.githubusercontent.com/CryoStrike/NexusUI/main/init.lua"))()

	Dev options (set BEFORE loading):
		getgenv().NEXUS_BASE  = "https://raw.githubusercontent.com/<user>/<repo>/<branch>/"
		getgenv().NEXUS_LOCAL = true   -- read modules from <workspace>/NexusUI/src/*.lua
]]

local env = (getgenv and getgenv()) or _G

local BASE = env.NEXUS_BASE or "https://raw.githubusercontent.com/CryoStrike/NexusUI/main/"
local LOCAL = env.NEXUS_LOCAL == true

-- Remove a previous instance (re-execution safe)
if env.NexusUI then
	pcall(function() env.NexusUI:Destroy() end)
	env.NexusUI = nil
end

local cache = {}

local function import(name)
	if cache[name] ~= nil then return cache[name] end

	local ok, source
	if LOCAL then
		ok, source = pcall(readfile, "NexusUI/src/" .. name .. ".lua")
	else
		ok, source = pcall(function() return game:HttpGet(BASE .. "src/" .. name .. ".lua") end)
	end
	assert(ok and type(source) == "string", "[Nexus] failed to fetch module '" .. name .. "'")

	local fn, err = loadstring(source, "=Nexus/" .. name)
	assert(fn, "[Nexus] syntax error in '" .. name .. "': " .. tostring(err))

	local result = fn(import) -- every module receives `import` as its first vararg
	cache[name] = result
	return result
end

local WindowClass = import("Window")
local LoaderClass = import("Loader")

local Nexus = { Version = "0.2.0", Windows = {}, Loaders = {} }

-- Shows the animated loading screen (optionally with a language picker) and yields until it is done.
-- Returns the chosen language, or nil if the loader was closed early. See src/Loader.lua for the options.
function Nexus:Load(options)
	local loader = LoaderClass.new(options or {})
	table.insert(self.Loaders, loader)
	loader._onDestroy = function()
		local i = table.find(self.Loaders, loader)
		if i then table.remove(self.Loaders, i) end
	end
	return loader:Run()
end

function Nexus:CreateWindow(options)
	local window = WindowClass.new(options or {})
	table.insert(self.Windows, window)
	window._onDestroy = function()
		local i = table.find(self.Windows, window)
		if i then table.remove(self.Windows, i) end
	end
	return window
end

function Nexus:Destroy()
	for i = #self.Loaders, 1, -1 do
		self.Loaders[i]:Destroy()
	end
	table.clear(self.Loaders)
	for i = #self.Windows, 1, -1 do
		self.Windows[i]:Destroy()
	end
	table.clear(self.Windows)
	if env.NexusUI == self then env.NexusUI = nil end
end

env.NexusUI = Nexus
return Nexus
