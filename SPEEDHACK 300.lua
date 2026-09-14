--//==================================================
--// JAYZ HUB - VIP SYSTEM
--//==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

--//==================================================
--// GITHUB VIP PANEL
--//==================================================

local PANEL_URL =
    "https://raw.githubusercontent.com/jayzeexbriones-xxxx/Instant-egg.lua/refs/heads/main/Panel.json"


--//==================================================
--// HTTP REQUEST
--//==================================================

local function getPanel()

    local req =
        request
        or http_request
        or (syn and syn.request)

    if typeof(req) == "function" then

        local ok, result = pcall(function()
            return req({
                Url = PANEL_URL,
                Method = "GET"
            })
        end)

        if ok and result then

            if result.Body then
                return result.Body
            end

            if result.body then
                return result.body
            end

        end
    end


    --// Fallback
    local ok, result = pcall(function()
        return game:HttpGet(PANEL_URL)
    end)

    if ok and result then
        return result
    end

    return nil
end


--//==================================================
--// LOAD PANEL
--//==================================================

local function loadPanel()

    local response = getPanel()

    if not response then
        return nil, "Unable to connect to panel"
    end

    response = tostring(response)

    -- Remove whitespace
    response = response:gsub("^%s+", "")
    response = response:gsub("%s+$", "")

    -- Remove UTF-8 BOM if present
    response = response:gsub("^\239\187\191", "")

    local ok, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not ok or type(data) ~= "table" then
        return nil, "Invalid panel data"
    end

    return data
end


--//==================================================
--// EXPIRY PARSER
--//==================================================

local function parseDate(dateString)

    if type(dateString) ~= "string" then
        return nil
    end

    local y, m, d, h, min, s =
        dateString:match(
            "^(%d+)%-(%d+)%-(%d+) (%d+):(%d+):(%d+)$"
        )

    if not y then
        return nil
    end

    return os.time({
        year = tonumber(y),
        month = tonumber(m),
        day = tonumber(d),
        hour = tonumber(h),
        min = tonumber(min),
        sec = tonumber(s)
    })
end


--//==================================================
--// VIP LOGIN GUI
--//==================================================

local LoginGui = Instance.new("ScreenGui")
LoginGui.Name = "JAYZ_VIP_LOGIN"
LoginGui.ResetOnSpawn = false
LoginGui.IgnoreGuiInset = true
LoginGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoginGui.Parent = PlayerGui


local LoginFrame = Instance.new("Frame")
LoginFrame.Size = UDim2.new(0, 280, 0, 190)
LoginFrame.Position = UDim2.new(0.5, -140, 0.5, -95)
LoginFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
LoginFrame.BorderSizePixel = 0
LoginFrame.Parent = LoginGui


local LoginCorner = Instance.new("UICorner")
LoginCorner.CornerRadius = UDim.new(0, 14)
LoginCorner.Parent = LoginFrame


--// Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 10)
Title.BackgroundTransparency = 1

Title.Text = "🔐 JAYZ HUB VIP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold

Title.Parent = LoginFrame


--// Key Box
local KeyBox = Instance.new("TextBox")
KeyBox.Size = UDim2.new(1, -30, 0, 45)
KeyBox.Position = UDim2.new(0, 15, 0, 60)

KeyBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
KeyBox.BorderSizePixel = 0

KeyBox.PlaceholderText = "Enter VIP Key"
KeyBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)

KeyBox.Text = ""
KeyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyBox.TextSize = 14
KeyBox.Font = Enum.Font.Gotham

KeyBox.ClearTextOnFocus = false

KeyBox.Parent = LoginFrame


local KeyCorner = Instance.new("UICorner")
KeyCorner.CornerRadius = UDim.new(0, 9)
KeyCorner.Parent = KeyBox


--// Login Button
local LoginButton = Instance.new("TextButton")
LoginButton.Size = UDim2.new(1, -30, 0, 45)
LoginButton.Position = UDim2.new(0, 15, 0, 115)

LoginButton.BackgroundColor3 = Color3.fromRGB(80, 60, 180)
LoginButton.BorderSizePixel = 0

LoginButton.Text = "LOGIN"
LoginButton.TextColor3 = Color3.fromRGB(255, 255, 255)
LoginButton.TextSize = 14
LoginButton.Font = Enum.Font.GothamBold

LoginButton.Parent = LoginFrame


local LoginCorner2 = Instance.new("UICorner")
LoginCorner2.CornerRadius = UDim.new(0, 9)
LoginCorner2.Parent = LoginButton


--// Status
local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -30, 0, 20)
Status.Position = UDim2.new(0, 15, 1, -25)

Status.BackgroundTransparency = 1

