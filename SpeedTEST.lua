-- ============================================================
-- STEAL AN EGG — Integrated UI
-- Speed + Instant Pickup + Anti-Ragdoll + Auto Farm + Egg Selection
-- ============================================================

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local CoreGui           = game:GetService("CoreGui")
local LocalPlayer       = Players.LocalPlayer

-- ============================================================
-- SPEED BYPASS
-- ============================================================
local _speedBypassConn   = nil
local _speedBypassActive = false

local function _activeHum()
    local c = LocalPlayer.Character
    if not c then return nil end
    for _, h in ipairs(c:GetChildren()) do
        if h:IsA("Humanoid") and not h.PlatformStand then return h end
    end
    return c:FindFirstChildOfClass("Humanoid")
end

local function initSpeedBypass()
    if type(getgc) ~= "function" or type(hookfunction) ~= "function" or type(islclosure) ~= "function" then
        warn("[SpeedBypass] missing getgc/hookfunction/islclosure"); return false
    end
    local function findFn(nups, line)
        local ok, r = pcall(function()
            for _, f in next, getgc() do
                if typeof(f) == "function" and islclosure(f) then
                    local upvs = debug.getupvalues(f)
                    if upvs and #upvs == nups and debug.info(f, "l") == line then
                        if nups == 10 then
                            local t = debug.getupvalue(f, 3)
                            if typeof(t) == "table" and rawget(t, "Humanoid") then return f end
                        else return f end
                    end
                end
            end
        end)
        return ok and r or nil
    end
    local func3 = findFn(19, 3)
    if not func3 then warn("[SpeedBypass] func3 not found"); return false end
    local v7 = debug.getupvalue(func3, 2)
    if not v7 then warn("[SpeedBypass] v7 not found"); return false end
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
    if not ok then warn("[SpeedBypass] hookfunction failed:", tostring(err)); return false end
    _speedBypassActive = true; return true
end

local function startSpeedBypass(spd)
    if _speedBypassConn then _speedBypassConn:Disconnect(); _speedBypassConn = nil end
    if not _speedBypassActive then return end
    _speedBypassConn = RunService.Heartbeat:Connect(function()
        local h = _activeHum(); if h then h.WalkSpeed = spd end
    end)
end

local function stopSpeedBypass()
    if _speedBypassConn then _speedBypassConn:Disconnect(); _speedBypassConn = nil end
    local h = _activeHum(); if h then h.WalkSpeed = 16 end
end

pcall(initSpeedBypass)

-- ============================================================
-- MODULE LOADER
-- ============================================================
local EggState, PlotState, Assets, RarityModule, AreaEggSlotIdentity, GameRemotes
local ModulesLoaded = false

local function tryRequire(...)
    for _, path in ipairs({...}) do
        local ok, result = pcall(function()
            local cur = ReplicatedStorage
            for seg in string.gmatch(path, "[^.]+") do
                cur = cur:FindFirstChild(seg)
                if not cur then return nil end
            end
            return require(cur)
        end)
        if ok and result then return result end
    end
    return nil
end

local function loadModules()
    if ModulesLoaded then return true end
    EggState            = tryRequire("Client.EggState",  "Shared.EggState")
    PlotState           = tryRequire("Client.PlotState", "Shared.PlotState")
    Assets              = tryRequire("Data.Assets",      "Shared.Assets", "Assets")
    RarityModule        = tryRequire("Data.Rarity",      "Shared.Rarity", "Rarity")
    AreaEggSlotIdentity = tryRequire("Shared.Util.AreaEggSlotIdentity", "Util.AreaEggSlotIdentity")
    GameRemotes         = tryRequire("Shared.Remotes",   "Remotes")
    ModulesLoaded       = EggState ~= nil and PlotState ~= nil
    return ModulesLoaded
end

-- ============================================================
-- RARITY
-- ============================================================
local RARITY_ORDER = {
    Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6,
    SuperRare=7,Exotic=8,Limited=9,Divine=10,Secret=11,Titan=12,
    Cosmic=13,Celestial=14,Transcendent=15,Prismatic=16,Rainbow=17,
    Eternal=18,Brainrot=19,Mythical=20,Exclusive=21,
}

local RARITIES_LIST = {
    "Common","Uncommon","Rare","Epic","Legendary","Mythic",
    "SuperRare","Exotic","Limited","Divine","Secret","Titan",
    "Cosmic","Celestial","Transcendent","Prismatic","Rainbow",
    "Eternal","Brainrot","Mythical","Exclusive"
}

