local UserInputService = game:GetService("UserInputService")
local dragging = false
local dragInput, dragStart, startPos

-- UI setup
local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local ToggleButton = Instance.new("TextButton")
local SpeedButton = Instance.new("TextButton")
local InstantHitButton = Instance.new("TextButton")

ScreenGui.Parent = game.CoreGui

MainFrame.Size = UDim2.new(0, 300, 0, 130)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -65)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Active = true
MainFrame.Draggable = false -- Hindi pa draggable, manual control
MainFrame.Parent = ScreenGui

-- ON/OFF Toggle Button
ToggleButton.Size = UDim2.new(1, -20, 0, 30)
ToggleButton.Position = UDim2.new(0, 10, 0, 10)
ToggleButton.Text = "MENU ON"
ToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleButton.TextColor3 = Color3.new(1, 1, 1)
ToggleButton.Parent = MainFrame

-- Speed Button
SpeedButton.Size = UDim2.new(0.5, -15, 1, -40)
SpeedButton.Position = UDim2.new(0, 10, 0, 40)
SpeedButton.Text = "Speed 300"
SpeedButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SpeedButton.TextColor3 = Color3.new(1, 1, 1)
SpeedButton.Parent = MainFrame

-- Instant Hit Button
InstantHitButton.Size = UDim2.new(0.5, -15, 1, -40)
InstantHitButton.Position = UDim2.new(0.5, 5, 0, 40)
InstantHitButton.Text = "Instant Hit"
InstantHitButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
InstantHitButton.TextColor3 = Color3.new(1, 1, 1)
InstantHitButton.Parent = MainFrame

-- Variables
local menuEnabled = true
local autoSpeed = false
local autoHit = false
local defaultSpeed = 16

-- Functions
local function getHumanoid()
    if game.Players.LocalPlayer.Character then
        return game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- Toggle menu ON/OFF
ToggleButton.MouseButton1Click:Connect(function()
    menuEnabled = not menuEnabled
    MainFrame.Visible = menuEnabled
    if menuEnabled then
        ToggleButton.Text = "MENU ON"
    else
        ToggleButton.Text = "MENU OFF"
    end
end)

-- Speed Button action
SpeedButton.MouseButton1Click:Connect(function()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 400
        autoSpeed = true
    end
end)

-- Instant Hit Button action
InstantHitButton.MouseButton1Click:Connect(function()
    local character = game.Players.LocalPlayer.Character
    if character and character:FindFirstChild("Head") then
        for _, target in pairs(workspace:GetChildren()) do
            if target:FindFirstChildOfClass("Humanoid") and target:FindFirstChild("Head") then
                local distance = (target.Head.Position - character.Head.Position).magnitude
                if distance < 50 then
                    target.Humanoid:TakeDamage(99999)
                end
            end
        end
        autoHit = true
    end
end)

-- Reset speed on respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = defaultSpeed
        autoSpeed = false
    end
end)

-- Automate speed
game:GetService("RunService").Stepped:Connect(function()
    if autoSpeed then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = 400
        end
    end
end)

-- Draggable UI logic
MainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
