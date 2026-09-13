local utility = {
    ProximityPromptService = game:GetService("ProximityPromptService"),
    Players = game:GetService("Players"),
    conns = {},
}

function utility:bind(connection, callback)
    local s, r = pcall(function(...)
        local conn = connection:Connect(callback)
        self.conns[conn] = conn
        return self.conns[conn]
    end)
    if s and r then
        return r
    end
    warn('failed to bind connection error: '..tostring(r))
end

function utility:unbind(connection)
    local s, r = pcall(function(...)
        local conn = self.conns[connection]
        if conn then
            conn:Disconnect()
            self.conns[connection] = nil
            return true
        end
        return false
    end)
    if s and r then
        return true
    end
    warn("failed to unbind")
end

function utility:init()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then
        warn('failed to get localplayer')
        return
    end

    local connection = self:bind(self.ProximityPromptService.PromptButtonHoldBegan, function(ProximityPrompt, Player)
        if Player == self.LocalPlayer and tostring(ProximityPrompt) == "CarryAreaEgg" then
            ProximityPrompt.HoldDuration = 0
        end
    end)
    if not connection then
        warn("failed to create connection")
    else
        warn("Utility init success")
    end
end

utility:init()

-- UI Setup
local ScreenGui = Instance.new("ScreenGui")
local DragUI = Instance.new("Frame")
local DragArea = Instance.new("TextButton")
local MainFrame = Instance.new("Frame")
local SpeedHackToggle = Instance.new("TextButton")
local InstantPickupToggle = Instance.new("TextButton")
local UICorner = Instance.new("UICorner")

ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "MyDragableUI"

DragUI.Size = UDim2.new(0, 200, 0, 150)
DragUI.Position = UDim2.new(0.5, -100, 0.5, -75)
DragUI.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DragUI.BorderSizePixel = 0
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = DragUI
DragUI.Parent = ScreenGui

DragArea.Size = UDim2.new(1, 0, 0, 30)
DragArea.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
DragArea.Position = UDim2.new(0, 0, 0, 0)
DragArea.Text = "Drag me"
DragArea.TextColor3 = Color3.fromRGB(255, 255, 255)
DragArea.Font = Enum.Font.GothamSemibold
DragArea.TextSize = 14
DragArea.Parent = DragUI

MainFrame.Size = UDim2.new(1, 0, 1, -30)
MainFrame.Position = UDim2.new(0, 0, 0, 30)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = DragUI

SpeedHackToggle.Size = UDim2.new(1, -20, 0, 40)
SpeedHackToggle.Position = UDim2.new(0, 10, 0, 10)
SpeedHackToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SpeedHackToggle.Text = "Speed Hack: Off"
SpeedHackToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedHackToggle.Font = Enum.Font.GothamSemibold
SpeedHackToggle.TextSize = 14
SpeedHackToggle.Parent = MainFrame

InstantPickupToggle.Size = UDim2.new(1, -20, 0, 40)
InstantPickupToggle.Position = UDim2.new(0, 10, 0, 60)
InstantPickupToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
InstantPickupToggle.Text = "Instant Pickup: Off"
InstantPickupToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
InstantPickupToggle.Font = Enum.Font.GothamSemibold
InstantPickupToggle.TextSize = 14
InstantPickupToggle.Parent = MainFrame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 8)
buttonCorner.Parent = SpeedHackToggle
local buttonCorner2 = Instance.new("UICorner")
buttonCorner2.CornerRadius = UDim.new(0, 8)
buttonCorner2.Parent = InstantPickupToggle

local speedHackEnabled = false
local instantPickupEnabled = false
local userInputService = game:GetService("UserInputService")

-- Toggle Speed Hack
SpeedHackToggle.MouseButton1Click:Connect(function()
    speedHackEnabled = not speedHackEnabled
    if speedHackEnabled then
        SpeedHackToggle.Text = "Speed Hack: On"
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 50
    else
        SpeedHackToggle.Text = "Speed Hack: Off"
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
    end
end)

-- Toggle Instant Pickup
InstantPickupToggle.MouseButton1Click:Connect(function()
    instantPickupEnabled = not instantPickupEnabled
    if instantPickupEnabled then
        InstantPickupToggle.Text = "Instant Pickup: On"
    else
        InstantPickupToggle.Text = "Instant Pickup: Off"
    end
end)

-- Make the UI draggable
local dragging = false
local dragInput, dragStart, startPos

DragArea.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = DragUI.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

DragArea.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        DragUI.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

-- Constantly check for instant pickup toggle
game:GetService("RunService").RenderStepped:Connect(function()
    if instantPickupEnabled then
        -- Trigger the instant pickup for "CarryAreaEgg"
        -- You can add your specific logic here if needed
        -- Example: simulate the prompt being pressed
        for _, prompt in pairs(utility.ProximityPromptService:GetPromptInstances()) do
            if tostring(prompt) == "CarryAreaEgg" then
                prompt.HoldDuration = 0
            end
        end
    end
end)
