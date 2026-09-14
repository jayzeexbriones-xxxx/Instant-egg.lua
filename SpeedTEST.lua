-- ============================================
-- SERVICES
-- ============================================
local utility = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    Workspace = game:GetService("Workspace"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui"),
    StarterGui = game:GetService("StarterGui")
}

-- ============================================
-- LOAD SPEED BYPASS (open source)
-- ============================================
pcall(function(...)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/stealaeggspeedbypass.lua"))()
end)

-- ============================================
-- AREAS
-- ============================================
utility.areas = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

getgenv().config = {
    minarea = 9
}

-- ============================================
-- UTILITY FUNCTIONS (original)
-- ============================================
utility.collectgarbage = function()
    local s, r = pcall(function(...) return getgc() end)
    if s and r then return r end
    return warn("failed to get garbage: "..tostring(r))
end

utility.safehook = function(f, c)
    local s, r = pcall(function(...) return hookfunction(f, newlclosure(c)) end)
    if s and r then return r end
    return warn("failed to hook function: "..tostring(r))
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
-- EGG FARMING LOGIC
-- ============================================
function utility:getBestEgg()
    local s, r = pcall(function(...)
        local egg = nil
        local biggestegg = 0
        for key, data in next, self.EggState.ReadFieldEggs().Records do
            local idx = table.find(self.areas, data.AreaId)
            if idx > getgenv().config.minarea then
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
        repeat
            local dt = task.wait(0.01)
            local start = self.LocalPlayer.Character.HumanoidRootPart.Position
            dist = (pos.BoundsCFrame.Position - start).Magnitude
            local half = start + (pos.BoundsCFrame.Position - start).Unit * dt * 350
            self.LocalPlayer.Character:MoveTo(half)
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

-- ============================================
-- UI CREATION
-- ============================================
local COLORS = {
    BG          = Color3.fromRGB(25, 25, 30),
    TITLE_BG    = Color3.fromRGB(35, 35, 42),
    STROKE      = Color3.fromRGB(60, 60, 70),
    TEXT        = Color3.fromRGB(255, 255, 255),
    SUBTEXT     = Color3.fromRGB(180, 180, 190),
    GREEN       = Color3.fromRGB(0, 180, 90),
    RED         = Color3.fromRGB(200, 50, 50),
    KNOB        = Color3.fromRGB(255, 255, 255),
    TRACK_OFF   = Color3.fromRGB(70, 70, 80)
}

local function createUI()
    if utility.CoreGui:FindFirstChild("StealEggUI") then
        utility.CoreGui.StealEggUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = utility.CoreGui

    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 280, 0, 220)
    Main.Position = UDim2.new(0.5, -140, 0.5, -110)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = Main

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = COLORS.STROKE
    MainStroke.Thickness = 1.5
    MainStroke.Parent = Main

    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = Main

    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar

    local TitleCover = Instance.new("Frame")
    TitleCover.Size = UDim2.new(1, 0, 0, 10)
    TitleCover.Position = UDim2.new(0, 0, 1, -10)
    TitleCover.BackgroundColor3 = COLORS.TITLE_BG
    TitleCover.BorderSizePixel = 0
    TitleCover.Parent = TitleBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -50, 1, 0)
    Title.Position = UDim2.new(0, 12, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🥚 Steal An Egg"
    Title.TextColor3 = COLORS.TEXT
    Title.TextSize = 14
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar

    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 25, 0, 25)
    CloseBtn.Position = UDim2.new(1, -32, 0, 5)
    CloseBtn.BackgroundColor3 = COLORS.RED
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = COLORS.TEXT
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.AutoButtonColor = false
    CloseBtn.Parent = TitleBar

    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 6)
    CloseCorner.Parent = CloseBtn

    -- ============ TOGGLE 1: SPEED ============
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, -120, 0, 25)
    SpeedLabel.Position = UDim2.new(0, 15, 0, 50)
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.Text = "⚡ Speed Bypass"
    SpeedLabel.TextColor3 = COLORS.TEXT
    SpeedLabel.TextSize = 14
    SpeedLabel.Font = Enum.Font.GothamBold
    SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
    SpeedLabel.Parent = Main

    local SpeedState = Instance.new("TextLabel")
    SpeedState.Size = UDim2.new(0, 45, 0, 25)
    SpeedState.Position = UDim2.new(1, -120, 0, 50)
    SpeedState.BackgroundTransparency = 1
    SpeedState.Text = "OFF"
    SpeedState.TextColor3 = COLORS.RED
    SpeedState.TextSize = 13
    SpeedState.Font = Enum.Font.GothamBold
    SpeedState.TextXAlignment = Enum.TextXAlignment.Right
    SpeedState.Parent = Main

    local SpeedTrack = Instance.new("Frame")
    SpeedTrack.Size = UDim2.new(0, 50, 0, 26)
    SpeedTrack.Position = UDim2.new(1, -65, 0, 50)
    SpeedTrack.BackgroundColor3 = COLORS.TRACK_OFF
    SpeedTrack.BorderSizePixel = 0
    SpeedTrack.Parent = Main

    local SpeedTrackCorner = Instance.new("UICorner")
    SpeedTrackCorner.CornerRadius = UDim.new(1, 0)
    SpeedTrackCorner.Parent = SpeedTrack

    local SpeedKnob = Instance.new("Frame")
    SpeedKnob.Size = UDim2.new(0, 20, 0, 20)
    SpeedKnob.Position = UDim2.new(0, 3, 0.5, -10)
    SpeedKnob.BackgroundColor3 = COLORS.KNOB
    SpeedKnob.BorderSizePixel = 0
    SpeedKnob.Parent = SpeedTrack

    local SpeedKnobCorner = Instance.new("UICorner")
    SpeedKnobCorner.CornerRadius = UDim.new(1, 0)
    SpeedKnobCorner.Parent = SpeedKnob

    local SpeedBtn = Instance.new("TextButton")
    SpeedBtn.Size = UDim2.new(0, 110, 0, 36)
    SpeedBtn.Position = UDim2.new(1, -120, 0, 45)
    SpeedBtn.BackgroundTransparency = 1
    SpeedBtn.Text = ""
    SpeedBtn.Parent = Main

    -- ============ TOGGLE 2: AUTO EGG ============
    local EggLabel = Instance.new("TextLabel")
    EggLabel.Size = UDim2.new(1, -120, 0, 25)
    EggLabel.Position = UDim2.new(0, 15, 0, 95)
    EggLabel.BackgroundTransparency = 1
    EggLabel.Text = "🥚 Auto Egg Farm"
    EggLabel.TextColor3 = COLORS.TEXT
    EggLabel.TextSize = 14
    EggLabel.Font = Enum.Font.GothamBold
    EggLabel.TextXAlignment = Enum.TextXAlignment.Left
    EggLabel.Parent = Main

    local EggState = Instance.new("TextLabel")
    EggState.Size = UDim2.new(0, 45, 0, 25)
    EggState.Position = UDim2.new(1, -120, 0, 95)
    EggState.BackgroundTransparency = 1
    EggState.Text = "OFF"
    EggState.TextColor3 = COLORS.RED
    EggState.TextSize = 13
    EggState.Font = Enum.Font.GothamBold
    EggState.TextXAlignment = Enum.TextXAlignment.Right
    EggState.Parent = Main

    local EggTrack = Instance.new("Frame")
    EggTrack.Size = UDim2.new(0, 50, 0, 26)
    EggTrack.Position = UDim2.new(1, -65, 0, 95)
    EggTrack.BackgroundColor3 = COLORS.TRACK_OFF
    EggTrack.BorderSizePixel = 0
    EggTrack.Parent = Main

    local EggTrackCorner = Instance.new("UICorner")
    EggTrackCorner.CornerRadius = UDim.new(1, 0)
    EggTrackCorner.Parent = EggTrack

    local EggKnob = Instance.new("Frame")
    EggKnob.Size = UDim2.new(0, 20, 0, 20)
    EggKnob.Position = UDim2.new(0, 3, 0.5, -10)
    EggKnob.BackgroundColor3 = COLORS.KNOB
    EggKnob.BorderSizePixel = 0
    EggKnob.Parent = EggTrack

    local EggKnobCorner = Instance.new("UICorner")
    EggKnobCorner.CornerRadius = UDim.new(1, 0)
    EggKnobCorner.Parent = EggKnob

    local EggBtn = Instance.new("TextButton")
    EggBtn.Size = UDim2.new(0, 110, 0, 36)
    EggBtn.Position = UDim2.new(1, -120, 0, 90)
    EggBtn.BackgroundTransparency = 1
    EggBtn.Text = ""
    EggBtn.Parent = Main

    -- Min Area Input
    local MinAreaLabel = Instance.new("TextLabel")
    MinAreaLabel.Size = UDim2.new(0, 100, 0, 25)
    MinAreaLabel.Position = UDim2.new(0, 15, 0, 140)
    MinAreaLabel.BackgroundTransparency = 1
    MinAreaLabel.Text = "Min Area (1-11):"
    MinAreaLabel.TextColor3 = COLORS.SUBTEXT
    MinAreaLabel.TextSize = 12
    MinAreaLabel.Font = Enum.Font.Gotham
    MinAreaLabel.TextXAlignment = Enum.TextXAlignment.Left
    MinAreaLabel.Parent = Main

    local MinAreaBox = Instance.new("TextBox")
    MinAreaBox.Size = UDim2.new(0, 50, 0, 26)
    MinAreaBox.Position = UDim2.new(0, 120, 0, 140)
    MinAreaBox.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    MinAreaBox.Text = "9"
    MinAreaBox.TextColor3 = COLORS.TEXT
    MinAreaBox.TextSize = 13
    MinAreaBox.Font = Enum.Font.GothamBold
    MinAreaBox.Parent = Main

    local MinAreaCorner = Instance.new("UICorner")
    MinAreaCorner.CornerRadius = UDim.new(0, 6)
    MinAreaCorner.Parent = MinAreaBox

    -- Status
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 180)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main

    return {
        ScreenGui = ScreenGui, Main = Main,
        SpeedTrack = SpeedTrack, SpeedKnob = SpeedKnob, SpeedState = SpeedState, SpeedBtn = SpeedBtn,
        EggTrack = EggTrack, EggKnob = EggKnob, EggState = EggState, EggBtn = EggBtn,
        MinAreaBox = MinAreaBox,
        Status = Status, CloseBtn = CloseBtn
    }
