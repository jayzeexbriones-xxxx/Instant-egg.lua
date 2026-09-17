-- ==========================================
-- UNDERGROUND SCRIPT V2 (Stable + UI Toggle)
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- SETTINGS
local OFFSET = 5 -- Ilang studs pababa? (Palitan mo kung gusto mo mas malalim)
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
ToggleBtn.TextSize = 13
ToggleBtn.Parent = MainFrame

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = ToggleBtn

-- ==========================================
-- BODY POSITION SETUP (Anti-Bug 2 Studs)
-- ==========================================
local bodyPos = Instance.new("BodyPosition")
bodyPos.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
bodyPos.P = 10000 -- Lakas ng paghatak pababa
bodyPos.D = 500   -- Damping (para hindi mag-vibrate)
bodyPos.Parent = rootPart
bodyPos.Enabled = false -- Naka-off muna

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
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Green = On
        SetCollision(false)
        
        -- Disable falling state para hindi mamatay
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        
        -- I-activate yung BodyPosition
        bodyPos.Position = Vector3.new(rootPart.Position.X, targetY, rootPart.Position.Z)
        bodyPos.Enabled = true
    else
        -- OFF
        ToggleBtn.Text = "UNDERGROUND: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red = Off
        SetCollision(true)
        
        -- Ibalik sa normal
        humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        
        -- I-deactivate yung BodyPosition at ibalik sa original Y
        bodyPos.Enabled = false
        rootPart.CFrame = CFrame.new(rootPart.Position.X, originalY, rootPart.Position.Z)
    end
end)

-- ==========================================
-- MAIN LOOP (Para manatili sa ilalim)
-- ==========================================
RunService.RenderStepped:Connect(function()
    if isUnderground and bodyPos.Enabled then
        -- I-lock yung Y sa targetY, pero hayaan yung X at Z na sumunod sa movement mo
        bodyPos.Position = Vector3.new(rootPart.Position.X, targetY, rootPart.Position.Z)
    end
end)

-- ==========================================
-- RESPAWN HANDLER
-- ==========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- I-update ang original Y base sa bagong character
    originalY = rootPart.Position.Y
    targetY = originalY - OFFSET
    
    -- I-reparent yung BodyPosition sa bagong RootPart
    bodyPos.Parent = rootPart
    bodyPos.Enabled = false
    
    -- Kung naka-ON pa rin, i-apply agad
    if isUnderground then
        SetCollision(false)
        bodyPos.Position = Vector3.new(rootPart.Position.X, targetY, rootPart.Position.Z)
        bodyPos.Enabled = true
    end
end)
