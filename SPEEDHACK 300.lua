-- Utility functions for connection management
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
    warn('failed to bind connection error: '..tostring(r))
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
        warn('failed to get localplayer')
        return
    end

    -- Bind to PromptButtonHoldBegan event
    local connection = self:bind(self.ProximityPromptService.PromptButtonHoldBegan, function(ProximityPrompt, Player)
        if Player == self.LocalPlayer and tostring(ProximityPrompt) == "CarryAreaEgg" then
            ProximityPrompt.HoldDuration = 0
        end
    end)
    if not connection then
        warn("failed to create connection")
    else
        print("Instant pickup enabled")
    end
    return connection
end

-- Main Script
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

-- UI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InstantPickupUI"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 200, 0, 50)
toggleButton.Position = UDim2.new(0.5, -100, 0.01, 0)
toggleButton.Text = "Enable Instant Pickup"
toggleButton.Parent = ScreenGui

local instantPickupEnabled = false
local connection = nil

-- Drag Functionality
local function enableDrag(button)
    local dragging = false
    local dragStart
    local startPos

    -- Kapag nagsimula ang drag
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    -- Habang nagdadrag
    button.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- Kapag natapos ang drag
    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Tawagin ang enableDrag function para maging draggable ang toggleButton
enableDrag(toggleButton)

-- Toggle Button Functionality
toggleButton.MouseButton1Click:Connect(function()
    instantPickupEnabled = not instantPickupEnabled
    if instantPickupEnabled then
        -- Enable instant pickup
        connection = utility:init()
        toggleButton.Text = "Disable Instant Pickup"
    else
        -- Disable instant pickup
        if connection then
            utility:unbind(connection)
            connection = nil
        end
        toggleButton.Text = "Enable Instant Pickup"
    end
end)

-- Optional: Auto-disable if needed when the game ends or reloads
game:BindToClose(function()
    if connection then
        utility:unbind(connection)
    end
end)
