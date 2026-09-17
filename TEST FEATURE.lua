-- ============================================
-- ANTI-FIELD V8 (Area Detection Teleport)
-- Pagdating sa Forest area, auto-teleport sa base
-- ============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============ SETTINGS ============
local START_POS = Vector3.new(519.155, 70.576, -356.103) -- Base position mo
local TRIGGER_AREA = "Forest"  -- Area kung saan mag-te-teleport
local TP_COOLDOWN = 3          -- Cooldown between teleports

-- ============ EGG STATE ============
local EggState = nil

local function loadEggState()
    if EggState then return true end
    local ok = pcall(function()
        local client = ReplicatedStorage:FindFirstChild("Client")
        if client then
            local es = client:FindFirstChild("EggState")
            if es then EggState = require(es) end
        end
    end)
    return ok and EggState ~= nil
end

-- ============ HANAPIN YUNG AREA NG CHARACTER MO ============
local function getCurrentArea()
    if not EggState then return nil end
    
    local char = LocalPlayer.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    
    -- Hanapin yung area base sa position mo
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil end
    
    -- Hanapin yung pinaka-malapit na area
    local closestArea = nil
    local closestDist = math.huge
    
    for _, rec in ipairs(fieldEggs.Records) do
        if rec.BoundsCFrame and rec.BoundsCFrame.Position then
            local dist = (rec.BoundsCFrame.Position - hrp.Position).Magnitude
            if dist < closestDist then
                closestDist = dist
                closestArea = rec.AreaId
            end
        end
    end
    
    -- Kung malapit lang (within 200 studs)
    if closestDist < 200 then
        return closestArea
    end
    
    return nil
end

-- ============ CHECK KUNG MAY DALA KANG EGG ============
local function hasCarriedEgg()
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Check AssetWeld
    for _, obj in pairs(hrp:GetChildren()) do
        if obj:IsA("WeldConstraint") then
            if obj.Part0 and not obj.Part0:IsDescendantOf(char) then return true end
            if obj.Part1 and not obj.Part1:IsDescendantOf(char) then return true end
        end
    end

    -- Check EggCarryBounds
    local carryBounds = Workspace:FindFirstChild("EggCarryBounds")
    if carryBounds then
        for _, obj in pairs(carryBounds:GetDescendants()) do
            if obj:IsA("BasePart") then
                local dist = (obj.Position - hrp.Position).Magnitude
                if dist < 25 then return true end
            end
        end
    end

    return false
end

-- ============ MAIN LOGIC ============
local antiFieldEnabled = false
local antiFieldConn = nil
local teleportCooldown = 0
local lastArea = nil

local function startAntiField()
    if not loadEggState() then
        return false, "EggState not found"
    end

    antiFieldConn = RunService.Heartbeat:Connect(function()
        if not antiFieldEnabled then return end
        
        -- Check cooldown
        if tick() - teleportCooldown < TP_COOLDOWN then return end
        
        local c = LocalPlayer.Character
        if not c then return end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local carrying = hasCarriedEgg()
        if not carrying then return end

        -- Hanapin yung current area
        local currentArea = getCurrentArea()
        
        if currentArea then
            -- Check kung nasa trigger area na
            if currentArea == TRIGGER_AREA then
                print("[AntiField] Detected " .. TRIGGER_AREA .. "! Teleporting to base...")
                
                teleportCooldown = tick()
                
                pcall(function()
                    c:PivotTo(CFrame.new(START_POS))
                    hrp.CFrame = CFrame.new(START_POS)
                end)
                
                print("[AntiField] Teleported to base! Cooldown active.")
            end
            
            -- I-log yung area changes (para sa debug)
            if lastArea ~= currentArea then
                print("[AntiField] Area changed: " .. tostring(lastArea) .. " -> " .. currentArea)
                lastArea = currentArea
            end
        end
    end)

    return true
end

local function stopAntiField()
    if antiFieldConn then
        antiFieldConn:Disconnect()
        antiFieldConn = nil
    end
end

