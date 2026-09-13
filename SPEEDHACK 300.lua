--LEAKED BY MIIA
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

NS = 60                -- Normal speed[span_0](start_span)[span_0](end_span)
CS = 30                -- Carry speed[span_1](start_span)[span_1](end_span)
LAGGER_SPEED = 40      -- Lagger normal speed[span_2](start_span)[span_2](end_span)
LAGGER_CARRY_SPEED = 20 -- Lagger carry speed[span_3](start_span)[span_3](end_span)

speedMode = false      -- true = use CS (Carry)[span_4](start_span)[span_4](end_span)
laggerToggled = false  -- true = Lagger mode active[span_5](start_span)[span_5](end_span)
laggerPhase = 0        -- 0 = off, 1 = Lagger normal, 2 = Lagger carry[span_6](start_span)[span_6](end_span)

autoCarrySpeedEnabled = false  -- optional auto‑carry[span_7](start_span)[span_7](end_span)
antiRagdollEnabled = true      -- keeps you upright[span_8](start_span)[span_8](end_span)

-- ============================================================
--  PREMIUM GUI OLUŞTURMA (Anomaly Hub Speed Boost)
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnomalyHub_UltraUI"
ScreenGui.ResetOnSpawn = false

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LP:WaitForChild("PlayerGui")
end

