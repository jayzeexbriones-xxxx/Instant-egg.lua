--==================================================
-- JAYZ HUB
-- VIP LOGIN + ONLINE PANEL + INSTANT PICKUP
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

--==================================================
-- CONFIG
--==================================================

local PANEL_URL = "https://pastebin.com/raw/PrGsxZ9L"
local HUB_NAME = "JAYZ HUB"

--==================================================
-- REMOVE OLD UI
--==================================================

pcall(function()
    local old = PlayerGui:FindFirstChild("JAYZHUB")
    if old then
        old:Destroy()
    end
end)

--==================================================
-- UTILITY
--==================================================

local utility = {
    ProximityPromptService = ProximityPromptService,
    Players = Players,
    conns = {}
}

function utility:bind(event, callback)
    local ok, conn = pcall(function()
        return event:Connect(callback)
    end)

    if ok and conn then
        self.conns[conn] = conn
        return conn
    end

    return nil
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
        return nil
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

--==================================================
-- GUI ROOT
--==================================================

local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "JAYZHUB"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

--==================================================
-- ROUND
--==================================================

local function round(object, radius)

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = object

end

--==================================================
-- DRAG
--==================================================

local function makeDraggable(handle, target)

    local dragging = false
    local dragStart
    local startPos
    local dragInput

    handle.Active = true

    handle.InputBegan:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging = true
            dragStart = input.Position
            startPos = target.Position

        end
    end)

    handle.InputChanged:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then

            dragInput = input

        end
    end)

    handle.InputEnded:Connect(function(input)

        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then

            dragging = false

        end
    end)

    UserInputService.InputChanged:Connect(function(input)

        if not dragging then
            return
        end

        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseMovement then

            local delta = input.Position - dragStart

            target.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,

                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )

        end
    end)

end

--==================================================
-- LOGIN FRAME
--==================================================

local LoginFrame = Instance.new("Frame")

LoginFrame.Name = "Login"

LoginFrame.Size =
    UDim2.new(0, 330, 0, 250)

LoginFrame.Position =
    UDim2.new(0.5, -165, 0.5, -125)

LoginFrame.BackgroundColor3 =
    Color3.fromRGB(23, 23, 23)

LoginFrame.BorderSizePixel = 0

LoginFrame.Parent = ScreenGui

round(LoginFrame, 16)

--==================================================
-- LOGIN HEADER
--==================================================

local LoginHeader = Instance.new("TextButton")

LoginHeader.Size =
    UDim2.new(1, 0, 0, 55)

LoginHeader.Position =
    UDim2.new(0, 0, 0, 0)

LoginHeader.BackgroundColor3 =
    Color3.fromRGB(43, 43, 43)

LoginHeader.BorderSizePixel = 0

LoginHeader.Text = "🔐  VIP ACCESS"

LoginHeader.TextColor3 =
    Color3.fromRGB(255, 255, 255)

LoginHeader.TextSize = 18

LoginHeader.Font =
    Enum.Font.GothamBold

LoginHeader.AutoButtonColor = false

LoginHeader.Parent = LoginFrame

round(LoginHeader, 16)

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")

Title.Size =
    UDim2.new(1, -30, 0, 30)

Title.Position =
    UDim2.new(0, 15, 0, 68)

Title.BackgroundTransparency = 1

Title.Text = HUB_NAME

Title.TextColor3 =
    Color3.fromRGB(255, 255, 255)

Title.TextSize = 19

Title.Font =
    Enum.Font.GothamBold

Title.Parent = LoginFrame

--==================================================
-- SUBTITLE
--==================================================

local SubTitle = Instance.new("TextLabel")

SubTitle.Size =
    UDim2.new(1, -30, 0, 22)

SubTitle.Position =
    UDim2.new(0, 15, 0, 96)

SubTitle.BackgroundTransparency = 1

SubTitle.Text =
    "Enter your VIP key to continue"

SubTitle.TextColor3 =
    Color3.fromRGB(155, 155, 155)

SubTitle.TextSize = 12

SubTitle.Font =
    Enum.Font.Gotham

SubTitle.Parent = LoginFrame

--==================================================
-- KEY BOX
--==================================================

local KeyBox = Instance.new("TextBox")

