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
    autoPickupRadius = 30,   -- 🎯 Radius para sa auto pickup (taasan kung kulang)
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
    return warn('failed to bind connection error: '..tostring(r))
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
-- STEP 5: INSTANT PICKUP (HoldDuration = 0)
-- ============================================
function utility:startInstantPickup()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then
        return warn('failed to get localplayer')
    end

    self.instantConn = self:bind(self.ProximityPromptService.PromptButtonHoldBegan, function(ProximityPrompt, Player)
        if Player == self.LocalPlayer and tostring(ProximityPrompt) == "CarryAreaEgg" then
            ProximityPrompt.HoldDuration = 0
        end
    end)

    if not self.instantConn then
        return warn("some how failed to create conn")
    end
    return true
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

    -- 🚫 Disconnect ragdoll triggers
    local conns = getconnections(self.RigSync.OnClientEvent)
    if conns then
        for _, conn in next, conns do
            pcall(function()
                conn:Disconnect()
                table.insert(utility.ragdollConns, conn)
            end)
        end
    end

    -- 🔧 Recovery loop
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
-- STEP 7: AUTO PICKUP DROPPED EGG
-- ============================================
utility.autoPickupEnabled = false
utility.autoPickupConn = nil

function utility:startAutoPickup()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    if not fireproximityprompt then return false, "Missing fireproximityprompt" end

    utility.autoPickupConn = self.RunService.Heartbeat:Connect(function()
        if not utility.autoPickupEnabled then return end

        local char = self.LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end

        -- ❌ Kung may dala ka na → skip
        local hasEgg = false
        for _, obj in next, char:GetChildren() do
            if obj.Name:lower():find("egg") then
                hasEgg = true
                break
            end
        end

        if hasEgg then return end

        -- 🔍 Hanapin pinakamalapit na dropped egg
        local myPos = hrp.Position
        local closestPrompt = nil
        local closestDist = getgenv().config.autoPickupRadius

        for _, obj in next, self.Workspace:GetDescendants() do
            if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
                -- Hanapin yung ProximityPrompt
                local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt")
                if not prompt and obj.Parent then
                    prompt = obj.Parent:FindFirstChildWhichIsA("ProximityPrompt")
                    if not prompt and obj.Parent.Parent then
                        prompt = obj.Parent.Parent:FindFirstChildWhichIsA("ProximityPrompt")
                    end
                end

                if prompt then
                    local dist = (obj.Position - myPos).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPrompt = prompt
                    end
                end
            end
        end

        -- ⚡ Auto grab
        if closestPrompt then
            pcall(function()
                closestPrompt.HoldDuration = 0
                fireproximityprompt(closestPrompt, 0, true)
            end)
        end
    end)

    return true
end

function utility:stopAutoPickup()
    if utility.autoPickupConn then
        utility.autoPickupConn:Disconnect()
        utility.autoPickupConn = nil
    end
end

-- ============================================
-- STEP 8: UI
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
    Main.Size = UDim2.new(0, 260, 0, 260)
    Main.Position = UDim2.new(0.5, -130, 0.5, -130)
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
    local autoPickupToggle = makeToggle(185, "Auto Pickup Egg", "🥚")

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 225)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        speedToggle = speedToggle, pickupToggle = pickupToggle,
        ragdollToggle = ragdollToggle, autoPickupToggle = autoPickupToggle,
        Status = Status, CloseBtn = CloseBtn
    }
end

-- ============================================
-- STEP 9: STATE + WIRING
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
    utility.pickupEnabled = not utility.pickupEnabled
    setToggle(ui.pickupToggle, utility.pickupEnabled)
    
    if utility.pickupEnabled then
        local ok = utility:startInstantPickup()
        if ok then
            ui.Status.Text = "Status: ⚡ Instant Pickup ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "Status: ❌ Instant Pickup failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.pickupEnabled = false
            setToggle(ui.pickupToggle, false)
        end
    else
        utility:stopInstantPickup()
        ui.Status.Text = "Status: ⚡ Instant Pickup OFF"
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
            ui.Status.Text = "Status: 🛡️ Anti-Ragdoll ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "Status: ❌ Anti-Ragdoll failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.antiRagdollEnabled = false
            setToggle(ui.ragdollToggle, false)
            warn("Anti-Ragdoll: " .. tostring(err))
        end
    else
        utility:stopAntiRagdoll()
        ui.Status.Text = "Status: 🛡️ Anti-Ragdoll OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- 🥚 Auto Pickup Egg (Dropped)
utility.autoPickupEnabled = false

ui.autoPickupToggle.btn.MouseButton1Click:Connect(function()
    utility.autoPickupEnabled = not utility.autoPickupEnabled
    setToggle(ui.autoPickupToggle, utility.autoPickupEnabled)
    
    if utility.autoPickupEnabled then
        local ok = utility:startAutoPickup()
        if ok then
            ui.Status.Text = "Status: 🥚 Auto Pickup ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "Status: ❌ Auto Pickup failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.autoPickupEnabled = false
            setToggle(ui.autoPickupToggle, false)
        end
    else
        utility:stopAutoPickup()
        ui.Status.Text = "Status: 🥚 Auto Pickup OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- Close
ui.CloseBtn.MouseButton1Click:Connect(function()
    utility.speedEnabled = false
    utility.pickupEnabled = false
    utility.antiRagdollEnabled = false
    utility.autoPickupEnabled = false
    if utility.speedConn then utility.speedConn:Disconnect() end
    utility:stopInstantPickup()
    utility:stopAntiRagdoll()
    utility:stopAutoPickup()
    ui.ScreenGui:Destroy()
end)

-- ============================================
-- STEP 10: INIT
-- ============================================
ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
