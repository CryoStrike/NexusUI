--[[
	NEXUS UI  -  hub.lua      (the UI of the hub: categories, buttons, sliders, ...)

	This is the file to edit when you want to change what the hub contains.
	It is loaded by init.lua, which gives it three things:
		Nexus     the library (Library.lua)
		Language  the texts   (language.lua)
		Config    shared settings from init.lua  { Repo, Name, Subtitle, Icon }

	HOW TO EDIT
		Add a button / slider / toggle ...  open that category's function below (buildCombat, buildFarm ...)
		                                    and add a  tab:AddButton({ ... })  line. See NEXUS_GUIDE.txt.
		Add a category ..................... 1. write a  local function buildMyCategory(tab) ... end
		                                     2. add one line for it in the CATEGORIES list
		                                     3. add its name to language.lua:  tab_mycategory = "My Category"
		Remove / reorder a category ........ delete or move its line in the CATEGORIES list
		Change a category icon ............. the  icon  field in CATEGORIES (a file name from assets/icons/)
		Change window size, resizing ....... the CreateWindow options in Hub.Build (bottom of this file)
		Change a visible text .............. language.lua  (every text is  tr("key"))

	The controls only print their value: put your real code inside each  Callback = function(...) ... end
]]

local Nexus, Language, Config = ...
local tr = Language.tr

local lp = game:GetService("Players").LocalPlayer

local Hub = {}

--------------------------------------------------------------- Settings
local DEMO_KEY = "NEXUS-DEMO" -- demo only: replace with your own key check

local ACCENTS = {
	Cyan = Color3.fromRGB(0, 170, 255), Violet = Color3.fromRGB(150, 110, 255),
	Emerald = Color3.fromRGB(40, 210, 140), Crimson = Color3.fromRGB(255, 80, 100), Gold = Color3.fromRGB(230, 190, 100),
}
Hub.Accent = ACCENTS.Cyan -- accent used by the loading screen (init.lua) and by the first hub

-- Kept across rebuilds (a language change rebuilds the hub, and must not reset these)
local state = {
	toggleKey = Enum.KeyCode.RightShift,
	accentName = "Cyan",
	customAccent = nil, -- set when the colour picker is used
}

local Window -- the current hub window

--------------------------------------------------------------- Tab icons
-- White PNGs in assets/icons/ (NEXUS tints them: grey, or the accent colour when selected).
-- Downloading them needs writefile + isfile + getcustomasset. Without those the tabs are text-only.
-- To use Roblox images instead, make icon() return "rbxassetid://<image id>".
local CAN_ICON = writefile ~= nil and isfile ~= nil and getcustomasset ~= nil
if not CAN_ICON then
	warn("[NEXUS] this executor lacks writefile/isfile/getcustomasset: tab icons are off (use rbxassetid:// icons instead).")
end
local function icon(name)
	if CAN_ICON and name then return Config.Repo .. "assets/icons/" .. name .. ".png" end
	return nil
end

--------------------------------------------------------------- Helpers
local function notify(title, content, kind)
	if Window then Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3 }) end
end

--==============================================================================
--  CATEGORIES   (one function per category; `tab` is where you add components)
--==============================================================================

---------------------------------------------------------------- Combat
local function buildCombat(tab)
	tab:AddToggle({
		Name = tr("combat_module"), Default = false, Flag = "combat_module",
		Callback = function(on) print("Combat module:", on) end,
	})
	tab:AddSlider({
		Name = tr("range"), Min = 0, Max = 1000, Default = 250, Increment = 1, Suffix = " / 1000", Flag = "combat_range",
		Callback = function(v) print("Range:", v) end,
	})
	tab:AddDropdown({
		Name = tr("priority"), Options = { "Nearest", "Lowest Health", "Random" }, Default = "Nearest", Flag = "combat_priority",
		Callback = function(v) print("Target priority:", v) end,
	})
	tab:AddKeybind({
		Name = tr("combat_key"), Default = Enum.KeyCode.R, Flag = "combat_key",
		Callback = function(key) print("Combat key pressed:", key.Name) end,
	})
end

