-- ==========================================
-- UNDERGROUND SCRIPT V3 (Fixed Toggle + Stable)
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- SETTINGS
local OFFSET = 5 -- Ilang studs pababa?
local isUnderground = false

-- Kuhanin ang Original Y Position
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
MainFrame.Size = UDim2.new(0, 160, 0, 55)
MainFrame.Position = UDim2.new(0.5, -80, 0.2, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 1, -20)
ToggleBtn.Position = UDim2.new(0, 10, 0, 10)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "UNDERGROUND: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 13
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- ==========================================
-- FUNCTIONS
-- ==========================================
local function SetCollision(state)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

-- ==========================================
-- TOGGLE LOGIC
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    isUnderground = not isUnderground
    
    if isUnderground then
        -- ON
        ToggleBtn.Text = "UNDERGROUND: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        SetCollision(false)
        
        -- Disable falling state para hindi mamatay
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        
        -- I-force agad pababa
        rootPart.CFrame = CFrame.new(rootPart.Position.X, targetY, rootPart.Position.Z)
        rootPart.Velocity = Vector3.new(0, 0, 0)
    else
        -- OFF
        ToggleBtn.Text = "UNDERGROUND: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        SetCollision(true)
        
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        
        -- Ibalik sa original Y
        rootPart.CFrame = CFrame.new(rootPart.Position.X, originalY, rootPart.Position.Z)
    end
end)

-- ==========================================
-- MAIN LOOP (Pinaka-importante para hindi umangat)
-- ==========================================
RunService.RenderStepped:Connect(function()
    if isUnderground and character and character.Parent then
        local currentPos = rootPart.Position
        
        -- I-force yung Y position pababa
        rootPart.CFrame = CFrame.new(currentPos.X, targetY, currentPos.Z)
        
        -- I-lock yung velocity para hindi mag-fall o mag-jump
        rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
        
        -- I-set yung Humanoid state sa Running para hindi mag-fall
        if humanoid.FloorMaterial == Enum.Material.Air then
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end)

-- ==========================================
-- RESPAWN HANDLER
-- ==========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    originalY = rootPart.Position.Y
    targetY = originalY - OFFSET
    
    if isUnderground then
        SetCollision(false)
        rootPart.CFrame = CFrame.new(rootPart.Position.X, targetY, rootPart.Position.Z)
    end
end)
