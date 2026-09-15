-- ============================================================
-- STEAL AN EGG — Forest Bait → TP Best → Return Home
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    minArea          = 9,       -- Best egg area (9+)
    hitThreshold     = 15,      -- Knockback sensitivity
    hitTimeout       = 8,       -- Max wait for guard hit
    grabTimeout      = 3,       -- Max wait for grab
    forestAreaName   = "Forest",
}

-- ============================================================
-- SERVICES
-- ============================================================
local EggState = nil
local Remotes = nil
local Save = nil
local PlotState = nil

local function loadModules()
    if EggState then return true end
    local ok = pcall(function()
        local client = ReplicatedStorage:FindFirstChild("Client")
        if client then
            local es = client:FindFirstChild("EggState")
            if es then EggState = require(es) end
            local ps = client:FindFirstChild("PlotState")
            if ps then PlotState = require(ps) end
        end
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if shared then
            local rem = shared:FindFirstChild("Remotes")
            if rem then Remotes = require(rem) end
            local sv = shared:FindFirstChild("Save")
            if sv then Save = require(sv) end
        end
    end)
    return ok and EggState ~= nil
end

-- ============================================================
-- HELPERS
-- ============================================================
local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRarityNumber(rec)
    if rec and rec.Rarity and type(rec.Rarity) == "table" then
        return rec.Rarity.RarityNumber or 0
    end
    return 0
end

local function getAssetScale(rec)
    return tonumber(rec.AssetScale) or 1
end

local function hasEgg()
    local c = LocalPlayer.Character
    if not c then return false end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("ItemType") == "AssetEgg" then
            return true
        end
    end
    return false
end

-- ============================================================
-- TP TO
-- ============================================================
local function tpTo(pos)
    local char = LocalPlayer.Character
    if not char then return false end
    pcall(function()
        char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
    end)
    local hrp = getHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
    end
    return true
end

-- ============================================================
-- FIND EGG
-- ============================================================
local function findEgg(areaName)
    if not EggState then return nil, nil end
    local ok, data = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not data or not data.Records then return nil, nil end

    for _, rec in ipairs(data.Records) do
        if (rec.State == "Slot" or rec.State == "Dropped") and rec.AreaId == areaName then
            local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
                and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
                or Workspace:FindFirstChild(rec.Uid, true)
            if model then
                local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                if part then
                    return rec, model
                end
            end
        end
    end
    return nil, nil
end