-- ============ UI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AntiFieldUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 280, 0, 160)
Main.Position = UDim2.new(0.5, -140, 0.2, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 25)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
Title.Text = "🚀 ANTI-FIELD V8 (Area TP)"
Title.TextColor3 = Color3.fromRGB(255, 200, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 11
Title.Parent = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 8)

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 35)
ToggleBtn.Position = UDim2.new(0, 10, 0, 30)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "AUTO-TP: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = Main
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 16)
Info.Position = UDim2.new(0, 10, 0, 70)
Info.BackgroundTransparency = 1
Info.Text = "Current Area: --"
Info.TextColor3 = Color3.fromRGB(100, 200, 255)
Info.TextSize = 10
Info.Font = Enum.Font.Code
Info.Parent = Main

local Info2 = Instance.new("TextLabel")
Info2.Size = UDim2.new(1, -20, 0, 16)
Info2.Position = UDim2.new(0, 10, 0, 88)
Info2.BackgroundTransparency = 1
Info2.Text = "Carrying: -- | Speed: --"
Info2.TextColor3 = Color3.fromRGB(100, 200, 255)
Info2.TextSize = 10
Info2.Font = Enum.Font.Code
Info2.Parent = Main

local Info3 = Instance.new("TextLabel")
Info3.Size = UDim2.new(1, -20, 0, 16)
Info3.Position = UDim2.new(0, 10, 0, 106)
Info3.BackgroundTransparency = 1
Info3.Text = "Trigger: " .. TRIGGER_AREA .. " | Cooldown: " .. TP_COOLDOWN .. "s"
Info3.TextColor3 = Color3.fromRGB(150, 150, 150)
Info3.TextSize = 9
Info3.Font = Enum.Font.Code
Info3.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 16)
Status.Position = UDim2.new(0, 10, 0, 124)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(255, 200, 0)
Status.TextSize = 9
Status.Font = Enum.Font.Gotham
Status.Parent = Main

local Info4 = Instance.new("TextLabel")
Info4.Size = UDim2.new(1, -20, 0, 14)
Info4.Position = UDim2.new(0, 10, 0, 142)
Info4.BackgroundTransparency = 1
Info4.Text = "Base: " .. tostring(START_POS)
Info4.TextColor3 = Color3.fromRGB(150, 150, 150)
Info4.TextSize = 8
Info4.Font = Enum.Font.Code
Info4.Parent = Main

-- ============ LIVE INFO ============
task.spawn(function()
    while true do
        task.wait(0.3)
        if antiFieldEnabled then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local carrying = hasCarriedEgg()
                    local currentArea = getCurrentArea() or "Unknown"
                    local cooldownLeft = math.max(0, TP_COOLDOWN - (tick() - teleportCooldown))
                    
                    Info.Text = "Current Area: " .. currentArea
                    Info.TextColor3 = currentArea == TRIGGER_AREA and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 100)
                    
                    Info2.Text = string.format("Carrying: %s | Speed: %.0f",
                        carrying and "YES ✅" or "NO", hum.WalkSpeed)
                    Info2.TextColor3 = carrying and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 150)
                    
                    if cooldownLeft > 0 then
                        Status.Text = string.format("⏱️ Cooldown: %.1fs", cooldownLeft)
                        Status.TextColor3 = Color3.fromRGB(255, 200, 0)
                    else
                        Status.Text = "✅ Ready"
                        Status.TextColor3 = Color3.fromRGB(100, 255, 100)
                    end
                end
            end
        end
    end
end)

-- ============ TOGGLE ============
ToggleBtn.MouseButton1Click:Connect(function()
    antiFieldEnabled = not antiFieldEnabled

    if antiFieldEnabled then
        ToggleBtn.Text = "AUTO-TP: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)

        local ok, err = startAntiField()
        if not ok then
            Info.Text = "❌ " .. tostring(err)
            Info.TextColor3 = Color3.fromRGB(255, 100, 100)
            antiFieldEnabled = false
            ToggleBtn.Text = "AUTO-TP: OFF"
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        end
    else
        ToggleBtn.Text = "AUTO-TP: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        stopAntiField()
    end
end)
