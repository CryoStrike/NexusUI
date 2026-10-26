-- Util: instance helpers, tweens, dragging, safe calls, GUI mounting.
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Util = {}

function Util.Create(class, props, children)
	local inst = Instance.new(class)
	local parent
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v else inst[k] = v end
	end
	for _, child in ipairs(children or {}) do child.Parent = inst end
	inst.Parent = parent -- parent last = fewer property replication/layout hits
	return inst
end

function Util.Tween(inst, props, duration, style, direction)
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(duration or 0.18, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

function Util.Corner(parent, radius)
	return Util.Create("UICorner", { CornerRadius = UDim.new(0, radius or 8), Parent = parent })
end

function Util.Stroke(parent, color, thickness, transparency)
	return Util.Create("UIStroke", {
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

function Util.Padding(parent, t, r, b, l)
	return Util.Create("UIPadding", {
		PaddingTop = UDim.new(0, t or 0), PaddingRight = UDim.new(0, r or t or 0),
		PaddingBottom = UDim.new(0, b or t or 0), PaddingLeft = UDim.new(0, l or r or t or 0),
		Parent = parent,
	})
end

function Util.SafeCall(fn, ...)
	if type(fn) ~= "function" then return end
	local ok, err = pcall(fn, ...)
	if not ok then warn("[Nexus] callback error: " .. tostring(err)) end
end

-- Drag `target` by holding `handle`. Connections go into `maid`.
function Util.Draggable(handle, target, maid)
	local dragging, startPos, origin = false, nil, nil

	maid:Give(handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging, startPos, origin = true, input.Position, target.Position
		end
	end))
	maid:Give(UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local d = input.Position - startPos
			target.Position = UDim2.new(origin.X.Scale, origin.X.Offset + d.X, origin.Y.Scale, origin.Y.Offset + d.Y)
		end
	end))
	maid:Give(UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
end

-- Parent a ScreenGui to the safest available container.
function Util.MountGui(gui)
	if gethui then
		local ok = pcall(function() gui.Parent = gethui() end)
		if ok and gui.Parent then return end
	end
	local ok = pcall(function() gui.Parent = CoreGui end)
	if not ok or not gui.Parent then
		gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	end
end

-- Accepts "rbxassetid://123" (returned as is) or an https URL
-- (downloaded once and converted with getcustomasset when the executor supports it).
local PNG_SIGNATURE = "\137PNG\r\n\26\n"
local warnedUnsupported = false

-- Downloaded images are cached as NexusUI/<name>.<ext>. A cached file that is not a real PNG
-- (e.g. an old HTML error page) is downloaded again. Problems are reported with warn().
function Util.GetAsset(src)
	if type(src) ~= "string" or src == "" then return "" end
	if not src:match("^https?://") then return src end

	if not (writefile and getcustomasset and isfile) then
		if not warnedUnsupported then
			warnedUnsupported = true
			warn("[Nexus] image links need writefile, isfile and getcustomasset, which this executor lacks. Use an rbxassetid:// image instead.")
		end
		return ""
	end

	local ext = src:match("%.(%w+)$") or "png"
	local name = (src:gsub("^https?://", ""):gsub("%W", "_"))
	local path = "NexusUI/" .. name:sub(-60) .. "." .. ext:lower()
	local isPng = ext:lower() == "png"

	local function valid(data)
		if type(data) ~= "string" or #data < 8 then return false end
		return (not isPng) or data:sub(1, 8) == PNG_SIGNATURE
	end

	if makefolder then
		local exists = isfolder and isfolder("NexusUI")
		if not exists then pcall(makefolder, "NexusUI") end
	end

	local needDownload = true
	if isfile(path) then
		if readfile then
			local ok, existing = pcall(readfile, path)
			needDownload = not (ok and valid(existing))
		else
			needDownload = false
		end
	end
	if needDownload then
		local ok, data = pcall(function() return game:HttpGet(src) end)
		if not (ok and valid(data)) then
			warn("[Nexus] could not download image: " .. src)
			return ""
		end
		local wrote, err = pcall(writefile, path, data)
		if not wrote then
			warn("[Nexus] could not save image (" .. tostring(err) .. "): " .. path)
			return ""
		end
	end

	local ok, asset = pcall(getcustomasset, path)
	if ok and asset then return asset end
	warn("[Nexus] getcustomasset failed for " .. path .. ": " .. tostring(asset))
	return ""
end

return Util