local function findBestEgg()
    if not EggState then return nil, nil end
    local ok, data = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not data or not data.Records then return nil, nil end

    local bestRec, bestModel, bestScore = nil, nil, -1
    for _, rec in ipairs(data.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local idx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then idx = i; break end
            end
            if idx and idx >= Config.minArea then
                local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
                    and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
                    or Workspace:FindFirstChild(rec.Uid, true)
                if model then
                    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local score = (getRarityNumber(rec) * 1000) + getAssetScale(rec)
                        if score > bestScore then
                            bestScore = score
                            bestRec = rec
                            bestModel = model
                        end
                    end
                end
            end
        end
    end
    return bestRec, bestModel
end

-- ============================================================
-- GRAB EGG (with retries)
-- ============================================================
local function grabEgg(rec, model)
    for attempt = 1, 5 do
        -- Try remote
        pcall(function()
            if Remotes and Remotes.EggWorld and Remotes.EggWorld.AskFieldEggCarry then
                Remotes.EggWorld.AskFieldEggCarry:InvokeServer({ Uid = rec.Uid })
            end
        end)
        pcall(function()
            if EggState and EggState.CarryFieldEgg then
                EggState.CarryFieldEgg(rec.Uid)
            end
        end)

        task.wait(0.08)

        -- Try prompt
        local prompt = model:FindFirstChild("CarryAreaEgg", true)
            or model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt and fireproximityprompt then
            pcall(function()
                prompt.Enabled = true
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 9999
                fireproximityprompt(prompt, 0)
            end)
        end

        task.wait(0.15)

        if hasEgg() then return true end
    end
    return false
end

-- ============================================================
-- WAIT FOR GUARD HIT (velocity/position detection)
-- ============================================================
local function waitForHit(timeout)
    timeout = timeout or Config.hitTimeout
    local hrp = getHRP()
    if not hrp then return false end

    local lastPos = hrp.Position
    local t0 = tick()
    local hit = false

    local conn = RunService.Heartbeat:Connect(function()
        local h = getHRP()
        if not h then return end
        local vel = h.AssemblyLinearVelocity
        local speed = vel.Magnitude
        local delta = (h.Position - lastPos).Magnitude
        local vVel = math.abs(vel.Y)

        if speed > Config.hitThreshold or delta > 2 or vVel > 20 then
            hit = true
        end
        lastPos = h.Position
    end)

    while tick() - t0 < timeout and not hit do
        task.wait(0.05)
    end

    conn:Disconnect()
    return hit
end

-- ============================================================
-- RETURN HOME (TP sa plot)
-- ============================================================
local function getPlotPos()
    local pos = nil
    pcall(function()
        if PlotState then
            local plot = PlotState.ResolvePlot(LocalPlayer)
            if plot and plot.RespawnPointCFrame then
                pos = plot.RespawnPointCFrame.Position
            elseif plot and plot.CenterPoint then
                pos = plot.CenterPoint.Position
            end
        end
    end)
    return pos or Vector3.new(544.4, 74.2, -364.2) -- fallback
end

local function returnHome()
    local plotPos = getPlotPos()
    if plotPos then
        tpTo(plotPos)
        task.wait(0.5)
    end
end

-- ============================================================
-- MAIN CYCLE
-- ============================================================
local running = false

local function mainCycle()
    if not running then return end
    if not loadModules() then
        task.wait(0.5)
        return
    end

    -- ============ STEP 1: Find Forest egg (bait) ============
    ui.Status.Text = "Status: 🐔 Finding Forest egg..."
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)

    local baitRec, baitModel = findEgg(Config.forestAreaName)
    if not baitRec or not baitModel then
        print("[Farm] No Forest egg — skipping")
        task.wait(0.5)
        return
    end

    local baitPart = baitModel.PrimaryPart or baitModel:FindFirstChildWhichIsA("BasePart", true)
    if not baitPart then return end

    -- ============ STEP 2: TP sa Forest egg ============
    ui.Status.Text = "Status: 🚀 TP to Forest..."
    tpTo(baitPart.Position)
    task.wait(0.3)

    -- ============ STEP 3: Grab bait egg ============
    ui.Status.Text = "Status: 🥚 Grabbing bait..."
    local baitGrabbed = grabEgg(baitRec, baitModel)
    print("[Farm] Bait grabbed:", baitGrabbed)

    -- ============ STEP 4: Wait for hit ============
    ui.Status.Text = "Status: ⚡ Waiting for hit..."
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)

    -- Get Forest guard and touch it
    pcall(function()
        local guardAreas = Workspace:FindFirstChild("__OBJECTS", true)
            and Workspace.__OBJECTS:FindFirstChild("Areas")
            and Workspace.__OBJECTS.Areas:FindFirstChild("GuardAreas")
        if guardAreas then
            local forest = guardAreas:FindFirstChild("Forest")
            if forest then
                local guard = forest:FindFirstChild("Guard")
                if guard then
                    local collider = guard:FindFirstChild("Collider")
                        or guard:FindFirstChild("HumanoidRootPart")
                        or guard.PrimaryPart
                    if collider and firetouchinterest then
                        local hrp = getHRP()
                        if hrp then
                            firetouchinterest(hrp, collider, 0)
                            task.wait(0.05)
                            firetouchinterest(hrp, collider, 1)
                        end
                    end
                end
            end
        end
    end)

    local hit = waitForHit(Config.hitTimeout)
    print("[Farm] Hit detected:", hit)

    if not hit then
        print("[Farm] No hit — returning home")
        returnHome()
        task.wait(0.5)
        return
    end

    -- ============ STEP 5: TP sa best egg ============
    ui.Status.Text = "Status: 🎯 TP to best egg..."
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)

    local bestRec, bestModel = findBestEgg()
    if not bestRec or not bestModel then
        print("[Farm] No best egg — returning home")
        returnHome()
        task.wait(0.5)
        return
    end

    local bestPart = bestModel.PrimaryPart or bestModel:FindFirstChildWhichIsA("BasePart", true)
    if not bestPart then return end

    tpTo(bestPart.Position)
    task.wait(0.3)

    -- ============ STEP 6: Grab best egg ============
    ui.Status.Text = "Status: 🥚 Grabbing best egg..."
    local bestGrabbed = grabEgg(bestRec, bestModel)
    print("[Farm] Best egg grabbed:", bestGrabbed)

    -- ============ STEP 7: Return home ============
    ui.Status.Text = "Status: 🏠 Returning home..."
    returnHome()
    task.wait(0.5)

    ui.Status.Text = "Status: ✅ Cycle complete"
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
end

-- ============================================================
-- UI
-- ============================================================
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    STROKE = Color3.fromRGB(60, 60, 70),
    TEXT = Color3.fromRGB(255, 255, 255),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    YELLOW = Color3.fromRGB(255, 200, 0),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
}

local function createUI()
    if CoreGui:FindFirstChild("StealEggUI") then
        CoreGui.StealEggUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 260, 0, 135)
    Main.Position = UDim2.new(0.5, -130, 0.5, -68)
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
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

    local Cover = Instance.new("Frame", TitleBar)
    Cover.Size = UDim2.new(1, 0, 0, 10)
    Cover.Position = UDim2.new(0, 0, 1, -10)
    Cover.BackgroundColor3 = COLORS.TITLE_BG
    Cover.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🥚 Forest Bait → Best Egg"
    Title.TextColor3 = COLORS.TEXT
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

    -- Toggle
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -120, 0, 25)
    lbl.Position = UDim2.new(0, 15, 0, 55)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🎯 Auto Farm"
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

    -- Status
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 100)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui,
        farmToggle = { track = track, knob = knob, state = state, btn = btn },
        Status = Status,
        CloseBtn = CloseBtn,
    }
end

local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.farmToggle.btn.MouseButton1Click:Connect(function()
    if not running then
        if not loadModules() then
            ui.Status.Text = "Status: ❌ EggState not found"
            ui.Status.TextColor3 = COLORS.RED
            return
        end
        running = true
        setToggle(ui.farmToggle, true)
        ui.Status.Text = "Status: 🎯 Starting..."
        ui.Status.TextColor3 = COLORS.GREEN

        task.spawn(function()
            while running do
                pcall(mainCycle)
                task.wait(0.3)
            end
        end)
    else
        running = false
        setToggle(ui.farmToggle, false)
        ui.Status.Text = "Status: ⏸ Stopped"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    running = false
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