local START_POS = Vector3.new(519.155, 70.576, -356.103)

-- ============================================================
-- STATE
-- ============================================================
local State = {
    running      = false,
    busy         = false,
    speed        = 120,
    antiGuard    = true,
    targetRarities = {},
    minEarningRate = 0,
    lockedRecord = nil,
    floatEnabled = false,
    floatHeight  = 3,
}

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

local function isRarityAllowed(record)
    local t = State.targetRarities
    if not t then return true end
    local hasAny = false
    if type(t) == "table" then
        for _ in pairs(t) do hasAny = true; break end
    end
    if not hasAny then return true end

    local name = getRarityName(record)
    if not name or name == "Unknown" then return true end
    if t[name] == true then return true end
    local nameLower = name:lower()
    for k, v in pairs(t) do
        if v == true and type(k) == "string" and k:lower() == nameLower then
            return true
        end
    end
    return false
end

-- ============================================================
-- FLOAT
-- ============================================================
local _floatConn = nil
local function updateFloat()
    if _floatConn then _floatConn:Disconnect(); _floatConn = nil end
    if not State.floatEnabled then return end
    _floatConn = RunService.RenderStepped:Connect(function()
        if not State.floatEnabled then return end
        local c = LocalPlayer.Character
        if not c then return end
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local rot = hrp.CFrame - hrp.CFrame.Position
        hrp.CFrame = CFrame.new(
            hrp.Position.X,
            hrp.Position.Y + State.floatHeight,
            hrp.Position.Z
        ) * rot
    end)
end

-- ============================================================
-- WALK TO
-- ============================================================
local function walkTo(goal, timeout, isReturning, checkFn)
    local h2 = hum()
    local r  = root()
    if not h2 or not r then return false end
    if typeof(goal) == "Instance" then goal = goal.Position end

    timeout = timeout or 20
    local speed = isReturning and (State.antiGuard and 1000 or State.speed) or State.speed
    local targetDist = 4

    if isReturning then
        r = root(); h2 = hum()
        if r and h2 then
            pcall(function() r.CFrame = CFrame.new(START_POS) end)
            r.AssemblyLinearVelocity  = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            h2.WalkSpeed = 16
        end
        return true
    end

    if (r.Position - goal).Magnitude <= targetDist then
        h2.WalkSpeed = 16; return true
    end

    if _speedBypassActive then startSpeedBypass(speed) else h2.WalkSpeed = speed end
    h2:MoveTo(goal)

    local t0      = workspace.DistributedGameTime
    local lastPos = r.Position
    local stuckT  = t0
    local shouldContinue = checkFn or function() return State.running end

    while workspace.DistributedGameTime - t0 < timeout do
        if not shouldContinue() then break end
        task.wait(0.02)
        r  = root(); h2 = hum()
        if not r or not h2 then break end
        local dist = (r.Position - goal).Magnitude
        if dist <= targetDist then
            h2.WalkSpeed = 0
            h2:Move(Vector3.zero, false)
            r.AssemblyLinearVelocity  = Vector3.zero
            r.AssemblyAngularVelocity = Vector3.zero
            break
        end
        local brake = math.min(speed * 0.05, 12)
        if dist <= brake then
            local bSpeed = math.max(16, speed * (dist/brake)^1.5)
            if _speedBypassActive then startSpeedBypass(bSpeed) else h2.WalkSpeed = bSpeed end
        end
        h2:MoveTo(goal)
        local now = workspace.DistributedGameTime
        if now - stuckT >= 2 then
            if (r.Position - lastPos).Magnitude < 0.5 then
                h2:MoveTo(goal); h2.Jump = true
            end
            lastPos = r.Position; stuckT = now
        end
    end

    if _speedBypassActive then stopSpeedBypass() end
    h2 = hum(); if h2 then h2.WalkSpeed = 16 end
    return true
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

    if State.lockedRecord then
        for _, rec in ipairs(fieldEggs.Records) do
            if rec.Uid == State.lockedRecord.Uid then
                if isRarityAllowed(rec) then
                    local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
                        and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
                        or Workspace:FindFirstChild(rec.Uid, true)
                    if model then return rec, model end
                end
                break
            end
        end
        State.lockedRecord = nil
    end

    local bestRec, bestModel, bestDist = nil, nil, math.huge
    for _, rec in ipairs(fieldEggs.Records) do
        if not isRarityAllowed(rec) then continue end
        local model = Workspace:FindFirstChild("AreaEggSlotsClient", true)
            and Workspace.AreaEggSlotsClient:FindFirstChild(rec.Uid)
            or Workspace:FindFirstChild(rec.Uid, true)
        if model then
            local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local d = (part.Position - r.Position).Magnitude
                if d < bestDist then
                    bestDist  = d
                    bestRec   = rec
                    bestModel = model
                end
            end
        end
    end

    if bestRec then State.lockedRecord = bestRec end
    return bestRec, bestModel