---------------------------------------------------------------- Character
local function buildCharacter(tab)
	tab:AddSlider({
		Name = tr("walk_speed"), Min = 16, Max = 100, Default = 16, Increment = 1, Flag = "walk_speed",
		Callback = function(v) print("Walk speed:", v) end,
	})
	tab:AddSlider({
		Name = tr("jump_power"), Min = 50, Max = 200, Default = 50, Increment = 1, Flag = "jump_power",
		Callback = function(v) print("Jump power:", v) end,
	})
	tab:AddToggle({
		Name = tr("anti_afk"), Default = true, Flag = "anti_afk",
		Callback = function(on) print("Anti-AFK:", on) end,
	})
	tab:AddButton({
		Name = tr("reset_char"),
		Callback = function() notify(tr("tab_character"), tr("pressed")) end,
	})
end

---------------------------------------------------------------- Farm
local function buildFarm(tab)
	tab:AddToggle({
		Name = tr("farm_toggle"), Default = false, Flag = "farm_toggle",
		Callback = function(on) print("Auto farm:", on) end,
	})
	tab:AddDropdown({
		Name = tr("farm_mode"), Options = { "Nearest", "Selected" }, Default = "Nearest", Flag = "farm_mode",
		Callback = function(v) print("Farm mode:", v) end,
	})
	tab:AddSlider({
		Name = tr("farm_delay"), Min = 0, Max = 10, Default = 1, Increment = 1, Suffix = " s", Flag = "farm_delay",
		Callback = function(v) print("Farm delay:", v) end,
	})
	tab:AddInput({
		Name = tr("target_name"), Placeholder = tr("target_ph"), Flag = "farm_target",
		Callback = function(text, enter) if enter then print("Target:", text) end end,
	})
end

---------------------------------------------------------------- Troll
local function buildTroll(tab)
	tab:AddToggle({
		Name = tr("troll_module"), Default = false, Flag = "troll_module",
		Callback = function(on) print("Troll module:", on) end,
	})
	tab:AddDropdown({
		Name = tr("effect"), Options = { "Spin", "Bounce", "Shake" }, Default = "Spin", Flag = "troll_effect",
		Callback = function(v) print("Effect:", v) end,
	})
	tab:AddSlider({
		Name = tr("intensity"), Min = 1, Max = 10, Default = 3, Increment = 1, Flag = "troll_intensity",
		Callback = function(v) print("Intensity:", v) end,
	})
	tab:AddButton({
		Name = tr("run_effect"),
		Callback = function() notify(tr("tab_troll"), tr("pressed"), "Success") end,
	})
	tab:AddButton({
		Name = tr("stop_all"),
		Callback = function() notify(tr("tab_troll"), tr("pressed"), "Warning") end,
	})
end

---------------------------------------------------------------- Visuals
local function buildVisuals(tab)
	local display = tab:AddSection(tr("sec_display"))
	display:AddToggle({
		Name = tr("highlight"), Default = false, Flag = "highlight",
		Callback = function(on) print("Highlight:", on) end,
	})
	display:AddSlider({
		Name = tr("fov"), Min = 40, Max = 120, Default = 70, Increment = 1, Suffix = "°", Flag = "fov",
		Callback = function(v) print("FOV:", v) end,
	})
	display:AddColorPicker({
		Name = tr("highlight_color"), Default = Color3.fromRGB(152, 35, 205), Alpha = true, Flag = "highlight_color",
		Callback = function(color, alpha) print("Highlight colour:", color, "alpha:", alpha) end,
	})
	display:AddDropdown({
		Name = tr("style"), Options = { "Balanced", "Performance", "Quality" }, Default = "Balanced",
		Callback = function(v) print("Style:", v) end,
	})

	local theming = tab:AddSection(tr("sec_theme"))
	theming:AddDropdown({
		Name = tr("accent"), Options = { "Cyan", "Violet", "Emerald", "Crimson", "Gold" }, Default = state.accentName,
		Callback = function(name)
			state.accentName = name
			state.customAccent = nil
			Window:SetAccent(ACCENTS[name])
		end,
	})
	theming:AddColorPicker({
		Name = tr("custom_accent"), Default = state.customAccent or ACCENTS[state.accentName],
		Callback = function(color)
			state.customAccent = color
			Window:SetAccent(color)
		end,
	})
