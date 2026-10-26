--[[
	NEXUS UI - Translucid Theme showcase hub
	Tabs: Features / Visuals / Settings / About

	Usage:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/CryoStrike/NexusUI/main/examples/translucid_hub.lua"))()
]]

local REPO = "https://raw.githubusercontent.com/CryoStrike/NexusUI/main/"
local Nexus = loadstring(game:HttpGet(REPO .. "init.lua"))()

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local DEMO_KEY = "NEXUS-DEMO" -- demo only: replace with your own key check

local Window = Nexus:CreateWindow({
	Name = "NEXUS",
	Subtitle = "TRANSLUCID THEME",
	Icon = REPO .. "assets/nexus-ico.png", -- or "rbxassetid://<uploaded logo id>"
	Accent = Color3.fromRGB(0, 170, 255),
	ToggleKey = Enum.KeyCode.RightShift,
	Size = UDim2.fromOffset(640, 430),
})

local function notify(title, content, kind)
	Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3 })
end

--------------------------------------------------------------- Features
local Features = Window:CreateTab("Features")

Features:AddToggle({
	Name = "Toggle", Default = false, Flag = "toggle_1",
	Callback = function(on) print("Toggle:", on) end,
})
Features:AddToggle({
	Name = "Toggle 2", Default = true, Flag = "toggle_2",
	Callback = function(on) print("Toggle 2:", on) end,
})
Features:AddSlider({
	Name = "Slider", Min = 0, Max = 1000, Default = 1, Increment = 1, Suffix = " / 1000", Flag = "slider_1",
	Callback = function(v) print("Slider:", v) end,
})
Features:AddButton({
	Name = "Action",
	Callback = function() notify("Action", "First action triggered.", "Success") end,
})
Features:AddButton({
	Name = "Action 2",
	Callback = function() notify("Action", "Second action triggered.", "Info") end,
})
Features:AddInput({
	Name = "Text Input", Placeholder = "Text Input", Flag = "text_input",
	Callback = function(text, enter)
		if enter and text ~= "" then notify("Text Input", "You typed: " .. text) end
	end,
})
Features:AddKeybind({
	Name = "Keybind", Default = Enum.KeyCode.E, Flag = "keybind_1",
	Callback = function(key) notify("Keybind", key.Name .. " pressed.") end,
	OnChanged = function(key) print("Keybind set to:", key and key.Name or "None") end,
})

--------------------------------------------------------------- Visuals
local Visuals = Window:CreateTab("Visuals")

local Display = Visuals:AddSection("Display")
Display:AddToggle({ Name = "Highlight", Default = false, Flag = "highlight", Callback = function(on) print("Highlight:", on) end })
Display:AddSlider({
	Name = "Field of View", Min = 40, Max = 120, Default = 70, Increment = 1, Suffix = "°", Flag = "fov",
	Callback = function(v) print("FOV:", v) end,
})
Display:AddDropdown({
	Name = "Style", Options = { "Balanced", "Performance", "Quality" }, Default = "Balanced",
	Callback = function(v) print("Style:", v) end,
})

local Theming = Visuals:AddSection("Theme")
local accents = {
	Cyan = Color3.fromRGB(0, 170, 255), Violet = Color3.fromRGB(150, 110, 255),
	Emerald = Color3.fromRGB(40, 210, 140), Crimson = Color3.fromRGB(255, 80, 100), Gold = Color3.fromRGB(230, 190, 100),
}
Theming:AddDropdown({
	Name = "Accent Colour", Options = { "Cyan", "Violet", "Emerald", "Crimson", "Gold" }, Default = "Cyan",
	Callback = function(name) Window:SetAccent(accents[name]) end,
})

--------------------------------------------------------------- Settings
local Settings = Window:CreateTab("Settings")

local Interface = Settings:AddSection("Interface")
Interface:AddKeybind({
	Name = "Toggle UI", Default = Enum.KeyCode.RightShift,
	OnChanged = function(key) Window:SetToggleKey(key) end,
})
Interface:AddButton({ Name = "Unload NEXUS", Callback = function() Nexus:Destroy() end })

local KeySystem = Settings:AddSection("Key System")
KeySystem:AddInput({ Name = "License Key", Placeholder = "Enter your key...", Flag = "license_key" })
KeySystem:AddButton({
	Name = "Key System",
	Callback = function()
		local key = Window.Flags.license_key and Window.Flags.license_key.Value or ""
		if key == DEMO_KEY then
			notify("Key System", "Key accepted.", "Success")
		elseif key == "" then
			notify("Key System", "Enter a key first.", "Warning")
		else
			notify("Key System", "Invalid key.", "Error")
		end
	end,
})

--------------------------------------------------------------- About
local About = Window:CreateTab("About")

local Info = About:AddSection("NEXUS UI")
Info:AddLabel({ Text = "Translucid Theme  -  v" .. tostring(Nexus.Version) })
Info:AddLabel({ Text = "Signed in as " .. lp.DisplayName .. " (@" .. lp.Name .. ")" })
Info:AddLabel({ Text = "github.com/CryoStrike/NexusUI" })

notify("NEXUS loaded", "Press RightShift to hide or show.", "Success")
