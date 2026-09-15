-- ============================================
-- STEP 1: LOAD SPEED BYPASS
-- ============================================
pcall(function(...)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/stealaeggspeedbypass.lua"))()
end)

-- ============================================
-- STEP 2: SERVICES
-- ============================================
local utility = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    CoreGui = game:GetService("CoreGui"),
}

-- ============================================
-- STEP 3: CONFIG
-- ============================================
getgenv().config = {
    speedValue = 260,
    minArea    = 9,
    basePos    = Vector3.new(519.155, 70.576, -356.103),
    arriveDist = 5,
    cycleDelay = 0.3,
}

-- ============================================
-- STEP 4: SPEED
-- ============================================
local _speedConn = nil
local _speedActive = false

local function _activeHum()
    local c = utility.Players.LocalPlayer.Character
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
    if _speedConn then _speedConn:Disconnect() _speedConn = nil end
    if not _speedActive then return end
    _speedConn = utility.RunService.Heartbeat:Connect(function()
        local h = _activeHum()
        if h then h.WalkSpeed = spd end
    end)
end

local function stopSpeed()
    if _speedConn then _speedConn:Disconnect() _speedConn = nil end
    local h = _activeHum()
    if h then h.WalkSpeed = 16 end
end

local speedReady = pcall(initSpeedBypass)

-- ============================================
-- STEP 5: AUTO FARM
-- ============================================
utility.farmEnabled = false
utility.farmThread = nil
utility.EggState = nil

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

local function getHRP()
    local c = utility.Players.LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = utility.Players.LocalPlayer.Character
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function loadEggState()
    if utility.EggState then return true end
    local ok, r = pcall(function()
        local client = utility.ReplicatedStorage:FindFirstChild("Client")
        if not client then return nil end
        local es = client:FindFirstChild("EggState")
        if not es then return nil end
        return require(es)
    end)
    if ok and r then
        utility.EggState = r
        return true
    end
    return false
end

local function findBestEgg()
    if not utility.EggState then return nil, nil end
    local ok, data = pcall(function() return utility.EggState.ReadFieldEggs() end)
    if not ok or not data or not data.Records then return nil, nil end

    local bestRec, bestModel = nil, nil
    local bestScore = -1

    for _, rec in ipairs(data.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local idx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then idx = i; break end
            end

            if idx and idx >= getgenv().config.minArea then
                local model = utility.Workspace:FindFirstChild("AreaEggSlotsClient", true)
                    and utility.Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
                    or utility.Workspace:FindFirstChild(rec.Uid, true)

                if model then
                    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local rarityNum = 0
                        if rec.Rarity and type(rec.Rarity) == "table" then
                            rarityNum = rec.Rarity.RarityNumber or 0
                        end
                        local scale = tonumber(rec.AssetScale) or 1
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

local function walkTo(targetPos, timeout)
    local h = getHum()
    local r = getHRP()
    if not h or not r then return false end

    timeout = timeout or 25
    if (r.Position - targetPos).Magnitude <= getgenv().config.arriveDist then return true end

    h:MoveTo(targetPos)

    local t0 = tick()
    while tick() - t0 < timeout do
        if not utility.farmEnabled then return false end
        task.wait(0.05)
        r = getHRP()
        h = getHum()
        if not r or not h then return false end
        if (r.Position - targetPos).Magnitude <= getgenv().config.arriveDist then
            return true
        end
        h:MoveTo(targetPos)
    end
    return true
end

local function grabEgg(rec, model)
    pcall(function()
        if utility.EggState and utility.EggState.CarryFieldEgg then
            utility.EggState.CarryFieldEgg(rec.Uid)
        end
    end)
    task.wait(0.08)

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
end

local function farmCycle()
    local rec, model = findBestEgg()
    if not rec or not model then
        task.wait(0.5)
        return
    end

    local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
    if not part then return end

    -- 1. MoveTo egg
    ui.Status.Text = "Status: 🎯 Moving to egg..."
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
    walkTo(part.Position, 25)
    if not utility.farmEnabled then return end

    -- 2. Grab
    ui.Status.Text = "Status: 🥚 Grabbing..."
    grabEgg(rec, model)

    -- 3. Return base
    ui.Status.Text = "Status: 🏠 Returning to base..."
    walkTo(getgenv().config.basePos, 25)
    if not utility.farmEnabled then return end

    task.wait(getgenv().config.cycleDelay)
end

function utility:startFarm()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    if not fireproximityprompt then return false, "Missing fireproximityprompt" end

    if not loadEggState() then
        return false, "EggState not found"
    end

    self.farmThread = task.spawn(function()
        while self.farmEnabled do
            pcall(farmCycle)
            task.wait(0.1)
        end
    end)

    return true
end

function utility:stopFarm()
    self.farmEnabled = false
    if self.farmThread then
        pcall(function() task.cancel(self.farmThread) end)
        self.farmThread = nil
    end
end

-- ============================================
-- STEP 6: UI
-- ============================================
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
    if utility.CoreGui:FindFirstChild("StealEggUI") then
        utility.CoreGui.StealEggUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = utility.CoreGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 260, 0, 180)
    Main.Position = UDim2.new(0.5, -130, 0.5, -90)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = COLORS.STROKE

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

    local speedToggle = makeToggle(50, "Speed Bypass (260)", "⚡")
    local farmToggle = makeToggle(95, "Auto Farm Best", "🎯")

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 145)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui,
        speedToggle = speedToggle,
        farmToggle = farmToggle,
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

-- ⚡ Speed
utility.speedEnabled = false
ui.speedToggle.btn.MouseButton1Click:Connect(function()
    utility.speedEnabled = not utility.speedEnabled
    setToggle(ui.speedToggle, utility.speedEnabled)

    if utility.speedEnabled then
        if speedReady then
            startSpeed(getgenv().config.speedValue)
            ui.Status.Text = "Status: ⚡ Speed ON (" .. getgenv().config.speedValue .. ")"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "Status: ❌ Speed bypass failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.speedEnabled = false
            setToggle(ui.speedToggle, false)
        end
    else
        stopSpeed()
        ui.Status.Text = "Status: ⚡ Speed OFF"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

-- 🎯 Auto Farm
ui.farmToggle.btn.MouseButton1Click:Connect(function()
    if not utility.farmEnabled then
        utility.farmEnabled = true
        setToggle(ui.farmToggle, true)

        local ok, err = utility:startFarm()
        if ok then
            ui.Status.Text = "Status: 🎯 Farm ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "Status: ❌ " .. tostring(err)
            ui.Status.TextColor3 = COLORS.RED
            utility.farmEnabled = false
            setToggle(ui.farmToggle, false)
        end
    else
        utility:stopFarm()
        setToggle(ui.farmToggle, false)
        ui.Status.Text = "Status: 🎯 Farm OFF"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    utility.speedEnabled = false
    utility.farmEnabled = false
    stopSpeed()
    utility:stopFarm()
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
