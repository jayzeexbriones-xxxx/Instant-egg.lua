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
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CoreGui = game:GetService("CoreGui")
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
    speedValue = 250,           -- ⚡ 250 para mabilis ma-tuka
    basePos = Vector3.new(514, 71, -368),
    chickenAreas = 3,           -- Areas 1-3 = chicken
    minArea = 9,                -- Best egg = area 9+
    knockbackThreshold = 25,    -- Sensitivity ng tuka detection
}

-- ============================================
-- STEP 4: EGG LOGIC
-- ============================================
function utility:getChickenEgg()
    local s, r = pcall(function(...)
        local egg = nil
        local closestDist = math.huge
        local myPos = self.LocalPlayer.Character and self.LocalPlayer.Character.HumanoidRootPart.Position
        if not myPos then return nil end
        
        for key, data in next, self.EggState.ReadFieldEggs().Records do
            local idx = table.find(self.areas, data.AreaId)
            if idx and idx <= getgenv().config.chickenAreas then
                local dist = (data.BoundsCFrame.Position - myPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    egg = data
                end
            end
        end
        return egg
    end)
    if s and r then return r end
    return nil
end

function utility:getBestEgg()
    local s, r = pcall(function(...)
        local egg = nil
        local biggestegg = 0
        for key, data in next, self.EggState.ReadFieldEggs().Records do
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

function utility:TeleportTo(pos)
    local char = self.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        hrp.CFrame = CFrame.new(pos)
    end)
end

function utility:getproximitypromptforegg(egg)
    local s, r = pcall(function(...)
        local eggPos = egg.BoundsCFrame.Position
        local closestPrompt = nil
        local closestDist = math.huge

        for _, prompt in next, self.Workspace:GetDescendants() do
            if prompt:IsA("ProximityPrompt") and prompt.Enabled then
                local parent = prompt.Parent
                if parent then
                    local pPos = parent:IsA("BasePart") and parent.Position or (parent:FindFirstChildWhichIsA("BasePart") and parent:FindFirstChildWhichIsA("BasePart").Position)
                    if pPos then
                        local dist = (eggPos - pPos).Magnitude
                        if dist < closestDist and dist < 15 then
                            closestDist = dist
                            closestPrompt = prompt
                        end
                    end
                end
            end
        end

        if not closestPrompt then
            local CarryAreaEggs = self.Workspace:QueryDescendants("#CarryAreaEgg")
            for _, prompt in next, CarryAreaEggs do
                if prompt:IsA("ProximityPrompt") then
                    local p = prompt.Parent
                    if p and p:IsA("BasePart") then
                        local dist = (eggPos - p.Position).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            closestPrompt = prompt
                        end
                    end
                end
            end
        end

        return closestPrompt
    end)
    if s and r then return r end
    return nil
end

function utility:hasEgg()
    local s, r = pcall(function(...)
        local char = self.LocalPlayer.Character
        if not char then return false end
        for _, obj in next, char:GetChildren() do
            if obj.Name:lower():find("egg") then
                return true
            end
        end
        return false
    end)
    if s and r then return r end
    return false
end

-- ⚡ VELOCITY-BASED PECK DETECTION
function utility:startVelocityWatcher(callback)
    local char = self.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local connection
    connection = utility.RunService.Heartbeat:Connect(function()
        if not utility.eggEnabled then
            connection:Disconnect()
            return
        end
        
        local currentChar = utility.LocalPlayer.Character
        if not currentChar then
            connection:Disconnect()
            return
        end
        
        local currentHRP = currentChar:FindFirstChild("HumanoidRootPart")
        if not currentHRP then return end
        
        local velocity = currentHRP.AssemblyLinearVelocity
        local speed = velocity.Magnitude
        
        if speed > getgenv().config.knockbackThreshold then
            connection:Disconnect()
            callback()
        end
    end)
    
    return connection
end

-- ============================================
-- STEP 5: INIT EGG
-- ============================================
function utility:initEgg()
    self.LocalPlayer = self.Players.LocalPlayer
    if not fireproximityprompt then
        return false, "Missing fireproximityprompt"
    end

    self.Client = self.ReplicatedStorage:FindFirstChild("Client")
    if not self.Client then return false, "No Client" end

    local eggStateModule = self.Client:FindFirstChild("EggState")
    if not eggStateModule then return false, "No EggState" end

    self.EggState = require(eggStateModule)
    if not self.EggState then return false, "EggState require failed" end

    return true
end

-- ============================================
-- STEP 6: LENNON STYLE AUTO EGG
-- ============================================
function utility:startEgg()
    if self.eggConn then pcall(function() task.cancel(self.eggConn) end) end
    self.eggConn = task.spawn(function()
        while self.eggEnabled do
            pcall(function()
                local myChar = self.LocalPlayer.Character
                local myPos = myChar and myChar.HumanoidRootPart.Position
                if not myPos then task.wait(0.3) return end
                
                local hasEgg = self:hasEgg()
                
                -- STEP 1: May dala? → base
                if hasEgg then
                    self:TeleportTo(getgenv().config.basePos)
                    task.wait(0.5)
                else
                    -- STEP 2: Wala pa → chicken egg muna
                    local chickenEgg = self:getChickenEgg()
                    if chickenEgg then
                        self:TeleportTo(chickenEgg.BoundsCFrame.Position)
                        task.wait(0.3)
                        
                        local p = self:getproximitypromptforegg(chickenEgg)
                        if p then
                            pcall(function() fireproximityprompt(p, 0, true) end)
                        end
                        
                        -- STEP 3: Hintayin TUKA (velocity trigger)
                        local pecked = false
                        local conn = self:startVelocityWatcher(function()
                            pecked = true
                        end)
                        
                        local waitTime = 0
                        while waitTime < 5 and not pecked do
                            task.wait(0.1)
                            waitTime = waitTime + 0.1
                        end
                        
                        if conn then conn:Disconnect() end
                        
                        -- STEP 4: Pag na-tuka → best egg → kunin → base
                        if pecked then
                            local bestEgg = self:getBestEgg()
                            if bestEgg then
                                self:TeleportTo(bestEgg.BoundsCFrame.Position)
                                task.wait(0.3)
                                
                                local bp = self:getproximitypromptforegg(bestEgg)
                                if bp then
                                    pcall(function() fireproximityprompt(bp, 0, true) end)
                                end
                                task.wait(0.3)
                                
                                -- Dalhin sa base
                                self:TeleportTo(getgenv().config.basePos)
                                task.wait(0.5)
                            end
                        end
                    end
                end
            end)
            task.wait(0.3)
        end
    end)
end

function utility:stopEgg()
    self.eggEnabled = false
    if self.eggConn then
        pcall(function() task.cancel(self.eggConn) end)
        self.eggConn = nil
    end
end

-- ============================================
-- STEP 7: UI
-- ============================================
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    STROKE = Color3.fromRGB(60, 60, 70),
    TEXT = Color3.fromRGB(255, 255, 255),
    SUBTEXT = Color3.fromRGB(180, 180, 190),
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
    Main.Size = UDim2.new(0, 280, 0, 180)
    Main.Position = UDim2.new(0.5, -140, 0.5, -90)
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

    local speedToggle = makeToggle(50, "Speed Bypass", "⚡")
    local eggToggle = makeToggle(95, "Auto Steal (Lennon)", "🥚")

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 145)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        speedToggle = speedToggle, eggToggle = eggToggle,
        Status = Status, CloseBtn = CloseBtn
    }
