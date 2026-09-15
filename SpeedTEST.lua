-- ============================================================
-- STEAL AN EGG — TP Chicken → Grab → Wait Peck → TP Best Egg → Stay
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
local State = {
    farmEnabled  = false,
    minArea      = 9,
    chickenAreas = 3,
    knockbackThreshold = 15,
}

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

-- ============================================================
-- MODULES
-- ============================================================
local EggState = nil
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
    end)
    return ok and EggState ~= nil
end

-- ============================================================
-- HELPERS
-- ============================================================
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

-- ============================================================
-- 🚀 TP (instant)
-- ============================================================
local function tpTo(pos)
    local char = LocalPlayer.Character
    if not char then return false end
    pcall(function()
        char:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
    end)
    local h = getHRP()
    if h then
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end
    return true
end

-- ============================================================
-- 🐔 FIND CHICKEN EGG (area 1-3)
-- ============================================================
local function findChickenEgg()
    if not EggState then return nil, nil end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil, nil end

    local bestRec, bestModel = nil, nil
    local bestDist = math.huge
    local r = getHRP()
    if not r then return nil, nil end

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local areaIdx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then areaIdx = i; break end
            end
            
            if areaIdx and areaIdx <= State.chickenAreas then
                local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
                    and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
                    or Workspace:FindFirstChild(rec.Uid, true)
                if model then
                    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local d = (part.Position - r.Position).Magnitude
                        if d < bestDist then
                            bestDist = d
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
-- 🎯 FIND BEST EGG (area 9+)
-- ============================================================
local function findBestEgg()
    if not EggState then return nil, nil end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil, nil end

    local bestRec, bestModel = nil, nil
    local bestScore = -1

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local areaIdx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then areaIdx = i; break end
            end
            
            if areaIdx and areaIdx >= State.minArea then
                local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
                    and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
                    or Workspace:FindFirstChild(rec.Uid, true)
                if model then
                    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local rarityNum = getRarityNumber(rec)
                        local scale = getAssetScale(rec)
                        local score = (rarityNum * 1000) + scale
                        
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
-- 🚀 GRAB EGG
-- ============================================================
local function grabEgg(rec, model)
    pcall(function() EggState.CarryFieldEgg(rec.Uid) end)
    task.wait(0.1)
    
    local prompt = model:FindFirstChild("CarryAreaEgg", true)
        or model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and fireproximityprompt then
        pcall(function()
            prompt.HoldDuration = 0
            fireproximityprompt(prompt, 0)
        end)
    end
    task.wait(0.2)
end

-- ============================================================
-- ⚡ WAIT FOR PECK
-- ============================================================
local function waitForPeck(timeout)
    timeout = timeout or 15
    local hrp = getHRP()
    if not hrp then return false end
    
    local lastPos = hrp.Position
    local t0 = tick()
    local pecked = false
    
    local conn = RunService.Heartbeat:Connect(function()
        local h = getHRP()
        if not h then return end
        
        local velocity = h.AssemblyLinearVelocity
        local speed = velocity.Magnitude
        local posDelta = (h.Position - lastPos).Magnitude
        local verticalVel = math.abs(velocity.Y)
        
        if speed > State.knockbackThreshold 
           or posDelta > 2 
           or verticalVel > 20 then
            pecked = true
        end
        
        lastPos = h.Position
    end)
    
    while tick() - t0 < timeout and not pecked do
        if not State.farmEnabled then break end
        task.wait(0.05)
    end
    
    conn:Disconnect()
    return pecked
end

-- ============================================================
-- 🚀 FARM CYCLE
-- ============================================================
local function farmCycle()
    if not State.farmEnabled then return end
    if not loadModules() then return end

    -- ============ STEP 1: TP sa chicken egg ============
    ui.Status.Text = "Status: 🐔 TP to chicken..."
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local chickenRec, chickenModel = findChickenEgg()
    if not chickenRec or not chickenModel then
        print("[Farm] No chicken egg found")
        task.wait(0.5)
        return
    end

    local chickenPart = chickenModel.PrimaryPart or chickenModel:FindFirstChildWhichIsA("BasePart", true)
    if not chickenPart then return end

    tpTo(chickenPart.Position)
    task.wait(0.3)

    -- ============ STEP 2: Grab chicken egg ============
    ui.Status.Text = "Status: 🥚 Grabbing chicken..."
    grabEgg(chickenRec, chickenModel)
    print("[Farm] ✅ Chicken grabbed")

    -- ============ STEP 3: Wait for peck ============
    ui.Status.Text = "Status: 🐔 Waiting for peck..."
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local pecked = waitForPeck(15)
    
    if not pecked then
        print("[Farm] No peck detected — retrying")
        task.wait(0.5)
        return
    end
    
    print("[Farm] ✅ Pecked! TP to best egg...")

    -- ============ STEP 4: TP sa best egg ============
    ui.Status.Text = "Status: 🎯 TP to best egg..."
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
    
    local bestRec, bestModel = findBestEgg()
    if not bestRec or not bestModel then
        print("[Farm] No best egg found — staying")
        State.farmEnabled = false
        setToggle(ui.farmToggle, false)
        ui.Status.Text = "Status: ⚠️ No best egg"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        return
    end

    local bestPart = bestModel.PrimaryPart or bestModel:FindFirstChildWhichIsA("BasePart", true)
    if not bestPart then return end

    tpTo(bestPart.Position)
    task.wait(0.3)

    -- ============ STEP 5: Grab best egg ============
    ui.Status.Text = "Status: 🥚 Grabbing best egg..."
    grabEgg(bestRec, bestModel)

    -- ============ STEP 6: STAY ============
    ui.Status.Text = "Status: 🏠 Staying at best egg area"
    ui.Status.TextColor3 = COLORS.GREEN
    print("[Farm] ✅ Stay at best egg area")
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
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80)
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
    Title.Text = "🥚 Steal An Egg"
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

    -- Farm toggle (only one)
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -120, 0, 25)
    lbl.Position = UDim2.new(0, 15, 0, 55)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🎯 Auto Farm Best"
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

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 100)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        farmToggle = {track = track, knob = knob, state = state, btn = btn},
        Status = Status, CloseBtn = CloseBtn
    }
end

local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- Farm toggle
ui.farmToggle.btn.MouseButton1Click:Connect(function()
    if not State.farmEnabled then
        if not loadModules() then
            ui.Status.Text = "Status: ❌ EggState not found"
            ui.Status.TextColor3 = COLORS.RED
            return
        end
        State.farmEnabled = true
        setToggle(ui.farmToggle, true)
        ui.Status.Text = "Status: 🎯 Auto Farm ON"
        ui.Status.TextColor3 = COLORS.GREEN
        
        task.spawn(function()
            while State.farmEnabled do
                pcall(farmCycle)
                task.wait(0.1)
            end
        end)
    else
        State.farmEnabled = false
        setToggle(ui.farmToggle, false)
        ui.Status.Text = "Status: 🎯 Auto Farm OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    State.farmEnabled = false
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
