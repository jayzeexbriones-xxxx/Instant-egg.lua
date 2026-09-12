local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local SpeedButton = Instance.new("TextButton")
local GoToEggButton = Instance.new("TextButton")
local AutoTeleportToggle = Instance.new("TextButton")
local AutoGrabToggle = Instance.new("TextButton")

-- UI setup
ScreenGui.Parent = game.CoreGui

MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

-- Speed Button (nasa unahan)
SpeedButton.Size = UDim2.new(1, 0, 0, 50)
SpeedButton.Position = UDim2.new(0, 0, 0, 0)
SpeedButton.Text = "Speed 300"
SpeedButton.BackgroundColor3 = Color3.new(0.2, 0.6, 0.2)
SpeedButton.Parent = MainFrame

-- GO TO BEST EGG Button
GoToEggButton.Size = UDim2.new(1, 0, 0, 50)
GoToEggButton.Position = UDim2.new(0, 0, 0.5, 0)
GoToEggButton.Text = "GO TO BEST EGG"
GoToEggButton.BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)
GoToEggButton.Parent = MainFrame

-- AUTO TELEPORT Toggle
AutoTeleportToggle.Size = UDim2.new(1, 0, 0, 50)
AutoTeleportToggle.Position = UDim2.new(0, 0, 1, 0)
AutoTeleportToggle.Text = "AUTO TELEPORT: OFF"
AutoTeleportToggle.BackgroundColor3 = Color3.new(0.8, 0.8, 0.2)
AutoTeleportToggle.Parent = MainFrame

-- AUTO GRAB Toggle
AutoGrabToggle.Size = UDim2.new(1, 0, 0, 50)
AutoGrabToggle.Position = UDim2.new(0, 0, 1.5, 0)
AutoGrabToggle.Text = "AUTO GRAB: OFF"
AutoGrabToggle.BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)
AutoGrabToggle.Parent = MainFrame

-- Functions
local player = game.Players.LocalPlayer

local function getHumanoid()
    if player.Character then
        return player.Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- Speed button action
SpeedButton.MouseButton1Click:Connect(function()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 300
    end
end)

-- GO TO BEST EGG button action
GoToEggButton.MouseButton1Click:Connect(function()
    -- Implement your teleport logic here
    print("Teleporting to best egg...")
    -- Example:
    -- player.Character:MoveTo(Vector3.new(x, y, z))
end)

-- AUTO TELEPORT toggle
local autoTeleportOn = false
AutoTeleportToggle.MouseButton1Click:Connect(function()
    autoTeleportOn = not autoTeleportOn
    if autoTeleportOn then
        AutoTeleportToggle.Text = "AUTO TELEPORT: ON"
    else
        AutoTeleportToggle.Text = "AUTO TELEPORT: OFF"
    end
end)

-- AUTO GRAB toggle
local autoGrabOn = false
AutoGrabToggle.MouseButton1Click:Connect(function()
    autoGrabOn = not autoGrabOn
    if autoGrabOn then
        AutoGrabToggle.Text = "AUTO GRAB: ON"
    else
        AutoGrabToggle.Text = "AUTO GRAB: OFF"
    end
end)

-- Optional: Automate teleportation or grabbing based on toggles
game:GetService("RunService").Stepped:Connect(function()
    if autoTeleportOn then
        -- Auto teleport logic
        -- Example: move to target
    end
    if autoGrabOn then
        -- Auto grab logic
    end
end)

-- Reset speed when character respawns
player.CharacterAdded:Connect(function()
    wait(1)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 16
    end
end)

-- Initialize speed
local humanoid = getHumanoid()
if humanoid then
    humanoid.WalkSpeed = 16
end
