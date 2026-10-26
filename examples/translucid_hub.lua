--[[
	NEXUS UI - Translucid Theme showcase hub

	Flow:  loading animation  ->  language picker  ->  resizable hub
	Tabs:  Combat / Character / Farm / Troll / Visuals / Settings / About

	The controls are UI placeholders: they print their value, so hook your own logic into the Callbacks.

	Usage:
		loadstring(game:HttpGet("https://raw.githubusercontent.com/CryoStrike/NexusUI/main/examples/translucid_hub.lua"))()
]]

local REPO = "https://raw.githubusercontent.com/CryoStrike/NexusUI/main/"
local Nexus = loadstring(game:HttpGet(REPO .. "init.lua"))()

local Players = game:GetService("Players")
local lp = Players.LocalPlayer

local DEMO_KEY = "NEXUS-DEMO" -- demo only: replace with your own key check

--------------------------------------------------------------- Tab icons
-- White PNGs in assets/icons/ (NEXUS tints them: grey, or the accent colour when selected).
-- Downloading them needs writefile + isfile + getcustomasset. Without those the tabs are text-only.
-- To use Roblox images instead, replace the return value with "rbxassetid://<image id>".
local CAN_ICON = writefile ~= nil and isfile ~= nil and getcustomasset ~= nil
if not CAN_ICON then
	warn("[NEXUS] this executor lacks writefile/isfile/getcustomasset: tab icons are off (use rbxassetid:// icons instead).")
end
local function icon(name)
	if CAN_ICON then return REPO .. "assets/icons/" .. name .. ".png" end
	return nil
end

--------------------------------------------------------------- Localisation
local LANGUAGES = { "English", "Français", "Español", "Deutsch", "Português" }