Status.Text = ""
Status.TextColor3 = Color3.fromRGB(255, 255, 255)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham

Status.Parent = LoginFrame


--//==================================================
--// INSTANT PICKUP UTILITY
--//==================================================

local utility = {
    ProximityPromptService = game:GetService("ProximityPromptService"),
    Players = game:GetService("Players"),
    conns = {}
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

    return connection
end


--//==================================================
--// MAIN HUB
--//==================================================

local function createHub()

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "InstantPickupUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui


    --// Main
    local Main = Instance.new("Frame")
    Main.Name = "Main"

    Main.Size = UDim2.new(0, 230, 0, 120)
    Main.Position = UDim2.new(0.5, -115, 0.15, 0)

    Main.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Main.BorderSizePixel = 0

    Main.Parent = ScreenGui


    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = Main


    --// Header
    local Header = Instance.new("TextButton")
    Header.Name = "DragHeader"

    Header.Size = UDim2.new(1, 0, 0, 38)
    Header.Position = UDim2.new(0, 0, 0, 0)

    Header.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Header.BorderSizePixel = 0

    Header.Text = "☰  JAYZ HUB"
    Header.TextColor3 = Color3.fromRGB(255, 255, 255)
    Header.TextSize = 14
    Header.Font = Enum.Font.GothamBold

    Header.AutoButtonColor = false
    Header.Active = true

    Header.Parent = Main


    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header


    --// Header cover
    local HeaderCover = Instance.new("Frame")

    HeaderCover.Size = UDim2.new(1, 0, 0, 12)
    HeaderCover.Position = UDim2.new(0, 0, 1, -12)

    HeaderCover.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    HeaderCover.BorderSizePixel = 0

    HeaderCover.Parent = Header


    --// Toggle
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

    Toggle.Parent = Main


    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(0, 9)
    ToggleCorner.Parent = Toggle


    --//==================================================
    --// DRAG
    --//==================================================

    local dragging = false
    local dragStart
    local startPosition


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


    UserInputService.InputChanged:Connect(function(input)

        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then

            updateDrag(input)

        end
    end)


    --//==================================================
    --// INSTANT PICKUP
    --//==================================================

    local enabled = false
    local connection = nil


    Toggle.Activated:Connect(function()

        enabled = not enabled

        if enabled then

            connection = utility:init()

            Toggle.Text = "✓ Instant Pickup : ON"
            Toggle.BackgroundColor3 =
                Color3.fromRGB(45, 145, 75)

        else

            if connection then
                utility:unbind(connection)
                connection = nil
            end

            Toggle.Text = "Instant Pickup : OFF"
            Toggle.BackgroundColor3 =
                Color3.fromRGB(40, 40, 40)
        end
    end)


    return ScreenGui, connection
end


--//==================================================
--// VIP LOGIN
--//==================================================

LoginButton.Activated:Connect(function()

    local key = KeyBox.Text

    if key == "" then

        Status.Text = "⚠️ Enter your VIP key"
        Status.TextColor3 = Color3.fromRGB(255, 180, 50)

        return
    end


    LoginButton.Text = "CHECKING..."
    Status.Text = "Connecting to panel..."


    local panel, errorMessage = loadPanel()


    if not panel then

        Status.Text = "❌ " .. tostring(errorMessage)
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)

        LoginButton.Text = "LOGIN"

        return
    end


    --// Server status
    if tostring(panel.status):lower() ~= "on" then

        Status.Text = "🔴 Script is OFF"
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)

        LoginButton.Text = "LOGIN"

        return
    end


    --// Keys
    if type(panel.keys) ~= "table" then

        Status.Text = "❌ Invalid keys data"
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)

        LoginButton.Text = "LOGIN"

        return
    end


    local userData = panel.keys[key]


    if not userData then

        Status.Text = "❌ Invalid VIP Key"
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)

        LoginButton.Text = "LOGIN"

        return
    end


    local expiry = parseDate(userData.expiry)


    if not expiry then

        Status.Text = "❌ Invalid expiry"
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)

        LoginButton.Text = "LOGIN"

        return
    end


    if os.time() >= expiry then

        Status.Text = "⛔ VIP Key Expired"
        Status.TextColor3 = Color3.fromRGB(255, 80, 80)

        LoginButton.Text = "LOGIN"

        return
    end


    --// SUCCESS
    Status.Text = "✅ VIP Access Granted"
    Status.TextColor3 = Color3.fromRGB(80, 255, 120)

    LoginButton.Text = "SUCCESS"


    task.wait(0.7)

    --// Hide login
    LoginGui:Destroy()


    --// Start hub
    createHub()

end)
