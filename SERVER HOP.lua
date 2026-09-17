-- ============================================================
-- 🎯 SERVER HOP — COMPACT UI
-- Maliit lang, working pa rin
-- ============================================================

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
local HopConfig = {
    maxPlayers = 3,
    autoRefresh = true,
    autoRefreshDelay = 5,
    maxPages = 5,
}

-- ============================================================
-- 🎯 FETCH SERVERS
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
                if playing <= HopConfig.maxPlayers and playing < maxP then
                    seen[srv.id] = true
                    allServers[#allServers + 1] = {
                        id = srv.id, playing = playing, maxPlayers = maxP,
                        ping = tonumber(srv.ping), fps = tonumber(srv.fps),
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

    table.sort(allServers, function(a, b)
        if a.playing ~= b.playing then return a.playing < b.playing end
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
    MID_YELLOW = Color3.fromRGB(180, 140, 30),
    HIGH_RED = Color3.fromRGB(160, 60, 60),
}

local function createServerHopUI()
    if CoreGui:FindFirstChild("ServerHopUI") then
        CoreGui.ServerHopUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ServerHopUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    -- 🎯 COMPACT: 220 x 320 (from 320 x 480)
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

    -- Title (28px from 32)
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
    Title.Text = "🎯 Server Hop"
    Title.TextColor3 = COLORS.CYAN
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

    -- Status (small)
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -20, 0, 14)
    Status.Position = UDim2.new(0, 10, 0, 34)
    Status.BackgroundTransparency = 1
    Status.Text = "🔍 Loading..."
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 9
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    -- Stats (small)
    local StatsLabel = Instance.new("TextLabel", Main)
    StatsLabel.Size = UDim2.new(1, -20, 0, 12)
    StatsLabel.Position = UDim2.new(0, 10, 0, 48)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Text = ""
    StatsLabel.TextColor3 = COLORS.CYAN
    StatsLabel.TextSize = 8
    StatsLabel.Font = Enum.Font.Gotham
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Refresh button (small)
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

    -- Auto-refresh toggle (small)
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

    -- Scroll (compact)
    local Scroll = Instance.new("ScrollingFrame", Main)
    Scroll.Size = UDim2.new(1, -20, 1, -100)
    Scroll.Position = UDim2.new(0, 10, 0, 76)
    Scroll.BackgroundColor3 = COLORS.DARK
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 3
    Scroll.ScrollBarImageColor3 = COLORS.CYAN
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

    -- Info (small)
    local InfoLabel = Instance.new("TextLabel", Main)
    InfoLabel.Size = UDim2.new(1, -20, 0, 12)
    InfoLabel.Position = UDim2.new(0, 10, 1, -18)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "💡 Click server"
    InfoLabel.TextColor3 = COLORS.TEXT
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
-- 🎯 SERVER ROW — COMPACT (36px from 46)
-- ============================================================
local function createServerRow(parent, index, data)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, -6, 0, 30)  -- Compact height
    row.BackgroundColor3 = COLORS.HOVER
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = index

    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)

    local stroke = Instance.new("UIStroke", row)
    stroke.Thickness = 1
    stroke.Transparency = 0.5

    local playing = data.playing
    local maxP = data.maxPlayers

    local badgeColor, statusText
    if playing == 0 then
        badgeColor = COLORS.EMPTY_GREEN
        statusText = "EMPTY"
    elseif playing <= 2 then
        badgeColor = COLORS.LOW_GREEN
        statusText = "LOW"
    elseif playing <= 4 then
        badgeColor = COLORS.MID_YELLOW
        statusText = "MID"
    else
        badgeColor = COLORS.HIGH_RED
        statusText = "HIGH"
    end

    stroke.Color = badgeColor

    -- Indicator (thin)
    local indicator = Instance.new("Frame", row)
    indicator.Size = UDim2.new(0, 3, 1, -6)
    indicator.Position = UDim2.new(0, 3, 0, 3)
    indicator.BackgroundColor3 = badgeColor
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)

    -- Player count (small)
    local countLabel = Instance.new("TextLabel", row)
    countLabel.Size = UDim2.new(0, 55, 1, 0)
    countLabel.Position = UDim2.new(0, 10, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = ("%d / %d"):format(playing, maxP)
    countLabel.TextColor3 = badgeColor
    countLabel.TextSize = 11
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- "players" (small)
    local playerLabel = Instance.new("TextLabel", row)
    playerLabel.Size = UDim2.new(0, 45, 1, 0)
    playerLabel.Position = UDim2.new(0, 65, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "players"
    playerLabel.TextColor3 = COLORS.TEXT
    playerLabel.TextSize = 8
    playerLabel.Font = Enum.Font.Gotham
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- Status badge (small)
    local statusBadge = Instance.new("TextLabel", row)
    statusBadge.Size = UDim2.new(0, 40, 0, 14)
    statusBadge.Position = UDim2.new(1, -46, 0.5, -7)
    statusBadge.BackgroundColor3 = badgeColor
    statusBadge.BackgroundTransparency = 0.7
    statusBadge.Text = statusText
    statusBadge.TextColor3 = COLORS.TEXT
    statusBadge.TextSize = 7
    statusBadge.Font = Enum.Font.GothamBold
    Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 3)

    -- Hover
    row.MouseEnter:Connect(function()
        row.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = COLORS.HOVER
    end)

    -- Click
    row.MouseButton1Click:Connect(function()
        ui.Status.Text = ("🎯 Hopping %d/%d..."):format(playing, maxP)
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

    ui.Status.Text = "🔍 Fetching..."
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
            ui.Status.Text = "❌ Walang low-player"
            ui.Status.TextColor3 = COLORS.RED
            return
        end

        local emptyCount, lowCount, midCount = 0, 0, 0
        for _, s in ipairs(servers) do
            if s.playing == 0 then emptyCount += 1
            elseif s.playing <= 2 then lowCount += 1
            elseif s.playing <= 4 then midCount += 1
            end
        end

        ui.Status.Text = ("✅ %d servers"):format(#servers)
        ui.Status.TextColor3 = COLORS.GREEN
        ui.StatsLabel.Text = ("🟢%d empty · %d low · %d mid"):format(
            emptyCount, lowCount, midCount)

        local yOffset = 0
        for i, serverData in ipairs(servers) do
            createServerRow(ui.Scroll, i, serverData)
            yOffset += 34  -- Compact row + padding
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
        ui.AutoRefreshBtn.BackgroundColor3 = COLORS.HIGH_RED
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

print("[HOP] ✅ Compact Server Hop UI ready")
