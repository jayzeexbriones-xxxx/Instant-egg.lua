local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer

-- UI setup
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 150)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Active = true
MainFrame.Parent = ScreenGui

local ToggleMenuButton = Instance.new("TextButton")
ToggleMenuButton.Size = UDim2.new(1, -20, 0, 30)
ToggleMenuButton.Position = UDim2.new(0, 10, 0, 10)
ToggleMenuButton.Text = "MENU ON"
ToggleMenuButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleMenuButton.TextColor3 = Color3.new(1, 1, 1)
ToggleMenuButton.Parent = MainFrame

local SpeedToggleButton = Instance.new("TextButton")
SpeedToggleButton.Size = UDim2.new(0.5, -15, 0, 40)
SpeedToggleButton.Position = UDim2.new(0, 10, 0, 50)
SpeedToggleButton.Text = "Speed OFF"
SpeedToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
SpeedToggleButton.TextColor3 = Color3.new(1, 1, 1)
SpeedToggleButton.Parent = MainFrame

local InstantGrabToggleButton = Instance.new("TextButton")
InstantGrabToggleButton.Size = UDim2.new(0.5, -15, 0, 40)
InstantGrabToggleButton.Position = UDim2.new(0.5, 5, 0, 50)
InstantGrabToggleButton.Text = "Instant Grab OFF"
InstantGrabToggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
InstantGrabToggleButton.TextColor3 = Color3.new(1, 1, 1)
InstantGrabToggleButton.Parent = MainFrame

-- Variables
local menuEnabled = true
local speedActive = false
local instantGrabActive = false
local defaultWalkSpeed = 16
local speedValue = 300

-- Toggle menu ON/OFF
ToggleMenuButton.MouseButton1Click:Connect(function()
    menuEnabled = not menuEnabled
    MainFrame.Visible = menuEnabled
    if menuEnabled then
        ToggleMenuButton.Text = "MENU ON"
    else
        ToggleMenuButton.Text = "MENU OFF"
    end
end)

-- Speed toggle
SpeedToggleButton.MouseButton1Click:Connect(function()
    local humanoid = nil
    if LocalPlayer.Character then
        humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    if humanoid then
        speedActive = not speedActive
        if speedActive then
            humanoid.WalkSpeed = speedValue
            SpeedToggleButton.Text = "Speed ON"
        else
            humanoid.WalkSpeed = defaultWalkSpeed
            SpeedToggleButton.Text = "Speed OFF"
        end
    end
end)

-- Instant Grab toggle
InstantGrabToggleButton.MouseButton1Click:Connect(function()
    instantGrabActive = not instantGrabActive
    if instantGrabActive then
        InstantGrabToggleButton.Text = "Instant Grab ON"
    else
        InstantGrabToggleButton.Text = "Instant Grab OFF"
    end
end)

-- Reset speed on respawn
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    wait(1)
    local humanoid = nil
    if game.Players.LocalPlayer.Character then
        humanoid = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    if humanoid then
        humanoid.WalkSpeed = defaultWalkSpeed
    end
end)

-- Automate speed
RunService.Stepped:Connect(function()
    if speedActive then
        local humanoid = nil
        if LocalPlayer.Character then
            humanoid = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        end
        if humanoid then
            humanoid.WalkSpeed = speedValue
        end
    end
end)

-- Instant Grab functionality
game:GetService("RunService").Heartbeat:Connect(function()
    if instantGrabActive then
        local character = LocalPlayer.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end
        for _, target in pairs(workspace:GetChildren()) do
            if target:FindFirstChildOfClass("Humanoid") and target ~= character then
                local targetRoot = target:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local distance = (targetRoot.Position - rootPart.Position).magnitude
                    if distance < 50 then
                        target.Humanoid:TakeDamage(99999)
                    end
                end
            end
        end
    end
end)

-- Draggable UI logic
local dragging = false
local dragStart, startPos

local function makeDraggable(frame, dragHandle)
    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    dragHandle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

makeDraggable(MainFrame, MainFrame) -- Draggable ang mismong main frame

print("🍭 Speed Hack at ON/OFF, Instant Grab at ON/OFF, draggable UI")