KeyBox.Size =
    UDim2.new(1, -40, 0, 42)

KeyBox.Position =
    UDim2.new(0, 20, 0, 125)

KeyBox.BackgroundColor3 =
    Color3.fromRGB(38, 38, 38)

KeyBox.BorderSizePixel = 0

KeyBox.PlaceholderText =
    "🔑  Enter VIP Key..."

KeyBox.PlaceholderColor3 =
    Color3.fromRGB(125, 125, 125)

KeyBox.Text = ""

KeyBox.TextColor3 =
    Color3.fromRGB(255, 255, 255)

KeyBox.TextSize = 14

KeyBox.Font =
    Enum.Font.GothamMedium

KeyBox.ClearTextOnFocus = false

KeyBox.Parent = LoginFrame

round(KeyBox, 9)

--==================================================
-- LOGIN BUTTON
--==================================================

local LoginButton = Instance.new("TextButton")

LoginButton.Size =
    UDim2.new(1, -40, 0, 40)

LoginButton.Position =
    UDim2.new(0, 20, 0, 175)

LoginButton.BackgroundColor3 =
    Color3.fromRGB(70, 70, 70)

LoginButton.BorderSizePixel = 0

LoginButton.Text = "LOGIN"

LoginButton.TextColor3 =
    Color3.fromRGB(255, 255, 255)

LoginButton.TextSize = 14

LoginButton.Font =
    Enum.Font.GothamBold

LoginButton.Parent = LoginFrame

round(LoginButton, 9)

--==================================================
-- STATUS
--==================================================

local LoginStatus = Instance.new("TextLabel")

LoginStatus.Size =
    UDim2.new(1, -40, 0, 20)

LoginStatus.Position =
    UDim2.new(0, 20, 0, 218)

LoginStatus.BackgroundTransparency = 1

LoginStatus.Text = ""

LoginStatus.TextColor3 =
    Color3.fromRGB(180, 180, 180)

LoginStatus.TextSize = 11

LoginStatus.Font =
    Enum.Font.Gotham

LoginStatus.Parent = LoginFrame

makeDraggable(LoginHeader, LoginFrame)

--==================================================
-- DATE PARSER
--==================================================

local function parseDate(dateString)

    if type(dateString) ~= "string" then
        return nil
    end

    local y, m, d, h, mi, s =
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
        min = tonumber(mi),
        sec = tonumber(s)
    })

end

--==================================================
-- HTTP REQUEST
--==================================================

