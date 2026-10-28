-- This example moved. The hub is now split into three scripts:
--     init.lua      launcher (loading screen, language picker, opens the hub)
--     language.lua  all texts and languages
--     hub.lua       the UI: categories, buttons, sliders ...
-- This file only keeps the old loadstring link working: it runs the launcher.
loadstring(game:HttpGet("https://raw.githubusercontent.com/CryoStrike/NexusUI/main/init.lua"))()
