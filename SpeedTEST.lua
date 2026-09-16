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
    ProximityPromptService = game:GetService("ProximityPromptService"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    Workspace = game:GetService("Workspace"),
    CoreGui = game:GetService("CoreGui"),
    conns = {},
}

-- ============================================
-- STEP 3: CONFIG
-- ============================================
getgenv().config = {
    speedValue = 260,
}

-- ============================================
-- STEP 4: BIND/UNBIND HELPERS
-- ============================================
function utility:bind(connection, callback)
    local s, r = pcall(function(...)
        local conn = connection:Connect(callback)
        self.conns[conn] = conn
        return self.conns[conn]
    end)
    if s and r then return r end
    return warn('failed to bind: '..tostring(r))
end

function utility:unbind(connection)
    local s, r = pcall(function(...)
        local conn = self.conns[connection]
        if conn then
            conn:Disconnect()
            self.conns[connection] = nil
            return true
        end
        return false
    end)
    if s and r then return true end
    return warn("failed to unbind")
end

-- ============================================
-- STEP 5: INSTANT PICKUP
-- ============================================
function utility:startInstantPickup()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return warn('no localplayer') end

    self.instantConn = self:bind(self.ProximityPromptService.PromptButtonHoldBegan, function(ProximityPrompt, Player)
        if Player == self.LocalPlayer and tostring(ProximityPrompt) == "CarryAreaEgg" then
            ProximityPrompt.HoldDuration = 0
        end
    end)

    return self.instantConn ~= nil
end

function utility:stopInstantPickup()
    if self.instantConn then
        self:unbind(self.instantConn)
        self.instantConn = nil
    end
end

-- ============================================
-- STEP 6: ANTI-RAGDOLL
-- ============================================
utility.antiRagdollEnabled = false
utility.antiRagdollConn = nil
utility.ragdollConns = {}

function utility:startAntiRagdoll()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    if not getconnections then return false, "Missing getconnections" end

    self.Packages = self.ReplicatedStorage:FindFirstChild("Packages")
    if not self.Packages then return false, "No Packages" end

    self.Networking = self.Packages:FindFirstChild("Networking")
    if not self.Networking then return false, "No Networking" end

    self.RigSync = self.Networking:FindFirstChild("RE/RigSync/Refresh")
    if not self.RigSync then return false, "No RE/RigSync/Refresh" end

    local conns = getconnections(self.RigSync.OnClientEvent)
    if conns then
        for _, conn in next, conns do
            pcall(function()
                conn:Disconnect()
                table.insert(utility.ragdollConns, conn)
            end)
        end
    end

    utility.antiRagdollConn = self.RunService.Heartbeat:Connect(function()
        if not utility.antiRagdollEnabled then return end

        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        for _, obj in next, char:GetDescendants() do
            if obj:IsA("RagdollConstraint") or obj:IsA("BallSocketConstraint") then
                pcall(function() obj:Destroy() end)
            end
        end

        if hum:GetState() == Enum.HumanoidStateType.Physics or
           hum:GetState() == Enum.HumanoidStateType.Ragdoll then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end

        for _, joint in next, char:GetDescendants() do
            if joint:IsA("Motor6D") and joint.Enabled == false then
                pcall(function() joint.Enabled = true end)
            end
        end
    end)

    return true
end

function utility:stopAntiRagdoll()
    if utility.antiRagdollConn then
        utility.antiRagdollConn:Disconnect()
        utility.antiRagdollConn = nil
    end
    utility.ragdollConns = {}
end

-- ============================================
-- STEP 7: ANTI-TRAP
-- ============================================
utility.antiTrapEnabled = false
utility.antiTrapConn = nil
utility.trapConns = {}

function utility:destroyTraps()
    local debris = self.Workspace:FindFirstChild("__DEBRIS")
    if not debris then return end

    for _, obj in next, debris:GetChildren() do
        if obj.Name == "PlayerTrap" then
            pcall(function() obj:Destroy() end)
            print("[AntiTrap] ✅ Destroyed PlayerTrap")
        end
    end
end

