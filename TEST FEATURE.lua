-- ============================================================
-- AUTO GRAB — HIGHEST FIRST + ESP LINE TO BEST EGG
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local RunService        = game:GetService("RunService")
local LocalPlayer       = Players.LocalPlayer

-- ============ STATE ============
local State = {
    running      = false,
    minArea      = 10,
    minValue     = 5e7,
    checkDelay   = 0.1,
    grabCooldown = 2,
    postGrabWait = 0.3,
    espEnabled   = true,
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

-- ============ CALCULATE EGG VALUE ============
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

-- ============ FIND ALL EGGS ============
local function findAllHighValueEggs()
    if not EggState then return {} end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return {} end

    local eggs = {}

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local areaIdx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then areaIdx = i break end
            end

            if areaIdx and areaIdx >= State.minArea then
                local value = calcEggValue(rec)
                if value >= State.minValue then
                    eggs[#eggs + 1] = { rec = rec, value = value }
                end
            end
        end
    end

    table.sort(eggs, function(a, b) return a.value > b.value end)
    return eggs
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

-- ============================================================
-- ESP LINE SYSTEM
-- ============================================================
local ESP = {
    line = nil,
    targetPart = nil,
    targetPos = nil,
}

local function createESPLine()
    if ESP.line then return end
    local line = Instance.new("Part")
    line.Name = "ESP_BestEggLine"
    line.Anchored = true
    line.CanCollide = false
    line.CanQuery = false
    line.CanTouch = false
    line.Transparency = 0.3
    line.Color = Color3.fromRGB(255, 215, 0)
    line.Material = Enum.Material.Neon
    line.Size = Vector3.new(0.15, 0.15, 1)
    line.Parent = Workspace
    ESP.line = line
end

local function updateESPLine()
    if not State.espEnabled then
        if ESP.line then ESP.line.Transparency = 1 end
        return
    end

    if not ESP.line then createESPLine() end
    if not ESP.line then return end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        ESP.line.Transparency = 1
        return
    end

    if not ESP.targetPos then
        ESP.line.Transparency = 1
        return
    end

    if ESP.targetPart and not ESP.targetPart.Parent then
        ESP.targetPart = nil
        ESP.targetPos = nil
        ESP.line.Transparency = 1
        return
    end

    local startPos = hrp.Position
    local endPos = ESP.targetPos
    local midPos = (startPos + endPos) / 2
    local distance = (endPos - startPos).Magnitude

    ESP.line.CFrame = CFrame.new(midPos, endPos)
    ESP.line.Size = Vector3.new(0.15, 0.15, distance)
    ESP.line.Transparency = 0.3
end

local function setESPTarget(rec)
    if not rec then
        ESP.targetPart = nil
        ESP.targetPos = nil
        return
    end
    local eggPos = getEggPos(rec)
    if eggPos then
        ESP.targetPos = eggPos
        local model = Workspace:FindFirstChild(rec.Uid, true)
        if model then
            ESP.targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        end
    end
end

local function clearESP()
    if ESP.line then
        ESP.line:Destroy()
        ESP.line = nil
    end
    ESP.targetPart = nil
    ESP.targetPos = nil
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
local function mainLoop()
    State.running = true
    warn("=== AUTO GRAB START (Highest First + ESP) ===")

    local lastGrabbed = {}
    local grabCount = 0

    while State.running do
        task.wait(State.checkDelay)
        if not State.running then break end

        if not loadModules() then
            task.wait(0.5)
            continue
        end

        local eggs = findAllHighValueEggs()

        if #eggs > 0 then
            setESPTarget(eggs[1].rec)
        else
            setESPTarget(nil)
        end

        if #eggs > 0 then
            local grabbed = false
            for _, item in ipairs(eggs) do
                if not State.running then break end

                local rec = item.rec
                local value = item.value
                local lastTime = lastGrabbed[rec.Uid]

                if not lastTime or (tick() - lastTime) > State.grabCooldown then
                    lastGrabbed[rec.Uid] = tick()

                    warn(("[TARGET] %s /s (%s) — grabbing"):format(
                        formatNumber(value), rec.AreaId))

                    local ok, method = fastGrabEgg(rec)
                    if ok then
                        grabCount = grabCount + 1
                        warn(("[GRAB #%d] ✅ %s | %s /s | %s"):format(
                            grabCount, rec.AreaId, formatNumber(value), method))
                        grabbed = true
                        break
                    end

                    task.wait(State.postGrabWait)
                end
            end

            if not grabbed then
                task.wait(0.3)
            end
        else
            task.wait(0.5)
        end

        if grabCount % 50 == 0 then
            local now = tick()
            for uid, t in pairs(lastGrabbed) do
                if now - t > 30 then lastGrabbed[uid] = nil end
            end
        end
    end

    clearESP()
    warn("=== AUTO GRAB STOP ===")
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
    CYAN = Color3.fromRGB(80, 200, 255),
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
    Main.Size = UDim2.new(0, 300, 0, 240)
    Main.Position = UDim2.new(0.5, -150, 0.5, -120)
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
    Title.Text = "💰 Auto Grab — Highest First"
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

    -- Auto Grab Toggle
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -120, 0, 25)
    lbl.Position = UDim2.new(0, 15, 0, 50)
    lbl.BackgroundTransparency = 1
    lbl.Text = "💰 Auto Grab"
    lbl.TextColor3 = COLORS.TEXT
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = Instance.new("TextLabel", Main)
    state.Size = UDim2.new(0, 45, 0, 25)
    state.Position = UDim2.new(1, -120, 0, 50)
    state.BackgroundTransparency = 1
    state.Text = "OFF"
    state.TextColor3 = COLORS.RED
    state.TextSize = 13
    state.Font = Enum.Font.GothamBold
    state.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", Main)
    track.Size = UDim2.new(0, 50, 0, 26)
    track.Position = UDim2.new(1, -65, 0, 50)
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
    btn.Position = UDim2.new(1, -120, 0, 45)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    -- ESP Toggle
    local espLbl = Instance.new("TextLabel", Main)
    espLbl.Size = UDim2.new(1, -120, 0, 25)
    espLbl.Position = UDim2.new(0, 15, 0, 80)
    espLbl.BackgroundTransparency = 1
    espLbl.Text = "📡 ESP Line to Best"
    espLbl.TextColor3 = COLORS.TEXT
    espLbl.TextSize = 14
    espLbl.Font = Enum.Font.GothamBold
    espLbl.TextXAlignment = Enum.TextXAlignment.Left

    local espState = Instance.new("TextLabel", Main)
    espState.Size = UDim2.new(0, 45, 0, 25)
    espState.Position = UDim2.new(1, -120, 0, 80)
    espState.BackgroundTransparency = 1
    espState.Text = "ON"
    espState.TextColor3 = COLORS.GREEN
    espState.TextSize = 13
    espState.Font = Enum.Font.GothamBold
    espState.TextXAlignment = Enum.TextXAlignment.Right

    local espTrack = Instance.new("Frame", Main)
    espTrack.Size = UDim2.new(0, 50, 0, 26)
    espTrack.Position = UDim2.new(1, -65, 0, 80)
    espTrack.BackgroundColor3 = COLORS.GREEN
    espTrack.BorderSizePixel = 0
    Instance.new("UICorner", espTrack).CornerRadius = UDim.new(1, 0)

    local espKnob = Instance.new("Frame", espTrack)
    espKnob.Size = UDim2.new(0, 20, 0, 20)
    espKnob.Position = UDim2.new(0, 27, 0.5, -10)
    espKnob.BackgroundColor3 = COLORS.KNOB
    espKnob.BorderSizePixel = 0
    Instance.new("UICorner", espKnob).CornerRadius = UDim.new(1, 0)

    local espBtn = Instance.new("TextButton", Main)
    espBtn.Size = UDim2.new(0, 110, 0, 36)
    espBtn.Position = UDim2.new(1, -120, 0, 75)
    espBtn.BackgroundTransparency = 1
    espBtn.Text = ""

    -- Info lines
    local InfoLbl = Instance.new("TextLabel", Main)
    InfoLbl.Size = UDim2.new(1, -30, 0, 18)
    InfoLbl.Position = UDim2.new(0, 15, 0, 115)
    InfoLbl.BackgroundTransparency = 1
    InfoLbl.Text = "🎯 Next: --"
    InfoLbl.TextColor3 = COLORS.CYAN
    InfoLbl.TextSize = 11
    InfoLbl.Font = Enum.Font.GothamBold
    InfoLbl.TextXAlignment = Enum.TextXAlignment.Left

    local QueueLbl = Instance.new("TextLabel", Main)
    QueueLbl.Size = UDim2.new(1, -30, 0, 18)
    QueueLbl.Position = UDim2.new(0, 15, 0, 133)
    QueueLbl.BackgroundTransparency = 1
    QueueLbl.Text = "📋 Queue: 0 eggs"
    QueueLbl.TextColor3 = COLORS.YELLOW
    QueueLbl.TextSize = 11
    QueueLbl.Font = Enum.Font.Gotham
    QueueLbl.TextXAlignment = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 18)
    Status.Position = UDim2.new(0, 15, 0, 151)
    Status.BackgroundTransparency = 1
    Status.Text = "Min: 50.00M | Highest First"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    local Stats = Instance.new("TextLabel", Main)
    Stats.Size = UDim2.new(1, -30, 0, 18)
    Stats.Position = UDim2.new(0, 15, 0, 169)
    Stats.BackgroundTransparency = 1
    Stats.Text = "✅ Grabbed: 0"
    Stats.TextColor3 = COLORS.GREEN
    Stats.TextSize = 10
    Stats.Font = Enum.Font.GothamBold
    Stats.TextXAlignment = Enum.TextXAlignment.Left

    local LastLbl = Instance.new("TextLabel", Main)
    LastLbl.Size = UDim2.new(1, -30, 0, 18)
    LastLbl.Position = UDim2.new(0, 15, 0, 189)
    LastLbl.BackgroundTransparency = 1
    LastLbl.Text = "Last: --"
    LastLbl.TextColor3 = COLORS.GREEN
    LastLbl.TextSize = 10
    LastLbl.Font = Enum.Font.Gotham
    LastLbl.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        track = track, knob = knob, state = state, btn = btn,
        espTrack = espTrack, espKnob = espKnob, espState = espState, espBtn = espBtn,
        Status = Status, InfoLbl = InfoLbl, QueueLbl = QueueLbl,
        Stats = Stats, LastLbl = LastLbl, CloseBtn = CloseBtn
    }
