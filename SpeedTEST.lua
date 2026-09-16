-- ============================================================
-- AUTO GRAB HIGH VALUE EGG — 150M+ ONLY
-- Pinaka-mataas na value lang (≥ 150 Million /s)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ============ STATE ============
local State = {
    running      = false,
    minArea      = 10,
    minValue     = 1.5e8,    -- 💰 150 MILLION minimum
    checkDelay   = 0.05,
    grabCooldown = 1,
    postGrabWait = 0.1,
}

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple", "Light Dark",
}

-- ============ MODULES ============
local EggState = nil
local AssetsDir = nil
local Mutations = nil
local AssetEarnings = nil

local function loadModules()
    if EggState then return true end
    local ok = pcall(function()
        local client = ReplicatedStorage:FindFirstChild("Client")
        if client then
            local es = client:FindFirstChild("EggState")
            if es then EggState = require(es) end
        end
        local data = ReplicatedStorage:FindFirstChild("Data")
        if data then
            local assets = data:FindFirstChild("Assets")
            if assets then
                local okA, mod = pcall(require, assets)
                if okA and mod then AssetsDir = mod.Directory end
            end
        end
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if shared then
            local modules = shared:FindFirstChild("Modules")
            if modules then
                local mut = modules:FindFirstChild("Mutations")
                if mut then
                    local okM, mod = pcall(require, mut)
                    if okM then Mutations = mod end
                end
            end
            local util = shared:FindFirstChild("Util")
            if util then
                local ae = util:FindFirstChild("AssetEarnings")
                if ae then
                    local okE, mod = pcall(require, ae)
                    if okE then AssetEarnings = mod end
                end
            end
        end
    end)
    return ok and EggState ~= nil
end

-- ============ HELPERS ============
local function getRarityNumber(rec)
    if rec and rec.Rarity and type(rec.Rarity) == "table" then
        return rec.Rarity.RarityNumber or 0
    end
    return 0
end

local function getAssetScale(rec)
    return tonumber(rec.AssetScale) or 1
end

local function getEggPos(rec)
    if not rec then return nil end
    if rec.BoundsCFrame and rec.BoundsCFrame.Position then
        return rec.BoundsCFrame.Position
    end
    return nil
end

-- ============ 💰 CALCULATE EGG VALUE ============
local function calcEggValue(rec)
    if not rec then return 0 end

    if AssetEarnings then
        local ok, rate = pcall(function()
            local item = {
                Category = rec.AssetCategory,
                Scale = tonumber(rec.AssetScale) or 1,
                Mutations = rec.Mutations or {},
            }
            return AssetEarnings.LiveRatePerSecond(item, nil, nil, LocalPlayer)
        end)
        if ok and type(rate) == "number" and rate > 0 then
            return rate
        end
    end

    local rarity = getRarityNumber(rec)
    local scale = getAssetScale(rec)
    local mutMult = 1

    if rec.Mutations and #rec.Mutations > 0 and Mutations then
        pcall(function()
            local item = { Mutations = rec.Mutations }
            mutMult = Mutations.EarningsFor(item) or 1
        end)
    end

    local baseRate = 0
    if AssetsDir then
        local dir = AssetsDir[rec.AssetCategory]
        if dir then baseRate = tonumber(dir.EarningRate) or 0 end
    end

    local scaleFactor = scale <= 5 and scale ^ 1.85 or (scale / 5) ^ 1.2 * 19.637875755794113
    local value = baseRate * scaleFactor * mutMult
    return math.max(1, math.round(value))
end

-- ============ FIND HIGHEST VALUE EGG (≥ 150M) ============
local function findHighestValueEgg()
    if not EggState then return nil, 0 end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil, 0 end

    local bestRec = nil
    local bestValue = 0

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local areaIdx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then areaIdx = i break end
            end

            if areaIdx and areaIdx >= State.minArea then
                local value = calcEggValue(rec)
                -- 💰 FILTER: ≥ 150M lang
                if value >= State.minValue and value > bestValue then
                    bestValue = value
                    bestRec = rec
                end
            end
        end
    end

    return bestRec, bestValue
end

-- ============ FAST GRAB ============
local function fastGrabEgg(rec)
    if not rec then return false, "no rec" end

    local ok1, res1 = pcall(function()
        return EggState.CarryFieldEgg(rec.Uid)
    end)
    if ok1 and res1 == true then
        return true, "instant"
    end

    local eggPos = getEggPos(rec)
    if not eggPos then return false, "no pos" end

    local CarryAreaEggs = Workspace:QueryDescendants("#CarryAreaEgg")
    local closetprompt, closetdist = nil, math.huge
    for _, prompt in next, CarryAreaEggs do
        local p = prompt.Parent
        if p then
            local dist = (eggPos - p.Position).Magnitude
            if dist < closetdist then
                closetdist = dist
                closetprompt = prompt
            end
        end
    end

    if closetprompt and fireproximityprompt then
        pcall(function()
            closetprompt.HoldDuration = 0
            fireproximityprompt(closetprompt, 0)
        end)
        return true, "prompt"
    end

    return false, "no prompt"
end