function utility:startAntiTrap()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end

    self:destroyTraps()

    local debris = self.Workspace:FindFirstChild("__DEBRIS")
    if debris then
        table.insert(utility.trapConns, debris.ChildAdded:Connect(function(child)
            if utility.antiTrapEnabled and child.Name == "PlayerTrap" then
                pcall(function() child:Destroy() end)
                print("[AntiTrap] ✅ Destroyed new PlayerTrap")
            end
        end))
    end

    table.insert(utility.trapConns, self.Workspace.ChildAdded:Connect(function(child)
        if utility.antiTrapEnabled and child.Name == "__DEBRIS" then
            child.ChildAdded:Connect(function(trap)
                if utility.antiTrapEnabled and trap.Name == "PlayerTrap" then
                    pcall(function() trap:Destroy() end)
                end
            end)
        end
    end))

    utility.antiTrapConn = self.RunService.Heartbeat:Connect(function()
        if not utility.antiTrapEnabled then return end
        self:destroyTraps()

        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        if char:GetAttribute("IsTrapped") == true then
            pcall(function()
                hum.PlatformStand = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end

        if hum.PlatformStand then
            pcall(function() hum.PlatformStand = false end)
        end

        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics or
           state == Enum.HumanoidStateType.Ragdoll or
           state == Enum.HumanoidStateType.FallingDown or
           state == Enum.HumanoidStateType.PlatformStanding then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end

        for _, joint in next, char:GetDescendants() do
            if joint:IsA("Motor6D") and joint.Enabled == false then
                pcall(function() joint.Enabled = true end)
            end
        end
    end)

    return true
end

function utility:stopAntiTrap()
    if utility.antiTrapConn then
        utility.antiTrapConn:Disconnect()
        utility.antiTrapConn = nil
    end
    for _, conn in next, utility.trapConns do
        pcall(function() conn:Disconnect() end)
    end
    utility.trapConns = {}
end

-- ============================================
-- STEP 8: AUTO GRAB BEST EGG
-- ============================================
utility.autoGrabEnabled = false
utility.autoGrabConn = nil

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple", "Light Dark",
}

utility.EggState = nil
utility.AssetsDir = nil
utility.Mutations = nil
utility.AssetEarnings = nil

function utility:loadEggModules()
    if self.EggState then return true end
    local ok = pcall(function()
        local client = self.ReplicatedStorage:FindFirstChild("Client")
        if client then
            local es = client:FindFirstChild("EggState")
            if es then self.EggState = require(es) end
        end
        local data = self.ReplicatedStorage:FindFirstChild("Data")
        if data then
            local assets = data:FindFirstChild("Assets")
            if assets then
                local okA, mod = pcall(require, assets)
                if okA and mod then self.AssetsDir = mod.Directory end
            end
        end
        local shared = self.ReplicatedStorage:FindFirstChild("Shared")
        if shared then
            local modules = shared:FindFirstChild("Modules")
            if modules then
                local mut = modules:FindFirstChild("Mutations")
                if mut then
                    local okM, mod = pcall(require, mut)
                    if okM then self.Mutations = mod end
                end
            end
            local util = shared:FindFirstChild("Util")
            if util then
                local ae = util:FindFirstChild("AssetEarnings")
                if ae then
                    local okE, mod = pcall(require, ae)
                    if okE then self.AssetEarnings = mod end
                end
            end
        end
    end)
    return ok and self.EggState ~= nil
end

function utility:getRarityNumber(rec)
    if rec and rec.Rarity and type(rec.Rarity) == "table" then
        return rec.Rarity.RarityNumber or 0
    end
    return 0
end

function utility:getAssetScale(rec)
    return tonumber(rec.AssetScale) or 1
end

function utility:getEggPos(rec)
    if not rec then return nil end
    if rec.BoundsCFrame and rec.BoundsCFrame.Position then
        return rec.BoundsCFrame.Position
    end
    return nil
end

function utility:calcEggValue(rec)
    if not rec then return 0 end

    if self.AssetEarnings then
        local ok, rate = pcall(function()
            local item = {
                Category = rec.AssetCategory,
                Scale = tonumber(rec.AssetScale) or 1,
                Mutations = rec.Mutations or {},
            }
            return self.AssetEarnings.LiveRatePerSecond(item, nil, nil, self.Players.LocalPlayer)
        end)
        if ok and type(rate) == "number" and rate > 0 then
            return rate
        end
    end

    local rarity = self:getRarityNumber(rec)
    local scale = self:getAssetScale(rec)
    local mutMult = 1

    if rec.Mutations and #rec.Mutations > 0 and self.Mutations then
        pcall(function()
            local item = { Mutations = rec.Mutations }
            mutMult = self.Mutations.EarningsFor(item) or 1
        end)
    end

    local baseRate = 0
    if self.AssetsDir then
        local dir = self.AssetsDir[rec.AssetCategory]
        if dir then baseRate = tonumber(dir.EarningRate) or 0 end
    end

    local scaleFactor = scale <= 5 and scale ^ 1.85 or (scale / 5) ^ 1.2 * 19.637875755794113
    local value = baseRate * scaleFactor * mutMult
    return math.max(1, math.round(value))