end

-- ============================================================
-- FARM CYCLE
-- ============================================================
local function farmCycle()
    if State.busy or not State.running then return end
    State.busy = true
    local _busyStart = tick()

    pcall(function()
        if not loadModules() then return end
        local r = root(); local h2 = hum()
        if not r or not h2 then return end
        if tick() - _busyStart > 30 then State.busy = false; return end

        local rec, model = findBestEgg()
        if not rec or not model then
            State.lockedRecord = nil
            return
        end

        local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
        if not part then State.lockedRecord = nil; return end

        if not walkTo(part.Position, 15, false) then return end
        if not State.running then return end

        r = root()
        if not r then State.busy = false; return end
        local dist = (r.Position - part.Position).Magnitude
        if dist > 8 then State.busy = false; return end

        local slotKey = nil
        pcall(function()
            if AreaEggSlotIdentity and rec.AreaId and rec.NestId then
                slotKey = AreaEggSlotIdentity.SlotKey(rec.AreaId, rec.NestId)
            end
        end)

        if _speedBypassActive then stopSpeedBypass() end
        local h2stop = hum()
        if h2stop then
            h2stop.WalkSpeed = 0
            h2stop:Move(Vector3.zero, false)
        end
        local rStop = root()
        if rStop then
            rStop.AssemblyLinearVelocity  = Vector3.zero
            rStop.AssemblyAngularVelocity = Vector3.zero
            pcall(function()
                rStop.CFrame = CFrame.new(
                    part.Position + (rStop.Position - part.Position).Unit * 2
                ) * (rStop.CFrame - rStop.CFrame.Position)
            end)
        end

        local claimed = false
        for _ = 1, 5 do
            pcall(function() EggState.CarryFieldEgg(rec.Uid, slotKey) end)
            local prompt = model:FindFirstChild("CarryAreaEgg", true)
                or model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function()
                    prompt.Enabled = true
                    prompt.HoldDuration = 0
                    if typeof(fireproximityprompt) == "function" then
                        fireproximityprompt(prompt, 0)
                    end
                    pcall(function() prompt:InputHoldBegin() end)
                    pcall(function() prompt:InputHoldEnd() end)
                end)
            end
            task.wait()
            local char = LocalPlayer.Character
            if char then
                for _, t in ipairs(char:GetChildren()) do
                    if t:IsA("Tool") and t:GetAttribute("ItemType") == "AssetEgg" then
                        claimed = true; break
                    end
                end
            end
            if claimed then break end
        end
        State.lockedRecord = nil

        if _speedBypassActive then startSpeedBypass(State.antiGuard and 1000 or State.speed) end

        local rbTimeout = tick() + 2
        while tick() < rbTimeout do
            local r3 = root()
            if not r3 then break end
            local vel = r3.AssemblyLinearVelocity
            local hVel = Vector3.new(vel.X, 0, vel.Z).Magnitude
            if hVel < 8 then break end
            task.wait(0.05)
        end

        walkTo(START_POS, 15, false)
        if not State.running then return end

        local char = LocalPlayer.Character
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") and t:GetAttribute("ItemType") == "AssetEgg" then
                    pcall(function() t.Parent = LocalPlayer.Backpack end)
                end
            end
        end
    end)

    local h2 = hum()
    if h2 then h2.WalkSpeed = 16 end
    State.busy = false
end

-- ============================================================
-- INSTANT PICKUP
-- ============================================================
local _instantConn = nil

local function startInstantPickup()
    if _instantConn then _instantConn:Disconnect(); _instantConn = nil end
    _instantConn = ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, player)
        if player == LocalPlayer and tostring(prompt) == "CarryAreaEgg" then
            prompt.HoldDuration = 0
        end
    end)
    return true
end

local function stopInstantPickup()
    if _instantConn then _instantConn:Disconnect(); _instantConn = nil end
end

