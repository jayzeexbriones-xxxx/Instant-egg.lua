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
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.Name = "MyDragableUI"

local DragUI = Instance.new("Frame")
DragUI.Size = UDim2.new(0, 200, 0, 150)
DragUI.Position = UDim2.new(0.5, -100, 0.5, -75)
DragUI.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DragUI.BorderSizePixel = 0
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = DragUI
DragUI.Parent = ScreenGui

-- Replace ang "Drag me" label with "HIDE MENU" button
local hideButton = Instance.new("TextButton")
hideButton.Size = UDim2.new(1, 0, 0, 30)
hideButton.Position = UDim2.new(0, 0, 0, 0)
hideButton.Text = "HIDE MENU"
hideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
hideButton.Font = Enum.Font.GothamSemibold
hideButton.TextSize = 14
hideButton.Parent = DragUI

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(1, 0, 1, -30)
MainFrame.Position = UDim2.new(0, 0, 0, 30)
MainFrame.BackgroundTransparency = 1
MainFrame.Parent = DragUI

local SpeedHackToggle = Instance.new("TextButton")
SpeedHackToggle.Size = UDim2.new(1, -20, 0, 40)
SpeedHackToggle.Position = UDim2.new(0, 10, 0, 10)
SpeedHackToggle.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
SpeedHackToggle.Text = "Speed Hack: Off"
SpeedHackToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedHackToggle.Font = Enum.Font.GothamSemibold
SpeedHackToggle.TextSize = 14
SpeedHackToggle.Parent = MainFrame

local InstantPickupToggle = Instance.new("TextButton")
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
local UserInputService = game:GetService("UserInputService")

-- Toggle Speed Hack
SpeedHackToggle.MouseButton1Click:Connect(function()
    speedHackEnabled = not speedHackEnabled
    if speedHackEnabled then
        SpeedHackToggle.Text = "Speed Hack: On"
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 50
        end
    else
        SpeedHackToggle.Text = "Speed Hack: Off"
        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = 16
        end
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

-- Gamitin ang toggle para i-hide o show ang UI
local uiVisible = true

hideButton.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    DragUI.Visible = uiVisible
end)

-- Optional: pwede mo pa rin gawing draggable ang UI
local dragging = false
local dragStart, startPos

DragUI.InputBegan:Connect(function(input)
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

DragUI.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        DragUI.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

-- Constantly check for instant pickup toggle
game:GetService("RunService").RenderStepped:Connect(function()
    if instantPickupEnabled then
        for _, prompt in pairs(utility.ProximityPromptService:GetPromptInstances()) do
            if tostring(prompt) == "CarryAreaEgg" then
                prompt.HoldDuration = 0
            end
        end
    end
end)
