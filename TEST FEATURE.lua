-- ==========================================
-- UNDERGROUND SCRIPT V5 (Manual Trigger + Anti-Death)
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ==========================================
-- SAFE CHARACTER SETUP (Walang Auto-Execute)
-- ==========================================
local character, humanoid, rootPart

local function setupCharacter()
    character = player.Character
    if not character then
        character = player.CharacterAdded:Wait()
    end
    
    humanoid = character:WaitForChild("Humanoid", 10)
    rootPart = character:WaitForChild("HumanoidRootPart", 10)
    
    return humanoid and rootPart
end

-- I-setup yung character ngayon
if not setupCharacter() then
    warn("Hindi mahanap ang Humanoid o RootPart. Script stopped.")
    return
end

-- SETTINGS
local OFFSET = 3 -- 3 studs muna tayo para safe
local isUnderground = false
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
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = state
        end
    end
end

-- ==========================================
-- TOGGLE LOGIC (Ikaw ang mag-ti-trigger)
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    if not character or not character.Parent then
        -- Kung patay ka, wag gawin
        ToggleBtn.Text = "PATAY KA BRO!"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        return
    end

    isUnderground = not isUnderground
    
    if isUnderground then
        -- ON
        ToggleBtn.Text = "UNDERGROUND: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        SetCollision(false)
        
        -- I-force pababa (dahan-dahan lang)
        rootPart.CFrame = CFrame.new(rootPart.Position.X, targetY, rootPart.Position.Z)
        rootPart.Velocity = Vector3.new(0, 0, 0)
    else
        -- OFF
        ToggleBtn.Text = "UNDERGROUND: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        SetCollision(true)
        
        -- Ibalik sa original Y
        rootPart.CFrame = CFrame.new(rootPart.Position.X, originalY, rootPart.Position.Z)
    end
end)

-- ==========================================
-- MAIN LOOP
-- ==========================================
RunService.RenderStepped:Connect(function()
    if isUnderground and character and character.Parent and rootPart then
        local currentPos = rootPart.Position
        rootPart.CFrame = CFrame.new(currentPos.X, targetY, currentPos.Z)
        rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z)
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
    
    -- Reset UI
    isUnderground = false
    ToggleBtn.Text = "UNDERGROUND: OFF"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    
    if isUnderground then
        SetCollision(false)
        rootPart.CFrame = CFrame.new(rootPart.Position.X, targetY, rootPart.Position.Z)
    end
end)
