-- NEXUS example hub: Main / Player / Settings
local REPO = "https://raw.githubusercontent.com/CryoStrike/NexusUI/main/"
local Nexus = loadstring(game:HttpGet(REPO .. "Library.lua"))()

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local Window = Nexus:CreateWindow({
	Name = "NEXUS",
	Subtitle = "TRANSLUCID THEME",
	Icon = REPO .. "assets/nexus-ico.png", -- or "rbxassetid://<uploaded logo id>"
	Accent = Color3.fromRGB(0, 170, 255),
	ToggleKey = Enum.KeyCode.RightShift,
})

--------------------------------------------------------------- Main
local Main = Window:CreateTab("Main")

local Controls = Main:AddSection("Controls")
Controls:AddToggle({
	Name = "Example Toggle", Default = false, Flag = "example_toggle",
	Callback = function(on) print("Toggle:", on) end,
})
Controls:AddSlider({
	Name = "Example Slider", Min = 0, Max = 1000, Default = 250, Increment = 1, Flag = "example_slider",
	Callback = function(v) print("Slider:", v) end,
})
Controls:AddDropdown({
	Name = "Mode", Options = { "Balanced", "Performance", "Quality" }, Default = "Balanced",
	Callback = function(v) print("Mode:", v) end,
})
Controls:AddDropdown({
	Name = "Multi Select", Options = { "Alpha", "Beta", "Gamma", "Delta" }, Default = { "Alpha" }, Multi = true,
	Callback = function(list) print("Selected:", table.concat(list, ", ")) end,
})

local Actions = Main:AddSection("Actions")
Actions:AddButton({
	Name = "Show Notification",
	Callback = function()
		Window:Notify({ Title = "Nexus", Content = "Hello from the Translucid theme!", Duration = 4, Type = "Info" })
	end,
})
Actions:AddInput({
	Name = "Text Input", Placeholder = "Type something...",
	Callback = function(text, enter) print("Input:", text, enter) end,
})

--------------------------------------------------------------- Player (read-only info)
local Player = Window:CreateTab("Player")
local Info = Player:AddSection("Account")
Info:AddLabel({ Text = "Display name: " .. lp.DisplayName })
Info:AddLabel({ Text = "Username: " .. lp.Name })
Info:AddLabel({ Text = "UserId: " .. lp.UserId })
Info:AddLabel({ Text = "Account age: " .. lp.AccountAge .. " days" })
Info:AddButton({
	Name = "Copy UserId",
	Callback = function()
		if setclipboard then
			setclipboard(tostring(lp.UserId))
			Window:Notify({ Title = "Copied", Content = "UserId copied to clipboard.", Type = "Success", Duration = 3 })
		else
			Window:Notify({ Title = "Unsupported", Content = "setclipboard is not available.", Type = "Warning" })
		end
	end,
})

--------------------------------------------------------------- Settings
local Settings = Window:CreateTab("Settings")
local Look = Settings:AddSection("Interface")

local accents = {
	Cyan = Color3.fromRGB(0, 170, 255), Violet = Color3.fromRGB(150, 110, 255),
	Emerald = Color3.fromRGB(40, 210, 140), Crimson = Color3.fromRGB(255, 80, 100), Gold = Color3.fromRGB(230, 190, 100),
}
Look:AddDropdown({
	Name = "Accent Colour", Options = { "Cyan", "Violet", "Emerald", "Crimson", "Gold" }, Default = "Cyan",
	Callback = function(name) Window:SetAccent(accents[name]) end,
})
Look:AddKeybind({
	Name = "Toggle UI", Default = Enum.KeyCode.RightShift,
	OnChanged = function(key) Window:SetToggleKey(key) end,
})
Look:AddButton({ Name = "Unload NEXUS", Callback = function() Nexus:Destroy() end })

Window:Notify({ Title = "NEXUS loaded", Content = "Press RightShift to hide or show.", Type = "Success" })