end

-- ============================================
-- STATE
-- ============================================
utility.speedEnabled = false
utility.eggEnabled = false
utility.speedConn = nil
utility.eggConn = nil

local GREEN = COLORS.GREEN
local RED = COLORS.RED
local TRACK_OFF = COLORS.TRACK_OFF
local KNOB = COLORS.KNOB

local function setToggle(track, knob, stateLabel, on)
    track.BackgroundColor3 = on and GREEN or TRACK_OFF
    knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    stateLabel.Text = on and "ON" or "OFF"
    stateLabel.TextColor3 = on and GREEN or RED
end

-- ============================================
-- SPEED BYPASS INIT
-- ============================================
function utility:initBypass()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    if not getgc then self.LocalPlayer:Kick("Missing getgc") return false end
    if not hookfunction then self.LocalPlayer:Kick("Missing hookfunction") return false end
    if not islclosure then self.LocalPlayer:Kick("Missing islclosure") return false end

    local func3 = self:findfunction(19, 605)
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
-- AUTO EGG INIT
-- ============================================
function utility:initEgg()
    self.LocalPlayer = self.Players.LocalPlayer
    if not fireproximityprompt then
        return false, "Missing fireproximityprompt"
    end

    self.Client = self.ReplicatedStorage:FindFirstChild("Client")
    if not self.Client then return false, "No Client" end

    self.EggState = require(self.Client:FindFirstChild("EggState"))
    if not self.EggState then return false, "No EggState" end

    return true
