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
utility.areas = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

getgenv().config = {
    speedValue = 260,
    minArea = 9,
    moveSpeed = 350,
    characterRaise = 3,
    espColor = Color3.fromRGB(255, 100, 255),  -- 🥚 Pink
    espLineColor = Color3.fromRGB(0, 255, 255), -- 🎯 Cyan line
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
-- STEP 7: AUTO GRAB BEST EGG
-- ============================================
utility.autoGrabEnabled = false
utility.autoGrabConn = nil
utility.eggState = nil
utility.client = nil

function utility:getBestEgg()
    local s, r = pcall(function(...)
        local egg = nil
        local biggestegg = 0
        for key, data in next, self.eggState.ReadFieldEggs().Records do
            local idx = table.find(self.areas, data.AreaId)
            if idx and idx > getgenv().config.minArea then
                if data.AssetScale > biggestegg then
                    biggestegg = data.AssetScale
                    egg = data
                end
            end
        end
        return egg
    end)
    if s and r then return r end
    return nil
end

function utility:GoTo(pos)
    pcall(function(...)
        local dist = math.huge
        local targetPos = pos.BoundsCFrame.Position
        repeat
            local dt = task.wait(0.01)
            local char = self.LocalPlayer.Character
            if not char then break end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            
            local start = hrp.Position
            dist = (targetPos - start).Magnitude
            local half = start + (targetPos - start).Unit * dt * getgenv().config.moveSpeed
            half = half + Vector3.new(0, getgenv().config.characterRaise, 0)
            char:MoveTo(half)
        until dist <= 5
    end)
end

function utility:getproximitypromptforegg(egg)
    local s, r = pcall(function(...)
        local CarryAreaEggs = self.Workspace:QueryDescendants("#CarryAreaEgg")
        local closetprompt = nil
        local closetdist = math.huge
        for key, prompt in next, CarryAreaEggs do
            local p = prompt.Parent
            if p then
                local dist = (egg.BoundsCFrame.Position - p.Position).Magnitude
                if dist < closetdist then
                    closetdist = dist
                    closetprompt = prompt
                end
            end
        end
        return closetprompt
    end)
    if s and r then return r end
    return nil
end

function utility:startAutoGrab()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    if not fireproximityprompt then return false, "Missing fireproximityprompt" end

    self.client = self.ReplicatedStorage:FindFirstChild("Client")
    if not self.client then return false, "No Client" end

    local eggStateModule = self.client:FindFirstChild("EggState")
    if not eggStateModule then return false, "No EggState" end

    self.eggState = require(eggStateModule)
    if not self.eggState then return false, "EggState require failed" end

    utility.autoGrabConn = task.spawn(function()
        while utility.autoGrabEnabled do
            pcall(function()
                local egg = self:getBestEgg()
                if egg then
                    self:GoTo(egg)
                    task.wait(0.5)
                    local p = self:getproximitypromptforegg(egg)
                    if p then
                        fireproximityprompt(p, 0, true)
                    end
                    task.wait(0.1)
                    self:GoTo({BoundsCFrame = CFrame.new(514, 71, -368)})
                else
                    self:GoTo({BoundsCFrame = CFrame.new(514, 71, -368)})
                end
            end)
            task.wait(1)
        end
    end)

    return true
end

function utility:stopAutoGrab()
    utility.autoGrabEnabled = false
    if utility.autoGrabConn then
        pcall(function() task.cancel(utility.autoGrabConn) end)
        utility.autoGrabConn = nil
    end
end

-- ============================================
-- STEP 8: ESP LINE + HIGHLIGHT SA BEST EGG
-- ============================================
utility.espEnabled = false
utility.espConn = nil
utility.espHighlights = {}
utility.espLines = {}

function utility:startESP()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end

    -- Clean up old
    for _, hl in next, utility.espHighlights do
        pcall(function() hl:Destroy() end)
    end
    for _, line in next, utility.espLines do
        pcall(function() line:Destroy() end)
    end
    utility.espHighlights = {}
    utility.espLines = {}

    utility.espConn = self.RunService.Heartbeat:Connect(function()
        if not utility.espEnabled then return end

        -- Load eggState kung wala pa
        if not self.eggState then
            local client = self.ReplicatedStorage:FindFirstChild("Client")
            if client then
                local eggStateModule = client:FindFirstChild("EggState")
                if eggStateModule then
                    local s, r = pcall(require, eggStateModule)
                    if s then self.eggState = r end
                end
            end
            return
        end

        local egg = self:getBestEgg()
        if not egg then return end

        local eggPos = egg.BoundsCFrame.Position
        local char = self.LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        -- 🥚 Highlight yung best egg
        for _, obj in next, self.Workspace:GetDescendants() do
            if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
                local dist = (obj.Position - eggPos).Magnitude
                if dist < 15 then
                    if not utility.espHighlights[obj] then
                        local hl = Instance.new("Highlight")
                        hl.FillColor = getgenv().config.espColor
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.FillTransparency = 0.5
                        hl.OutlineTransparency = 0
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = obj
                        utility.espHighlights[obj] = hl
                    end
                end
            end
        end

        -- 🎯 LINE papunta sa best egg
        if not utility.espLines[eggPos] then
            local line = Instance.new("Part")
            line.Name = "ESPLine"
            line.Anchored = true
            line.CanCollide = false
            line.Material = Enum.Material.Neon
            line.Color = getgenv().config.espLineColor
            line.Transparency = 0.3
            line.Size = Vector3.new(0.1, 0.1, 1)
            line.Parent = self.Workspace
            utility.espLines[eggPos] = line
        end

        -- I-update yung line position at size
        for pos, line in next, utility.espLines do
            if line and line.Parent then
                local myPos = hrp.Position
                local midPoint = (myPos + eggPos) / 2
                local distance = (myPos - eggPos).Magnitude
                
                line.CFrame = CFrame.new(midPoint, eggPos)
                line.Size = Vector3.new(0.1, 0.1, distance)
            end
        end

        -- Clean up destroyed highlights
        for obj, hl in next, utility.espHighlights do
            if not obj.Parent then
                pcall(function() hl:Destroy() end)
                utility.espHighlights[obj] = nil
            end
        end
    end)

    return true
end

function utility:stopESP()
    if utility.espConn then
        utility.espConn:Disconnect()
        utility.espConn = nil
    end
    for _, hl in next, utility.espHighlights do
        pcall(function() hl:Destroy() end)
    end
    for _, line in next, utility.espLines do
        pcall(function() line:Destroy() end)
    end
    utility.espHighlights = {}
    utility.espLines = {}
end

-- ============================================
-- STEP 9: UI
-- ============================================
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
    if utility.CoreGui:FindFirstChild("StealEggUI") then
        utility.CoreGui.StealEggUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = utility.CoreGui

    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 260, 0, 310)
    Main.Position = UDim2.new(0.5, -130, 0.5, -155)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local c1 = Instance.new("UICorner", Main)
    c1.CornerRadius = UDim.new(0, 10)
    local s1 = Instance.new("UIStroke", Main)
    s1.Color = COLORS.STROKE

    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    local c2 = Instance.new("UICorner", TitleBar)
    c2.CornerRadius = UDim.new(0, 10)
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
    local c3 = Instance.new("UICorner", CloseBtn)
    c3.CornerRadius = UDim.new(0, 6)

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
        local tc = Instance.new("UICorner", track)
        tc.CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", track)
        knob.Size = UDim2.new(0, 20, 0, 20)
        knob.Position = UDim2.new(0, 3, 0.5, -10)
        knob.BackgroundColor3 = COLORS.KNOB
        knob.BorderSizePixel = 0
        local kc = Instance.new("UICorner", knob)
        kc.CornerRadius = UDim.new(1, 0)

        local btn = Instance.new("TextButton", Main)
        btn.Size = UDim2.new(0, 110, 0, 36)
        btn.Position = UDim2.new(1, -120, 0, y - 5)
        btn.BackgroundTransparency = 1
        btn.Text = ""

        return {track = track, knob = knob, state = state, btn = btn}
    end

    local speedToggle = makeToggle(50, "Speed Hack", "⚡")
    local pickupToggle = makeToggle(95, "Instant Pickup", "⚡")
    local ragdollToggle = makeToggle(140, "Anti-Ragdoll", "🛡️")
    local autoGrabToggle = makeToggle(185, "Auto Grab Best", "🎯")
    local espToggle = makeToggle(230, "ESP Line Best", "🎯")

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 275)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        speedToggle = speedToggle, pickupToggle = pickupToggle,
        ragdollToggle = ragdollToggle, autoGrabToggle = autoGrabToggle,
        espToggle = espToggle,
        Status = Status, CloseBtn = CloseBtn
    }
end

-- ============================================
-- STEP 10: STATE + WIRING
-- ============================================
local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- ⚡ Speed Hack
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
        ui.Status.Text = "Status: ⚡ Speed ON (" .. getgenv().config.speedValue .. ")"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        if utility.speedConn then
            utility.speedConn:Disconnect()
            utility.speedConn = nil
        end
        local char = utility.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        ui.Status.Text = "Status: ⚡ Speed OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- ⚡ Instant Pickup
utility.pickupEnabled = false

ui.pickupToggle.btn.MouseButton1Click:Connect(function()
    utility.pickupE
