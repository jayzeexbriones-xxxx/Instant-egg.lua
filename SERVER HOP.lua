-- ============================================================
-- PART 2: UI (0-1 PLAYER ONLY)
-- ============================================================

local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    STROKE = Color3.fromRGB(60, 60, 70),
    TEXT = Color3.fromRGB(255, 255, 255),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    YELLOW = Color3.fromRGB(255, 200, 0),
    CYAN = Color3.fromRGB(80, 200, 255),
    DARK = Color3.fromRGB(18, 18, 22),
    HOVER = Color3.fromRGB(45, 45, 55),
    EMPTY_GREEN = Color3.fromRGB(20, 180, 100),
    LOW_GREEN = Color3.fromRGB(30, 140, 80),
    ORANGE = Color3.fromRGB(255, 140, 50),
    PURPLE = Color3.fromRGB(180, 100, 255),
}

if CoreGui:FindFirstChild("ServerHopUI") then
    CoreGui.ServerHopUI:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ServerHopUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 220, 0, 340)
Main.Position = UDim2.new(0.5, -110, 0.5, -170)
Main.BackgroundColor3 = COLORS.BG
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = COLORS.STROKE

-- Title
local TitleBar = Instance.new("Frame", Main)
TitleBar.Size = UDim2.new(1, 0, 0, 28)
TitleBar.BackgroundColor3 = COLORS.TITLE_BG
TitleBar.BorderSizePixel = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 8)

local TitleCover = Instance.new("Frame", TitleBar)
TitleCover.Size = UDim2.new(1, 0, 0, 8)
TitleCover.Position = UDim2.new(0, 0, 1, -8)
TitleCover.BackgroundColor3 = COLORS.TITLE_BG
TitleCover.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TitleBar)
Title.Size = UDim2.new(1, -35, 1, 0)
Title.Position = UDim2.new(0, 8, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎯 Server Hop (0-1)"
Title.TextColor3 = COLORS.PURPLE
Title.TextSize = 11
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", TitleBar)
CloseBtn.Size = UDim2.new(0, 20, 0, 20)
CloseBtn.Position = UDim2.new(1, -24, 0, 4)
CloseBtn.BackgroundColor3 = COLORS.RED
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = COLORS.TEXT
CloseBtn.TextSize = 11
CloseBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 4)

-- Status
local Status = Instance.new("TextLabel", Main)
Status.Size = UDim2.new(1, -20, 0, 14)
Status.Position = UDim2.new(0, 10, 0, 34)
Status.BackgroundTransparency = 1
Status.Text = "🔍 Loading..."
Status.TextColor3 = COLORS.YELLOW
Status.TextSize = 9
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left

-- Stats
local StatsLabel = Instance.new("TextLabel", Main)
StatsLabel.Size = UDim2.new(1, -20, 0, 12)
StatsLabel.Position = UDim2.new(0, 10, 0, 48)
StatsLabel.BackgroundTransparency = 1
StatsLabel.Text = ""
StatsLabel.TextColor3 = COLORS.CYAN
StatsLabel.TextSize = 8
StatsLabel.Font = Enum.Font.Gotham
StatsLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Current server
local CurrentLabel = Instance.new("TextLabel", Main)
CurrentLabel.Size = UDim2.new(1, -20, 0, 12)
CurrentLabel.Position = UDim2.new(0, 10, 0, 62)
CurrentLabel.BackgroundTransparency = 1
CurrentLabel.Text = "📍 Current: checking..."
CurrentLabel.TextColor3 = COLORS.ORANGE
CurrentLabel.TextSize = 8
CurrentLabel.Font = Enum.Font.Gotham
CurrentLabel.TextXAlignment = Enum.TextXAlignment.Left

-- Refresh button
local RefreshBtn = Instance.new("TextButton", Main)
RefreshBtn.Size = UDim2.new(0, 55, 0, 18)
RefreshBtn.Position = UDim2.new(1, -65, 0, 33)
RefreshBtn.BackgroundColor3 = COLORS.CYAN
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Text = "🔄"
RefreshBtn.TextColor3 = COLORS.TEXT
RefreshBtn.TextSize = 11
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.AutoButtonColor = false
Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 4)

