-- ==========================================
-- NOCLIP / WALLHACK SCRIPT
-- ==========================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- SETTINGS
local noclipEnabled = false

-- ==========================================
-- GUMAWA NG UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NoclipUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 150, 0, 45)
ToggleBtn.Position = UDim2.new(0.5, -75, 0.15, 0)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "NOCLIP: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Active = true
ToggleBtn.Draggable = true -- Pwedeng hilahin
ToggleBtn.Parent = ScreenGui

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

-- ==========================================
-- TOGGLE LOGIC
-- ==========================================
ToggleBtn.MouseButton1Click:Connect(function()
    noclipEnabled = not noclipEnabled
    
    if noclipEnabled then
        ToggleBtn.Text = "NOCLIP: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Green
    else
        ToggleBtn.Text = "NOCLIP: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red
    end
end)

-- ==========================================
-- NOCLIP LOOP (Ito yung pumapatay sa collision)
-- ==========================================
RunService.Stepped:Connect(function()
    if noclipEnabled and character and character.Parent then
        for _, part in pairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ==========================================
-- RESPAWN HANDLER (Para hindi mawala yung UI)
-- ==========================================
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    humanoid = character:WaitForChild("Humanoid")
    
    -- Reset yung button pag respawn
    noclipEnabled = false
    ToggleBtn.Text = "NOCLIP: OFF"
    ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
end)
