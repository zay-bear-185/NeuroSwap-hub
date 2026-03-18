--[[
	WARNING: Heads up! This script has not been verified by ScriptBlox. Use at your own risk!
]]
-- // NEUROSWAP HUB - Rayfield UI Script
-- // Aimbot | ESP | Speed | Fly

local success, err = pcall(function()

-- Load Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- =====================
-- STATE
-- =====================
local AimbotEnabled = false
local AimbotFOV = 50
local AimbotKeybind = Enum.UserInputType.MouseButton2
local FOVCircleVisible = true
local VisibilityCheck = false

local SpeedEnabled = false
local SpeedValue = 50

local FlyEnabled = false
local FlySpeed = 50
local FlyBodyVelocity = nil
local FlyBodyGyro = nil

local BoxESPEnabled = false
local ESPBoxes = {}

-- =====================
-- FOV CIRCLE
-- =====================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Color = Color3.fromRGB(255, 80, 80)
FOVCircle.Thickness = 1.5
FOVCircle.NumSides = 64
FOVCircle.Radius = AimbotFOV
FOVCircle.Filled = false
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- =====================
-- UTILITY FUNCTIONS
-- =====================

local function GetCharacter(player)
    return player and player.Character
end
local function IsVisible(part)
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin)

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local result = workspace:Raycast(origin, direction, rayParams)

    if result and result.Instance then
        return result.Instance:IsDescendantOf(part.Parent)
    end

    return false
