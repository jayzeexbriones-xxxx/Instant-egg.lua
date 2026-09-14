--// JAYZ SPEED + CHARACTER LOWER TEST

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local speedEnabled = false
local lowerEnabled = false
local speedValue = 100
local lowerAmount = 2

local speedConnection
local lowerConnection
local originalSpeed = 16
local originalCFrame

local function getCharacter()
    return player.Character
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

--// GUI
local gui = Instance.new("ScreenGui")
gui.Name = "JAYZ_TEST"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 240, 0, 190)
main.Position = UDim2.new(0.5, -120, 0.2, 0)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
main.BorderSizePixel = 0
main.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = main

--// Header
local header = Instance.new("TextButton")
header.Size = UDim2.new(1, 0, 0, 38)
header.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
header.BorderSizePixel = 0
header.Text = "☰  JAYZ SPEED TEST"
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.TextSize = 14
header.Font = Enum.Font.GothamBold
header.Parent = main

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

--// Speed Input
local speedInput = Instance.new("TextBox")
speedInput.Size = UDim2.new(0, 100, 0, 40)
speedInput.Position = UDim2.new(0, 10, 0, 48)
speedInput.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedInput.BorderSizePixel = 0
speedInput.Text = "100"
speedInput.PlaceholderText = "Speed"
speedInput.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInput.TextSize = 14
speedInput.Font = Enum.Font.Gotham
speedInput.ClearTextOnFocus = false
speedInput.Parent = main

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 8)
speedCorner.Parent = speedInput

--// Speed ON/OFF
local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0, 110, 0, 40)
speedButton.Position = UDim2.new(0, 120, 0, 48)
speedButton.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
speedButton.BorderSizePixel = 0
speedButton.Text = "Speed : OFF"
speedButton.TextColor3 = Color3.fromRGB(255, 255, 255)
speedButton.TextSize = 13
speedButton.Font = Enum.Font.GothamBold
speedButton.Parent = main

local speedButtonCorner = Instance.new("UICorner")
speedButtonCorner.CornerRadius = UDim.new(0, 8)
speedButtonCorner.Parent = speedButton

--// Character Lower ON/OFF
local lowerButton = Instance.new("TextButton")
lowerButton.Size = UDim2.new(1, -20, 0, 45)
lowerButton.Position = UDim2.new(0, 10, 0, 105)
lowerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
lowerButton.BorderSizePixel = 0
lowerButton.Text = "Character Lower : OFF"
lowerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
lowerButton.TextSize = 13
lowerButton.Font = Enum.Font.GothamBold
lowerButton.Parent = main

local lowerCorner = Instance.new("UICorner")
lowerCorner.CornerRadius = UDim.new(0, 8)
lowerCorner.Parent = lowerButton

--// Drag
local dragging = false
local dragStart
local startPosition

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = true
        dragStart = input.Position
        startPosition = main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then

        local delta = input.Position - dragStart

        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

--// Speed
speedButton.Activated:Connect(function()

    if not speedEnabled then

        local value = tonumber(speedInput.Text)

        if not value or value <= 0 then
            speedInput.Text = "100"
            return
        end

        speedValue = value

        local humanoid = getHumanoid()

        if not humanoid then
            return
        end

        originalSpeed = humanoid.WalkSpeed
        humanoid.WalkSpeed = speedValue

        if speedConnection then
            speedConnection:Disconnect()
        end

        speedConnection = RunService.Heartbeat:Connect(function()
            local hum = getHumanoid()

            if hum then
                hum.WalkSpeed = speedValue
            end
        end)

        speedEnabled = true
        speedButton.Text = "Speed : ON"
        speedButton.BackgroundColor3 = Color3.fromRGB(45, 145, 75)

    else

        if speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end

        local humanoid = getHumanoid()

        if humanoid then
            humanoid.WalkSpeed = originalSpeed
        end

        speedEnabled = false
        speedButton.Text = "Speed : OFF"
        speedButton.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
    end
end)

--// Character Lower
lowerButton.Activated:Connect(function()

    if not lowerEnabled then

        local root = getRoot()

        if not root then
            return
        end

        originalCFrame = root.CFrame

        root.CFrame = root.CFrame * CFrame.new(0, -lowerAmount, 0)

        lowerEnabled = true
        lowerButton.Text = "Character Lower : ON"
        lowerButton.BackgroundColor3 = Color3.fromRGB(45, 145, 75)

        if lowerConnection then
            lowerConnection:Disconnect()
        end

        lowerConnection = RunService.Heartbeat:Connect(function()
            local currentRoot = getRoot()

            if currentRoot then
                currentRoot.CFrame =
                    currentRoot.CFrame * CFrame.new(0, -lowerAmount, 0)
            end
        end)

    else

        if lowerConnection then
            lowerConnection:Disconnect()
            lowerConnection = nil
        end

        local root = getRoot()

        if root and originalCFrame then
            root.CFrame = originalCFrame
        end

        lowerEnabled = false
        lowerButton.Text = "Character Lower : OFF"
        lowerButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)

--// Respawn
player.CharacterAdded:Connect(function(character)

    local humanoid = character:WaitForChild("Humanoid", 5)

    if humanoid and speedEnabled then
        humanoid.WalkSpeed = speedValue
    end

end)
