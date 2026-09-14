-- ============================================================
-- STEAL AN EGG — Speed + Auto Farm Best Egg
-- ============================================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
local State = {
    speedEnabled = false,
    farmEnabled  = false,
    speedValue   = 300,
}

local START_POS = Vector3.new(519.155, 70.576, -356.103)

-- ============================================================
-- SPEED BYPASS (TAMANG LINE: 3)
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
    
    -- 🎯 TAMANG LINE: 3 (hindi 605!)
    local func3 = findFn(19, 3)
    if not func3 then warn("[Speed] func3 not found"); return false end
    
    local v7 = debug.getupvalue(func3, 2)
    if not v7 then warn("[Speed] v7 not found"); return false end
    
    local ok, err = pcall(function()
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
    if not ok then warn("[Speed] hook failed:", tostring(err)); return false end
    
    print("[Speed] OK - bypass active")
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
-- EGG STATE
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

local function getRarityName(rec)
    if rec and rec.Rarity then
        if type(rec.Rarity) == "table" and rec.Rarity._id then
            return rec.Rarity._id
        end
        if type(rec.Rarity) == "string" then return rec.Rarity end
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

    local bestRec, bestModel, bestDist = nil, nil, math.huge
    local r = getHRP()
    if not r then return nil, nil end

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
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
local function walkTo(pos, timeout)
    local h2 = getHum()
    local r = getHRP()
    if not h2 or not r then return false end
    
    timeout = timeout or 20
    if (r.Position - pos).Magnitude <= 5 then return true end
    
    if _speedActive then startSpeed(State.speedValue) end
    h2:MoveTo(pos)
    
    local t0 = tick()
    while tick() - t0 < timeout do
        if not State.farmEnabled then break end
        task.wait(0.05)
        r = getHRP(); h2 = getHum()
        if not r or not h2 then break end
        if (r.Position - pos).Magnitude <= 5 then break end
        h2:MoveTo(pos)
    end
    return true
end

-- ============================================================
-- FARM CYCLE
-- ============================================================
local function farmCycle()
    if not State.farmEnabled then return end
    if not loadModules() then return end

    local rec, model = findBestEgg()
    if not rec or not model then
        return
    end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    -- Walk to egg
    walkTo(part.Position, 15)
    if not State.farmEnabled then return end

    task.wait(0.3)

    -- Grab
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

    -- Return to base
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

    -- Title bar
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

    -- Toggle maker
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

    local speedToggle = makeToggle(50, "Speed Bypass", "⚡")
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

-- ============================================================
-- WIRING
-- ============================================================
local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- Speed toggle
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

-- Farm toggle
ui.farmToggle.btn.MouseButton1Click:Connect(function()
    if not State.farmEnabled then
        -- Starting
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
                task.wait(0.2)
            end
        end)
    else
        -- Stopping
        State.farmEnabled = false
        setToggle(ui.farmToggle, false)
        ui.Status.Text = "Status: 🎯 Auto Farm OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    State.farmEnabled = false
    State.speedEnabled = false
    stopSpeed()
    ui.ScreenGui:Destroy()
end)

-- Init status
if speedReady then
    ui.Status.Text = "Status: ✅ Ready (Speed ready)"
    ui.Status.TextColor3 = COLORS.GREEN
else
    ui.Status.Text = "Status: ⚠️ Speed bypass failed"
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
end