-- ============================================================
-- ANTI-RAGDOLL
-- ============================================================
local _antiRagdollConn = nil
local _ragdollConns = {}

local function startAntiRagdoll()
    if type(getconnections) ~= "function" then return false, "Missing getconnections" end
    local Packages = ReplicatedStorage:FindFirstChild("Packages")
    if not Packages then return false, "No Packages" end
    local Networking = Packages:FindFirstChild("Networking")
    if not Networking then return false, "No Networking" end
    local RigSync = Networking:FindFirstChild("RE/RigSync/Refresh")
    if not RigSync then return false, "No RigSync" end

    local conns = getconnections(RigSync.OnClientEvent)
    if conns then
        for _, conn in next, conns do
            pcall(function() conn:Disconnect(); table.insert(_ragdollConns, conn) end)
        end
    end

    _antiRagdollConn = RunService.Heartbeat:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local h = char:FindFirstChildOfClass("Humanoid")
        if not h then return end
        for _, obj in next, char:GetDescendants() do
            if obj:IsA("RagdollConstraint") or obj:IsA("BallSocketConstraint") then
                pcall(function() obj:Destroy() end)
            end
        end
        if h:GetState() == Enum.HumanoidStateType.Physics or
           h:GetState() == Enum.HumanoidStateType.Ragdoll then
            pcall(function() h:ChangeState(Enum.HumanoidStateType.GettingUp) end)
        end
        for _, joint in next, char:GetDescendants() do
            if joint:IsA("Motor6D") and joint.Enabled == false then
                pcall(function() joint.Enabled = true end)
            end
        end
    end)
    return true
end

local function stopAntiRagdoll()
    if _antiRagdollConn then _antiRagdollConn:Disconnect(); _antiRagdollConn = nil end
    _ragdollConns = {}
end

-- ============================================================
-- UI
-- ============================================================
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    STROKE = Color3.fromRGB(60, 60, 70),
    TEXT = Color3.fromRGB(255, 255, 255),
    SUB = Color3.fromRGB(180, 180, 190),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
    BTN = Color3.fromRGB(45, 45, 55),
    BTN_HOVER = Color3.fromRGB(55, 55, 65),
    ACCENT = Color3.fromRGB(90, 130, 220),
}

