--// JAYZ SPEED TEST

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local enabled = false
local speed = 350
local originalSpeed = 16
local connection

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "JAYZ_SPEED_TEST"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 230, 0, 145)
main.Position = UDim2.new(0.5, -115, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

--// Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "☰  JAYZ SPEED TEST"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 14
title.Font = Enum.Font.GothamBold
title.Parent = main

--// Speed Input
local input = Instance.new("TextBox")
input.Size = UDim2.new(1, -20, 0, 40)
input.Position = UDim2.new(0, 10, 0, 43)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
input.BorderSizePixel = 0
input.PlaceholderText = "Enter speed"
input.Text = "350"
input.TextColor3 = Color3.fromRGB(255, 255, 255)
input.TextSize = 14
input.Font = Enum.Font.Gotham
input.ClearTextOnFocus = false
input.Parent = main

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 8)
inputCorner.Parent = input

--// Button
local button = Instance.new("TextButton")
button.Size = UDim2.new(1, -20, 0, 40)
button.Position = UDim2.new(0, 10, 0, 92)
button.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
button.BorderSizePixel = 0
button.Text = "ENABLE SPEED"
button.TextColor3 = Color3.fromRGB(255, 255, 255)
button.TextSize = 13
button.Font = Enum.Font.GothamBold
button.Parent = main

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = button

--// Get Humanoid
local function getHumanoid()
    local character = player.Character
    if not character then
        return nil
    end

    return character:FindFirstChildOfClass("Humanoid")
end

--// Enable / Disable
button.Activated:Connect(function()

    if not enabled then

        local value = tonumber(input.Text)

        if not value then
            input.Text = "350"
            return
        end

        if value <= 0 then
            return
        end

        speed = value

        local humanoid = getHumanoid()

        if not humanoid then
            return
        end

        originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = speed

        if connection then
            connection:Disconnect()
        end

        connection = RunService.Heartbeat:Connect(function()
            local hum = getHumanoid()

            if hum then
                hum.WalkSpeed = speed
            end
        end)

        enabled = true
        button.Text = "✓ SPEED : " .. tostring(speed)
        button.BackgroundColor3 = Color3.fromRGB(45, 145, 75)

    else

        if connection then
            connection:Disconnect()
            connection = nil
        end

        local humanoid = getHumanoid()

        if humanoid then
            humanoid.WalkSpeed = originalSpeed
        end

        enabled = false
        button.Text = "ENABLE SPEED"
        button.BackgroundColor3 = Color3.fromRGB(80, 60, 180)

    end
end)

--// Restore after respawn
player.CharacterAdded:Connect(function(character)

    local humanoid = character:WaitForChild("Humanoid", 5)

    if humanoid and enabled then
        humanoid.WalkSpeed = speed
    end

end)