-- Dış Ana Çerçeve
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 190)
MainFrame.Position = UDim2.new(0.5, -140, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(90, 60, 220)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

-- KÖŞELERDEN 7 PİKSEL SİLİNMİŞ / İÇERİ ÇEKİLMİŞ ARKA PLAN GÖRSELİ
local BackgroundImage = Instance.new("ImageLabel")
BackgroundImage.Name = "BackgroundImage"
BackgroundImage.Size = UDim2.new(1, -14, 1, -14) -- Genişlik ve yükseklikten (7px + 7px = 14px) düşüldü
BackgroundImage.Position = UDim2.new(0, 7, 0, 7)     -- Her kenardan 7 piksel içeri çekildi
BackgroundImage.Image = "rbxassetid://114138477258742"
BackgroundImage.ScaleType = Enum.ScaleType.Crop
BackgroundImage.BackgroundTransparency = 1
BackgroundImage.BorderSizePixel = 0
BackgroundImage.ZIndex = 1
BackgroundImage.Parent = MainFrame

local ImageCorner = Instance.new("UICorner")
ImageCorner.CornerRadius = UDim.new(0, 8)
ImageCorner.Parent = BackgroundImage

-- Karartma Katmanı
local Overlay = Instance.new("Frame")
Overlay.Name = "Overlay"
Overlay.Size = UDim2.new(1, 0, 1, 0)
Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
Overlay.BackgroundTransparency = 0.35
Overlay.BorderSizePixel = 0
Overlay.ZIndex = 2
Overlay.Parent = MainFrame

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
Header.BackgroundTransparency = 0.2
Header.BorderSizePixel = 0
Header.ZIndex = 3
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "ANOMALY HUB"
Title.TextColor3 = Color3.fromRGB(160, 130, 255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 4
Title.Parent = Header

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(0, 100, 1, 0)
SubTitle.Position = UDim2.new(1, -110, 0, 0)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "SPEED BOOST"
SubTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.GothamMedium
SubTitle.TextXAlignment = Enum.TextXAlignment.Right
SubTitle.ZIndex = 4
SubTitle.Parent = Header

-- Kutu Oluşturucu Fonksiyon
local function createInputRow(yPos, labelText, defaultValue, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -24, 0, 36)
    Container.Position = UDim2.new(0, 12, 0, yPos)
    Container.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    Container.BackgroundTransparency = 0.25
    Container.BorderSizePixel = 0
    Container.ZIndex = 3
    Container.Parent = MainFrame

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = Container

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.6, 0, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = labelText
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextSize = 12
    Label.Font = Enum.Font.GothamSemibold
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.ZIndex = 4
    Label.Parent = Container

    local Box = Instance.new("TextBox")
    Box.Size = UDim2.new(0, 70, 0, 24)
    Box.Position = UDim2.new(1, -76, 0.5, -12)
    Box.BackgroundColor3 = Color3.fromRGB(35, 35, 48)
    Box.BackgroundTransparency = 0.2
    Box.BorderSizePixel = 0
    Box.Text = tostring(defaultValue)
    Box.TextColor3 = Color3.fromRGB(255, 255, 255)
    Box.TextSize = 12
    Box.Font = Enum.Font.GothamBold
    Box.ZIndex = 4
    Box.Parent = Container

    local BoxCorner = Instance.new("UICorner")
    BoxCorner.CornerRadius = UDim.new(0, 6)
    BoxCorner.Parent = Box

    local BoxStroke = Instance.new("UIStroke")
    BoxStroke.Thickness = 1
    BoxStroke.Color = Color3.fromRGB(90, 60, 220)
    BoxStroke.Parent = Box

    Box.FocusLost:Connect(function()
        local val = tonumber(Box.Text)
        if val then
            callback(val)
        else
            Box.Text = tostring(defaultValue)
        end
    end)

    return Box
end

local NormalBox = createInputRow(52, "Normal Speed", NS, function(val) NS = val end)
local CarryBox = createInputRow(96, "Carry Speed", CS, function(val) CS = val end)

-- Status Bar
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, -24, 0, 30)
StatusFrame.Position = UDim2.new(0, 12, 0, 144)
StatusFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
StatusFrame.BackgroundTransparency = 0.25
StatusFrame.BorderSizePixel = 0
StatusFrame.ZIndex = 3
StatusFrame.Parent = MainFrame

local StatusCorner = Instance.new("UICorner")
StatusCorner.CornerRadius = UDim.new(0, 8)
StatusCorner.Parent = StatusFrame

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, -10, 1, 0)
StatusText.Position = UDim2.new(0, 10, 0, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Mod: NORMAL"
StatusText.TextColor3 = Color3.fromRGB(100, 220, 150)
StatusText.TextSize = 11
StatusText.Font = Enum.Font.GothamBold
StatusText.TextXAlignment = Enum.TextXAlignment.Left
StatusText.ZIndex = 4
StatusText.Parent = StatusFrame

-- ============================================================
--  HELPER FUNCTIONS
-- ============================================================
local MOVE_KEYS = {
    [Enum.KeyCode.W] = true, [Enum.KeyCode.A] = true,
    [Enum.KeyCode.S] = true, [Enum.KeyCode.D] = true,
    [Enum.KeyCode.Up] = true, [Enum.KeyCode.Left] = true,
    [Enum.KeyCode.Down] = true, [Enum.KeyCode.Right] = true,
}

function isRagdollState(hum)
    if not hum then return true end
    local st = hum:GetState()
    return hum.PlatformStand == true
        or st == Enum.HumanoidStateType.Physics
        or st == Enum.HumanoidStateType.Ragdoll
end

function getActiveMoveSpeed()
    local laggerOn = laggerToggled == true
    local laggerCarry = laggerOn and (laggerPhase == 2)

    if speedMode and not laggerOn then
        StatusText.Text = "Mod: CARRY (" .. tostring(CS) .. ")"
        StatusText.TextColor3 = Color3.fromRGB(255, 170, 0)
        return tonumber(CS) or 30
    end
    if laggerOn then
        if laggerCarry then
            StatusText.Text = "Mod: LAGGER CARRY"
            return tonumber(LAGGER_CARRY_SPEED) or 20
        end
        StatusText.Text = "Mod: LAGGER"
        return tonumber(LAGGER_SPEED) or 40
    end
    
    StatusText.Text = "Mod: NORMAL (" .. tostring(NS) .. ")"
    StatusText.TextColor3 = Color3.fromRGB(100, 220, 150)
    return tonumber(NS) or 60
end

-- ============================================================
--  LINEAR VELOCITY & SPOOF ENGINE
-- ============================================================
local _linVel, _linVelAtt0, _linVelAtt1, _linVelChar = nil, nil, nil, nil
local spoofedVelocity = Vector3.zero

local function destroyLinVel()
    if _linVel then pcall(_linVel.Destroy, _linVel) end
    if _linVelAtt0 then pcall(_linVelAtt0.Destroy, _linVelAtt0) end
    if _linVelAtt1 then pcall(_linVelAtt1.Destroy, _linVelAtt1) end
    _linVel, _linVelAtt0, _linVelAtt1, _linVelChar = nil, nil, nil, nil
end

function setupLinearVelocity(char)
    destroyLinVel()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        local ok, res = pcall(function() return char:WaitForChild("HumanoidRootPart", 5) end)
        if ok then hrp = res end
    end
    if not hrp then return end

    local att0 = Instance.new("Attachment")
    att0.Name = "OrvynLinVelAtt0"
    att0.Parent = hrp

    local att1 = Instance.new("Attachment")
    att1.Name = "OrvynLinVelAtt1"
    att1.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Name = "OrvynLinVel"
    lv.Attachment0 = att0
    lv.Attachment1 = att1
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
    lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.MaxForce = 1e6
    lv.PlaneVelocity = Vector2.new(0, 0)
    lv.Parent = hrp

    _linVel = lv
    _linVelAtt0 = att0
    _linVelAtt1 = att1
    _linVelChar = char
end

function setLinVelXZ(x, z)
    if _linVel and _linVel.Parent then
        pcall(function()
            _linVel.PlaneVelocity = Vector2.new(x, z)
        end)
    end
end

function clearLinVel()
    if _linVel and _linVel.Parent then
        pcall(function()
            _linVel.PlaneVelocity = Vector2.new(0, 0)
        end)
    end
end

function ensureLinVel()
    local char = LP.Character
    if not char then return false end
    if _linVel and _linVel.Parent and _linVelChar == char then
        return true
    end
    setupLinearVelocity(char)
    return _linVel ~= nil and _linVel.Parent ~= nil
end

pcall(function()
    if not (getrawmetatable and setreadonly and newcclosure) then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldIndex = mt.__index
    mt.__index = newcclosure(function(self, key)
        if key == "AssemblyLinearVelocity" or key == "Velocity" then
            if typeof(self) == "Instance" and self:IsA("BasePart")
                and self.Name == "HumanoidRootPart"
                and LP.Character and self:IsDescendantOf(LP.Character) then
                return spoofedVelocity
            end
        end
        return oldIndex(self, key)
    end)
    local oldNewIndex = mt.__newindex
    mt.__newindex = newcclosure(function(self, key, value)
        if key == "AssemblyLinearVelocity" or key == "Velocity" then
            if typeof(self) == "Instance" and self:IsA("BasePart")
                and self.Name == "HumanoidRootPart"
                and LP.Character and self:IsDescendantOf(LP.Character) then
                return
            end
        end
        return oldNewIndex(self, key, value)
    end)
    setreadonly(mt, true)
end)

RunService.Heartbeat:Connect(function()
    spoofedVelocity = Vector3.zero
end)

-- ============================================================
--  MAIN MOVEMENT LOOP (RenderStepped)
-- ============================================================
local lastMoveDir = Vector3.zero

RunService.RenderStepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- WALKSPEED DETECT (18 - 25 arası otomatik carry speed)
    local ws = hum.WalkSpeed
    if ws > 18 and ws < 25 then
        speedMode = true
    else
        speedMode = false
    end

    if isRagdollState(hum) then
        lastMoveDir = Vector3.zero
        clearLinVel()
        return
    end

    ensureLinVel()

    local md = hum.MoveDirection
    local spd = getActiveMoveSpeed()

    if md.Magnitude > 0 then
        lastMoveDir = md
        setLinVelXZ(md.X * spd, md.Z * spd)
    elseif antiRagdollEnabled and lastMoveDir.Magnitude > 0 then
        local anyHeld = false
        for key in pairs(MOVE_KEYS) do
            if UIS:IsKeyDown(key) then
                anyHeld = true
                break
            end
        end
        if anyHeld then
            setLinVelXZ(lastMoveDir.X * spd, lastMoveDir.Z * spd)
        else
            clearLinVel()
        end
    else
        clearLinVel()
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    pcall(setupLinearVelocity, char)
end)

task.defer(function()
    if LP.Character then
        task.wait(0.3)
        pcall(setupLinearVelocity, LP.Character)
    end
end)