end

---------------------------------------------------------------- Settings
local function buildSettings(tab)
	local interface = tab:AddSection(tr("sec_interface"))
	interface:AddKeybind({
		Name = tr("hide_key"), Default = state.toggleKey,
		OnChanged = function(key)
			if key then
				state.toggleKey = key
				Window:SetToggleKey(key)
			end
		end,
	})
	interface:AddButton({ Name = tr("minimize"), Callback = function() Window:Minimize() end })
	interface:AddDropdown({
		Name = tr("language"), Options = Language.List, Default = Language.Current,
		Callback = function(lang)
			if lang == Language.Current then return end
			if Language.set(lang) then
				task.defer(Hub.Rebuild) -- rebuild the hub in the new language
			end
		end,
	})
	interface:AddLabel({ Text = tr("resize_hint") })
	interface:AddButton({ Name = tr("unload"), Callback = function() Nexus:Destroy() end })

	local keySystem = tab:AddSection(tr("sec_keysystem"))
	keySystem:AddInput({ Name = tr("license_key"), Placeholder = tr("license_ph"), Flag = "license_key" })
	keySystem:AddButton({
		Name = tr("key_system"),
		Callback = function()
			local key = Window.Flags.license_key and Window.Flags.license_key.Value or ""
			if key == DEMO_KEY then
				notify(tr("key_system"), tr("key_ok"), "Success")
			elseif key == "" then
				notify(tr("key_system"), tr("key_empty"), "Warning")
			else
				notify(tr("key_system"), tr("key_bad"), "Error")
			end
		end,
	})
end

---------------------------------------------------------------- About
local function buildAbout(tab)
	local info = tab:AddSection(tr("about_title"))
	info:AddLabel({ Text = tr("about_version", tostring(Nexus.Version)) })
	info:AddLabel({ Text = tr("about_signed", lp.DisplayName, lp.Name) })
	info:AddLabel({ Text = "github.com/CryoStrike/NexusUI" })
end

--==============================================================================
--  CATEGORY LIST   (sidebar order, top to bottom)
--      name   key in language.lua for the category name
--      icon   file name in assets/icons/ (without .png), or nil for text only
--      build  the function above that fills the category
--==============================================================================
local CATEGORIES = {
	{ name = "tab_combat",    icon = "combat",    build = buildCombat },
	{ name = "tab_character", icon = "character", build = buildCharacter },
	{ name = "tab_farm",      icon = "farm",      build = buildFarm },
	{ name = "tab_troll",     icon = "troll",     build = buildTroll },
	{ name = "tab_visuals",   icon = "visuals",   build = buildVisuals },
	{ name = "tab_settings",  icon = "settings",  build = buildSettings },
	{ name = "tab_about",     icon = "about",     build = buildAbout },
}

--==============================================================================
--  BUILD
--==============================================================================
function Hub.Build(rebuilt)
	Window = Nexus:CreateWindow({
		Name = Config.Name,
		Subtitle = Config.Subtitle,
		Icon = Config.Icon, -- or "rbxassetid://<uploaded logo id>"
		Accent = state.customAccent or ACCENTS[state.accentName],
		ToggleKey = state.toggleKey,
		Size = UDim2.fromOffset(700, 500),
		Resizable = true,
		MinSize = Vector2.new(560, 360),
	})

	for _, category in ipairs(CATEGORIES) do
		local tab = Window:CreateTab(tr(category.name), icon(category.icon))
		category.build(tab)
	end

	if rebuilt then
		notify(tr("loaded_title"), tr("lang_set", Language.Current), "Success")
	else
		notify(tr("loaded_title"), tr("loaded_text", state.toggleKey.Name), "Success")
	end
end

-- Destroy the hub and build it again (used when the language changes)
function Hub.Rebuild()
	if Window then Window:Destroy() end
	Hub.Build(true)
end

return Hub