end

local ui = createUI()

local function setToggle(track, knob, state, on)
    track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    state.Text = on and "ON" or "OFF"
    state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- ESP Toggle click
ui.espBtn.MouseButton1Click:Connect(function()
    State.espEnabled = not State.espEnabled
    setToggle(ui.espTrack, ui.espKnob, ui.espState, State.espEnabled)
    if not State.espEnabled then
        if ESP.line then ESP.line.Transparency = 1 end
    end
end)

-- Live info update
task.spawn(function()
    while true do
        task.wait(0.5)
        if State.running then
            local eggs = findAllHighValueEggs()
            if #eggs > 0 then
                local top = eggs[1]
                ui.InfoLbl.Text = ("🎯 Next: %s /s (%s)"):format(
                    formatNumber(top.value), top.rec.AreaId)
                ui.QueueLbl.Text = ("📋 Queue: %d eggs (descending)"):format(#eggs)
            else
                ui.InfoLbl.Text = "🎯 Next: -- (waiting)"
                ui.QueueLbl.Text = "📋 Queue: 0 eggs"
            end
        end
    end
end)

-- Auto Grab Toggle click
ui.btn.MouseButton1Click:Connect(function()
    if not State.running then
        if not loadModules() then
            ui.Status.Text = "❌ EggState not found"
            ui.Status.TextColor3 = COLORS.RED
            return
        end
        setToggle(ui.track, ui.knob, ui.state, true)
        ui.Status.Text = "Min: 50.00M | Highest First"
        ui.Status.TextColor3 = COLORS.GREEN
        task.spawn(mainLoop)
    else
        State.running = false
        setToggle(ui.track, ui.knob, ui.state, false)
        ui.Status.Text = "Stopped"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    State.running = false
    clearESP()
    ui.ScreenGui:Destroy()
end)

-- ESP Line updater
RunService.RenderStepped:Connect(function()
    if State.espEnabled and State.running then
        updateESPLine()
    end
end)

-- Auto-init
task.spawn(function()
    task.wait(0.5)
    if loadModules() then
        ui.Status.Text = "✅ Ready | Min: 50.00M"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.Status.Text = "⚠️ Waiting for game..."
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)
