-- ============================================================
-- STEAL AN EGG — Auto Farm Best Egg (Simple Test)
-- ============================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
local State = {
    running = false,
    speed = 260,
    minArea = 9,
}

local START_POS = Vector3.new(519.155, 70.576, -356.103)

local AREA_NAMES = {
    "Forest","Lake","Desert","Jungle","Snow","Volcano",
    "Abyss Ocean","Prehistoric","Cosmic","Cherry Blossom","Titan Temple"
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
        warn("[Speed] missing functions"); return false
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
    if not func3 then warn("[Speed] func3 not found"); return false end
    local v7 = debug.getupvalue(func3, 2)
    if not v7 then warn("[Speed] v7 not found"); return false end
    local ok, err = pcall(function()
        local orig
        orig = hookfunction(v7, function(p1, p2)
            if p2 and typeof(p2) == "table" then setmetatable(p2, {}) end
            return orig(p1, p2)
        end)
    end)
    if not ok then warn("[Speed] hook failed:", tostring(err)); return false end
    print("[Speed] OK")
    _speedActive = true
    return true
end

local function startSpeed(spd)
    if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
    if not _speedActive then return end
    _speedConn = RunService.Heartbeat:Connect(function()
        local h = _activeHum(); if h then h.WalkSpeed = spd end
    end)
end

local function stopSpeed()
    if _speedConn then _speedConn:Disconnect(); _speedConn = nil end
    local h = _activeHum(); if h then h.WalkSpeed = 16 end
end

pcall(initSpeedBypass)

-- ============================================================
-- MODULES
-- ============================================================
local EggState = nil
local function loadEggState()
    if EggState then return true end
    local ok, r = pcall(function()
        local client = ReplicatedStorage:FindFirstChild("Client")
        if not client then return nil end
        local mod = client:FindFirstChild("EggState")
        if not mod then return nil end
        return require(mod)
    end)
    if ok and r then EggState = r; return true end
    return false
end

-- ============================================================
-- HELPERS
-- ============================================================
local function root()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hum()
    local c = LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getRarityName(record)
    if record and record.Rarity then
        if type(record.Rarity) == "table" and record.Rarity._id then
            return record.Rarity._id
        end
        if type(record.Rarity) == "string" then return record.Rarity end
    end
    return "Unknown"
end

-- ============================================================
-- FIND BEST EGG
-- ============================================================
local function findBestEgg()
    if not EggState then return nil, nil end
    local ok, fieldEggs = pcall(function() return EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return nil, nil end

    local r = root()
    if not r then return nil, nil end

    local bestRec, bestModel, bestDist = nil, nil, math.huge
    for _, rec in ipairs(fieldEggs.Records) do
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
    return bestRec, bestModel
end

-- ============================================================
-- WALK TO
-- ============================================================
local function walkTo(goal, timeout)
    local h2 = hum()
    local r = root()
    if not h2 or not r then return false end
    if typeof(goal) == "Instance" then goal = goal.Position end
    timeout = timeout or 15

    if (r.Position - goal).Magnitude <= 4 then h2.WalkSpeed = 16; return true end

    if _speedActive then startSpeed(State.speed) else h2.WalkSpeed = State.speed end
    h2:MoveTo(goal)

    local t0 = tick()
    while tick() - t0 < timeout do
        if not State.running then break end
        task.wait(0.05)
        r = root(); h2 = hum()
        if not r or not h2 then break end
        local dist = (r.Position - goal).Magnitude
        if dist <= 4 then
            h2.WalkSpeed = 0
            r.AssemblyLinearVelocity = Vector3.zero
            break
        end
        h2:MoveTo(goal)
    end
    if _speedActive then stopSpeed() end
    h2 = hum(); if h2 then h2.WalkSpeed = 16 end
    return true
end

-- ============================================================
-- FARM CYCLE
-- ============================================================
local function farmCycle()
    if not State.running then return end
    if not loadEggState() then return end

    local rec, model = findBestEgg()
    if not rec or not model then
        return
    end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    walkTo(part.Position, 15)
    if not State.running then return end

    task.wait(0.3)

    -- Claim
    pcall(function() EggState.CarryFieldEgg(rec.Uid) end)
    local prompt = model:FindFirstChild("CarryAreaEgg", true)
        or model:FindFirstChildWhichIsA("ProximityPrompt", true)
    if prompt and fireproximityprompt then
        pcall(function()
            prompt.HoldDuration = 0
            fireproximityprompt(prompt, 0)
        end)
    end

    task.wait(0.5)

    -- Return base
    walkTo(START_POS, 15)
    task.wait(0.5)
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

    -- Title
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
    Title.Text = "🥚 Auto Farm Best Egg"
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
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        track = track, knob = knob, state = state, btn = btn,
        Status = Status, CloseBtn = CloseBtn
    }
end

-- ============================================================
-- WIRING
-- ============================================================
local ui = createUI()

local function setToggle(on)
    ui.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    ui.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    ui.state.Text = on and "ON" or "OFF"
    ui.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.btn.MouseButton1Click:Connect(function()
    State.running = not State.running
    setToggle(State.running)

    if State.running then
        if not loadEggState() then
            ui.Status.Text = "Status: ❌ EggState failed"
            ui.Status.TextColor3 = COLORS.RED
            State.running = false
            setToggle(false)
            return
        end
        ui.Status.Text = "Status: 🎯 Auto Farm ON"
        ui.Status.TextColor3 = COLORS.GREEN
        
        task.spawn(function()
            while State.running do
                pcall(farmCycle)
                task.wait(0.1)
            end
        end)
    else
        ui.Status.Text = "Status: 🎯 Auto Farm OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        stopSpeed()
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    State.running = false
    stopSpeed()
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