end

function utility:findAllHighValueEggs()
    if not self.EggState then return {} end
    local ok, fieldEggs = pcall(function() return self.EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return {} end

    local eggs = {}
    local minValue = 5e7  -- 50M
    local minArea = 10

    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local areaIdx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then areaIdx = i break end
            end

            if areaIdx and areaIdx >= minArea then
                local value = self:calcEggValue(rec)
                if value >= minValue then
                    eggs[#eggs + 1] = { rec = rec, value = value }
                end
            end
        end
    end

    table.sort(eggs, function(a, b) return a.value > b.value end)
    return eggs
end

function utility:fastGrabEgg(rec)
    if not rec then return false end

    local ok1, res1 = pcall(function()
        return self.EggState.CarryFieldEgg(rec.Uid)
    end)
    if ok1 and res1 == true then return true end

    local eggPos = self:getEggPos(rec)
    if not eggPos then return false end

    local CarryAreaEggs = self.Workspace:QueryDescendants("#CarryAreaEgg")
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
        return true
    end

    return false
end

function utility:startAutoGrab()
    if not self:loadEggModules() then
        return false, "EggState not found"
    end

    self.autoGrabLastGrabbed = {}
    self.autoGrabCount = 0
    self.autoGrabLastValue = 0

    local checkDelay = 0.1
    local grabCooldown = 2
    local postGrabWait = 0.3

    self.autoGrabConn = self.RunService.Heartbeat:Connect(function()
        if not self.autoGrabEnabled then return end

        -- Throttle sa 0.1s
        local now = tick()
        if self.autoGrabLastCheck and (now - self.autoGrabLastCheck) < checkDelay then
            return
        end
        self.autoGrabLastCheck = now

        local eggs = self:findAllHighValueEggs()
        if #eggs > 0 then
            for _, item in ipairs(eggs) do
                if not self.autoGrabEnabled then break end

                local rec = item.rec
                local value = item.value
                local lastTime = self.autoGrabLastGrabbed[rec.Uid]

                if not lastTime or (tick() - lastTime) > grabCooldown then
                    self.autoGrabLastGrabbed[rec.Uid] = tick()

                    local ok = self:fastGrabEgg(rec)
                    if ok then
                        self.autoGrabCount = self.autoGrabCount + 1
                        self.autoGrabLastValue = value
                        print(("[AutoGrab #%d] ✅ %s /s (%s)"):format(
                            self.autoGrabCount, 
                            string.format("%.2fM", value / 1e6), 
                            rec.AreaId))
                        task.wait(postGrabWait)
                        break
                    end
                end
            end
        end
    end)

    return true
end

function utility:stopAutoGrab()
    if self.autoGrabConn then
        self.autoGrabConn:Disconnect()
        self.autoGrabConn = nil
    end
end

-- ============================================
-- STEP 9: UI (COMPACT VERSION)
-- ============================================
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    STROKE = Color3.fromRGB(60, 60, 70),
    TEXT = Color3.fromRGB(255, 255, 255),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
    GOLD = Color3.fromRGB(255, 215, 0),
}

local function createUI()
    if utility.CoreGui:FindFirstChild("StealEggUI") then
        utility.CoreGui.StealEggUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = utility.CoreGui

    -- 🎯 MAS MALIIT: 220 x 300
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 220, 0, 300)
    Main.Position = UDim2.new(0.5, -110, 0.5, -150)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local c1 = Instance.new("UICorner", Main)
    c1.CornerRadius = UDim.new(0, 8)
    local s1 = Instance.new("UIStroke", Main)
    s1.Color = COLORS.STROKE

    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 28)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    local c2 = Instance.new("UICorner", TitleBar)
    c2.CornerRadius = UDim.new(0, 8)
    local TitleCover = Instance.new("Frame", TitleBar)
    TitleCover.Size = UDim2.new(1, 0, 0, 8)
    TitleCover.Position = UDim2.new(0, 0, 1, -8)
    TitleCover.BackgroundColor3 = COLORS.TITLE_BG
    TitleCover.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🥚 Steal An Egg"
    Title.TextColor3 = COLORS.TEXT
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -25, 0, 4)
    CloseBtn.BackgroundColor3 = COLORS.RED
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = COLORS.TEXT
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    local c3 = Instance.new("UICorner", CloseBtn)
    c3.CornerRadius = UDim.new(0, 5)

    -- 🎯 COMPACT TOGGLE: 40x22, font 11
    local function makeToggle(y, label, icon)
        local lbl = Instance.new("TextLabel", Main)
        lbl.Size = UDim2.new(1, -105, 0, 22)
        lbl.Position = UDim2.new(0, 12, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. " " .. label
        lbl.TextColor3 = COLORS.TEXT
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local state = Instance.new("TextLabel", Main)
        state.Size = UDim2.new(0, 35, 0, 22)
        state.Position = UDim2.new(1, -100, 0, y)
        state.BackgroundTransparency = 1
        state.Text = "OFF"
        state.TextColor3 = COLORS.RED
        state.TextSize = 10
        state.Font = Enum.Font.GothamBold
        state.TextXAlignment = Enum.TextXAlignment.Right

        local track = Instance.new("Frame", Main)
        track.Size = UDim2.new(0, 40, 0, 22)
        track.Position = UDim2.new(1, -55, 0, y)
        track.BackgroundColor3 = COLORS.TRACK_OFF
        track.BorderSizePixel = 0
        local tc = Instance.new("UICorner", track)
        tc.CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", track)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = COLORS.KNOB
        knob.BorderSizePixel = 0
        local kc = Instance.new("UICorner", knob)
        kc.CornerRadius = UDim.new(1, 0)

        local btn = Instance.new("TextButton", Main)
        btn.Size = UDim2.new(0, 100, 0, 30)
        btn.Position = UDim2.new(1, -105, 0, y - 4)
        btn.BackgroundTransparency = 1
        btn.Text = ""

        return {track = track, knob = knob, state = state, btn = btn}
    end

    local speedToggle = makeToggle(38, "Speed Bypass", "⚡")
    local pickupToggle = makeToggle(72, "Instant Pickup", "⚡")
    local ragdollToggle = makeToggle(106, "Anti-Ragdoll", "🛡️")
    local antiTrapToggle = makeToggle(140, "Anti-Trap", "🪤")
    local autoGrabToggle = makeToggle(174, "Auto Grab 50M+", "💰")

    -- Auto Grab info (compact)
    local GrabInfo = Instance.new("TextLabel", Main)
    GrabInfo.Size = UDim2.new(1, -20, 0, 16)
    GrabInfo.Position = UDim2.new(0, 12, 0, 200)
    GrabInfo.BackgroundTransparency = 1
    GrabInfo.Text = "Next: -- | Grabbed: 0"
    GrabInfo.TextColor3 = COLORS.GOLD
    GrabInfo.TextSize = 9
    GrabInfo.Font = Enum.Font.Gotham
    GrabInfo.TextXAlignment = Enum.TextXAlignment.Left

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -20, 0, 16)
    Status.Position = UDim2.new(0, 12, 0, 218)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    -- Flow hint
    local FlowHint = Instance.new("TextLabel", Main)
    FlowHint.Size = UDim2.new(1, -20, 0, 14)
    FlowHint.Position = UDim2.new(0, 12, 0, 240)
    FlowHint.BackgroundTransparency = 1
    FlowHint.Text = "💡 1B → 500M → 100M → 50M"
    FlowHint.TextColor3 = Color3.fromRGB(100, 200, 255)
    FlowHint.TextSize = 9
    FlowHint.Font = Enum.Font.Gotham
    FlowHint.TextXAlignment = Enum.TextXAlignment.Left

    -- Stats line
    local StatsLine = Instance.new("TextLabel", Main)
    StatsLine.Size = UDim2.new(1, -20, 0, 14)
    StatsLine.Position = UDim2.new(0, 12, 0, 258)
    StatsLine.BackgroundTransparency = 1
    StatsLine.Text = "Min: 50M | Area: 10+"
    StatsLine.TextColor3 = Color3.fromRGB(150, 150, 160)
    StatsLine.TextSize = 9
    StatsLine.Font = Enum.Font.Gotham
    StatsLine.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        speedToggle = speedToggle, pickupToggle = pickupToggle,
        ragdollToggle = ragdollToggle, antiTrapToggle = antiTrapToggle,
        autoGrabToggle = autoGrabToggle,
        GrabInfo = GrabInfo, Status = Status,
        CloseBtn = CloseBtn
    }
