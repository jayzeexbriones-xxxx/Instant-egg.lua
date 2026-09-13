--// Utility Functions
local utility = {
    ProximityPromptService = game:GetService("ProximityPromptService"),
    Players = game:GetService("Players"),
    conns = {},
}

function utility:bind(connection, callback)
    local s, r = pcall(function()
        local conn = connection:Connect(callback)
        self.conns[conn] = conn
        return conn
    end)

    if s and r then
        return r
    end

    warn("failed to bind connection error: " .. tostring(r))
end

function utility:unbind(connection)
    local s, r = pcall(function()
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
        warn("failed to get localplayer")
        return
    end

    local connection = self:bind(
        self.ProximityPromptService.PromptButtonHoldBegan,
        function(ProximityPrompt, Player)

            if Player == self.LocalPlayer
            and tostring(ProximityPrompt) == "CarryAreaEgg" then

                ProximityPrompt.HoldDuration = 0
            end
        end
    )

    if not connection then
        warn("failed to create connection")
    else
        print("Instant pickup enabled")
    end

    return connection
end


--// Main
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")


--// ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InstantPickupUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui


--// Toggle Button
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "InstantPickupButton"
toggleButton.Size = UDim2.new(0, 220, 0, 55)
toggleButton.Position = UDim2.new(0.5, -110, 0.08, 0)

toggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
toggleButton.BorderSizePixel = 0

toggleButton.Text = "Enable Instant Pickup"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 16
toggleButton.Font = Enum.Font.GothamBold

toggleButton.AutoButtonColor = true
toggleButton.Active = true

toggleButton.Parent = ScreenGui


--// Rounded Corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = toggleButton


--// Drag System
local dragging = false
local dragStart
local startPos
local dragInput

toggleButton.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then

        dragging = true
        dragStart = input.Position
        startPos = toggleButton.Position
        dragInput = input

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end

        end)
    end
end)


toggleButton.InputChanged:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then

        dragInput = input
    end
end)


UserInputService.InputChanged:Connect(function(input)

    if input == dragInput and dragging then

        local delta = input.Position - dragStart

        toggleButton.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,

            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)


--// Toggle Function
local instantPickupEnabled = false
local connection = nil

toggleButton.Activated:Connect(function()

    instantPickupEnabled = not instantPickupEnabled

    if instantPickupEnabled then

        -- Enable
        connection = utility:init()

        toggleButton.Text = "Disable Instant Pickup"
        toggleButton.BackgroundColor3 = Color3.fromRGB(45, 150, 75)

    else

        -- Disable
        if connection then
            utility:unbind(connection)
            connection = nil
        end

        toggleButton.Text = "Enable Instant Pickup"
        toggleButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    end
end)


--// Cleanup
game:BindToClose(function()

    if connection then
        utility:unbind(connection)
        connection = nil
    end

end)