-- Auto refresh
local AutoRefreshBtn = Instance.new("TextButton", Main)
AutoRefreshBtn.Size = UDim2.new(0, 55, 0, 18)
AutoRefreshBtn.Position = UDim2.new(1, -65, 0, 53)
AutoRefreshBtn.BackgroundColor3 = COLORS.LOW_GREEN
AutoRefreshBtn.BorderSizePixel = 0
AutoRefreshBtn.Text = "Auto"
AutoRefreshBtn.TextColor3 = COLORS.TEXT
AutoRefreshBtn.TextSize = 9
AutoRefreshBtn.Font = Enum.Font.GothamBold
AutoRefreshBtn.AutoButtonColor = false
Instance.new("UICorner", AutoRefreshBtn).CornerRadius = UDim.new(0, 4)

-- Scroll
local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, -20, 1, -100)
Scroll.Position = UDim2.new(0, 10, 0, 76)
Scroll.BackgroundColor3 = COLORS.DARK
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = COLORS.PURPLE
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 5)
local scrollPadding = Instance.new("UIPadding", Scroll)
scrollPadding.PaddingTop = UDim.new(0, 3)
scrollPadding.PaddingBottom = UDim.new(0, 3)
scrollPadding.PaddingLeft = UDim.new(0, 3)
scrollPadding.PaddingRight = UDim.new(0, 3)
local scrollLayout = Instance.new("UIListLayout", Scroll)
scrollLayout.Padding = UDim.new(0, 3)
scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder

-- Info
local InfoLabel = Instance.new("TextLabel", Main)
InfoLabel.Size = UDim2.new(1, -20, 0, 12)
InfoLabel.Position = UDim2.new(0, 10, 1, -18)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "💡 0-1 player servers only"
InfoLabel.TextColor3 = COLORS.PURPLE
InfoLabel.TextSize = 8
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.TextXAlignment = Enum.TextXAlignment.Left

