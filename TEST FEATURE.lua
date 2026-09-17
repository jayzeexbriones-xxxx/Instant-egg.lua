local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local enabled = false
local originalCFrame = nil

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    return char:WaitForChild("HumanoidRootPart")
end

local function setUnderground(state)
    local hrp = getHRP()

    if state then
        -- Save original position
        originalCFrame = hrp.CFrame

        -- 3 studs underground
        hrp.CFrame = hrp.CFrame * CFrame.new(0, -3, 0)
    else
        -- Return to original position
        if originalCFrame then
            hrp.CFrame = originalCFrame
            originalCFrame = nil
        end
    end
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "UndergroundUI"
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(220, 110)
frame.Position = UDim2.new(0.5, -110, 0.5, -55)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "UNDERGROUND"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 17
title.Font = Enum.Font.GothamBold
title.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -30, 0, 45)
button.Position = UDim2.fromOffset(15, 50)
button.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
button.Text = "OFF"
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 18
button.Font = Enum.Font.GothamBold
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

button.MouseButton1Click:Connect(function()
    enabled = not enabled

    setUnderground(enabled)

    if enabled then
        button.Text = "ON"
        button.BackgroundColor3 = Color3.fromRGB(35, 150, 70)
    else
        button.Text = "OFF"
        button.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
    end
end)

-- Respawn safety
player.CharacterAdded:Connect(function()
    enabled = false
    originalCFrame = nil

    task.wait(1)

    if button then
        button.Text = "OFF"
        button.BackgroundColor3 = Color3.fromRGB(150, 35, 35)
    end
end)