end

-- ============================================
-- STEP 10: WIRING
-- ============================================
local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- ⚡ Speed
utility.speedEnabled = false
utility.speedConn = nil

ui.speedToggle.btn.MouseButton1Click:Connect(function()
    utility.speedEnabled = not utility.speedEnabled
    setToggle(ui.speedToggle, utility.speedEnabled)
    
    if utility.speedEnabled then
        if utility.speedConn then utility.speedConn:Disconnect() end
        utility.speedConn = utility.RunService.Heartbeat:Connect(function()
            if not utility.speedEnabled then return end
            local char = utility.Players.LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            if not hum then return end
            hum.WalkSpeed = getgenv().config.speedValue
        end)
        ui.Status.Text = "⚡ Speed ON"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        if utility.speedConn then utility.speedConn:Disconnect() utility.speedConn = nil end
        local char = utility.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        ui.Status.Text = "⚡ Speed OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- ⚡ Instant Pickup
utility.pickupEnabled = false

ui.pickupToggle.btn.MouseButton1Click:Connect(function()
    utility.pickupEnabled = not utility.pickupEnabled
    setToggle(ui.pickupToggle, utility.pickupEnabled)
    
    if utility.pickupEnabled then
        local ok = utility:startInstantPickup()
        if ok then
            ui.Status.Text = "⚡ Pickup ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ Pickup failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.pickupEnabled = false
            setToggle(ui.pickupToggle, false)
        end
    else
        utility:stopInstantPickup()
        ui.Status.Text = "⚡ Pickup OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- 🛡️ Anti-Ragdoll
utility.antiRagdollEnabled = false

ui.ragdollToggle.btn.MouseButton1Click:Connect(function()
    utility.antiRagdollEnabled = not utility.antiRagdollEnabled
    setToggle(ui.ragdollToggle, utility.antiRagdollEnabled)
    
    if utility.antiRagdollEnabled then
        local ok, err = utility:startAntiRagdoll()
        if ok then
            ui.Status.Text = "🛡️ Anti-Ragdoll ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ Anti-Ragdoll failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.antiRagdollEnabled = false
            setToggle(ui.ragdollToggle, false)
        end
    else
        utility:stopAntiRagdoll()
        ui.Status.Text = "🛡️ Anti-Ragdoll OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- 🪤 Anti-Trap
utility.antiTrapEnabled = false

ui.antiTrapToggle.btn.MouseButton1Click:Connect(function()
    utility.antiTrapEnabled = not utility.antiTrapEnabled
    setToggle(ui.antiTrapToggle, utility.antiTrapEnabled)
    
    if utility.antiTrapEnabled then
        local ok = utility:startAntiTrap()
        if ok then
            ui.Status.Text = "🪤 Anti-Trap ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ Anti-Trap failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.antiTrapEnabled = false
            setToggle(ui.antiTrapToggle, false)
        end
    else
        utility:stopAntiTrap()
        ui.Status.Text = "🪤 Anti-Trap OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- 💰 Auto Grab
ui.autoGrabToggle.btn.MouseButton1Click:Connect(function()
    utility.autoGrabEnabled = not utility.autoGrabEnabled
    setToggle(ui.autoGrabToggle, utility.autoGrabEnabled)

    if utility.autoGrabEnabled then
        local ok, err = utility:startAutoGrab()
        if ok then
            ui.Status.Text = "💰 Auto Grab ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ " .. tostring(err)
            ui.Status.TextColor3 = COLORS.RED
            utility.autoGrabEnabled = false
            setToggle(ui.autoGrabToggle, false)
        end
    else
        utility:stopAutoGrab()
        ui.Status.Text = "💰 Auto Grab OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- Live update para sa GrabInfo
utility.RunService.Heartbeat:Connect(function()
    if not utility.autoGrabEnabled then return end
    local now = tick()
    if utility.lastGrabInfoUpdate and (now - utility.lastGrabInfoUpdate) < 0.5 then
        return
    end
    utility.lastGrabInfoUpdate = now

    local eggs = utility:findAllHighValueEggs()
    if #eggs > 0 then
        local top = eggs[1]
        ui.GrabInfo.Text = ("Next: %s | Grabbed: %d"):format(
            string.format("%.2fM", top.value / 1e6),
            utility.autoGrabCount or 0)
    else
        ui.GrabInfo.Text = ("Next: -- | Grabbed: %d"):format(utility.autoGrabCount or 0)
    end
end)

-- Close
ui.CloseBtn.MouseButton1Click:Connect(function()
    utility.speedEnabled = false
    utility.pickupEnabled = false
    utility.antiRagdollEnabled = false
    utility.antiTrapEnabled = false
    utility.autoGrabEnabled = false
    if utility.speedConn then utility.speedConn:Disconnect() end
    utility:stopInstantPickup()
    utility:stopAntiRagdoll()
    utility:stopAntiTrap()
    utility:stopAutoGrab()
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