-- ============================================================
-- SERVER ROW
-- ============================================================
local function createServerRow(parent, index, data)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, -6, 0, 32)
    row.BackgroundColor3 = COLORS.HOVER
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = index
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local isZero = (data.playing == 0)
    local mainColor = isZero and COLORS.EMPTY_GREEN or COLORS.LOW_GREEN

    local stroke2 = Instance.new("UIStroke", row)
    stroke2.Color = mainColor
    stroke2.Thickness = 1
    stroke2.Transparency = 0.3

    local indicator = Instance.new("Frame", row)
    indicator.Size = UDim2.new(0, 3, 1, -6)
    indicator.Position = UDim2.new(0, 3, 0, 3)
    indicator.BackgroundColor3 = mainColor
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    local countLabel = Instance.new("TextLabel", row)
    countLabel.Size = UDim2.new(0, 55, 1, 0)
    countLabel.Position = UDim2.new(0, 10, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = ("%d / %d"):format(data.playing, data.maxPlayers)
    countLabel.TextColor3 = mainColor
    countLabel.TextSize = 12
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left

    local playerLabel = Instance.new("TextLabel", row)
    playerLabel.Size = UDim2.new(0, 45, 1, 0)
    playerLabel.Position = UDim2.new(0, 65, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = isZero and "EMPTY" or "player"
    playerLabel.TextColor3 = mainColor
    playerLabel.TextSize = 8
    playerLabel.Font = Enum.Font.GothamBold
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left

    if data.ping then
        local pingLabel = Instance.new("TextLabel", row)
        pingLabel.Size = UDim2.new(0, 45, 0, 10)
        pingLabel.Position = UDim2.new(0, 110, 0, 3)
        pingLabel.BackgroundTransparency = 1
        pingLabel.Text = ("%dms"):format(math.floor(data.ping))
        pingLabel.TextColor3 = COLORS.YELLOW
        pingLabel.TextSize = 8
        pingLabel.Font = Enum.Font.Gotham
        pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    end

    local joinBadge = Instance.new("TextLabel", row)
    joinBadge.Size = UDim2.new(0, 42, 0, 16)
    joinBadge.Position = UDim2.new(1, -48, 0.5, -8)
    joinBadge.BackgroundColor3 = mainColor
    joinBadge.BackgroundTransparency = 0.3
    joinBadge.Text = isZero and "SOLO" or "JOIN"
    joinBadge.TextColor3 = COLORS.TEXT
    joinBadge.TextSize = 8
    joinBadge.Font = Enum.Font.GothamBold
    Instance.new("UICorner", joinBadge).CornerRadius = UDim.new(0, 3)

    row.MouseEnter:Connect(function()
        row.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        joinBadge.BackgroundTransparency = 0
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = COLORS.HOVER
        joinBadge.BackgroundTransparency = 0.3
    end)

    row.MouseButton1Click:Connect(function()
        Status.Text = ("🎯 Hopping %s..."):format(isZero and "SOLO" or "1-player")
        Status.TextColor3 = COLORS.GREEN
        task.wait(0.3)
        hopTo(data.id)
    end)

    return row
end

-- ============================================================
-- REFRESH
-- ============================================================
local autoRefreshEnabled = true
local refreshing = false

local function refreshServerList()
    if refreshing then return end
    refreshing = true

    for _, child in ipairs(Scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    Status.Text = "🔍 Fetching 0-1 servers..."
    Status.TextColor3 = COLORS.YELLOW
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)

    task.spawn(function()
        local servers, err = fetchServers()
        RefreshBtn.BackgroundColor3 = COLORS.CYAN
        refreshing = false

        if not servers then
            Status.Text = tostring(err)
            Status.TextColor3 = COLORS.RED
            return
        end

        if #servers == 0 then
            Status.Text = "❌ Walang 0-1 player server"
            Status.TextColor3 = COLORS.RED
            return
        end

        local emptyCount, oneCount = 0, 0
        for _, s in ipairs(servers) do
            if s.playing == 0 then emptyCount += 1 else oneCount += 1 end
        end

        Status.Text = ("✅ %d servers"):format(#servers)
        Status.TextColor3 = COLORS.GREEN
        StatsLabel.Text = ("🟢 %d EMPTY · %d 1-player"):format(emptyCount, oneCount)

        local yOffset = 0
        for i, serverData in ipairs(servers) do
            createServerRow(Scroll, i, serverData)
            yOffset += 36
        end
        Scroll.CanvasSize = UDim2.new(0, 0, 0, yOffset + 6)
    end)
end

-- ============================================================
-- AUTO REFRESH LOOP
-- ============================================================
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(5)
        if autoRefreshEnabled and not refreshing then
            local rowCount = 0
            for _, child in ipairs(Scroll:GetChildren()) do
                if child:IsA("TextButton") then rowCount += 1 end
            end
            if rowCount < 3 then refreshServerList() end
        end
    end
end)

-- ============================================================
-- LIVE PLAYER COUNT
-- ============================================================
task.spawn(function()
    while ScreenGui.Parent do
        task.wait(2)
        pcall(function()
            local count = #Players:GetPlayers()
            CurrentLabel.Text = ("📍 Current: %d players"):format(count)
            if count == 1 then CurrentLabel.TextColor3 = COLORS.EMPTY_GREEN
            elseif count == 2 then CurrentLabel.TextColor3 = COLORS.LOW_GREEN
            else CurrentLabel.TextColor3 = COLORS.ORANGE end
        end)
    end
end)

-- ============================================================
-- WIRING
-- ============================================================
RefreshBtn.MouseButton1Click:Connect(function()
    if not refreshing then refreshServerList() end
end)

RefreshBtn.MouseEnter:Connect(function()
    RefreshBtn.BackgroundColor3 = Color3.fromRGB(120, 220, 255)
end)
RefreshBtn.MouseLeave:Connect(function()
    RefreshBtn.BackgroundColor3 = COLORS.CYAN
end)

AutoRefreshBtn.MouseButton1Click:Connect(function()
    autoRefreshEnabled = not autoRefreshEnabled
    if autoRefreshEnabled then
        AutoRefreshBtn.BackgroundColor3 = COLORS.LOW_GREEN
        AutoRefreshBtn.Text = "Auto"
        Status.Text = "✅ Auto ON"
        Status.TextColor3 = COLORS.GREEN
    else
        AutoRefreshBtn.BackgroundColor3 = COLORS.RED
        AutoRefreshBtn.Text = "Off"
        Status.Text = "❌ Auto OFF"
        Status.TextColor3 = COLORS.RED
    end
end)

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

task.spawn(function()
    task.wait(0.5)
    refreshServerList()
end)

print("[HOP] ✅ Part 2 loaded — UI ready")
