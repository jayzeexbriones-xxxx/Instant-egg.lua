-- ============================================================
-- STEAL AN EGG — TP Chicken → Tuka → Tween Best → Base
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
    speedEnabled = false,
    farmEnabled  = false,
    speedValue   = 700,
    minArea      = 9,
    tweenSpeed   = 350,
    chickenAreas = 3,
    knockbackThreshold = 15,
}

local START_POS = Vector3.new(519.155, 70.576, -356.103)

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

-- ============================================================
-- SPEED BYPASS
-- ============================================================
local _speedConn = nil
local _speedActive = false

local function _activeHum()
    local c = LocalPlayer.Character
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

local function initSpeedBypass()
    if type(getgc) ~= "function" or type(hookfunction) ~= "function" or type(islclosure) ~= "function" then
        return false
    end
    local function findFn(nups, line)
        local ok, r = pcall(function()
            for _, f in next, getgc() do
                if typeof(f) == "function" and islclosure(f) then
                    local upvs = debug.getupvalues(f)
                    if upvs and #upvs == nups and debug.info(f, "l") == line then
                        return f
                    end
                end
            end
        end)
        return ok and r or nil
    end
    
    local func3 = findFn(19, 3)
    if not func3 then return false end
    
    local v7 = debug.getupvalue(func3, 2)
    if not v7 then return false end
    
    local ok = pcall(function()
        local orig
        if type(newlclosure) == "function" then
            orig = hookfunction(v7, newlclosure(function(p1, p2)
                if p2 and typeof(p2) == "table" then setmetatable(p2, {}) end
                return orig(p1, p2)
            end))
        else
            orig = hookfunction(v7, function(p1, p2)
                if p2 and typeof(p2) == "table" then setmetatable(p2, {}) end
                return orig(p1, p2)
            end)
        end
    end)
    if not ok then return false end
    
    _speedActive = true
    return true
end

local function startSpeed(spd)
    if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
    if not _speedActive then return end
    _speedConn = RunService.Heartbeat:Connect(function()
        local h = _activeHum()
        if h then h.WalkSpeed = spd end
    end)
end

local function stopSpeed()
    if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
    local h = _activeHum()
    if h then h.WalkSpeed = 16 end
end

local speedReady = pcall(initSpeedBypass)

-- ============================================================
-- MODULES
-- ============================================================
local EggState = nil
local PlotState = nil
local AreaEggSlotIdentity = nil

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

local function hasEggTool()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ItemType") == "AssetEgg" then
            return true
        end
    end
    return false
end

-- ============================================================
-- 🚀 TP TO POSITION (instant — para sa chicken)
-- ============================================================
local function tpTo(pos)
    local char = LocalPlayer.Character
    local hrp = getHRP()
    if not char or not hrp then return false end
    
    local gy = pos.Y
    -- Try humanoid floor detection
    local h = getHum()
    if h then
        gy = h.FloorMaterial ~= Enum.Material.Air and pos.Y or pos.Y
    end
    
    pcall(function()
        char:PivotTo(CFrame.new(pos.X, gy + 3, pos.Z))
    end)
    
    local h2 = getHRP()
    if h2 then
        h2.AssemblyLinearVelocity = Vector3.zero
        h2.AssemblyAngularVelocity = Vector3.zero
    end
    
    return true
end

