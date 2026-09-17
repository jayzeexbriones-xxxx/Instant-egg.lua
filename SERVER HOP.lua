-- ============================================================
-- 🎯 SERVER HOP — Auto Refresh Until Low Player Server Found
-- Puro empty/low lang ang nakikita
-- ============================================================

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ CONFIG ============
local HopConfig = {
    maxPlayers = 3,          -- 🎯 Max players (0-3 lang ipapakita)
    autoRefresh = true,      -- 🔄 Auto-refresh pag puro puno
    autoRefreshDelay = 5,    -- Seconds bago mag-auto refresh
    maxPages = 5,            -- Ilang pages ng servers hanapin
    timeout = 15,
}

-- ============================================================
-- 🎯 FETCH SERVERS (multi-page)
-- ============================================================
local function fetchServers()
    local requester = (syn and syn.request)
        or (http and http.request) or http_request or request
    
    if type(requester) ~= "function" then
        return nil, "❌ Walang HTTP requester"
    end
    
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
            Url = url,
            Method = "GET",
            Headers = { ["Accept"] = "application/json" },
        })
        
        if not ok or type(response) ~= "table" then
            break
        end
        
        local statusCode = tonumber(response.StatusCode or response.Status)
        if not statusCode or statusCode < 200 or statusCode >= 300 then
            break
        end
        
        local body = response.Body or response.body or ""
        local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, body)
        
        if not decodeOk or type(decoded) ~= "table" then
            break
        end
        
        local servers = decoded.data or {}
        for _, srv in ipairs(servers) do
            if type(srv) == "table" and srv.id and srv.id ~= game.JobId 
               and not seen[srv.id] then
                local playing = tonumber(srv.playing) or 0
                local maxP = tonumber(srv.maxPlayers) or 0
                if playing <= HopConfig.maxPlayers and playing < maxP then
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
        
        task.wait(0.3) -- Rate limit prevent
    until false
    
    -- Sort: lowest players first
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
    local ok = pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, serverId, LocalPlayer)
    end)
    return ok
end

