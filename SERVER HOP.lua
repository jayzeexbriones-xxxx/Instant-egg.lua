-- ============================================================
-- 🎯 SERVER HOP — 0-1 PLAYER ONLY (COMPACT UI)
-- ============================================================

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
local HopConfig = {
    minPlayers = 0,        -- 0 players
    maxPlayers = 1,        -- 1 player max
    autoRefresh = true,
    autoRefreshDelay = 5,
    maxPages = 5,
}

-- ============================================================
-- 🎯 FETCH SERVERS (0-1 PLAYER ONLY)
-- ============================================================
local function fetchServers()
    local requester = (syn and syn.request)
        or (http and http.request) or http_request or request
    if type(requester) ~= "function" then return nil, "❌ No HTTP" end

    local allServers = {}
    local cursor = nil
    local pagesFetched = 0
    local seen = {}

    repeat
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&excludeFullGames=true&limit=100")
            :format(game.PlaceId)
        if cursor then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local ok, response = pcall(requester, {
            Url = url, Method = "GET",
            Headers = { ["Accept"] = "application/json" },
        })
        if not ok or type(response) ~= "table" then break end

        local statusCode = tonumber(response.StatusCode or response.Status)
        if not statusCode or statusCode < 200 or statusCode >= 300 then break end

        local body = response.Body or response.body or ""
        local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
        if not decodeOk or type(decoded) ~= "table" then break end

        local servers = decoded.data or {}
        for _, srv in ipairs(servers) do
            if type(srv) == "table" and srv.id and srv.id ~= game.JobId
               and not seen[srv.id] then
                local playing = tonumber(srv.playing) or 0
                local maxP = tonumber(srv.maxPlayers) or 0
                -- 🎯 0-1 PLAYER ONLY
                if playing >= HopConfig.minPlayers
                   and playing <= HopConfig.maxPlayers
                   and playing < maxP then
                    seen[srv.id] = true
                    allServers[#allServers + 1] = {
                        id = srv.id,
                        playing = playing,
                        maxPlayers = maxP,
                        ping = tonumber(srv.ping),
                        fps = tonumber(srv.fps),
                    }
                end
            end
        end

        pagesFetched += 1
        cursor = decoded.nextPageCursor
        if pagesFetched >= HopConfig.maxPages then break end
        if type(cursor) ~= "string" or cursor == "" then break end
        task.wait(0.3)
    until false

    -- Sort: 0 players muna, tapos lowest ping
    table.sort(allServers, function(a, b)
        if a.playing ~= b.playing then
            return a.playing < b.playing
        end
        return (a.ping or 999) < (b.ping or 999)
    end)
    return allServers
end

-- ============================================================
-- 🎯 HOP
-- ============================================================
local function hopTo(serverId)
    return pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)
end

-- ============================================================
-- 🎯 UI — COMPACT
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

local function createServerHopUI()
    if CoreGui:FindFirstChild("ServerHopUI") then
        CoreGui.ServerHopUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ServerHopUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    -- 🎯 COMPACT: 220 x 320
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 220, 0, 320)
    Main.Position = UDim2.new(0.5, -110, 0.5, -160)
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

    -- Refresh
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

    return {
        ScreenGui = ScreenGui, Main = Main,
        Status = Status, StatsLabel = StatsLabel,
        RefreshBtn = RefreshBtn, AutoRefreshBtn = AutoRefreshBtn,
        Scroll = Scroll, ScrollLayout = scrollLayout,
        CloseBtn = CloseBtn, InfoLabel = InfoLabel,
    }
end

local ui = createServerHopUI()

