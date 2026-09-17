-- ==========================================
-- UNDERGROUND SCRIPT WITH UI TOGGLE
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- SETTINGS
local OFFSET = 5 -- Ilang studs pababa? (5 studs default)
local isUnderground = false -- Status ng script

-- Kunin ang Original Y Position
local originalY = rootPart.Position.Y 
local targetY = originalY - OFFSET

-- ==========================================
-- GUMAWA NG UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UndergroundUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 150, 0, 50)
MainFrame.Position = UDim2.new(0.5, -75, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true -- Pwedeng hilahin
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 1, -20)
ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red = Off
ToggleBtn.Text = "UNDERGROUND: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- ==========================================
-- LOGIC NG SCRIPT
-- ==========================================

local function SetCollision(state)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

ToggleBtn.MouseButton1Click:Connect(function()
    isUnderground = not isUnderground
    
    if isUnderground then
        -- ON
        ToggleBtn.Text = "UNDERGROUND: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Green = On
        SetCollision(false)
        
        -- Disable falling state para hindi mamatay
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    else
        -- OFF
        ToggleBtn.Text = "UNDERGROUND: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red = Off
        SetCollision(true)
        
        -- Ibalik sa normal
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        
        -- I-reset pabalik sa original Y
        rootPart.CFrame = CFrame.new(rootPart.Position.X, originalY, rootPart.Position.Z)
    end
end)

-- ==========================================
-- MAIN LOOP (Para hindi mabalik ng server sa taas)
-- ==========================================
RunService.RenderStepped:Connect(function()
    if isUnderground and character and character.Parent then
        local currentPos = rootPart.Position
        -- I-force ang position sa ilalim
        rootPart.CFrame = CFrame.new(currentPos.X, targetY, currentPos.Z)
        -- I-set velocity para hindi mag-fall nang tuloy-tuloy
        rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
    end
end)

-- ==========================================
-- PARA SA MGA NAG-RERESPAWN
-- ==========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- I-update ang original Y base sa bagong character
    originalY = rootPart.Position.Y
    targetY = originalY - OFFSET
    
    -- Kung naka-ON pa rin, i-apply agad
    if isUnderground then
        SetCollision(false)
    end
end)