local function createUI()
    if CoreGui:FindFirstChild("StealEggUI") then
        CoreGui.StealEggUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    -- MAIN FRAME
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 290, 0, 420)
    Main.Position = UDim2.new(0.5, -145, 0.5, -210)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local s1 = Instance.new("UIStroke", Main)
    s1.Color = COLORS.STROKE

    -- TITLE BAR
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
    Title.TextSize = 14
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

    -- TOGGLE BUILDER
    local function makeToggle(y, label, icon)
        local lbl = Instance.new("TextLabel", Main)
        lbl.Size = UDim2.new(1, -120, 0, 25)
        lbl.Position = UDim2.new(0, 15, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. " " .. label
        lbl.TextColor3 = COLORS.TEXT
        lbl.TextSize = 13
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local state = Instance.new("TextLabel", Main)
        state.Size = UDim2.new(0, 45, 0, 25)
        state.Position = UDim2.new(1, -120, 0, y)
        state.BackgroundTransparency = 1
        state.Text = "OFF"
        state.TextColor3 = COLORS.RED
        state.TextSize = 12
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

    -- TOGGLES
    local speedToggle    = makeToggle(50, "Speed Hack", "⚡")
    local pickupToggle   = makeToggle(95, "Instant Pickup", "⚡")
    local ragdollToggle  = makeToggle(140, "Anti-Ragdoll", "🛡️")
    local autoFarmToggle = makeToggle(185, "Auto Farm", "🎯")
    local floatToggle    = makeToggle(230, "Float", "🦘")

    -- EGG SELECTION SECTION
    local selLabel = Instance.new("TextLabel", Main)
    selLabel.Size = UDim2.new(1, -30, 0, 20)
    selLabel.Position = UDim2.new(0, 15, 0, 275)
    selLabel.BackgroundTransparency = 1
    selLabel.Text = "🎯 Egg Selection:"
    selLabel.TextColor3 = COLORS.SUB
    selLabel.TextSize = 12
    selLabel.Font = Enum.Font.GothamBold
    selLabel.TextXAlignment = Enum.TextXAlignment.Left

    -- EGG SELECTION BUTTONS (grid 3 columns)
    local selectedRarity = {}
    local rarityButtons = {}
    
    local function makeRarityBtn(rarity, x, y)
        local btn = Instance.new("TextButton", Main)
        btn.Size = UDim2.new(0, 85, 0, 24)
        btn.Position = UDim2.new(0, x, 0, y)
        btn.BackgroundColor3 = COLORS.BTN
        btn.Text = rarity
        btn.TextColor3 = COLORS.SUB
        btn.TextSize = 10
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)

        btn.MouseButton1Click:Connect(function()
            selectedRarity[rarity] = not selectedRarity[rarity]
            if selectedRarity[rarity] then
                btn.BackgroundColor3 = COLORS.ACCENT
                btn.TextColor3 = COLORS.TEXT
            else
                btn.BackgroundColor3 = COLORS.BTN
                btn.TextColor3 = COLORS.SUB
            end
            State.targetRarities = selectedRarity
        end)

        return btn
    end

    -- Grid layout
    local row1 = {"Legendary", "Mythic", "Divine"}
    local row2 = {"Secret", "Cosmic", "Eternal"}
    
    for i, r in ipairs(row1) do
        rarityButtons[r] = makeRarityBtn(r, 15 + (i-1) * 90, 300)
    end
    for i, r in ipairs(row2) do
        rarityButtons[r] = makeRarityBtn(r, 15 + (i-1) * 90, 328)
    end

    -- Select All / Clear
    local selectAllBtn = Instance.new("TextButton", Main)
    selectAllBtn.Size = UDim2.new(0, 85, 0, 24)
    selectAllBtn.Position = UDim2.new(0, 15, 0, 358)
    selectAllBtn.BackgroundColor3 = COLORS.GREEN
    selectAllBtn.Text = "Select All"
    selectAllBtn.TextColor3 = COLORS.TEXT
    selectAllBtn.TextSize = 10
    selectAllBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", selectAllBtn).CornerRadius = UDim.new(0, 5)

    selectAllBtn.MouseButton1Click:Connect(function()
        for r, btn in pairs(rarityButtons) do
            selectedRarity[r] = true
            btn.BackgroundColor3 = COLORS.ACCENT
            btn.TextColor3 = COLORS.TEXT
        end
        State.targetRarities = selectedRarity
    end)

    local clearBtn = Instance.new("TextButton", Main)
    clearBtn.Size = UDim2.new(0, 85, 0, 24)
    clearBtn.Position = UDim2.new(0, 105, 0, 358)
    clearBtn.BackgroundColor3 = COLORS.RED
    clearBtn.Text = "Clear"
    clearBtn.TextColor3 = COLORS.TEXT
    clearBtn.TextSize = 10
    clearBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", clearBtn).CornerRadius = UDim.new(0, 5)

    clearBtn.MouseButton1Click:Connect(function()
        for r, btn in pairs(rarityButtons) do
            selectedRarity[r] = false
            btn.BackgroundColor3 = COLORS.BTN
            btn.TextColor3 = COLORS.SUB
        end
        State.targetRarities = selectedRarity
    end)

    -- STATUS
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 390)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        speedToggle = speedToggle, pickupToggle = pickupToggle,
        ragdollToggle = ragdollToggle, autoFarmToggle = autoFarmToggle,
        floatToggle = floatToggle,
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

-- SPEED HACK
local speedEnabled = false
ui.speedToggle.btn.MouseButton1Click:Connect(function()
    speedEnabled = not speedEnabled
    setToggle(ui.speedToggle, speedEnabled)
    if speedEnabled then
        startSpeedBypass(260)
        ui.Status.Text = "Status: ⚡ Speed ON (260)"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        stopSpeedBypass()
        ui.Status.Text = "Status: ⚡ Speed OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- INSTANT PICKUP
local pickupEnabled = false
ui.pickupToggle.btn.MouseButton1Click:Connect(function()
    pickupEnabled = not pickupEnabled
    setToggle(ui.pickupToggle, pickupEnabled)
    if pickupEnabled then
        startInstantPickup()
        ui.Status.Text = "Status: ⚡ Instant Pickup ON"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        stopInstantPickup()
        ui.Status.Text = "Status: ⚡ Instant Pickup OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- ANTI-RAGDOLL
local ragdollEnabled = false
ui.ragdollToggle.btn.MouseButton1Click:Connect(function()
    ragdollEnabled = not ragdollEnabled
    setToggle(ui.ragdollToggle, ragdollEnabled)
    if ragdollEnabled then
        local ok, err
