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
function Util.GetAsset(src)
	if type(src) ~= "string" or src == "" then return "" end
	if not src:match("^https?://") then return src end

	if writefile and getcustomasset and isfile then
		local safe = (src:sub(-24):gsub("%W", "_"))
		local path = "NexusUI/" .. safe
		if makefolder and isfolder and not isfolder("NexusUI") then pcall(makefolder, "NexusUI") end
		if not isfile(path) then
			local ok, data = pcall(function() return game:HttpGet(src) end)
			if ok then pcall(writefile, path, data) end
		end
		if isfile(path) then
			local ok, asset = pcall(getcustomasset, path)
			if ok then return asset end
		end
	end
	return ""
end

return Util
