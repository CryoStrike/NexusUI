--[[
	NEXUS UI  -  init.lua      (the LAUNCHER: run this one)

		loadstring(game:HttpGet("https://raw.githubusercontent.com/CryoStrike/NexusUI/main/init.lua"))()

	What it does, in order:
		1. Library.lua   loads the UI library (also removes a previous NEXUS if you run the script twice)
		2. language.lua  loads the texts + languages                 -> edit it to translate / add a language
		3. hub.lua       loads the hub UI (categories, buttons ...)  -> edit it to change the hub
		4. shows the loading screen + language picker, then opens the hub

	Dev options (set BEFORE running):
		getgenv().NEXUS_BASE  = "https://raw.githubusercontent.com/<user>/<repo>/<branch>/"   -- test another branch / fork
		getgenv().NEXUS_LOCAL = true   -- read every script from <workspace>/NexusUI/ instead of GitHub
]]

local env = (getgenv and getgenv()) or _G
local BASE = env.NEXUS_BASE or "https://raw.githubusercontent.com/CryoStrike/NexusUI/main/"
local LOCAL = env.NEXUS_LOCAL == true

-- Settings shared with hub.lua (and used by the loading screen below)
local Config = {
	Repo = BASE,
	Name = "NEXUS",
	Subtitle = "TRANSLUCID THEME",
	Icon = BASE .. "assets/nexus-ico.png", -- or "rbxassetid://<uploaded logo id>"
}

-- Download (or read, in local mode) one script, run it and return what it returns.
-- Extra arguments are handed to the script as `...`.
local function run(path, ...)
	local ok, source
	if LOCAL then
		ok, source = pcall(readfile, "NexusUI/" .. path)
	else
		ok, source = pcall(function() return game:HttpGet(BASE .. path) end)
	end
	assert(ok and type(source) == "string", "[Nexus] failed to fetch '" .. path .. "'")

	local fn, err = loadstring(source, "=Nexus/" .. path)
	assert(fn, "[Nexus] syntax error in '" .. path .. "': " .. tostring(err))
	return fn(...)
end

local Nexus    = run("Library.lua")
local Language = run("language.lua")
local Hub      = run("hub.lua", Nexus, Language, Config)

-- Tell the developer about untranslated texts (nothing breaks, English is shown instead)
for _, problem in ipairs(Language.Validate()) do
	warn("[Nexus] language: " .. problem)
end

-- Loading animation, then the language picker. Yields until the user presses Continue.
local chosen = Nexus:Load({
	Name = Config.Name,
	Subtitle = Config.Subtitle,
	Icon = Config.Icon,
	Accent = Hub.Accent,
	Steps = { "Initializing", "Loading modules", "Preparing interface" },
	Duration = 3,
	Languages = Language.List,
	DefaultLanguage = Language.Default,
	LanguageTitle = "Select language",
	ContinueText = "Continue",
})
if not chosen then return end -- loader was closed (e.g. the script was re-executed)

Language.set(chosen)
Hub.Build()