local STRINGS = {
	English = {
		tab_combat = "Combat", tab_character = "Character", tab_farm = "Farm", tab_troll = "Troll",
		tab_visuals = "Visuals", tab_settings = "Settings", tab_about = "About",
		combat_module = "Combat Module", range = "Range", priority = "Target Priority", combat_key = "Combat Key",
		walk_speed = "Walk Speed", jump_power = "Jump Power", anti_afk = "Anti-AFK", reset_char = "Reset Character",
		farm_toggle = "Auto Farm", farm_mode = "Farm Mode", farm_delay = "Farm Delay", target_name = "Target Name", target_ph = "Enter a name...",
		troll_module = "Troll Module", effect = "Effect", intensity = "Intensity", run_effect = "Run Effect", stop_all = "Stop All",
		sec_display = "Display", highlight = "Highlight", fov = "Field of View", style = "Style", sec_theme = "Theme", accent = "Accent Colour",
		sec_interface = "Interface", hide_key = "Hide Hub Key", minimize = "Minimize Hub", language = "Language", unload = "Unload NEXUS",
		resize_hint = "Drag the bottom-right corner to resize the hub.",
		sec_keysystem = "Key System", license_key = "License Key", license_ph = "Enter your key...", key_system = "Key System",
		key_ok = "Key accepted.", key_empty = "Enter a key first.", key_bad = "Invalid key.",
		about_title = "NEXUS UI", about_version = "Translucid Theme - v%s", about_signed = "Signed in as %s (@%s)",
		pressed = "Button pressed.", loaded_title = "NEXUS loaded", loaded_text = "Press %s to hide or show the hub.", lang_set = "Language: %s",
	},
	["Français"] = {
		tab_combat = "Combat", tab_character = "Personnage", tab_farm = "Farm", tab_troll = "Troll",
		tab_visuals = "Visuels", tab_settings = "Paramètres", tab_about = "À propos",
		combat_module = "Module de combat", range = "Portée", priority = "Priorité de cible", combat_key = "Touche de combat",
		walk_speed = "Vitesse de marche", jump_power = "Puissance de saut", anti_afk = "Anti-AFK", reset_char = "Réinitialiser le personnage",
		farm_toggle = "Auto Farm", farm_mode = "Mode de farm", farm_delay = "Délai de farm", target_name = "Nom de la cible", target_ph = "Entrez un nom...",
		troll_module = "Module Troll", effect = "Effet", intensity = "Intensité", run_effect = "Lancer l'effet", stop_all = "Tout arrêter",
		sec_display = "Affichage", highlight = "Surbrillance", fov = "Champ de vision", style = "Style", sec_theme = "Thème", accent = "Couleur d'accent",
		sec_interface = "Interface", hide_key = "Touche pour masquer", minimize = "Réduire le hub", language = "Langue", unload = "Décharger NEXUS",
		resize_hint = "Faites glisser le coin inférieur droit pour redimensionner.",
		sec_keysystem = "Système de clé", license_key = "Clé de licence", license_ph = "Entrez votre clé...", key_system = "Système de clé",
		key_ok = "Clé acceptée.", key_empty = "Entrez d'abord une clé.", key_bad = "Clé invalide.",
		about_title = "NEXUS UI", about_version = "Thème Translucid - v%s", about_signed = "Connecté en tant que %s (@%s)",
		pressed = "Bouton pressé.", loaded_title = "NEXUS chargé", loaded_text = "Appuyez sur %s pour masquer ou afficher le hub.", lang_set = "Langue : %s",
	},
	["Español"] = {
		tab_combat = "Combate", tab_character = "Personaje", tab_farm = "Farmeo", tab_troll = "Troll",
		tab_visuals = "Visuales", tab_settings = "Ajustes", tab_about = "Acerca de",
		combat_module = "Módulo de combate", range = "Alcance", priority = "Prioridad de objetivo", combat_key = "Tecla de combate",
		walk_speed = "Velocidad de caminar", jump_power = "Fuerza de salto", anti_afk = "Anti-AFK", reset_char = "Reiniciar personaje",
		farm_toggle = "Auto Farm", farm_mode = "Modo de farmeo", farm_delay = "Retraso de farmeo", target_name = "Nombre del objetivo", target_ph = "Introduce un nombre...",
		troll_module = "Módulo Troll", effect = "Efecto", intensity = "Intensidad", run_effect = "Ejecutar efecto", stop_all = "Detener todo",
		sec_display = "Pantalla", highlight = "Resaltado", fov = "Campo de visión", style = "Estilo", sec_theme = "Tema", accent = "Color de acento",
		sec_interface = "Interfaz", hide_key = "Tecla para ocultar", minimize = "Minimizar hub", language = "Idioma", unload = "Descargar NEXUS",
		resize_hint = "Arrastra la esquina inferior derecha para cambiar el tamaño.",
		sec_keysystem = "Sistema de clave", license_key = "Clave de licencia", license_ph = "Introduce tu clave...", key_system = "Sistema de clave",
		key_ok = "Clave aceptada.", key_empty = "Introduce primero una clave.", key_bad = "Clave no válida.",
		about_title = "NEXUS UI", about_version = "Tema Translucid - v%s", about_signed = "Sesión iniciada como %s (@%s)",
		pressed = "Botón pulsado.", loaded_title = "NEXUS cargado", loaded_text = "Pulsa %s para ocultar o mostrar el hub.", lang_set = "Idioma: %s",
	},
	Deutsch = {
		tab_combat = "Kampf", tab_character = "Charakter", tab_farm = "Farm", tab_troll = "Troll",
		tab_visuals = "Visuals", tab_settings = "Optionen", tab_about = "Info",
		combat_module = "Kampfmodul", range = "Reichweite", priority = "Zielpriorität", combat_key = "Kampftaste",
		walk_speed = "Laufgeschwindigkeit", jump_power = "Sprungkraft", anti_afk = "Anti-AFK", reset_char = "Charakter zurücksetzen",
		farm_toggle = "Auto-Farm", farm_mode = "Farm-Modus", farm_delay = "Farm-Verzögerung", target_name = "Zielname", target_ph = "Namen eingeben...",
		troll_module = "Troll-Modul", effect = "Effekt", intensity = "Intensität", run_effect = "Effekt ausführen", stop_all = "Alles stoppen",
		sec_display = "Anzeige", highlight = "Hervorhebung", fov = "Sichtfeld", style = "Stil", sec_theme = "Design", accent = "Akzentfarbe",
		sec_interface = "Oberfläche", hide_key = "Taste zum Ausblenden", minimize = "Hub minimieren", language = "Sprache", unload = "NEXUS entladen",
		resize_hint = "Ziehe die untere rechte Ecke, um die Größe zu ändern.",
		sec_keysystem = "Schlüsselsystem", license_key = "Lizenzschlüssel", license_ph = "Schlüssel eingeben...", key_system = "Schlüsselsystem",
		key_ok = "Schlüssel akzeptiert.", key_empty = "Gib zuerst einen Schlüssel ein.", key_bad = "Ungültiger Schlüssel.",
		about_title = "NEXUS UI", about_version = "Translucid-Design - v%s", about_signed = "Angemeldet als %s (@%s)",
		pressed = "Schaltfläche gedrückt.", loaded_title = "NEXUS geladen", loaded_text = "Drücke %s, um den Hub aus- oder einzublenden.", lang_set = "Sprache: %s",
	},
	["Português"] = {
		tab_combat = "Combate", tab_character = "Personagem", tab_farm = "Farm", tab_troll = "Troll",
		tab_visuals = "Visuais", tab_settings = "Opções", tab_about = "Sobre",
		combat_module = "Módulo de combate", range = "Alcance", priority = "Prioridade de alvo", combat_key = "Tecla de combate",
		walk_speed = "Velocidade de caminhada", jump_power = "Força do pulo", anti_afk = "Anti-AFK", reset_char = "Reiniciar personagem",
		farm_toggle = "Auto Farm", farm_mode = "Modo de farm", farm_delay = "Atraso do farm", target_name = "Nome do alvo", target_ph = "Digite um nome...",
		troll_module = "Módulo Troll", effect = "Efeito", intensity = "Intensidade", run_effect = "Executar efeito", stop_all = "Parar tudo",
		sec_display = "Exibição", highlight = "Destaque", fov = "Campo de visão", style = "Estilo", sec_theme = "Tema", accent = "Cor de destaque",
		sec_interface = "Interface", hide_key = "Tecla para ocultar", minimize = "Minimizar hub", language = "Idioma", unload = "Descarregar NEXUS",
		resize_hint = "Arraste o canto inferior direito para redimensionar.",
		sec_keysystem = "Sistema de chave", license_key = "Chave de licença", license_ph = "Digite sua chave...", key_system = "Sistema de chave",
		key_ok = "Chave aceita.", key_empty = "Digite uma chave primeiro.", key_bad = "Chave inválida.",
		about_title = "NEXUS UI", about_version = "Tema Translucid - v%s", about_signed = "Conectado como %s (@%s)",
		pressed = "Botão pressionado.", loaded_title = "NEXUS carregado", loaded_text = "Pressione %s para ocultar ou mostrar o hub.", lang_set = "Idioma: %s",
	},
}