end

function utility:startEgg()
    if self.eggConn then task.cancel(self.eggConn) end
    self.eggConn = task.spawn(function()
        while self.eggEnabled do
            pcall(function(...)
                local egg = self:getBestEgg()
                if egg then
                    self:GoTo(egg)
                    task.wait(0.5)
                    local p = self:getproximitypromptforegg(egg)
                    if p then
                        fireproximityprompt(self:getproximitypromptforegg(egg))
                    end
                    task.wait(0.1)
                    self:GoTo({["BoundsCFrame"] = CFrame.new(514, 71, -368)})
                else
                    self:GoTo({["BoundsCFrame"] = CFrame.new(514, 71, -368)})
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
-- BUILD UI + WIRE
-- ============================================
local ui = createUI()

-- Speed toggle
ui.SpeedBtn.MouseButton1Click:Connect(function()
    if not utility.speedReady then
        ui.Status.Text = "Status: ❌ Speed not ready"
        ui.Status.TextColor3 = RED
        return
    end
    utility.speedEnabled = not utility.speedEnabled
    setToggle(ui.SpeedTrack, ui.SpeedKnob, ui.SpeedState, utility.speedEnabled)

    if utility.speedEnabled then
        utility:startSpeed()
        ui.Status.Text = "Status: ⚡ Speed ON"
        ui.Status.TextColor3 = GREEN
    else
        utility:stopSpeed()
        ui.Status.Text = "Status: ⚡ Speed OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- Egg toggle
ui.EggBtn.MouseButton1Click:Connect(function()
    if not utility.eggReady then
        ui.Status.Text = "Status: ❌ Auto Egg not ready"
        ui.Status.TextColor3 = RED
        return
    end
    utility.eggEnabled = not utility.eggEnabled
    setToggle(ui.EggTrack, ui.EggKnob, ui.EggState, utility.eggEnabled)

    if utility.eggEnabled then
        utility:startEgg()
        ui.Status.Text = "Status: 🥚 Auto Egg ON"
        ui.Status.TextColor3 = GREEN
    else
        utility:stopEgg()
        ui.Status.Text = "Status: 🥚 Auto Egg OFF"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- Min area input
ui.MinAreaBox.FocusLost:Connect(function()
    local num = tonumber(ui.MinAreaBox.Text)
    if num and num >= 1 and num <= 11 then
        getgenv().config.minarea = num
        ui.Status.Text = "Status: Min Area = " .. num
        ui.Status.TextColor3 = GREEN
    else
        ui.MinAreaBox.Text = tostring(getgenv().config.minarea)
    end
end)

-- Close
ui.CloseBtn.MouseButton1Click:Connect(function()
    utility.speedEnabled = false
    utility.eggEnabled = false
    utility:stopSpeed()
    utility:stopEgg()
    ui.ScreenGui:Destroy()
end)

-- ============================================
-- INIT BOTH
-- ============================================
task.spawn(function()
    -- Init speed
    local speedOK, speedErr = utility:initBypass()
    utility.speedReady = speedOK

    -- Init egg
    local eggOK, eggErr = utility:initEgg()
    utility.eggReady = eggOK

    if speedOK and eggOK then
        ui.Status.Text = "Status: ✅ Both ready"
        ui.Status.TextColor3 = GREEN
    elseif speedOK then
        ui.Status.Text = "Status: ⚡ Speed ready, 🥚 Egg failed"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    elseif eggOK then
        ui.Status.Text = "Status: 🥚 Egg ready, ⚡ Speed failed"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    else
        ui.Status.Text = "Status: ❌ Init failed"
        ui.Status.TextColor3 = RED
        warn("Speed err: " .. tostring(speedErr))
        warn("Egg err: " .. tostring(eggErr))
    end
end)