-- ============================================================
-- 🎯 UI
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
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 320, 0, 480)
    Main.Position = UDim2.new(0.5, -160, 0.5, -240)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = COLORS.STROKE
    
    -- Title
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
    
    local TitleCover = Instance.new("Frame", TitleBar)
    TitleCover.Size = UDim2.new(1, 0, 0, 10)
    TitleCover.Position = UDim2.new(0, 0, 1, -10)
    TitleCover.BackgroundColor3 = COLORS.TITLE_BG
    TitleCover.BorderSizePixel = 0
    
    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎯 Server Hop — Low Player Only"
    Title.TextColor3 = COLORS.CYAN
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Position = UDim2.new(1, -27, 0, 5)
    CloseBtn.BackgroundColor3 = COLORS.RED
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = COLORS.TEXT
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
    
    -- Status Bar
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -24, 0, 20)
    Status.Position = UDim2.new(0, 12, 0, 40)
    Status.BackgroundTransparency = 1
    Status.Text = "🔍 Loading servers..."
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Stats
    local StatsLabel = Instance.new("TextLabel", Main)
    StatsLabel.Size = UDim2.new(1, -24, 0, 16)
    StatsLabel.Position = UDim2.new(0, 12, 0, 58)
    StatsLabel.BackgroundTransparency = 1
    StatsLabel.Text = ""
    StatsLabel.TextColor3 = COLORS.CYAN
    StatsLabel.TextSize = 9
    StatsLabel.Font = Enum.Font.Gotham
    StatsLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Refresh Button
    local RefreshBtn = Instance.new("TextButton", Main)
    RefreshBtn.Size = UDim2.new(0, 80, 0, 24)
    RefreshBtn.Position = UDim2.new(1, -92, 0, 40)
    RefreshBtn.BackgroundColor3 = COLORS.CYAN
    RefreshBtn.BorderSizePixel = 0
    RefreshBtn.Text = "🔄 Refresh"
    RefreshBtn.TextColor3 = COLORS.TEXT
    RefreshBtn.TextSize = 10
    RefreshBtn.Font = Enum.Font.GothamBold
    RefreshBtn.AutoButtonColor = false
    Instance.new("UICorner", RefreshBtn).CornerRadius = UDim.new(0, 5)
    
    -- 🎯 Auto-Refresh Toggle
    local AutoRefreshBtn = Instance.new("TextButton", Main)
    AutoRefreshBtn.Size = UDim2.new(0, 80, 0, 20)
    AutoRefreshBtn.Position = UDim2.new(0, 12, 0, 78)
    AutoRefreshBtn.BackgroundColor3 = COLORS.LOW_GREEN
    AutoRefreshBtn.BorderSizePixel = 0
    AutoRefreshBtn.Text = "🔄 Auto: ON"
    AutoRefreshBtn.TextColor3 = COLORS.TEXT
    AutoRefreshBtn.TextSize = 9
    AutoRefreshBtn.Font = Enum.Font.GothamBold
    AutoRefreshBtn.AutoButtonColor = false
    Instance.new("UICorner", AutoRefreshBtn).CornerRadius = UDim.new(0, 4)
    
    -- Scroll
    local Scroll = Instance.new("ScrollingFrame", Main)
    Scroll.Size = UDim2.new(1, -24, 1, -120)
    Scroll.Position = UDim2.new(0, 12, 0, 104)
    Scroll.BackgroundColor3 = COLORS.DARK
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 4
    Scroll.ScrollBarImageColor3 = COLORS.CYAN
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 6)
    local scrollPadding = Instance.new("UIPadding", Scroll)
    scrollPadding.PaddingTop = UDim.new(0, 4)
    scrollPadding.PaddingBottom = UDim.new(0, 4)
    scrollPadding.PaddingLeft = UDim.new(0, 4)
    scrollPadding.PaddingRight = UDim.new(0, 4)
    local scrollLayout = Instance.new("UIListLayout", Scroll)
    scrollLayout.Padding = UDim.new(0, 4)
    scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Info
    local InfoLabel = Instance.new("TextLabel", Main)
    InfoLabel.Size = UDim2.new(1, -24, 0, 16)
    InfoLabel.Position = UDim2.new(0, 12, 1, -22)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "💡 Click any server para mag-hop"
    InfoLabel.TextColor3 = COLORS.TEXT
    InfoLabel.TextSize = 9
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
-- 🎯 SERVER ROW
-- ============================================================
local function createServerRow(parent, index, data)
    local row = Instance.new("TextButton", parent)
    row.Size = UDim2.new(1, -8, 0, 42)
    row.BackgroundColor3 = COLORS.HOVER
    row.BorderSizePixel = 0
    row.Text = ""
    row.AutoButtonColor = false
    row.LayoutOrder = index
    
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    
    local stroke = Instance.new("UIStroke", row)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    
    local playing = data.playing
    local maxP = data.maxPlayers
    
    -- Color based on players
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
    
    -- Indicator
    local indicator = Instance.new("Frame", row)
    indicator.Size = UDim2.new(0, 4, 1, -8)
    indicator.Position = UDim2.new(0, 4, 0, 4)
    indicator.BackgroundColor3 = badgeColor
    indicator.BorderSizePixel = 0
    Instance.new("UICorner", indicator).CornerRadius = UDim.new(1, 0)
    
    -- Player count
    local countLabel = Instance.new("TextLabel", row)
    countLabel.Size = UDim2.new(0, 80, 1, 0)
    countLabel.Position = UDim2.new(0, 14, 0, 0)
    countLabel.BackgroundTransparency = 1
    countLabel.Text = ("%d / %d"):format(playing, maxP)
    countLabel.TextColor3 = badgeColor
    countLabel.TextSize = 14
    countLabel.Font = Enum.Font.GothamBold
    countLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- "players"
    local playerLabel = Instance.new("TextLabel", row)
    playerLabel.Size = UDim2.new(0, 60, 1, 0)
    playerLabel.Position = UDim2.new(0, 90, 0, 0)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Text = "players"
    playerLabel.TextColor3 = COLORS.TEXT
    playerLabel.TextSize = 10
    playerLabel.Font = Enum.Font.Gotham
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Ping info
    if data.ping then
        local pingLabel = Instance.new("TextLabel", row)
        pingLabel.Size = UDim2.new(0, 60, 1, 0)
        pingLabel.Position = UDim2.new(0, 155, 0, 0)
        pingLabel.BackgroundTransparency = 1
        pingLabel.Text = ("%dms"):format(math.floor(data.ping))
        pingLabel.TextColor3 = COLORS.YELLOW
        pingLabel.TextSize = 9
        pingLabel.Font = Enum.Font.Gotham
        pingLabel.TextXAlignment = Enum.TextXAlignment.Left
    end
    
    -- Status badge
    local statusBadge = Instance.new("TextLabel", row)
    statusBadge.Size = UDim2.new(0, 50, 0, 18)
    statusBadge.Position = UDim2.new(1, -60, 0.5, -9)
    statusBadge.BackgroundColor3 = badgeColor
    statusBadge.BackgroundTransparency = 0.7
    statusBadge.Text = statusText
    statusBadge.TextColor3 = COLORS.TEXT
    statusBadge.TextSize = 8
    statusBadge.Font = Enum.Font.GothamBold
    Instance.new("UICorner", statusBadge).CornerRadius = UDim.new(0, 3)
    
    -- Hover
    row.MouseEnter:Connect(function()
        row.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    end)
    row.MouseLeave:Connect(function()
        row.BackgroundColor3 = COLORS.HOVER
    end)
    
    -- Click to hop
    row.MouseButton1Click:Connect(function()
        ui.Status.Text = ("🎯 Hopping to %d/%d players server..."):format(playing, maxP)
        ui.Status.TextColor3 = COLORS.GREEN
        task.wait(0.3)
        hopTo(data.id)
    end)
    
    return row