local function getPanel()

    -- Delta / executor request
    local requestFunction =
        request
        or http_request
        or (syn and syn.request)

    if typeof(requestFunction) == "function" then

        local ok, result = pcall(function()

            return requestFunction({
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

    -- Roblox HttpGet fallback
    local ok, result = pcall(function()

        return game:HttpGet(PANEL_URL)

    end)

    if ok and result then
        return result
    end

    return nil

end

--==================================================
-- CHECK VIP KEY
--==================================================

local function checkVIPKey(inputKey)

    local response = getPanel()

    if not response then

        return false,
            "Unable to connect to panel"

    end

    local decodeOK, data =
        pcall(function()

            return HttpService:JSONDecode(response)

        end)

    if not decodeOK
    or type(data) ~= "table" then

        return false,
            "Invalid panel data"

    end

    -- Global status
    if data.status == "off" then

        return false,
            "Script is currently OFF"

    end

    -- Keys
    if type(data.keys) ~= "table" then

        return false,
            "No keys found in panel"

    end

    -- Find key
    local keyData =
        data.keys[inputKey]

    if not keyData then

        return false,
            "Invalid VIP Key"

    end

    -- Expiry
    if not keyData.expiry then

        return false,
            "Key has no expiry"

    end

    local expiryTime =
        parseDate(keyData.expiry)

    if not expiryTime then

        return false,
            "Invalid expiry format"

    end

    if os.time() >= expiryTime then

        return false,
            "VIP Key has expired"

    end

    return true,
        "Login successful"

end

--==================================================
-- MAIN UI
--==================================================

local function createMainUI()

    local Main = Instance.new("Frame")

    Main.Name = "Main"

    Main.Size =
        UDim2.new(0, 230, 0, 120)

    Main.Position =
        UDim2.new(0.5, -115, 0.15, 0)

    Main.BackgroundColor3 =
        Color3.fromRGB(25, 25, 25)

    Main.BorderSizePixel = 0

    Main.Parent = ScreenGui

    round(Main, 12)

    -- HEADER

    local Header = Instance.new("TextButton")

    Header.Name = "DragHeader"

    Header.Size =
        UDim2.new(1, 0, 0, 38)

    Header.BackgroundColor3 =
        Color3.fromRGB(45, 45, 45)

    Header.BorderSizePixel = 0

    Header.Text = "☰  JAYZ HUB"

    Header.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    Header.TextSize = 14

    Header.Font =
        Enum.Font.GothamBold

    Header.AutoButtonColor = false

    Header.Parent = Main

    round(Header, 12)

    -- COVER

    local HeaderCover = Instance.new("Frame")

    HeaderCover.Size =
        UDim2.new(1, 0, 0, 12)

    HeaderCover.Position =
        UDim2.new(0, 0, 1, -12)

    HeaderCover.BackgroundColor3 =
        Color3.fromRGB(45, 45, 45)

    HeaderCover.BorderSizePixel = 0

    HeaderCover.Active = false

    HeaderCover.Parent = Header

    -- TOGGLE

    local Toggle = Instance.new("TextButton")

    Toggle.Name = "Toggle"

    Toggle.Size =
        UDim2.new(1, -20, 0, 55)

    Toggle.Position =
        UDim2.new(0, 10, 0, 50)

    Toggle.BackgroundColor3 =
        Color3.fromRGB(40, 40, 40)

    Toggle.BorderSizePixel = 0

    Toggle.Text =
        "Instant Pickup : OFF"

    Toggle.TextColor3 =
        Color3.fromRGB(255, 255, 255)

    Toggle.TextSize = 14

    Toggle.Font =
        Enum.Font.GothamBold

    Toggle.Parent = Main

    round(Toggle, 9)

    makeDraggable(Header, Main)

    -- INSTANT PICKUP

    local instantPickupEnabled = false
    local connection = nil

    Toggle.Activated:Connect(function()

        instantPickupEnabled =
            not instantPickupEnabled

        if instantPickupEnabled then

            connection =
                utility:init()

            if connection then

                Toggle.Text =
                    "✓ Instant Pickup : ON"

                Toggle.BackgroundColor3 =
                    Color3.fromRGB(45, 145, 75)

            else

                instantPickupEnabled = false

                Toggle.Text =
                    "Instant Pickup : OFF"

            end

        else

            if connection then

                utility:unbind(connection)

                connection = nil

            end

            Toggle.Text =
                "Instant Pickup : OFF"

            Toggle.BackgroundColor3 =
                Color3.fromRGB(40, 40, 40)

        end

    end)

end

--==================================================
-- LOGIN
--==================================================

local loginBusy = false

LoginButton.Activated:Connect(function()

    if loginBusy then
        return
    end

    local key = KeyBox.Text

    key = key:gsub("^%s+", "")
    key = key:gsub("%s+$", "")

    if key == "" then

        LoginStatus.Text =
            "⚠ Please enter your VIP key"

        return
    end

    loginBusy = true

    LoginButton.Text =
        "CHECKING..."

    LoginStatus.Text =
        "Connecting to online panel..."

    local success, message =
        checkVIPKey(key)

    if success then

        LoginStatus.Text =
            "✓ " .. message

        LoginStatus.TextColor3 =
            Color3.fromRGB(80, 220, 110)

        LoginButton.Text =
            "SUCCESS"

        LoginButton.BackgroundColor3 =
            Color3.fromRGB(45, 145, 75)

        task.wait(0.5)

        LoginFrame:Destroy()

        createMainUI()

    else

        LoginStatus.Text =
            "✕ " .. tostring(message)

        LoginStatus.TextColor3 =
            Color3.fromRGB(255, 90, 90)

        LoginButton.Text =
            "LOGIN"

        LoginButton.BackgroundColor3 =
            Color3.fromRGB(70, 70, 70)

    end

    loginBusy = false

end)

--==================================================
-- START
--==================================================

print("JAYZ HUB VIP LOGIN LOADED")
print("Panel: " .. PANEL_URL)
