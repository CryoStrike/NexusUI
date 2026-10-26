<p align="center"><img src="assets/nexus-ico.png" width="120" alt="Nexus logo"></p>

# NEXUS UI — Translucid Theme

A modular, object-oriented Luau UI library for Roblox script hubs. Dark glass look, live accent colour, tween animations and strict cleanup (no leaked connections or instances).

## Features

- Window with draggable header, minimise / close, show-hide keybind, logo slot
- Tabs and titled sections
- Toggle, Slider, Button, Dropdown (single + multi), Keybind, Text input, Label
- Notifications (Info / Success / Warning / Error) with progress bar
- Live accent switching (`Window:SetAccent`)
- Flags registry: `Window.Flags.my_flag.Value`
- `Maid`-based cleanup: `Window:Destroy()` / `Nexus:Destroy()`; re-executing the script removes the old instance
- Works with `gethui` / CoreGui / PlayerGui fallback

## Quick start

```lua
local Nexus = loadstring(game:HttpGet("https://raw.githubusercontent.com/CryoStrike/NexusUI/main/init.lua"))()

local Window = Nexus:CreateWindow({
    Name = "NEXUS",
    Subtitle = "TRANSLUCID THEME",
    Icon = "https://raw.githubusercontent.com/CryoStrike/NexusUI/main/assets/nexus-ico.png",
    Accent = Color3.fromRGB(0, 170, 255),
})

local Tab = Window:CreateTab("Main")
local Section = Tab:AddSection("Controls")

Section:AddToggle({ Name = "Toggle", Default = false, Flag = "t1", Callback = function(v) print(v) end })
Section:AddSlider({ Name = "Slider", Min = 0, Max = 100, Default = 50, Callback = print })
Section:AddButton({ Name = "Notify", Callback = function()
    Window:Notify({ Title = "Hi", Content = "It works!", Type = "Success" })
end })
```

See [`examples/hub.lua`](examples/hub.lua) for a complete Main / Player / Settings hub.

## API

| Call | Notes |
|------|-------|
| `Nexus:CreateWindow{ Name, Subtitle, Icon, Accent, Size, ToggleKey, Theme }` | returns `Window` |
| `Window:CreateTab(name, icon?)` | returns `Tab` |
| `Tab:AddSection(name)` | returns `Section` (Tabs also accept components directly) |
| `:AddToggle{ Name, Default, Flag, Callback(bool) }` | `el:Set(v, silent?)` |
| `:AddSlider{ Name, Min, Max, Default, Increment, Suffix, Flag, Callback(n) }` | `el:Set(v, silent?)` |
| `:AddButton{ Name, Callback }` | |
| `:AddDropdown{ Name, Options, Default, Multi, Flag, Callback(v)}` | `el:Set`, `el:SetOptions(list)` |
| `:AddKeybind{ Name, Default, Callback(key), OnChanged(key) }` | click, then press a key (Backspace clears) |
| `:AddInput{ Name, Placeholder, Default, ClearOnFocus, Callback(text, enter) }` | |
| `:AddLabel{ Text }` | `el:Set(text)` |
| `Window:Notify{ Title, Content, Duration, Type }` | |
| `Window:SetAccent(Color3)` / `Window:SetToggleKey(KeyCode)` / `Window:Toggle(bool?)` | |
| `Window:Destroy()` / `Nexus:Destroy()` | full cleanup |

Every element has `.Value`, `:Set()`, `:Destroy()` and `.Frame`.

## Logo

Pass `Icon` as `rbxassetid://<id>` (upload the logo to Roblox) or as an https URL. URLs are downloaded once to `workspace/NexusUI/` and loaded via `getcustomasset` when your environment supports it.

## Development

```lua
-- copy this repo to <workspace>/NexusUI/, then:
getgenv().NEXUS_LOCAL = true
local Nexus = loadstring(readfile("NexusUI/init.lua"))()
```

## Structure

```
NexusUI/
├─ init.lua            loader + public API
├─ src/
│  ├─ Window.lua       window shell, header, sidebar
│  ├─ Tab.lua          tabs + sections
│  ├─ Components.lua   toggle, slider, button, dropdown, keybind, input, label
│  ├─ Notifications.lua
│  ├─ Theme.lua        palette + live accent listeners
│  ├─ Util.lua         tweens, drag, instance helpers
│  └─ Maid.lua         cleanup
├─ examples/hub.lua
├─ assets/nexus-ico.png
└─ LICENSE
```

## License

MIT
