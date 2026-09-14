-- ============================================
-- SERVICES
-- ============================================
local utility = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    CoreGui = game:GetService("CoreGui")
}

-- ============================================
-- AREAS
-- ============================================
utility.areas = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

getgenv().config = { minarea = 9 }

-- ============================================
-- UTILITY (bypass functions)
-- ============================================
utility.collectgarbage = function()
    local s, r = pcall(function(...) return getgc() end)
    if s and r then return r end
    return nil
end

utility.safehook = function(f, c)
    local s, r = pcall(function(...) return hookfunction(f, newlclosure(c)) end)
    if s and r then return r end
    return nil
end

function utility:findfunction(nups, linedefined)
    local s, r = pcall(function(...)
        for _, f in next, self.collectgarbage() do
            if typeof(f) == 'function' and islclosure(f) then
                local upvs = debug.getupvalues(f)
                local line = debug.info(f, "l")
                if upvs and #upvs == nups and line == linedefined then
                    if nups == 10 then
                        local t = debug.getupvalue(f, 3)
                        if typeof(t) == "table" and rawget(t, "Humanoid") then
                            return f
                        end
                    else
                        return f
                    end
                end
            end
        end
        return nil
    end)
    if s and r then return r end
    return nil
end

-- ============================================
-- EGG LOGIC (FIXED)
-- ============================================
function utility:getBestEgg()
    local s, r = pcall(function(...)
        local egg = nil
        local biggestegg = 0
        for key, data in next, self.EggState.ReadFieldEggs().Records do
            local idx = table.find(self.areas, data.AreaId)
            if idx and idx > getgenv().config.minarea then
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

-- FIXED: Direct teleport using CFrame
function utility:TeleportTo(pos)
    local char = self.LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    pcall(function()
        hrp.CFrame = CFrame.new(pos)
    end)
end

-- FIXED: Find prompt directly on egg or nearby
function utility:getproximitypromptforegg(egg)
    local s, r = pcall(function(...)
        local eggPos = egg.BoundsCFrame.Position
        local closestPrompt = nil
        local closestDist = math.huge
        
        -- Search all ProximityPrompts in workspace
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
        
        -- Fallback: original method
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

-- ============================================
-- INIT BYPASS (SPEED)
-- ============================================
function utility:initBypass()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    if not getgc then return false, "Missing getgc" end
    if not hookfunction then return false, "Missing hookfunction" end
    if not islclosure then return false, "Missing islclosure" end

    -- Try multiple line numbers
    local attempts = {605, 3, 604, 606, 600}
    local func3 = nil
    for _, line in ipairs(attempts) do
        func3 = self:findfunction(19, line)
        if func3 then break end
    end
    
    if not func3 then return false, "Failed to get func3" end

    local v7 = debug.getupvalue(func3, 2)
    if not v7 then return false, "Failed to get v7" end

    local hookedfunc3
    hookedfunc3 = self.safehook(v7, function(p1, p2)
        if p2 and typeof(p2) == "table" then
            setmetatable(p2, {})
        end
        return hookedfunc3(p1, p2)
    end)

    return true
end

function utility:startSpeed()
    if self.speedConn then self.speedConn:Disconnect() end
    self.speedConn = self.RunService.Heartbeat:Connect(function()
        if not self.speedEnabled then return end
        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        hum.WalkSpeed = 500
    end)
end

function utility:stopSpeed()
    if self.speedConn then
        self.speedConn:Disconnect()
        self.speedConn = nil
    end
    local char = self.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.WalkSpeed = 16 end
    end
end

-- ============================================
-- INIT EGG
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

function utility:startEgg()
    if self.eggConn then pcall(function() task.cancel(self.eggConn) end) end
    self.eggConn = task.spawn(function()
        while self.eggEnabled do
            pcall(function()
                local egg = self:getBestEgg()
                if egg then
                    -- Teleport directly to egg
                    self:TeleportTo(egg.BoundsCFrame.Position)
                    task.wait(0.3)
                    
                    -- Find and fire prompt
                    local p = self:getproximitypromptforegg(egg)
                    if p then
                        pcall(function()
                            fireproximityprompt(p, 0, true)
                        end)
                    end
                    
                    task.wait(0.3)
                    -- Return to base
                    self:TeleportTo(Vector3.new(514, 71, -368))
                else
                    self:TeleportTo(Vector3.new(514, 71, -368))
                end
            end)
            task.wait(1)
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
-- UI
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
    Main.Size = UDim2.new(0, 280, 0, 220)
    Main.Position = UDim2.new(0.5, -140, 0.5, -110)
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

    -- Helper
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
    local eggToggle = makeToggle(95, "Auto Egg Farm", "🥚")

    local MinAreaLabel = Instance.new("TextLabel", Main)
    MinAreaLabel.Size = UDim2.new(0, 120, 0, 25)
    MinAreaLabel.Position = UDim2.new(0, 15, 0, 140)
    MinAreaLabel.BackgroundTransparency = 1
    MinAreaLabel.Text = "Min Area (1-11):"
    MinAreaLabel.TextColor3 = COLORS.SUBTEXT
    MinAreaLabel.TextSize = 12
    MinAreaLabel.Font = Enum.Font.Gotham
    MinAreaLabel.TextXAlignment = Enum.TextXAlignment.Left

    local MinAreaBox = Instance.new("TextBox", Main)
    MinAreaBox.Size = UDim2.new(0, 50, 0, 26)
    MinAreaBox.Position = UDim2.new(0, 140, 0, 140)
    MinAreaBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    MinAreaBox.Text = "9"
    MinAreaBox.TextColor3 = COLORS.TEXT
    MinAreaBox.TextSize = 13
    MinAreaBox.Font = Enum.Font.GothamBold
    local mac = Instance.new("UICorner", MinAreaBox)
    mac.CornerRadius = UDim.new(0, 6)

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 180)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        speedToggle = speedToggle, eggToggle = eggToggle,
        MinAreaBox = MinAreaBox, Status = Status, CloseBtn = CloseBtn
    }
end

-- ============================================
-- STATE + WIRING
-- ============================================
utility.speedEnabled = false
utility.eggEnabled = false

local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.speedToggle.btn.MouseButton1Click:Connect(function()
    if not utility.speedReady then
        ui.Status.Text = "Status: ❌ Speed not ready"
        ui.Status.TextColor3 = COLORS.RED
        return
    end
    utility.speedEnabled = not utility.speedEnabled
    setToggle(ui.speedToggle, utility.speedEnabled)
    if utility.speedEnabled then
        utility:startSpeed()
        ui.Status.Text = "Status: ⚡ Speed ON"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        utility:stopSpeed()
        ui.Status.Text = "Status: ⚡ Speed OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

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
        ui.Status.Text = "Status: 🥚 Auto Egg ON"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        utility:stopEgg()
        ui.Status.Text = "Status: 🥚 Auto Egg OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

ui.MinAreaBox.FocusLost:Connect(function()
    local num = tonumber(ui.MinAreaBox.Text)
    if num and num >= 1 and num <= 11 then
        getgenv().config.minarea = num
        ui.Status.Text = "Status: Min Area = " .. num
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.MinAreaBox.Text = tostring(getgenv().config.minarea)
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    utility.speedEnabled = false
    utility.eggEnabled = false
    utility:stopSpeed()
    utility:stopEgg()
    ui.ScreenGui:Destroy()
end)

-- ============================================
-- INIT
-- ============================================
task.spawn(function()
    local speedOK, speedErr = utility:initBypass()
    utility.speedReady = speedOK

    local eggOK, eggErr = utility:initEgg()
    utility.eggReady = eggOK

    if speedOK and eggOK then
        ui.Status.Text = "Status: ✅ Both ready"
        ui.Status.TextColor3 = COLORS.GREEN
    elseif speedOK then
        ui.Status.Text = "Status: ⚡ Speed ready | 🥚 Egg failed"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    elseif eggOK then
        ui.Status.Text = "Status: 🥚 Egg ready | ⚡ Speed failed"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    else
        ui.Status.Text = "Status: ❌ Init failed"
        ui.Status.TextColor3 = COLORS.RED
        warn("Speed: " .. tostring(speedErr))
        warn("Egg: " .. tostring(eggErr))
    end
end)