local state = {
	language = "English",
	toggleKey = Enum.KeyCode.RightShift,
	accentName = "Cyan",
}
local ACCENTS = {
	Cyan = Color3.fromRGB(0, 170, 255), Violet = Color3.fromRGB(150, 110, 255),
	Emerald = Color3.fromRGB(40, 210, 140), Crimson = Color3.fromRGB(255, 80, 100), Gold = Color3.fromRGB(230, 190, 100),
}

local function tr(key)
	local set = STRINGS[state.language]
	return (set and set[key]) or STRINGS.English[key] or key
end

--------------------------------------------------------------- Hub
local Window

local function notify(title, content, kind)
	if Window then Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3 }) end
end

local function build(rebuilt)
	Window = Nexus:CreateWindow({
		Name = "NEXUS",
		Subtitle = "TRANSLUCID THEME",
		Icon = REPO .. "assets/nexus-ico.png", -- or "rbxassetid://<uploaded logo id>"
		Accent = ACCENTS[state.accentName],
		ToggleKey = state.toggleKey,
		Size = UDim2.fromOffset(700, 500),
		Resizable = true,
		MinSize = Vector2.new(560, 360),
	})

	----------------------------------------------------------- Combat
	local Combat = Window:CreateTab(tr("tab_combat"), icon("combat"))
	Combat:AddToggle({
		Name = tr("combat_module"), Default = false, Flag = "combat_module",
		Callback = function(on) print("Combat module:", on) end,
	})
	Combat:AddSlider({
		Name = tr("range"), Min = 0, Max = 1000, Default = 250, Increment = 1, Suffix = " / 1000", Flag = "combat_range",
		Callback = function(v) print("Range:", v) end,
	})
	Combat:AddDropdown({
		Name = tr("priority"), Options = { "Nearest", "Lowest Health", "Random" }, Default = "Nearest", Flag = "combat_priority",
		Callback = function(v) print("Target priority:", v) end,
	})
	Combat:AddKeybind({
		Name = tr("combat_key"), Default = Enum.KeyCode.R, Flag = "combat_key",
		Callback = function(key) print("Combat key pressed:", key.Name) end,
	})

	----------------------------------------------------------- Character
	local Character = Window:CreateTab(tr("tab_character"), icon("character"))
	Character:AddSlider({
		Name = tr("walk_speed"), Min = 16, Max = 100, Default = 16, Increment = 1, Flag = "walk_speed",
		Callback = function(v) print("Walk speed:", v) end,
	})
	Character:AddSlider({
		Name = tr("jump_power"), Min = 50, Max = 200, Default = 50, Increment = 1, Flag = "jump_power",
		Callback = function(v) print("Jump power:", v) end,
	})
	Character:AddToggle({
		Name = tr("anti_afk"), Default = true, Flag = "anti_afk",
		Callback = function(on) print("Anti-AFK:", on) end,
	})
	Character:AddButton({
		Name = tr("reset_char"),
		Callback = function() notify(tr("tab_character"), tr("pressed")) end,
	})

	----------------------------------------------------------- Farm
	local Farm = Window:CreateTab(tr("tab_farm"), icon("farm"))
	Farm:AddToggle({
		Name = tr("farm_toggle"), Default = false, Flag = "farm_toggle",
		Callback = function(on) print("Auto farm:", on) end,
	})
	Farm:AddDropdown({
		Name = tr("farm_mode"), Options = { "Nearest", "Selected" }, Default = "Nearest", Flag = "farm_mode",
		Callback = function(v) print("Farm mode:", v) end,
	})
	Farm:AddSlider({
		Name = tr("farm_delay"), Min = 0, Max = 10, Default = 1, Increment = 1, Suffix = " s", Flag = "farm_delay",
		Callback = function(v) print("Farm delay:", v) end,
	})
	Farm:AddInput({
		Name = tr("target_name"), Placeholder = tr("target_ph"), Flag = "farm_target",
		Callback = function(text, enter) if enter then print("Target:", text) end end,
	})

	----------------------------------------------------------- Troll
	local Troll = Window:CreateTab(tr("tab_troll"), icon("troll"))
	Troll:AddToggle({
		Name = tr("troll_module"), Default = false, Flag = "troll_module",
		Callback = function(on) print("Troll module:", on) end,
	})
	Troll:AddDropdown({
		Name = tr("effect"), Options = { "Spin", "Bounce", "Shake" }, Default = "Spin", Flag = "troll_effect",
		Callback = function(v) print("Effect:", v) end,
	})
	Troll:AddSlider({
		Name = tr("intensity"), Min = 1, Max = 10, Default = 3, Increment = 1, Flag = "troll_intensity",
		Callback = function(v) print("Intensity:", v) end,
	})
	Troll:AddButton({
		Name = tr("run_effect"),
		Callback = function() notify(tr("tab_troll"), tr("pressed"), "Success") end,
	})
	Troll:AddButton({
		Name = tr("stop_all"),
		Callback = function() notify(tr("tab_troll"), tr("pressed"), "Warning") end,
	})

	----------------------------------------------------------- Visuals
	local Visuals = Window:CreateTab(tr("tab_visuals"), icon("visuals"))
	local Display = Visuals:AddSection(tr("sec_display"))
	Display:AddToggle({
		Name = tr("highlight"), Default = false, Flag = "highlight",
		Callback = function(on) print("Highlight:", on) end,
	})
	Display:AddSlider({
		Name = tr("fov"), Min = 40, Max = 120, Default = 70, Increment = 1, Suffix = "°", Flag = "fov",
		Callback = function(v) print("FOV:", v) end,
	})
	Display:AddDropdown({
		Name = tr("style"), Options = { "Balanced", "Performance", "Quality" }, Default = "Balanced",
		Callback = function(v) print("Style:", v) end,
	})
	local Theming = Visuals:AddSection(tr("sec_theme"))
	Theming:AddDropdown({
		Name = tr("accent"), Options = { "Cyan", "Violet", "Emerald", "Crimson", "Gold" }, Default = state.accentName,
		Callback = function(name)
			state.accentName = name
			Window:SetAccent(ACCENTS[name])
		end,
	})

	----------------------------------------------------------- Settings
	local Settings = Window:CreateTab(tr("tab_settings"), icon("settings"))
	local Interface = Settings:AddSection(tr("sec_interface"))
	Interface:AddKeybind({
		Name = tr("hide_key"), Default = state.toggleKey,
		OnChanged = function(key)
			if key then
				state.toggleKey = key
				Window:SetToggleKey(key)
			end
		end,
	})
	Interface:AddButton({ Name = tr("minimize"), Callback = function() Window:Minimize() end })
	Interface:AddDropdown({
		Name = tr("language"), Options = LANGUAGES, Default = state.language,
		Callback = function(lang)
			if lang == state.language then return end
			state.language = lang
			task.defer(function() -- rebuild the hub in the new language
				Window:Destroy()
				build(true)
			end)
		end,
	})
	Interface:AddLabel({ Text = tr("resize_hint") })
	Interface:AddButton({ Name = tr("unload"), Callback = function() Nexus:Destroy() end })

	local KeySystem = Settings:AddSection(tr("sec_keysystem"))
	KeySystem:AddInput({ Name = tr("license_key"), Placeholder = tr("license_ph"), Flag = "license_key" })
	KeySystem:AddButton({
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

	----------------------------------------------------------- About
	local About = Window:CreateTab(tr("tab_about"), icon("about"))
	local Info = About:AddSection(tr("about_title"))
	Info:AddLabel({ Text = string.format(tr("about_version"), tostring(Nexus.Version)) })
	Info:AddLabel({ Text = string.format(tr("about_signed"), lp.DisplayName, lp.Name) })
	Info:AddLabel({ Text = "github.com/CryoStrike/NexusUI" })

	if rebuilt then
		notify(tr("loaded_title"), string.format(tr("lang_set"), state.language), "Success")
	else
		notify(tr("loaded_title"), string.format(tr("loaded_text"), state.toggleKey.Name), "Success")
	end
end

--------------------------------------------------------------- Loading screen -> language -> hub
local chosen = Nexus:Load({
	Name = "NEXUS",
	Subtitle = "TRANSLUCID THEME",
	Icon = REPO .. "assets/nexus-ico.png",
	Accent = ACCENTS.Cyan,
	Steps = { "Initializing", "Loading modules", "Preparing interface" },
	Duration = 3,
	Languages = LANGUAGES,
	DefaultLanguage = "English",
	LanguageTitle = "Select language",
	ContinueText = "Continue",
})
if not chosen then return end -- loader was closed (e.g. the script was re-executed)

state.language = chosen
build(false)