-- ============================================================
-- 🚀 TWEEN MOVE (steady — para sa best egg at base)
-- ============================================================
local function tweenTo(targetPos, timeout)
    local hrp = getHRP()
    if not hrp then return false end
    
    timeout = timeout or 8
    if (hrp.Position - targetPos).Magnitude <= 5 then return true end
    
    local dist = (hrp.Position - targetPos).Magnitude
    local tweenTime = math.max(dist / State.tweenSpeed, 0.05)
    
    local tween = TweenService:Create(
        hrp,
        TweenInfo.new(tweenTime, Enum.EasingStyle.Linear),
        { CFrame = CFrame.new(targetPos) }
    )
    
    local done = false
    tween.Completed:Connect(function() done = true end)
    tween:Play()
    
    local t0 = tick()
    while not done and tick() - t0 < timeout do
        if not State.farmEnabled then 
            tween:Cancel()
            break 
        end
        task.wait(0.01)
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
-- ⚡ WAIT FOR CHICKEN PECK
-- ============================================================
local function waitForPeck(timeout)
    timeout = timeout or 5
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

    -- ============ STEP 1: TP sa Chicken Egg ============
    ui.Status.Text = "Status: 🐔 TP to chicken egg..."
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local chickenRec, chickenModel = findChickenEgg()
    if not chickenRec or not chickenModel then
        print("[Farm] No chicken egg found")
        task.wait(0.5)
        return
    end

    local chickenPart = chickenModel.PrimaryPart or chickenModel:FindFirstChildWhichIsA("BasePart", true)
    if not chickenPart then return end

    -- 🚀 INSTANT TP sa chicken
    tpTo(chickenPart.Position)
    task.wait(0.2)

    -- 🥚 Kunin yung chicken egg
    pcall(function() EggState.CarryFieldEgg(chickenRec.Uid) end)
    local prompt = chickenModel:FindFirstChild("CarryAreaEgg", true)
        or chickenModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and fireproximityprompt then
        pcall(function()
            prompt.HoldDuration = 0
            fireproximityprompt(prompt, 0)
        end)
    end

    -- ============ STEP 2: Wait for peck ============
    ui.Status.Text = "Status: 🐔 Waiting for peck..."
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local pecked = waitForPeck(5)
    
    if not pecked then
        print("[Farm] No peck — retrying")
        task.wait(0.3)
        return
    end
    
    print("[Farm] ✅ Pecked! Going to best egg...")

    -- ============ STEP 3: Tween sa Best Egg ============
    ui.Status.Text = "Status: 🎯 Tweening to best egg..."
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
    
    local bestRec, bestModel = findBestEgg()
    if not bestRec or not bestModel then
        print("[Farm] No best egg — going to base")
        tweenTo(START_POS, 8)
        task.wait(1)
        State.farmEnabled = false
        setToggle(ui.farmToggle, false)
        return
    end

    local bestPart = bestModel.PrimaryPart or bestModel:FindFirstChildWhichIsA("BasePart", true)
    if not bestPart then return end

    -- 🚀 Tween sa best egg (350 speed)
    tweenTo(bestPart.Position, 10)
    task.wait(0.15)

    -- 🥚 Kunin yung best egg
    pcall(function() EggState.CarryFieldEgg(bestRec.Uid) end)
    local bestPrompt = bestModel:FindFirstChild("CarryAreaEgg", true)
        or bestModel:FindFirstChildWhichIsA("ProximityPrompt", true)
    if bestPrompt and fireproximityprompt then
        pcall(function()
            bestPrompt.HoldDuration = 0
            fireproximityprompt(bestPrompt, 0)
        end)
    end

    task.wait(0.3)

    -- ============ STEP 4: Deliver to base ============
    ui.Status.Text = "Status: 🏠 Delivering to base..."
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
    
    local deliverPos = START_POS
    pcall(function()
        if PlotState then
            local plot = PlotState.ResolvePlot()
            if plot and plot.CenterPoint then
                deliverPos = plot.CenterPoint.Position
            end
        end
    end)
    
    tweenTo(deliverPos, 10)
    task.wait(1.5)

    -- ============ STEP 5: Check claim ============
    local claimed = false
    local checkT0 = tick()
    while tick() - checkT0 < 3 do
        if not hasEggTool() then
            claimed = true
            break
        end
        task.wait(0.2)
    end

    -- ============ STEP 6: AUTO OFF ============
    State.farmEnabled = false
    setToggle(ui.farmToggle, false)
    
    if claimed then
        ui.Status.Text = "Status: ✅ Delivered — Auto OFF"
        ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
        print("[Farm] ✅ Delivered!")
    else
        ui.Status.Text = "Status: ⚠️ Delivered (unconfirmed)"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
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
    Main.Size = UDim2.new(0, 260, 0, 180)
    Main.Position = UDim2.new(0.5, -130, 0.5, -90)
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

    local function makeToggle(y, label, icon)
        local lbl = Instance.new("TextLabel", Main)
        lbl.Size = UDim2.new(1, -120, 0, 25)
        lbl.Position = UDim2.new(0, 15, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. " " .. label
        lbl.TextColor3 = COLORS.TEXT
        lbl.TextSize = 14
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local state = Instance.new("TextLabel", Main)
        state.Size = UDim2.new(0, 45, 0, 25)
        state.Position = UDim2.new(1, -120, 0, y)
        state.BackgroundTransparency = 1
        state.Text = "OFF"
        state.TextColor3 = COLORS.RED
        state.TextSize = 13
        state.Font = Enum.Font.GothamBold
        state.TextXAlignment = Enum.TextXAlignment.Right

        local track = Instance.new("Frame", Main)
        track.Size = UDim2.new(0, 50, 0, 26)
        track.Position = UDim2.new(1, -65, 0, y)
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
        btn.Position = UDim2.new(1, -120, 0, y - 5)
        btn.BackgroundTransparency = 1
        btn.Text = ""

        return {track = track, knob = knob, state = state, btn = btn}
    end

    local speedToggle = makeToggle(50, "Speed Bypass (700)", "⚡")
    local farmToggle = makeToggle(95, "Auto Farm Best", "🎯")

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 145)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        speedToggle = speedToggle, farmToggle = farmToggle,
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

ui.speedToggle.btn.MouseButton1Click:Connect(function()
    State.speedEnabled = not State.speedEnabled
    setToggle(ui.speedToggle, State.speedEnabled)
    
    if State.speedEnabled then
        if speedReady then
            startSpeed(State.speedValue)
            ui.Status.Text = "Status: ⚡ Speed ON (" .. State.speedValue .. ")"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "Status: ❌ Speed bypass failed"
            ui.Status.TextColor3 = COLORS.RED
            State.speedEnabled = false
            setToggle(ui.speedToggle, false)
        end
    else
        stopSpeed()
        ui.Status.Text = "Status: ⚡ Speed OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

ui.farmToggle.btn.MouseButton1Click:Connect(function()
    if not State.farmEnabled then
        if not loadModules() then
            ui.Status.Text = "Status: ❌ EggState not found"
            ui.Status.TextColor3 = COLORS.RED
            return
        end
        State.farmEnabled = true
        setToggle(ui.farmToggle, true)
        ui.Status.Text = "Status: 🐔 Starting..."
        ui.Status.TextColor3 = COLORS.GREEN
        
        task.spawn(function()
            pcall(farmCycle)
        end)
    else
        State.farmEnabled = false
        setToggle(ui.farmToggle, false)
        ui.Status.Text = "Status: 🎯 Cancelled"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    State.farmEnabled = false
    State.speedEnabled = false
    stopSpeed()
    ui.ScreenGui:Destroy()
end)

if speedReady then
    ui.Status.Text = "Status: ✅ Ready (Speed 700)"
    ui.Status.TextColor3 = COLORS.GREEN
else
    ui.Status.Text = "Status: ⚠️ Speed bypass failed"
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
end
