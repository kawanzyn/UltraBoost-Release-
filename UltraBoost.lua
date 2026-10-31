--[[
	ULTRABOOST v0.3.0
	Client-side visual tuning with reversible Ultra, Balanced and Light modes.

	Uses standard client-side Roblox/Luau APIs only. No HTTP loader, executor-only
	APIs, hidden APIs, remote calls, instance deletion, or anti-cheat bypasses.
	Use only where local scripts are permitted. Results vary by experience/device.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
	warn("[UltraBoost] LocalPlayer unavailable. Run in a client context.")
	return
end

local playerGui = player:WaitForChild("PlayerGui", 15)
if not playerGui then
	warn("[UltraBoost] PlayerGui unavailable.")
	return
end

local GUI_NAME = "UltraBoost_GUI"
if playerGui:FindFirstChild(GUI_NAME) then
	warn("[UltraBoost] Already running. Close the existing panel first.")
	return
end

local Terrain = Workspace:FindFirstChildOfClass("Terrain")
local WHITE = Color3.new(1, 1, 1)
local SMOOTH = Enum.Material.SmoothPlastic

local destroyed = false
local activeMode = nil
local collisionEnabled = false
local monitorEnabled = true
local watchersActive = false

-- Separate snapshots keep visual mode switching independent from collision.
local visualSaved = setmetatable({}, { __mode = "k" })
local collisionSaved = setmetatable({}, { __mode = "k" })
local terrainColorsSaved = {}
local watcherConnections = {}
local scanSerial = {}
local cameraConnection = nil
local cameraChangedConnection = nil
local monitorConnection = nil

local function rememberAndSet(store, instance, property, value)
	local values = store[instance]
	if not values then
		values = {}
		store[instance] = values
	end

	if values[property] == nil then
		local ok, original = pcall(function()
			return instance[property]
		end)
		if not ok then
			return false
		end
		values[property] = original
	end

	local ok = pcall(function()
		instance[property] = value
	end)
	return ok
end

local function restoreStore(store)
	for instance, values in pairs(store) do
		for property, original in pairs(values) do
			pcall(function()
				instance[property] = original
			end)
		end
	end
	table.clear(store)
end

local function restoreTerrainColors()
	if not Terrain then
		table.clear(terrainColorsSaved)
		return
	end

	for material, originalColor in pairs(terrainColorsSaved) do
		pcall(function()
			Terrain:SetMaterialColor(material, originalColor)
		end)
	end
	table.clear(terrainColorsSaved)
end

local function applyWhiteTerrain()
	if not Terrain then
		return
	end

	local ok, materials = pcall(function()
		return Enum.Material:GetEnumItems()
	end)
	if not ok then
		return
	end

	for _, material in ipairs(materials) do
		local gotColor, originalColor = pcall(function()
			return Terrain:GetMaterialColor(material)
		end)
		if gotColor and terrainColorsSaved[material] == nil then
			terrainColorsSaved[material] = originalColor
		end
		pcall(function()
			Terrain:SetMaterialColor(material, WHITE)
		end)
	end
end

local protectedNameParts = {
	"player", "character", "npc", "enemy", "boss", "humanoid",
	"tool", "weapon", "item", "pickup", "collect", "coin", "egg",
	"objective", "quest", "checkpoint", "spawn", "portal", "button",
	"switch", "lever", "door", "vehicle", "pet", "shop", "gui",
}

local groundNameParts = {
	"ground", "floor", "baseplate", "terrain", "road", "path",
	"sidewalk", "pavement", "walkway",
}

local function containsAny(text, fragments)
	local lowered = string.lower(text)
	for _, fragment in ipairs(fragments) do
		if string.find(lowered, fragment, 1, true) then
			return true
		end
	end
	return false
end

local function isProtectedObject(instance)
	local current = instance
	while current and current ~= Workspace and current ~= Lighting do
		if current:IsA("Model") and current:FindFirstChildOfClass("Humanoid") then
			return true
		end
		if current:IsA("Tool") or current:IsA("Accessory") then
			return true
		end
		if containsAny(current.Name, protectedNameParts) then
			return true
		end
		current = current.Parent
	end
	return false
end

local function isGroundPart(part)
	local current = part
	while current and current ~= Workspace do
		if containsAny(current.Name, groundNameParts) then
			return true
		end
		current = current.Parent
	end

	-- Conservative fallback for large, thin, upward-facing anchored surfaces.
	local size = part.Size
	local area = size.X * size.Z
	local thinLimit = math.max(4, math.min(size.X, size.Z) * 0.08)
	return part.Anchored
		and area >= 400
		and size.Y <= thinLimit
		and part.CFrame.UpVector.Y >= 0.85
end

local function isEnvironmentPart(part)
	if not part:IsA("BasePart") or not part:IsDescendantOf(Workspace) or not part.Anchored then
		return false
	end
	if isProtectedObject(part) or isGroundPart(part) then
		return false
	end
	return true
end

local function shouldSimplifyTexture(instance)
	if isProtectedObject(instance) then
		return false
	end

	local parentPart = instance:FindFirstAncestorWhichIsA("BasePart")
	if parentPart then
		return isGroundPart(parentPart) or isEnvironmentPart(parentPart)
	end

	return instance:IsDescendantOf(Lighting)
end

local function hideTexture(instance)
	if instance:IsA("Decal") or instance:IsA("Texture") then
		rememberAndSet(visualSaved, instance, "Transparency", 1)
	elseif instance:IsA("SurfaceAppearance") then
		-- Clearing maps exposes the underlying part color/material where supported.
		for _, property in ipairs({ "ColorMap", "NormalMap", "RoughnessMap", "MetalnessMap" }) do
			rememberAndSet(visualSaved, instance, property, "")
		end
	end
end

local function applyEffects(instance, mode)
	if mode == "Light" or isProtectedObject(instance) then
		return
	end

	if instance:IsA("ParticleEmitter")
		or instance:IsA("Trail")
		or instance:IsA("Beam")
		or instance:IsA("PostEffect")
		or instance:IsA("Fire")
		or instance:IsA("Smoke")
		or instance:IsA("Sparkles") then
		rememberAndSet(visualSaved, instance, "Enabled", false)
	end
end

local function applyInstance(instance)
	if destroyed then
		return
	end

	local mode = activeMode
	if mode and not isProtectedObject(instance) then
		if instance:IsA("BasePart") then
			local ground = isGroundPart(instance)
			local environment = isEnvironmentPart(instance)

			if ground or environment then
				rememberAndSet(visualSaved, instance, "Material", SMOOTH)
				rememberAndSet(visualSaved, instance, "MaterialVariant", "")

				if mode == "Ultra" then
					if environment then
						rememberAndSet(visualSaved, instance, "LocalTransparencyModifier", 1)
						rememberAndSet(visualSaved, instance, "CastShadow", false)
					end
				elseif mode == "Balanced" then
					rememberAndSet(visualSaved, instance, "Color", WHITE)
					rememberAndSet(visualSaved, instance, "CastShadow", false)
				end
			end
		elseif (instance:IsA("Decal") or instance:IsA("Texture") or instance:IsA("SurfaceAppearance"))
			and shouldSimplifyTexture(instance) then
			hideTexture(instance)
		else
			applyEffects(instance, mode)
		end
	end

	-- Only confidently classified, anchored environment parts are eligible.
	-- Ground, characters, tools and gameplay-named objects are always excluded.
	if collisionEnabled and instance:IsA("BasePart")
		and instance.Anchored and isEnvironmentPart(instance) then
		rememberAndSet(collisionSaved, instance, "CanCollide", false)
	end
end

local function scanRoot(root)
	if not root then
		return
	end

	local serial = (scanSerial[root] or 0) + 1
	scanSerial[root] = serial

	task.spawn(function()
		local ok, stack = pcall(function()
			return root:GetChildren()
		end)
		if not ok then
			return
		end

		local processed = 0
		while #stack > 0 do
			if destroyed or scanSerial[root] ~= serial then
				return
			end
			if not activeMode and not collisionEnabled then
				return
			end

			local instance = table.remove(stack)
			applyInstance(instance)
			processed += 1

			local childOk, children = pcall(function()
				return instance:GetChildren()
			end)
			if childOk then
				for _, child in ipairs(children) do
					table.insert(stack, child)
				end
			end

			if processed % 100 == 0 then
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
	if camera and not camera:IsDescendantOf(Workspace) then
		cameraConnection = camera.DescendantAdded:Connect(applyInstance)
	end
end

local function ensureWatchers()
	if watchersActive or (not activeMode and not collisionEnabled) then
		return
	end

	watchersActive = true
	table.insert(watcherConnections, Workspace.DescendantAdded:Connect(applyInstance))
	table.insert(watcherConnections, Lighting.DescendantAdded:Connect(applyInstance))

	cameraChangedConnection = Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watchCamera()
		if activeMode or collisionEnabled then
			scanRoot(Workspace.CurrentCamera)
		end
	end)
	watchCamera()
end

local function updateWatchers()
	if activeMode or collisionEnabled then
		ensureWatchers()
	else
		disconnectWatchers()
	end
end

local function applyTerrain(mode)
	if not Terrain then
		return
	end

	if mode == "Ultra" or mode == "Balanced" then
		rememberAndSet(visualSaved, Terrain, "Decoration", false)
		applyWhiteTerrain()
	end
end

local function applyMode(mode)
	if mode ~= "Ultra" and mode ~= "Balanced" and mode ~= "Light" then
		return false
	end

	-- Restore only visual properties; independent collision settings stay active.
	restoreStore(visualSaved)
	restoreTerrainColors()
	activeMode = mode

	if mode == "Ultra" or mode == "Balanced" then
		rememberAndSet(visualSaved, Lighting, "GlobalShadows", false)
	end

	applyTerrain(mode)
	updateWatchers()
	scanRoot(Workspace)
	scanRoot(Lighting)
	scanRoot(Workspace.CurrentCamera)
	return true
end

local function setCollisionEnabled(enabled)
	collisionEnabled = enabled
	if not enabled then
		restoreStore(collisionSaved)
	else
		updateWatchers()
		scanRoot(Workspace)
	end
	updateWatchers()
end

local function restoreAll()
	activeMode = nil
	collisionEnabled = false
	disconnectWatchers()
	restoreStore(visualSaved)
	restoreStore(collisionSaved)
	restoreTerrainColors()
end

-- Touch-friendly panel.
local screen = Instance.new("ScreenGui")
screen.Name = GUI_NAME
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 100
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.fromOffset(252, 322)
panel.Position = UDim2.new(0, 12, 0, 92)
panel.BackgroundColor3 = Color3.fromRGB(22, 25, 33)
panel.BackgroundTransparency = 0.06
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
	label.TextWrapped = true
	label.Parent = panel
	return label
end

local title = makeLabel("Title", "ULTRABOOST  •  CLIENT", UDim2.fromOffset(10, 7), UDim2.fromOffset(174, 22), 13)
title.TextColor3 = Color3.fromRGB(112, 190, 255)

local function makeSmallButton(name, text, x, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Position = UDim2.fromOffset(x, 7)
	button.Size = UDim2.fromOffset(22, 22)
	button.BackgroundColor3 = color
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextSize = 17
	button.Font = Enum.Font.GothamBold
	button.BorderSizePixel = 0
	button.Parent = panel
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)
	return button
end

local closeButton = makeSmallButton("Close", "×", 220, Color3.fromRGB(145, 55, 65))
local minimizeButton = makeSmallButton("Minimize", "−", 194, Color3.fromRGB(65, 75, 92))

local fpsLabel = makeLabel("FPS", "FPS: --", UDim2.fromOffset(10, 33), UDim2.fromOffset(228, 18), 12)
fpsLabel.TextColor3 = Color3.fromRGB(190, 200, 215)

local statusLabel = makeLabel("Status", "Pronto • alterações locais", UDim2.fromOffset(10, 51), UDim2.fromOffset(230, 18), 10)
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

makeButton("Ultra", "⚡  ULTRA • ambiente mínimo", 75, 30, Color3.fromRGB(37, 103, 166), function()
	if applyMode("Ultra") then
		statusLabel.Text = "Ultra aplicado • cenário simplificado"
	end
end)

makeButton("Balanced", "⚖  EQUILIBRADO • mapa branco", 109, 30, Color3.fromRGB(75, 91, 115), function()
	if applyMode("Balanced") then
		statusLabel.Text = "Equilibrado aplicado • mapa branco"
	end
end)

makeButton("Light", "🪶  LEVE • plástico + sem texturas", 143, 30, Color3.fromRGB(53, 112, 91), function()
	if applyMode("Light") then
		statusLabel.Text = "Leve aplicado • cores preservadas"
	end
end)

local collisionButton
collisionButton = makeButton("Collision", "COLISÃO AMBIENTAL: OFF", 179, 28, Color3.fromRGB(91, 78, 111), function()
	setCollisionEnabled(not collisionEnabled)
	collisionButton.Text = collisionEnabled and "COLISÃO AMBIENTAL: ON" or "COLISÃO AMBIENTAL: OFF"
	statusLabel.Text = collisionEnabled
		and "Colisão local desativada em peças ambientais elegíveis"
		or "Colisão original restaurada"
end)

local monitorButton
monitorButton = makeButton("Monitor", "MONITOR FPS: ON", 211, 28, Color3.fromRGB(75, 79, 96), function()
	monitorEnabled = not monitorEnabled
	monitorButton.Text = monitorEnabled and "MONITOR FPS: ON" or "MONITOR FPS: OFF"
	if not monitorEnabled then
		if monitorConnection then
			monitorConnection:Disconnect()
			monitorConnection = nil
		end
		fpsLabel.Text = "FPS: monitor desligado"
	else
		fpsLabel.Text = "FPS: --"
	end
end)

makeButton("Restore", "↩  RESTAURAR ORIGINAL", 243, 29, Color3.fromRGB(105, 68, 62), function()
	restoreAll()
	collisionButton.Text = "COLISÃO AMBIENTAL: OFF"
	statusLabel.Text = "Configurações originais restauradas"
end)

local footnote = makeLabel(
	"Footnote",
	"FPS estimado • colisão local não garantida pelo servidor",
	UDim2.fromOffset(10, 278),
	UDim2.fromOffset(230, 34),
	9
)
footnote.TextColor3 = Color3.fromRGB(145, 157, 177)

local miniButton = Instance.new("TextButton")
miniButton.Name = "ShowPanel"
miniButton.Size = UDim2.fromOffset(48, 42)
miniButton.Position = UDim2.new(0, 12, 0, 92)
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

local frames = 0
local elapsed = 0

local function startMonitor()
	if monitorConnection or not monitorEnabled or destroyed then
		return
	end

	monitorConnection = RunService.RenderStepped:Connect(function(deltaTime)
		if destroyed or not monitorEnabled then
			return
		end

		frames += 1
		elapsed += deltaTime
		if elapsed >= 1 then
			local fps = math.floor(frames / elapsed + 0.5)
			fpsLabel.Text = "FPS: " .. tostring(fps) .. " • estimativa local"
			frames = 0
			elapsed = 0
		end
	end)
end

monitorButton.Activated:Connect(function()
	if monitorEnabled then
		-- The callback above toggles the state; this branch is reached when re-enabled.
		startMonitor()
	else
		frames = 0
		elapsed = 0
	end
end)

startMonitor()
print("[UltraBoost] v0.3.0 loaded. Choose Ultra, Equilibrado or Leve.")