end

-- ============================================================
-- 🎯 REFRESH LOGIC
-- ============================================================
local autoRefreshEnabled = HopConfig.autoRefresh
local refreshing = false

local function refreshServerList()
    if refreshing then return end
    refreshing = true
    
    -- Clear rows
    for _, child in ipairs(ui.Scroll:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    
    ui.Status.Text = "🔍 Fetching servers..."
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
            ui.Status.Text = "❌ Walang low-player servers"
            ui.Status.TextColor3 = COLORS.RED
            ui.StatsLabel.Text = "Hintayin mo mag-refresh..."
            return
        end
        
        -- Count by type
        local emptyCount, lowCount, midCount = 0, 0, 0
        for _, s in ipairs(servers) do
            if s.playing == 0 then emptyCount += 1
            elseif s.playing <= 2 then lowCount += 1
            elseif s.playing <= 4 then midCount += 1
            end
        end
        
        ui.Status.Text = ("✅ %d servers nahanap"):format(#servers)
        ui.Status.TextColor3 = COLORS.GREEN
        ui.StatsLabel.Text = ("🟢 %d empty | %d low | %d mid"):format(
            emptyCount, lowCount, midCount)
        
        -- Create rows
        local yOffset = 0
        for i, serverData in ipairs(servers) do
            createServerRow(ui.Scroll, i, serverData)
            yOffset += 46
        end
        
        ui.Scroll.CanvasSize = UDim2.new(0, 0, 0, yOffset + 8)
    end)
end

-- ============================================================
-- 🎯 AUTO REFRESH LOOP
-- ============================================================
task.spawn(function()
    while ui.ScreenGui.Parent do
        task.wait(HopConfig.autoRefreshDelay)
        
        if autoRefreshEnabled and ui.ScreenGui.Parent and not refreshing then
            -- Count rows (servers)
            local rowCount = 0
            for _, child in ipairs(ui.Scroll:GetChildren()) do
                if child:IsA("TextButton") then
                    rowCount += 1
                end
            end
            
            -- Auto refresh pag wala o konti servers
            if rowCount < 3 then
                ui.Status.Text = "🔄 Auto-refresh (konti servers)..."
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
        ui.AutoRefreshBtn.Text = "🔄 Auto: ON"
        ui.Status.Text = "✅ Auto-refresh ON"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.AutoRefreshBtn.BackgroundColor3 = COLORS.HIGH_RED
        ui.AutoRefreshBtn.Text = "🔄 Auto: OFF"
        ui.Status.Text = "❌ Auto-refresh OFF"
        ui.Status.TextColor3 = COLORS.RED
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    ui.ScreenGui:Destroy()
end)

-- Start
task.spawn(function()
    task.wait(0.5)
    refreshServerList()
end)

print("[HOP] ✅ Server Hop UI ready")