-- ============ FORMAT NUMBER ============
local function formatNumber(n)
    n = tonumber(n) or 0
    local units = {{1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"}}
    for _, u in ipairs(units) do
        if n >= u[1] then
            local v = n / u[1]
            return string.format("%.2f%s", v, u[2])
        end
    end
    return tostring(math.round(n))
end

-- ============ MAIN LOOP ============
local function mainLoop()
    State.running = true
    warn("=== HIGH VALUE AUTO GRAB START (150M+) ===")

    local lastGrabbed = {}
    local grabCount = 0

    while State.running do
        task.wait(State.checkDelay)
        if not State.running then break end

        if not loadModules() then
            task.wait(0.5)
            continue
        end

        local rec, value = findHighestValueEgg()
        if rec and value >= State.minValue then
            local lastTime = lastGrabbed[rec.Uid]
            if not lastTime or (tick() - lastTime) > State.grabCooldown then
                lastGrabbed[rec.Uid] = tick()

                local ok, method = fastGrabEgg(rec)
                if ok then
                    grabCount = grabCount + 1
                    warn(("[GRAB #%d] ✅ %s | %s /s | %s | %s"):format(
                        grabCount, rec.AreaId, formatNumber(value), method, rec.Uid))
                end

                task.wait(State.postGrabWait)
            end
        end

        if grabCount % 50 == 0 then
            local now = tick()
            for uid, t in pairs(lastGrabbed) do
                if now - t > 30 then lastGrabbed[uid] = nil end
            end
        end
    end

    warn("=== HIGH VALUE AUTO GRAB STOP ===")
end

-- ============ UI ============
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    STROKE = Color3.fromRGB(60, 60, 70),
    TEXT = Color3.fromRGB(255, 255, 255),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
    YELLOW = Color3.fromRGB(255, 200, 0),
    GOLD = Color3.fromRGB(255, 215, 0),
}

local function createUI()
    if CoreGui:FindFirstChild("AutoGrabUI") then
        CoreGui.AutoGrabUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "AutoGrabUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 290, 0, 175)
    Main.Position = UDim2.new(0.5, -145, 0.5, -87)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local s1 = Instance.new("UIStroke", Main)
    s1.Color = COLORS.STROKE

    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

    local TitleCover = Instance.new("Frame", TitleBar)
    TitleCover.Size = UDim2.new(1, 0, 0, 10)
    TitleCover.Position = UDim2.new(0, 0, 1, -10)
    TitleCover.BackgroundColor3 = COLORS.TITLE_BG
    TitleCover.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "💰 Auto Grab 150M+"
    Title.TextColor3 = COLORS.GOLD
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -32, 0, 5)
    CloseBtn.BackgroundColor3 = COLORS.RED
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = COLORS.TEXT
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -120, 0, 25)
    lbl.Position = UDim2.new(0, 15, 0, 55)
    lbl.BackgroundTransparency = 1
    lbl.Text = "💰 150M+ Only"
    lbl.TextColor3 = COLORS.TEXT
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = Instance.new("TextLabel", Main)
    state.Size = UDim2.new(0, 45, 0, 25)
    state.Position = UDim2.new(1, -120, 0, 55)
    state.BackgroundTransparency = 1
    state.Text = "OFF"
    state.TextColor3 = COLORS.RED
    state.TextSize = 13
    state.Font = Enum.Font.GothamBold
    state.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", Main)
    track.Size = UDim2.new(0, 50, 0, 26)
    track.Position = UDim2.new(1, -65, 0, 55)
    track.BackgroundColor3 = COLORS.TRACK_OFF
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 3, 0.5, -10)
    knob.BackgroundColor3 = COLORS.KNOB
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(0, 110, 0, 36)
    btn.Position = UDim2.new(1, -120, 0, 50)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    local InfoLbl = Instance.new("TextLabel", Main)
    InfoLbl.Size = UDim2.new(1, -30, 0, 18)
    InfoLbl.Position = UDim2.new(0, 15, 0, 90)
    InfoLbl.BackgroundTransparency = 1
    InfoLbl.Text = "Best: -- /s"
    InfoLbl.TextColor3 = COLORS.GOLD
    InfoLbl.TextSize = 11
    InfoLbl.Font = Enum.Font.GothamBold
    InfoLbl.TextXAlignment = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 18)
    Status.Position = UDim2.new(0, 15, 0, 110)
    Status.BackgroundTransparency = 1
    Status.Text = "Min: 150.00M /s"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    local Stats = Instance.new("TextLabel", Main)
    Stats.Size = UDim2.new(1, -30, 0, 18)
    Stats.Position = UDim2.new(0, 15, 0, 130)
    Stats.BackgroundTransparency = 1
    Stats.Text = "Grabbed: 0"
    Stats.TextColor3 = COLORS.GREEN
    Stats.TextSize = 10
    Stats.Font = Enum.Font.Gotham
    Stats.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        track = track, knob = knob, state = state, btn = btn,
        Status = Status, InfoLbl = InfoLbl, Stats = Stats,
        CloseBtn = CloseBtn
    }
end

local ui = createUI()

local function setToggle(on)
    ui.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    ui.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    ui.state.Text = on and "ON" or "OFF"
    ui.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- Live info update
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.running then
            local rec, value = findHighestValueEgg()
            if rec and value > 0 then
                ui.InfoLbl.Text = ("Best: %s /s (%s)"):format(formatNumber(value), rec.AreaId)
            else
                ui.InfoLbl.Text = "Best: -- /s"
            end
        end
    end
end)

-- Toggle click
ui.btn.MouseButton1Click:Connect(function()
    if not State.running then
        if not loadModules() then
            ui.Status.Text = "❌ EggState not found"
            ui.Status.TextColor3 = COLORS.RED
            return
        end
        setToggle(true)
        ui.Status.Text = "Min: 150.00M /s"
        ui.Status.TextColor3 = COLORS.GREEN
        task.spawn(mainLoop)
    else
        State.running = false
        setToggle(false)
        ui.Status.Text = "Stopped"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    State.running = false
    ui.ScreenGui:Destroy()
end)

-- Auto-init
task.spawn(function()
    task.wait(0.5)
    if loadModules() then
        ui.Status.Text = "✅ Ready | Min: 150.00M /s"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.Status.Text = "⚠️ Waiting for game..."
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)
