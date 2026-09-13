--// Utility
local utility = {
    ProximityPromptService = game:GetService("ProximityPromptService"),
    Players = game:GetService("Players"),
    conns = {},
}

function utility:bind(connection, callback)
    local ok, conn = pcall(function()
        return connection:Connect(callback)
    end)

    if ok and conn then
        self.conns[conn] = conn
        return conn
    end

    warn("Failed to bind connection: " .. tostring(conn))
end

function utility:unbind(connection)
    if connection and self.conns[connection] then
        pcall(function()
            connection:Disconnect()
        end)

        self.conns[connection] = nil
        return true
    end

    return false
end

function utility:init()
    self.LocalPlayer = self.Players.LocalPlayer

    if not self.LocalPlayer then
        warn("Failed to get LocalPlayer")
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

    if connection then
        print("Instant pickup enabled")
    end

    return connection
end


--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")


--// ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "InstantPickupUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui


--// Main Frame
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 230, 0, 120)
Main.Position = UDim2.new(0.5, -115, 0.15, 0)

Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Main.BorderSizePixel = 0

Main.Parent = ScreenGui


--// Rounded Main
local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = Main


--// Drag Header
local Header = Instance.new("TextButton")
Header.Name = "DragHeader"

Header.Size = UDim2.new(1, 0, 0, 38)
Header.Position = UDim2.new(0, 0, 0, 0)

Header.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Header.BorderSizePixel = 0

Header.Text = "☰  INSTANT PICKUP"
Header.TextColor3 = Color3.fromRGB(255, 255, 255)
Header.TextSize = 14
Header.Font = Enum.Font.GothamBold

Header.AutoButtonColor = false
Header.Active = true

Header.Parent = Main


--// Header Corners
local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 12)
HeaderCorner.Parent = Header


--// Bottom cover para squared ang lower header
local HeaderCover = Instance.new("Frame")
HeaderCover.Size = UDim2.new(1, 0, 0, 12)
HeaderCover.Position = UDim2.new(0, 0, 1, -12)

HeaderCover.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
HeaderCover.BorderSizePixel = 0

HeaderCover.Parent = Header


--// Toggle Button
local Toggle = Instance.new("TextButton")
Toggle.Name = "Toggle"

Toggle.Size = UDim2.new(1, -20, 0, 55)
Toggle.Position = UDim2.new(0, 10, 0, 50)

Toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Toggle.BorderSizePixel = 0

Toggle.Text = "Enable Instant Pickup"
Toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
Toggle.TextSize = 14
Toggle.Font = Enum.Font.GothamBold

Toggle.Active = true
Toggle.AutoButtonColor = true

Toggle.Parent = Main


--// Toggle Corner
local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 9)
ToggleCorner.Parent = Toggle


--//==================================================
--// DRAG SYSTEM
--//==================================================

local dragging = false
local dragStart = nil
local startPosition = nil

local function updateDrag(input)

    if not dragging then
        return
    end

    local delta = input.Position - dragStart

    Main.Position = UDim2.new(
        startPosition.X.Scale,
        startPosition.X.Offset + delta.X,

        startPosition.Y.Scale,
        startPosition.Y.Offset + delta.Y
    )
end


Header.InputBegan:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then

        dragging = true
        dragStart = input.Position
        startPosition = Main.Position

        input.Changed:Connect(function()

            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end

        end)
    end
end)


Header.InputChanged:Connect(function(input)

    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then

        if dragging then
            updateDrag(input)
        end
    end
end)


UserInputService.InputChanged:Connect(function(input)

    if dragging then

        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

            updateDrag(input)
        end
    end
end)


--//==================================================
--// INSTANT PICKUP TOGGLE
--//==================================================

local instantPickupEnabled = false
local connection = nil

Toggle.Activated:Connect(function()

    instantPickupEnabled = not instantPickupEnabled

    if instantPickupEnabled then

        connection = utility:init()

        Toggle.Text = "✓ Instant Pickup : ON"
        Toggle.BackgroundColor3 = Color3.fromRGB(45, 145, 75)

    else

        if connection then
            utility:unbind(connection)
            connection = nil
        end

        Toggle.Text = "Instant Pickup : OFF"
        Toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    end
end)


--//==================================================
--// CLEANUP
--//==================================================

game:BindToClose(function()

    if connection then
        utility:unbind(connection)
        connection = nil
    end

end)
