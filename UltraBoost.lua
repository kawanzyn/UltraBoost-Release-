--[[
	ULTRABOOST v0.2.0
	Client-side visual tuning for Roblox.
	Designed to use standard Roblox/Luau APIs only; no executor-only functions,
	HTTP loaders, hidden APIs, remote calls, or anti-cheat bypasses.

	Use only where permitted by the experience/platform rules.
	Performance and executor compatibility must be tested on the target device.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
	warn("[UltraBoost] LocalPlayer unavailable. Run this in a client context.")
	return
end

local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
	warn("[UltraBoost] PlayerGui unavailable.")
	return
end

local GUI_NAME = "UltraBoost_GUI"
if playerGui:FindFirstChild(GUI_NAME) then
	warn("[UltraBoost] Already running. Use the existing panel or close it first.")
	return
end

-- Only properties explicitly changed by this script are saved.
-- The first observed value is retained so changing profiles remains reversible.
local saved = {}
local activeProfile = nil
local hideTextures = false
local watchersActive = false
local destroyed = false
local watcherConnections = {}
local scanSerial = {}
local cameraConnection = nil
local cameraChangedConnection = nil
local monitorConnection = nil

local function setSavedProperty(instance, property, value)
	local values = saved[instance]
	if not values then
		values = {}
		saved[instance] = values
	end

	if values[property] == nil then
		local ok, original = pcall(function()
			return instance[property]
		end)
		if not ok then
			return
		end
		values[property] = original
	end

	pcall(function()
		instance[property] = value
	end)
end

local function restoreProperty(instance, property)
	local values = saved[instance]
	if not values or values[property] == nil then
		return
	end

	local original = values[property]
	pcall(function()
		instance[property] = original
	end)

	values[property] = nil
	if next(values) == nil then
		saved[instance] = nil
	end
end

local function applyEnabled(instance, shouldBeEnabled)
	if shouldBeEnabled then
		restoreProperty(instance, "Enabled")
	else
		setSavedProperty(instance, "Enabled", false)
	end
end

local function applyInstance(instance)
	if destroyed then
		return
	end

	local profile = activeProfile
	if profile then
		if instance:IsA("ParticleEmitter") then
			applyEnabled(instance, profile.ParticlesEnabled)
		elseif instance:IsA("Trail") then
			applyEnabled(instance, profile.TrailsEnabled)
		elseif instance:IsA("Beam") then
			applyEnabled(instance, profile.BeamsEnabled)
		elseif instance:IsA("PostEffect") then
			applyEnabled(instance, profile.PostEffectsEnabled)
		elseif instance:IsA("Fire") or instance:IsA("Smoke") or instance:IsA("Sparkles") then
			applyEnabled(instance, profile.LegacyEffectsEnabled)
		end

		if instance:IsA("BasePart") then
			if profile.DisablePartShadows then
				setSavedProperty(instance, "CastShadow", false)
			else
				restoreProperty(instance, "CastShadow")
			end
		end
	end

	if instance:IsA("Decal") or instance:IsA("Texture") then
		if hideTextures then
			setSavedProperty(instance, "Transparency", 1)
		else
			restoreProperty(instance, "Transparency")
		end
	end
end

local function scanRoot(root)
	if not root then
		return
	end

	local serial = (scanSerial[root] or 0) + 1
	scanSerial[root] = serial

	task.spawn(function()
		local ok, initialChildren = pcall(function()
			return root:GetChildren()
		end)
		if not ok then
			return
		end

		-- Walk the hierarchy incrementally. This avoids building one huge
		-- GetDescendants() array on memory-constrained phones.
		local stack = initialChildren
		local processed = 0
		while #stack > 0 do
			if destroyed or scanSerial[root] ~= serial then
				return
			end
			if not activeProfile and not hideTextures then
				return
			end

			local instance = table.remove(stack)
			processed += 1
			applyInstance(instance)

			local childOk, children = pcall(function()
				return instance:GetChildren()
			end)
			if childOk then
				for _, child in ipairs(children) do
					table.insert(stack, child)
				end
			end

			-- Spread work across frames and keep the temporary list bounded
			-- to the current traversal frontier rather than all descendants.
			if processed % 120 == 0 then
				task.wait()
			end
		end
	end)
end

local function disconnectWatchers()
	for _, connection in ipairs(watcherConnections) do
		pcall(function()
			connection:Disconnect()
		end)
	end
	table.clear(watcherConnections)

	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end
	if cameraChangedConnection then
		cameraChangedConnection:Disconnect()
		cameraChangedConnection = nil
	end

	watchersActive = false
	table.clear(scanSerial)
end

local function watchCamera()
	if cameraConnection then
		cameraConnection:Disconnect()
		cameraConnection = nil
	end

	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end

	cameraConnection = camera.DescendantAdded:Connect(function(instance)
		if activeProfile or hideTextures then
			applyInstance(instance)
		end
	end)
end

local function ensureWatchers()
	if watchersActive then
		return
	end

	watchersActive = true

	table.insert(watcherConnections, Workspace.DescendantAdded:Connect(function(instance)
		if activeProfile or hideTextures then
			applyInstance(instance)
		end
	end))

	table.insert(watcherConnections, Lighting.DescendantAdded:Connect(function(instance)
		if activeProfile or hideTextures then
			applyInstance(instance)
		end
	end))

	cameraChangedConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCamera()
		if activeProfile or hideTextures then
			scanRoot(Workspace.CurrentCamera)
		end
	end)

	watchCamera()
end

local PROFILES = {
	Ultra = {
		GlobalShadows = false,
		ParticlesEnabled = false,
		TrailsEnabled = false,
		BeamsEnabled = false,
		PostEffectsEnabled = false,
		LegacyEffectsEnabled = false,
		DisablePartShadows = true,
	},
	Balanced = {
		GlobalShadows = true, -- restore the experience's original setting
		ParticlesEnabled = true,
		TrailsEnabled = true,
		BeamsEnabled = true,
		PostEffectsEnabled = false,
		LegacyEffectsEnabled = true,
		DisablePartShadows = false,
	},
}

local function applyProfile(name)
	local profile = PROFILES[name]
	if not profile then
		return
	end

	activeProfile = profile
	ensureWatchers()

	if profile.GlobalShadows then
		restoreProperty(Lighting, "GlobalShadows")
	else
		setSavedProperty(Lighting, "GlobalShadows", false)
	end

	scanRoot(Workspace)
	scanRoot(Lighting)
	if Workspace.CurrentCamera then
		scanRoot(Workspace.CurrentCamera)
	end
end

local function restoreAll()
	activeProfile = nil
	hideTextures = false
	disconnectWatchers()

	for instance, values in pairs(saved) do
		for property, original in pairs(values) do
			pcall(function()
				instance[property] = original
			end)
		end
	end
	table.clear(saved)
end

-- Build a small touch-friendly panel inside PlayerGui (no CoreGui access needed).
local screen = Instance.new("ScreenGui")
screen.Name = GUI_NAME
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 100
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(232, 222)
panel.Position = UDim2.new(0, 12, 0, 110)
panel.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Parent = screen

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(70, 82, 105)
panelStroke.Transparency = 0.25
panelStroke.Thickness = 1
panelStroke.Parent = panel

local function makeLabel(name, text, position, size, fontSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Position = position
	label.Size = size
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(238, 241, 248)
	label.TextSize = fontSize
	label.Font = Enum.Font.GothamSemibold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel
	return label
end

local title = makeLabel("Title", "ULTRABOOST  •  CLIENT", UDim2.fromOffset(10, 7), UDim2.fromOffset(160, 22), 13)
title.TextColor3 = Color3.fromRGB(112, 190, 255)

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.Position = UDim2.fromOffset(202, 7)
closeButton.Size = UDim2.fromOffset(22, 22)
closeButton.BackgroundColor3 = Color3.fromRGB(145, 55, 65)
closeButton.Text = "×"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 18
closeButton.Font = Enum.Font.GothamBold
closeButton.BorderSizePixel = 0
closeButton.Parent = panel
Instance.new("UICorner", closeButton).CornerRadius = UDim.new(0, 6)

local fpsLabel = makeLabel("FPS", "FPS: --", UDim2.fromOffset(10, 32), UDim2.fromOffset(210, 18), 12)
fpsLabel.TextColor3 = Color3.fromRGB(190, 200, 215)

local statusLabel = makeLabel("Status", "Pronto • alterações locais", UDim2.fromOffset(10, 49), UDim2.fromOffset(210, 18), 10)
statusLabel.TextColor3 = Color3.fromRGB(160, 175, 195)

local function makeButton(name, text, y, height, color, callback)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(10, y)
	button.Size = UDim2.new(1, -20, 0, height)
	button.BackgroundColor3 = color
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 13
	button.Font = Enum.Font.GothamSemibold
	button.Parent = panel
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 7)
	button.Activated:Connect(callback)
	return button
end

makeButton("Ultra", "⚡  ULTRA • reduzir efeitos", 72, 32, Color3.fromRGB(37, 103, 166), function()
	applyProfile("Ultra")
	statusLabel.Text = "Modo Ultra aplicado no cliente"
end)

makeButton("Balanced", "⚖  EQUILIBRADO", 109, 32, Color3.fromRGB(53, 92, 79), function()
	applyProfile("Balanced")
	statusLabel.Text = "Modo equilibrado aplicado"
end)

local textureButton
textureButton = makeButton("Textures", "Texturas/decals: OFF", 146, 27, Color3.fromRGB(75, 79, 96), function()
	hideTextures = not hideTextures
	if hideTextures then
		ensureWatchers()
		scanRoot(Workspace)
		scanRoot(Lighting)
		if Workspace.CurrentCamera then
			scanRoot(Workspace.CurrentCamera)
		end
		textureButton.Text = "Texturas/decals: ON"
		statusLabel.Text = "Texturas ocultadas localmente"
	else
		for instance, values in pairs(saved) do
			if values.Transparency ~= nil and (instance:IsA("Decal") or instance:IsA("Texture")) then
				restoreProperty(instance, "Transparency")
			end
		end
		textureButton.Text = "Texturas/decals: OFF"
		statusLabel.Text = "Texturas originais restauradas"
		if not activeProfile then
			disconnectWatchers()
		end
	end
end)

makeButton("Restore", "↩  RESTAURAR ORIGINAL", 178, 27, Color3.fromRGB(105, 68, 62), function()
	restoreAll()
	textureButton.Text = "Texturas/decals: OFF"
	statusLabel.Text = "Configurações originais restauradas"
end)

local miniButton = Instance.new("TextButton")
miniButton.Name = "ShowPanel"
miniButton.Size = UDim2.fromOffset(48, 42)
miniButton.Position = UDim2.new(0, 12, 0, 110)
miniButton.BackgroundColor3 = Color3.fromRGB(28, 105, 165)
miniButton.Text = "UB"
miniButton.TextColor3 = Color3.new(1, 1, 1)
miniButton.TextSize = 16
miniButton.Font = Enum.Font.GothamBold
miniButton.Visible = false
miniButton.BorderSizePixel = 0
miniButton.Parent = screen
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(0, 10)
miniButton.Activated:Connect(function()
	panel.Visible = true
	miniButton.Visible = false
end)

local minimizeButton = Instance.new("TextButton")
minimizeButton.Name = "Minimize"
minimizeButton.Size = UDim2.fromOffset(22, 22)
minimizeButton.Position = UDim2.fromOffset(176, 7)
minimizeButton.BackgroundColor3 = Color3.fromRGB(65, 75, 92)
minimizeButton.Text = "−"
minimizeButton.TextColor3 = Color3.new(1, 1, 1)
minimizeButton.TextSize = 17
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.BorderSizePixel = 0
minimizeButton.Parent = panel
Instance.new("UICorner", minimizeButton).CornerRadius = UDim.new(0, 6)
minimizeButton.Activated:Connect(function()
	panel.Visible = false
	miniButton.Visible = true
end)

local function closeUltraBoost()
	if destroyed then
		return
	end
	destroyed = true
	restoreAll()
	if monitorConnection then
		monitorConnection:Disconnect()
		monitorConnection = nil
	end
	screen:Destroy()
end

closeButton.Activated:Connect(closeUltraBoost)
screen.Parent = playerGui

-- Low-cost FPS estimate: count frames, update the UI once per second.
local frames = 0
local elapsed = 0
monitorConnection = RunService.RenderStepped:Connect(function(deltaTime)
	if destroyed then
		return
	end

	frames += 1
	elapsed += deltaTime

	if elapsed >= 1 then
		local fps = math.floor(frames / elapsed + 0.5)
		fpsLabel.Text = "FPS: " .. tostring(fps) .. "  |  Local"
		frames = 0
		elapsed = 0
	end
end)

print("[UltraBoost] Loaded. Choose Ultra or Balanced; use Restore before leaving.")
