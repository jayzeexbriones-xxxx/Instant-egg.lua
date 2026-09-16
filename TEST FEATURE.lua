-- ============================================================
-- CLOVERHUB EXACT COPY — Chicken TP Flow
-- Extracted directly from CloverHub source code
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ============ SERVICES (from CloverHub) ============
local HttpService       = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Stats             = game:GetService("Stats")

-- ============ STATE ============
local State = {
    running       = false,
    moveSpeed     = 1000,
    stepCap       = 32,
    chickenArea   = "Forest",
    minValue      = 1e7,
    targetArea    = nil,
    targetPos     = nil,
}

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple", "Light Dark",
}

-- ============ MODULES (from CloverHub) ============
local EggState = nil
local AssetsDir = nil
local Mutations = nil
local AssetEarnings = nil
local AreaEggSlotIdentity = nil

local function loadModules()
    if EggState then return true end
    local ok = pcall(function()
        local client = ReplicatedStorage:FindFirstChild("Client")
        if client then
            local es = client:FindFirstChild("EggState")
            if es then EggState = require(es) end
        end
        local shared = ReplicatedStorage:FindFirstChild("Shared")
        if shared then
            local util = shared:FindFirstChild("Util")
            if util then
                local aes = util:FindFirstChild("AreaEggSlotIdentity")
                if aes then AreaEggSlotIdentity = require(aes) end
            end
        end
        local data = ReplicatedStorage:FindFirstChild("Data")
        if data then
            local assets = data:FindFirstChild("Assets")
            if assets then
                local okA, mod = pcall(require, assets)
                if okA and mod then AssetsDir = mod.Directory end
            end
        end
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

local function getEggPos(rec)
    if not rec then return nil end
    if rec.BottomCFrame and rec.BottomCFrame.Position then
        return rec.BottomCFrame.Position
    end
    if rec.BoundsCFrame and rec.BoundsCFrame.Position then
        return rec.BoundsCFrame.Position
    end
    return nil
end

-- ============================================================
-- 🛡️ KILLPARTIGNORE (EXACT from CloverHub)
-- ============================================================
local function keepKillPartIgnore()
    local root = getHRP()
    if root and root:GetAttribute("KillPartIgnore") ~= true then
        pcall(function() root:SetAttribute("KillPartIgnore", true) end)
    end
end

local function watchKillPartIgnore(character)
    task.spawn(function()
        local root = character and (character:FindFirstChild("HumanoidRootPart")
            or character:WaitForChild("HumanoidRootPart", 5))
        if not (root and root:IsA("BasePart")) then return end
        keepKillPartIgnore()
        root:GetAttributeChangedSignal("KillPartIgnore"):Connect(function()
            if root:GetAttribute("KillPartIgnore") ~= true then
                keepKillPartIgnore()
            end
        end)
    end)
end

if LocalPlayer.Character then watchKillPartIgnore(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(watchKillPartIgnore)

-- ============================================================
-- 🛡️ ANTI-DEATH (EXACT from CloverHub)
-- ============================================================
local antiDeathConn = nil
local function startAntiDeath()
    if antiDeathConn then return end
    local hum = getHum()
    if not hum then return end
    hum.BreakJointsOnDeath = false
    pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false) end)
    antiDeathConn = hum.HealthChanged:Connect(function(hp)
        if hp <= 0 then
            pcall(function()
                hum.Health = hum.MaxHealth
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    startAntiDeath()
end)
task.spawn(function()
    task.wait(1)
    startAntiDeath()
end)

-- ============================================================
-- 🎯 AREA CENTER (from CloverHub)
-- ============================================================
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

-- ============================================================
-- 💰 CALCULATE EGG VALUE (from CloverHub)
-- ============================================================
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
        if ok and type(rate) == "number" and rate > 0 then return rate end
    end
    local rarity = rec.Rarity and rec.Rarity.RarityNumber or 0
    local scale = tonumber(rec.AssetScale) or 1
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

-- ============================================================
-- 🐔 FIND CHICKEN EGG (CloverHub: Forest only)
-- ============================================================
local function findChickenEgg()
    if not EggState then return nil end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil end
    for _, rec in ipairs(fieldEggs.Records) do
        if rec.AreaId == State.chickenArea and (rec.State == "Slot" or rec.State == "Dropped") then
            return rec
        end
    end
    return nil
end

-- ============================================================
-- 💰 FIND BEST EGG (CloverHub: highest value)
-- ============================================================
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
-- 🚀 CLOVERHUB MOVETWEEN (EXACT from CloverHub)
-- ============================================================
local function moveTweenTo(targetPos, speed, timeout, checkFn)
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hrp then return false, "no character" end

    speed = math.clamp(tonumber(speed) or State.moveSpeed, 100, 1000)
    timeout = timeout or 30
    local stepCap = State.stepCap or 32

    local target = typeof(targetPos) == "Vector3" and targetPos or targetPos.Position
    if not target then return false, "no target" end

    local t0 = os.clock()
    local lastStep = os.clock()
    local bestDist, lastGain = math.huge, os.clock()

    while os.clock() - t0 < timeout do
        if checkFn and not checkFn() then return false, "cancelled" end
        local h = hrp
        if not h or not h.Parent then break end
        if not isAlive() then task.wait(0.1) continue end

        local flat = Vector3.new(target.X - h.Position.X, 0, target.Z - h.Position.Z)
        local rem = flat.Magnitude
        if rem <= 5 then return true end

        if rem < bestDist - 2 then
            bestDist, lastGain = rem, os.clock()
        elseif os.clock() - lastGain > 1.5 then
            return false, "blocked"
        end

        local nowT = os.clock()
        local dt = nowT - lastStep
        lastStep = nowT
        if dt > 1 / 30 then dt = 1 / 30 end
        if dt <= 0 then dt = 1 / 60 end

        local step = math.min(speed * dt, stepCap, flat.Magnitude)
        local nextP = h.Position + flat.Unit * step
        local facing = Vector3.new(-flat.Unit.Z, 0, flat.Unit.X)
        h.CFrame = CFrame.lookAt(nextP, nextP + facing)
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
        keepKillPartIgnore()
        RunService.Heartbeat:Wait()
    end
    return false, "timeout"
end

-- ============================================================
-- 🎯 CLOVERHUB CARRY SLOT KEY (EXACT)
-- ============================================================
local function carrySlotKey(rec)
    if not (AreaEggSlotIdentity and rec and rec.Uid) then return nil end
    local key
    pcall(function()
        if AreaEggSlotIdentity.LooksLikeFirstAreaUid(rec.Uid) then
            key = AreaEggSlotIdentity.SlotKey(rec.AreaId, rec.NestId)
        end
    end)
    return key
end

-- ============================================================
-- 🎯 GRAB EGG (CloverHub style: CarryFieldEgg + prompt fallback)
-- ============================================================
local function grabEgg(rec)
    if not rec then return false end

    local slotKey = carrySlotKey(rec)

    -- CloverHub: RequestCarryAreaEgg (CarryFieldEgg) with slotKey
    local ok1, res1 = pcall(function()
        return EggState.CarryFieldEgg(rec.Uid, slotKey)
    end)
    if ok1 and res1 == true then
        return true, "instant"
    end

    -- Fallback: proximity prompt
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

-- ============================================================
-- 🐔 CLOVERHUB FORESTSTRIKE (EXACT from CloverHub source)
-- ============================================================
local function triggerForestStrike(baitUid)
    local objects = workspace:FindFirstChild("__OBJECTS")
    local areas = objects and objects:FindFirstChild("Areas")
    local guards = areas and areas:FindFirstChild("GuardAreas")
    local forest = guards and guards:FindFirstChild("Forest")
    local guard = forest and forest:FindFirstChild("Guard")
    local guardRoot = guard and (guard.PrimaryPart or guard:FindFirstChild("HumanoidRootPart", true))
    if not guardRoot then return false, "no guard" end

    local packages = ReplicatedStorage:FindFirstChild("Packages")
    local networking = packages and packages:FindFirstChild("Networking")
    local remote = networking and networking:FindFirstChild("RE/GuardPatrol/ForestStrike")
    if not remote or not remote:IsA("RemoteEvent") then return false, "no remote" end

    pcall(function()
        remote:FireServer({
            EggUid = baitUid,
            GuardCFrame = guardRoot.CFrame,
        })
    end)
    warn("[CHICKEN] 🎯 ForestStrike fired!")
    return true
end

-- ============================================================
-- 🎯 CLOVERHUB: WAIT FOR CARRY (carry confirmation)
-- ============================================================
local function waitForCarry(uid, timeout)
    timeout = timeout or 3
    local t0 = os.clock()
    while os.clock() - t0 < timeout do
        if not State.running then return false end
        -- Check if carrying
        local carrying = false
        pcall(function()
            local fieldEggs = EggState.ReadFieldEggs()
            for _, rec in ipairs(fieldEggs.Records) do
                if rec.Uid == uid and rec.State == "Carried" then
                    carrying = true
                    break
                end
            end
        end)
        if carrying then return true end
        task.wait(0.05)
    end
    return false
end

-- ============================================================
-- 🎯 FORMAT NUMBER
-- ============================================================
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
-- 🎯 MAIN FLOW (EXACT CloverHub style)
-- ============================================================
local function mainFlow()
    State.running = true
    warn("=== CLOVERHUB CHICKEN TP ===")

    if not loadModules() then
        warn("[FLOW] Modules not loaded!")
        State.running = false
        return
    end

    startAntiDeath()
    keepKillPartIgnore()

    -- STEP 1: Find chicken egg sa Forest
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
        warn("[FLOW] MoveTween 1000 sa chicken egg...")
        moveTweenTo(cpos, 1000, 15, function() return State.running end)
        task.wait(0.3)

        warn("[FLOW] Grab chicken egg...")
        local ok, method = grabEgg(chicken)
        if ok then
            warn(("[FLOW] ✅ Grabbed via %s"):format(method))
        end

        -- Wait for carry confirmation
        local carried = waitForCarry(chicken.Uid, 3)
        warn(("[FLOW] Carry confirmed: %s"):format(tostring(carried)))

        task.wait(0.5)

        -- 🎯 Fire ForestStrike (CloverHub exact)
        warn("[FLOW] 🎯 Firing ForestStrike...")
        local strikeOk = triggerForestStrike(chicken.Uid)
        if strikeOk then
            warn("[FLOW] ✅ ForestStrike fired - hintayin 1s...")
        end
        task.wait(1)
    end

    if not State.running then return end

    -- STEP 3: Find best egg (highest value)
    warn("[FLOW] STEP 3: Hanapin best egg...")
    local best, bestValue = findBestEgg()
    if not best then
        warn("[FLOW] Walang best egg!")
        State.running = false
        return
    end

    warn(("[FLOW] Best: %s /s (%s)"):format(
        formatNumber(bestValue), best.AreaId))

    -- STEP 4: MoveTween 1000 sa best egg area (STAY)
    local areaPos = getAreaCenter(best.AreaId) or getEggPos(best)
    if areaPos then
        State.targetArea = best.AreaId
        State.targetPos = areaPos

        warn(("[FLOW] MoveTween 1000 sa %s (%.0f studs)..."):format(
            best.AreaId, (getHRP().Position - areaPos).Magnitude))
        moveTweenTo(areaPos, 1000, 60, function() return State.running end)
    end

    warn(("=== TAPOS — NASA %s AREA NA ==="):format(best.AreaId))
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
    Title.Text = "🐔 CloverHub Chicken TP"
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
    lbl.Position = UDim2.new(0, 15, 0, 50)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🐔 CloverHub Flow"
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
    Status.Text = "⚡ Speed 1000 | ForestStrike"
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
    Info.Text = "🎯 Exact CloverHub Logic"
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
        ui.Status2.Text = "🐔 Running CloverHub flow..."
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
    if antiDeathConn then antiDeathConn:Disconnect() antiDeathConn = nil end
    ui.ScreenGui:Destroy()
end)

task.spawn(function()
    task.wait(0.5)
    if loadModules() then
        ui.Status2.Text = "✅ Ready | CloverHub Exact"
        ui.Status2.TextColor3 = COLORS.GREEN
    else
        ui.Status2.Text = "⚠️ Waiting for game..."
        ui.Status2.TextColor3 = COLORS.YELLOW
    end
end)