-- ============================================================
-- 🎯 SERVER ROW — COMPACT
-- ============================================================
local function createServerRow(parent, index, data)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, -6, 0, 30)
    row.BackgroundColor3 = COLORS.HOVER
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = index

    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local isZero = (data.playing == 0)
    local badgeColor = isZero and COLORS.EMPTY_GREEN or COLORS.LOW_GREEN
    local statusText = isZero and "SOLO" or "JOIN"

    local stroke2 = Instance.new("UIStroke", row)
    stroke2.Color = badgeColor
    stroke2.Thickness = 1
    stroke2.Transparency = 0.5

    -- Indicator
    local indicator = Instance.new("Frame", row)
    indicator.Size = UDim2.new(0, 3, 1, -6)
    indicator.Position = UDim2.new(0, 3, 0, 3)
    indicator.BackgroundColor3 = badgeColor
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    -- Player count
    local countLabel = Instance.new("TextLabel", row)
    countLabel.Size = UDim2.new(0, 55, 1, 0)
    countLabel.Position = UDim2.new(0, 10, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = ("%d / %d"):format(data.playing, data.maxPlayers)
    countLabel.TextColor3 = badgeColor
    countLabel.TextSize = 11
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Status text
    local playerLabel = Instance.new("TextLabel", row)
    playerLabel.Size = UDim2.new(0, 45, 1, 0)
    playerLabel.Position = UDim2.new(0, 65, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = isZero and "EMPTY" or "player"
    playerLabel.TextColor3 = badgeColor
    playerLabel.TextSize = 8
    playerLabel.Font = Enum.Font.GothamBold
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Ping
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

    -- Join badge
    local joinBadge = Instance.new("TextLabel", row)
    joinBadge.Size = UDim2.new(0, 40, 0, 14)
    joinBadge.Position = UDim2.new(1, -46, 0.5, -7)
    joinBadge.BackgroundColor3 = badgeColor
    joinBadge.BackgroundTransparency = 0.3
    joinBadge.Text = statusText
    joinBadge.TextColor3 = COLORS.TEXT
    joinBadge.TextSize = 7
    joinBadge.Font = Enum.Font.GothamBold
    Instance.new("UICorner", joinBadge).CornerRadius = UDim.new(0, 3)

    -- Hover
    row.MouseEnter:Connect(function()
        row.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
        joinBadge.BackgroundTransparency = 0
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = COLORS.HOVER
        joinBadge.BackgroundTransparency = 0.3
    end)

    -- Click
    row.MouseButton1Click:Connect(function()
        ui.Status.Text = ("🎯 Hopping %s..."):format(isZero and "SOLO" or "1-player")
        ui.Status.TextColor3 = COLORS.GREEN
        task.wait(0.3)
        hopTo(data.id)
    end)

    return row
end

-- ============================================================
-- 🎯 REFRESH
-- ============================================================
local autoRefreshEnabled = HopConfig.autoRefresh
local refreshing = false

local function refreshServerList()
    if refreshing then return end
    refreshing = true

    for _, child in ipairs(ui.Scroll:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    ui.Status.Text = "🔍 Fetching 0-1 servers..."
    ui.Status.TextColor3 = COLORS.YELLOW
    ui.RefreshBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 120)

    task.spawn(function()
        local servers, err = fetchServers()
        ui.RefreshBtn.BackgroundColor3 = COLORS.CYAN
        refreshing = false

        if not servers then
            ui.Status.Text = tostring(err)
            ui.Status.TextColor3 = COLORS.RED
            return
        end

        if #servers == 0 then
            ui.Status.Text = "❌ Walang 0-1 player server"
            ui.Status.TextColor3 = COLORS.RED
            return
        end

        local emptyCount, oneCount = 0, 0
        for _, s in ipairs(servers) do
            if s.playing == 0 then emptyCount += 1 else oneCount += 1 end
        end

        ui.Status.Text = ("✅ %d servers"):format(#servers)
        ui.Status.TextColor3 = COLORS.GREEN
        ui.StatsLabel.Text = ("🟢%d empty · %d 1-player"):format(emptyCount, oneCount)

        local yOffset = 0
        for i, serverData in ipairs(servers) do
            createServerRow(ui.Scroll, i, serverData)
            yOffset += 34
        end
        ui.Scroll.CanvasSize = UDim2.new(0, 0, 0, yOffset + 6)
    end)
end

-- ============================================================
-- 🎯 AUTO REFRESH LOOP
-- ============================================================
task.spawn(function()
    while ui.ScreenGui.Parent do
        task.wait(HopConfig.autoRefreshDelay)
        if autoRefreshEnabled and ui.ScreenGui.Parent and not refreshing then
            local rowCount = 0
            for _, child in ipairs(ui.Scroll:GetChildren()) do
                if child:IsA("TextButton") then rowCount += 1 end
            end
            if rowCount < 3 then
                ui.Status.Text = "🔄 Auto-refresh..."
                ui.Status.TextColor3 = COLORS.YELLOW
                refreshServerList()
            end
        end
    end
end)

-- ============================================================
-- 🎯 WIRING
-- ============================================================
ui.RefreshBtn.MouseButton1Click:Connect(function()
    if not refreshing then refreshServerList() end
end)

ui.RefreshBtn.MouseEnter:Connect(function()
    ui.RefreshBtn.BackgroundColor3 = Color3.fromRGB(120, 220, 255)
end)
ui.RefreshBtn.MouseLeave:Connect(function()
    ui.RefreshBtn.BackgroundColor3 = COLORS.CYAN
end)

ui.AutoRefreshBtn.MouseButton1Click:Connect(function()
    autoRefreshEnabled = not autoRefreshEnabled
    if autoRefreshEnabled then
        ui.AutoRefreshBtn.BackgroundColor3 = COLORS.LOW_GREEN
        ui.AutoRefreshBtn.Text = "Auto"
        ui.Status.Text = "✅ Auto ON"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.AutoRefreshBtn.BackgroundColor3 = COLORS.RED
        ui.AutoRefreshBtn.Text = "Off"
        ui.Status.Text = "❌ Auto OFF"
        ui.Status.TextColor3 = COLORS.RED
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    ui.ScreenGui:Destroy()
end)

task.spawn(function()
    task.wait(0.5)
    refreshServerList()
end)

print("[HOP] ✅ 0-1 Player Server Hop ready")
