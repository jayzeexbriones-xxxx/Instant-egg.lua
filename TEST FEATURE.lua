-- ============================================================
-- CHICKEN RAGDOLL → MOVETWEEN → BEST EGG AREA → STAY
-- CloverHub-style manual step (hindi TweenService)
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ============ STATE ============
local State = {
    running      = false,
    moveSpeed    = 500,       -- 🎯 MoveTween speed (100-1000)
    stepCap      = 32,        -- 🎯 Max studs per frame (anti-detect)
    chickenArea  = "Forest",
    minValue     = 1e7,       -- 10M minimum
    ragdollWait  = 20,
    targetArea   = nil,
    targetPos    = nil,
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
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function isAlive()
    local hum = getHum()
    return hum and hum.Health > 0
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

local function getEggPos(rec)
    if not rec then return nil end
    if rec.BoundsCFrame and rec.BoundsCFrame.Position then
        return rec.BoundsCFrame.Position
    end
    return nil
end

-- ============ GET AREA CENTER ============
local function getAreaCenter(areaName)
    local ok, area = pcall(function()
        return Workspace.__OBJECTS.Areas.GuardAreas[areaName]
    end)
    if ok and area then
        local bounds = area:FindFirstChild("Bounds")
        if bounds and bounds:IsA("BasePart") then
            return bounds.Position
        end
        if area.PrimaryPart then
            return area.PrimaryPart.Position
        end
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

-- ============ FIND CHICKEN EGG ============
local function findChickenEgg()
    if not EggState then return nil end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil end

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.AreaId == State.chickenArea then
            if rec.State == "Slot" or rec.State == "Dropped" then
                return rec
            end
        end
    end
    return nil
end

-- ============ FIND BEST EGG ============
local function findBestEgg()
    if not EggState then return nil end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil end

    local bestRec = nil
    local bestValue = 0

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local value = calcEggValue(rec)
            if value >= State.minValue and value > bestValue then
                bestValue = value
                bestRec = rec
            end
        end
    end

    return bestRec, bestValue
end

-- ============================================================
-- 🎯 CLOVERHUB-STYLE MOVE TWEEN (MANUAL STEP)
-- Hindi TweenService - manual CFrame write with stepCap
-- ============================================================
local function moveTweenTo(targetPos, speed, timeout, checkFn)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return false, "no character" end

    -- Config
    speed = math.clamp(tonumber(speed) or State.moveSpeed, 100, 1000)
    timeout = timeout or 30
    local stepCap = State.stepCap or 32

    -- Kunin yung final target (Vector3)
    local target = typeof(targetPos) == "Vector3" and targetPos or targetPos.Position
    if not target then return false, "no target" end

    local t0 = os.clock()
    local lastStep = os.clock()
    local bestDist, lastGain = math.huge, os.clock()

    warn(("[MOVE] Nagsimula - target sa %.0f studs @ %d studs/s"):format(
        (hrp.Position - target).Magnitude, speed))

    while os.clock() - t0 < timeout do
        if checkFn and not checkFn() then
            return false, "cancelled"
        end

        local h = hrp
        if not h or not h.Parent then break end
        if not isAlive() then
            task.wait(0.1)
            continue
        end

        -- 🎯 Distance check (flat, XZ)
        local flat = Vector3.new(target.X - h.Position.X, 0,
                                  target.Z - h.Position.Z)
        local rem = flat.Magnitude
        if rem <= 5 then
            warn("[MOVE] ✅ Nakarating na!")
            return true
        end

        -- 🎯 Stall detection
        if rem < bestDist - 2 then
            bestDist, lastGain = rem, os.clock()
        elseif os.clock() - lastGain > 1.5 then
            warn("[MOVE] ⚠️ Stuck - walang progreso")
            return false, "blocked"
        end

        -- 🎯 Frame time (capped sa 1/30s)
        local nowT = os.clock()
        local dt = nowT - lastStep
        lastStep = nowT
        if dt > 1 / 30 then dt = 1 / 30 end
        if dt <= 0 then dt = 1 / 60 end

        -- 🎯 KEY LOGIC: manual step + stepCap
        local step = math.min(speed * dt, stepCap, flat.Magnitude)
        local nextP = h.Position + flat.Unit * step

        -- 🎯 CFrame.lookAt (facing sideways)
        local facing = Vector3.new(-flat.Unit.Z, 0, flat.Unit.X)
        h.CFrame = CFrame.lookAt(nextP, nextP + facing)

        -- 🎯 Zero velocity (walang spike)
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero

        RunService.Heartbeat:Wait()
    end

    warn("[MOVE] ⏱ Timeout")
    return false, "timeout"
end

-- ============ GRAB EGG ============
local function grabEgg(rec)
    if not rec then return false end

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

-- ============ RAGDOLL CHECK ============
local function isRagdolled()
    local t = LocalPlayer:GetAttribute("RagdollEndTime")
    if type(t) == "number" and t > workspace:GetServerTimeNow() then
        return true, "RagdollEndTime"
    end

    local hum = getHum()
    if hum and hum.PlatformStand then
        return true, "PlatformStand"
    end

    if hum then
        local st = hum:GetState()
        if st == Enum.HumanoidStateType.Physics 
           or st == Enum.HumanoidStateType.Ragdoll
           or st == Enum.HumanoidStateType.FallingDown then
            return true, "State"
        end
    end

    return false, nil
end

-- ============ WAIT FOR RAGDOLL ============
local function waitForRagdoll(timeout)
    warn("[CHICKEN] Hinihintay ma-ragdoll...")
    local t0 = os.clock()

    while os.clock() - t0 < timeout do
        if not State.running then return false end

        local ragdolled, signal = isRagdolled()
        if ragdolled then
            warn(("[CHICKEN] ✅ Na-ragdoll! (signal=%s)"):format(tostring(signal)))

            local rdStart = os.clock()
            while isRagdolled() and (os.clock() - rdStart) < 5 do
                if not State.running then return false end
                task.wait(0.1)
            end
            return true
        end

        task.wait(0.01)
    end

    warn("[CHICKEN] ⏱ Timeout")
    return false
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

-- ============ MAIN FLOW ============
local function mainFlow()
    State.running = true
    warn("=== CHICKEN RAGDOLL → MOVETWEEN → STAY ===")

    if not loadModules() then
        warn("[FLOW] Modules not loaded!")
        State.running = false
        return
    end

    -- STEP 1: Hanapin chicken egg
    warn("[FLOW] STEP 1: Hanapin chicken egg...")
    local chicken = findChickenEgg()
    if not chicken then
        warn("[FLOW] Walang chicken egg!")
        State.running = false
        return
    end

    -- STEP 2: MoveTween sa chicken egg
    local cpos = getEggPos(chicken)
    if cpos then
        warn("[FLOW] MoveTween sa chicken egg...")
        moveTweenTo(cpos, State.moveSpeed, 15, function()
            return State.running
        end)
        task.wait(0.3)

        warn("[FLOW] Grab chicken egg...")
        local ok, method = grabEgg(chicken)
        if ok then
            warn(("[FLOW] ✅ Grabbed via %s"):format(method))
        end
        task.wait(0.3)
    end

    -- STEP 3: Hanapin best egg
    warn("[FLOW] STEP 3: Hanapin best egg...")
    local best, bestValue = findBestEgg()
    if not best then
        warn("[FLOW] Walang best egg!")
        State.running = false
        return
    end

    warn(("[FLOW] Best: %s /s (%s)"):format(
        formatNumber(bestValue), best.AreaId))

    -- STEP 4: Hintayin ma-ragdoll
    warn("[FLOW] STEP 4: Hintayin ma-ragdoll...")
    local hit = waitForRagdoll(State.ragdollWait)

    if not hit then
        warn("[FLOW] Walang ragdoll")
        State.running = false
        return
    end

    -- STEP 5: MoveTween sa best egg area
    local areaPos = getAreaCenter(best.AreaId) or getEggPos(best)
    if areaPos then
        State.targetArea = best.AreaId
        State.targetPos = areaPos

        warn(("[FLOW] MoveTween sa %s (%.0f studs) @ %d studs/s..."):format(
            best.AreaId, (getHRP().Position - areaPos).Magnitude, State.moveSpeed))
        moveTweenTo(areaPos, State.moveSpeed, 60, function()
            return State.running
        end)
    end

    -- STEP 6: STAY
    warn(("=== TAPOS — NASA %s AREA NA, STAY ==="):format(best.AreaId))
    ui.Status2.Text = ("✅ %s — STAY"):format(best.AreaId)
    ui.Status2.TextColor3 = COLORS.GREEN
    State.running = false
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
    if CoreGui:FindFirstChild("ChickenTPUI") then
        CoreGui.ChickenTPUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ChickenTPUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 260, 0, 190)
    Main.Position = UDim2.new(0.5, -130, 0.5, -95)
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
    Title.Text = "🐔 Chicken Ragdoll → MoveTween"
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

    -- Toggle
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -120, 0, 25)
    lbl.Position = UDim2.new(0, 15, 0, 50)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🐔 Chicken → MoveTween"
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

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 90)
    Status.BackgroundTransparency = 1
    Status.Text = "Speed: 500 studs/s | Step: 32"
    Status.TextColor3 = COLORS.CYAN
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    local Status2 = Instance.new("TextLabel", Main)
    Status2.Size = UDim2.new(1, -30, 0, 20)
    Status2.Position = UDim2.new(0, 15, 0, 110)
    Status2.BackgroundTransparency = 1
    Status2.Text = "Status: Ready"
    Status2.TextColor3 = COLORS.YELLOW
    Status2.TextSize = 10
    Status2.Font = Enum.Font.Gotham
    Status2.TextXAlignment = Enum.TextXAlignment.Left

    local Info = Instance.new("TextLabel", Main)
    Info.Size = UDim2.new(1, -30, 0, 20)
    Info.Position = UDim2.new(0, 15, 0, 130)
    Info.BackgroundTransparency = 1
    Info.Text = "Manual step (hindi TweenService)"
    Info.TextColor3 = COLORS.GREEN
    Info.TextSize = 9
    Info.Font = Enum.Font.Gotham
    Info.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        track = track, knob = knob, state = state, btn = btn,
        Status = Status, Status2 = Status2, Info = Info, CloseBtn = CloseBtn
    }
end

local ui = createUI()

local function setToggle(on)
    ui.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    ui.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    ui.state.Text = on and "ON" or "OFF"
    ui.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.btn.MouseButton1Click:Connect(function()
    if not State.running then
        if not loadModules() then
            ui.Status2.Text = "❌ EggState not found"
            ui.Status2.TextColor3 = COLORS.RED
            return
        end
        setToggle(true)
        ui.Status2.Text = "🐔 Running flow..."
        ui.Status2.TextColor3 = COLORS.GREEN
        task.spawn(mainFlow)
    else
        State.running = false
        setToggle(false)
        ui.Status2.Text = "Stopped"
        ui.Status2.TextColor3 = COLORS.YELLOW
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    State.running = false
    ui.ScreenGui:Destroy()
end)

task.spawn(function()
    task.wait(0.5)
    if loadModules() then
        ui.Status2.Text = "✅ Ready | MoveTween 500"
        ui.Status2.TextColor3 = COLORS.GREEN
    else
        ui.Status2.Text = "⚠️ Waiting for game..."
        ui.Status2.TextColor3 = COLORS.YELLOW
    end
end)