end

-- ============================================
-- STEP 8: STATE + WIRING
-- ============================================
local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

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

utility.eggEnabled = false
utility.eggConn = nil

ui.eggToggle.btn.MouseButton1Click:Connect(function()
    if not utility.eggReady then
        ui.Status.Text = "Status: ❌ Auto Egg not ready"
        ui.Status.TextColor3 = COLORS.RED
        return
    end
    utility.eggEnabled = not utility.eggEnabled
    setToggle(ui.eggToggle, utility.eggEnabled)
    if utility.eggEnabled then
        utility:startEgg()
        ui.Status.Text = "Status: 🥚 Auto Steal ON"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        utility:stopEgg()
        ui.Status.Text = "Status: 🥚 Auto Steal OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    utility.speedEnabled = false
    utility.eggEnabled = false
    if utility.speedConn then utility.speedConn:Disconnect() end
    utility:stopEgg()
    ui.ScreenGui:Destroy()
end)

-- ============================================
-- STEP 9: INIT
-- ============================================
task.spawn(function()
    local eggOK, eggErr = utility:initEgg()
    utility.eggReady = eggOK

    if eggOK then
        ui.Status.Text = "Status: ✅ Ready"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.Status.Text = "Status: ❌ Egg init failed"
        ui.Status.TextColor3 = COLORS.RED
        warn("Egg: " .. tostring(eggErr))
    end
end)