end
local function GetRootPart(player)
    local char = GetCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function GetHead(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChild("Head")
end

local function GetHumanoid(player)
    local char = GetCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function IsAlive(player)
    local hum = GetHumanoid(player)
    return hum and hum.Health > 0
end

local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function GetScreenCenter()
    return Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local closestDist = math.huge
    local center = GetScreenCenter()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not IsAlive(player) then continue end

        local head = GetHead(player)
        if not head then continue end

        local screenPos, onScreen = WorldToScreen(head.Position)
        if not onScreen then continue end
if VisibilityCheck and not IsVisible(head) then continue end

        local dist = (screenPos - center).Magnitude
        if dist < AimbotFOV and dist < closestDist then
            closestDist = dist
            closestPlayer = player
        end
    end

    return closestPlayer
end

-- =====================
-- AIMBOT LOGIC
-- =====================

local function DoAimbot()
    if not AimbotEnabled then return end

    local isHeld = false
    if AimbotKeybind == Enum.UserInputType.MouseButton2 then
        isHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
    elseif AimbotKeybind == Enum.UserInputType.MouseButton1 then
        isHeld = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
    else
        isHeld = UserInputService:IsKeyDown(AimbotKeybind)
    end

    if not isHeld then return end

    local target = GetClosestPlayerToCursor()
    if not target then return end

    local head = GetHead(target)
    if not head then return end

    local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
Camera.CFrame = Camera.CFrame:Lerp(targetCF, 0.15)
end

-- =====================
-- BOX ESP LOGIC
-- =====================

local function CreateESPBox(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.fromRGB(255, 50, 50)
    box.Thickness = 1
    box.Filled = false

    local nameLabel = Drawing.new("Text")
    nameLabel.Visible = false
    nameLabel.Color = Color3.fromRGB(255, 255, 255)
    nameLabel.Size = 13
    nameLabel.Center = true
    nameLabel.Outline = true
    nameLabel.OutlineColor = Color3.fromRGB(0,0,0)
    nameLabel.Text = player.Name

    ESPBoxes[player] = { box = box, nameLabel = nameLabel }
end

local function RemoveESPBox(player)
    if ESPBoxes[player] then
        ESPBoxes[player].box:Remove()
        ESPBoxes[player].nameLabel:Remove()
        ESPBoxes[player] = nil
    end
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not ESPBoxes[player] then
            CreateESPBox(player)
        end

        local espData = ESPBoxes[player]
        if not espData then continue end

        if not BoxESPEnabled or not IsAlive(player) then
            espData.box.Visible = false
            espData.nameLabel.Visible = false
            continue
        end

        local char = GetCharacter(player)
        if not char then
            espData.box.Visible = false
            espData.nameLabel.Visible = false
            continue
        end

        local rootPart = GetRootPart(player)
        local head = GetHead(player)
        if not rootPart or not head then
            espData.box.Visible = false
            espData.nameLabel.Visible = false
            continue
        end

        -- Calculate bounding box from character
        local topPos, topOnScreen = WorldToScreen(head.Position + Vector3.new(0, 0.7, 0))
        local botPos, botOnScreen = WorldToScreen(rootPart.Position - Vector3.new(0, 3, 0))

        if not topOnScreen or not botOnScreen then
            espData.box.Visible = false
            espData.nameLabel.Visible = false
            continue
        end

        local height = math.abs(botPos.Y - topPos.Y)
        local width = height * 0.6
        local x = topPos.X - width / 2
        local y = topPos.Y

        espData.box.Size = Vector2.new(width, height)
        espData.box.Position = Vector2.new(x, y)
        espData.box.Visible = true

        espData.nameLabel.Position = Vector2.new(topPos.X, y - 16)
        espData.nameLabel.Visible = true
    end
end

Players.PlayerRemoving:Connect(RemoveESPBox)
Players.PlayerAdded:Connect(function(player)
    CreateESPBox(player)
end)
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPBox(player)
    end
end

-- =====================
-- FLY LOGIC
-- =====================

local function EnableFly()
    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local hum = GetHumanoid(LocalPlayer)
    if hum then hum.PlatformStand = true end

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    FlyBodyVelocity.P = 1e4
    FlyBodyVelocity.Parent = root

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    FlyBodyGyro.P = 1e4
    FlyBodyGyro.CFrame = root.CFrame
    FlyBodyGyro.Parent = root
end

local function DisableFly()
    if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro = nil end

    local char = LocalPlayer.Character
    if char then
        local hum = GetHumanoid(LocalPlayer)
        if hum then hum.PlatformStand = false end
    end
end

local function UpdateFly()
    if not FlyEnabled or not FlyBodyVelocity or not FlyBodyGyro then return end

    local char = LocalPlayer.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local moveDir = Vector3.zero
    local camCF = Camera.CFrame

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0,1,0) end

    if moveDir.Magnitude > 0 then
        FlyBodyVelocity.Velocity = moveDir.Unit * FlySpeed
    else
        FlyBodyVelocity.Velocity = Vector3.zero
    end

    FlyBodyGyro.CFrame = camCF
end

-- =====================
-- SPEED LOGIC
-- =====================

local SpeedConnection = nil

local function EnableSpeed()
    SpeedConnection = RunService.Heartbeat:Connect(function()
        if not SpeedEnabled then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = SpeedValue end
    end)
end

local function DisableSpeed()
    if SpeedConnection then SpeedConnection:Disconnect(); SpeedConnection = nil end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

EnableSpeed()

-- =====================
-- RUNSERVICE LOOP
-- =====================

RunService.RenderStepped:Connect(function()
    -- Update FOV circle position
    FOVCircle.Position = GetScreenCenter()
    FOVCircle.Radius = AimbotFOV

    -- Aimbot
    DoAimbot()

    -- Fly
    UpdateFly()

    -- ESP
    UpdateESP()
end)

-- =====================
-- RAYFIELD UI
-- =====================

local Window = Rayfield:CreateWindow({
    Name = "NeuroSwap",
    LoadingTitle = "NeuroSwap",
    LoadingSubtitle = "Loading Features...",
    Theme = "Ocean", -- cleaner blue theme
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false,
})

-- =====================
-- TAB: AIMBOT
-- =====================

local AimbotTab = Window:CreateTab("Aimbot", "crosshair")

-- Enable Aimbot
AimbotTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = false,
    Callback = function(val)
        AimbotEnabled = val
        FOVCircle.Visible = val and FOVCircleVisible
    end,
})

-- Visibility Check
AimbotTab:CreateToggle({
    Name = "Visibility Check",
    CurrentValue = false,
    Callback = function(val)
        VisibilityCheck = val
    end,
})

-- FOV Circle
AimbotTab:CreateToggle({
    Name = "Show FOV Circle",
    CurrentValue = true,
    Callback = function(val)
        FOVCircleVisible = val
        FOVCircle.Visible = AimbotEnabled and val
    end,
})

-- FOV Size
AimbotTab:CreateSlider({
    Name = "FOV Size",
    Range = {50, 500},
    Increment = 5,
    CurrentValue = 50,
    Callback = function(val)
        AimbotFOV = val
    end,
})
AimbotTab:CreateParagraph({
    Title = "Aimbot Info",
    Content = "Hold your selected keybind to activate aimbot. Targets the closest enemy within the FOV circle. Default keybind: MouseButton2 (Right Click).",
})

-- =====================
-- TAB: ESP
-- =====================

local ESPTab = Window:CreateTab("ESP", "eye")

ESPTab:CreateToggle({
    Name = "Box ESP",
    CurrentValue = false,
    Flag = "BoxESPToggle",
    Callback = function(val)
        BoxESPEnabled = val
        if not val then
            for _, espData in pairs(ESPBoxes) do
                espData.box.Visible = false
                espData.nameLabel.Visible = false
            end
        end
    end,
})

ESPTab:CreateColorPicker({
    Name = "ESP Box Color",
    Color = Color3.fromRGB(255, 50, 50),
    Flag = "ESPColorPicker",
    Callback = function(color)
        for _, espData in pairs(ESPBoxes) do
            espData.box.Color = color
        end
    end,
})

ESPTab:CreateParagraph({
    Title = "ESP Info",
    Content = "Box ESP draws rectangles around all visible players with their name displayed above.",
})

-- =====================
-- TAB: MOVEMENT
-- =====================

local MovementTab = Window:CreateTab("Movement", "zap")

MovementTab:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(val)
        SpeedEnabled = val
        if not val then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 500},
    Increment = 1,
    Suffix = " studs/s",
    CurrentValue = 50,
    Flag = "SpeedSlider",
    Callback = function(val)
        SpeedValue = val
        if SpeedEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end
    end,
})

MovementTab:CreateDivider()

MovementTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "FlyToggle",
    Callback = function(val)
        FlyEnabled = val
        if val then
            EnableFly()
        else
            DisableFly()
        end
    end,
})

MovementTab:CreateSlider({
    Name = "Fly Speed",
    Range = {10, 300},
    Increment = 5,
    Suffix = " studs/s",
    CurrentValue = 50,
    Flag = "FlySpeedSlider",
    Callback = function(val)
        FlySpeed = val
    end,
})

MovementTab:CreateParagraph({
    Title = "Fly Controls",
    Content = "W/A/S/D to move. Space to go up. Left Shift to go down. Camera direction controls your flight path.",
})

-- =====================
-- TAB: SETTINGS
-- =====================

local SettingsTab = Window:CreateTab("Settings", "settings")

SettingsTab:CreateButton({
    Name = "Reset Character",
    Callback = function()
        LocalPlayer:LoadCharacter()
        FlyEnabled = false
        DisableFly()
    end,
})

SettingsTab:CreateButton({
    Name = "Destroy GUI",
    Callback = function()
        FOVCircle:Remove()
        for _, espData in pairs(ESPBoxes) do
            espData.box:Remove()
            espData.nameLabel:Remove()
        end
        Rayfield:Destroy()
    end,
})

SettingsTab:CreateParagraph({
    Title = "https://discord.gg/nHUkW96x",
    Content = "Version 1.0 | Made with Rayfield UI\nFeatures: Aimbot, Box ESP, Speed Hack, Fly\nUse responsibly.",
})

-- Character respawn handling
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if FlyEnabled then
        EnableFly()
    end
end)

-- Cleanup on script end
game:GetService("Players").LocalPlayer.AncestryChanged:Connect(function()
    pcall(function()
        FOVCircle:Remove()
        for _, espData in pairs(ESPBoxes) do
            espData.box:Remove()
            espData.nameLabel:Remove()
        end
    end)
end)

Rayfield:LoadConfiguration()

end)

if not success then
    warn("NEUROSWAP HUB error: " .. tostring(err))
end
