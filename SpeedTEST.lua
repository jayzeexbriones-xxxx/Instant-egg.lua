-- ============================================
-- SERVICES
-- ============================================
local utility = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players"),
    UserInputService = game:GetService("UserInputService"),
    CoreGui = game:GetService("CoreGui")
}

-- ============================================
-- UTILITY FUNCTIONS (original, untouched)
-- ============================================
utility.collectgarbage = function()
    local s, r = pcall(function(...)
        return getgc()
    end)
    if s and r then
        return r
    end
    return warn("failed to get garbage: "..tostring(r))
end

utility.safehook = function(f, c)
    local s, r = pcall(function(...)
        return hookfunction(f, newlclosure(c))
    end)
    if s and r then
        return r
    end
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

    if s and r then
        return r
    end
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
    -- Cleanup old
    if utility.CoreGui:FindFirstChild("UtilityUI") then
        utility.CoreGui.UtilityUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UtilityUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = utility.CoreGui

    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 260, 0, 120)
    Main.Position = UDim2.new(0.5, -130, 0.5, -60)
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
    Title.Text = "⚡ Utility Bypass"
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

    -- Bypass Label
    local BypassLabel = Instance.new("TextLabel")
    BypassLabel.Size = UDim2.new(1, -100, 0, 30)
    BypassLabel.Position = UDim2.new(0, 15, 0, 50)
    BypassLabel.BackgroundTransparency = 1
    BypassLabel.Text = "Bypass"
    BypassLabel.TextColor3 = COLORS.TEXT
    BypassLabel.TextSize = 15
    BypassLabel.Font = Enum.Font.GothamBold
    BypassLabel.TextXAlignment = Enum.TextXAlignment.Left
    BypassLabel.Parent = Main

    -- State Text (ON/OFF)
    local StateText = Instance.new("TextLabel")
    StateText.Size = UDim2.new(0, 50, 0, 30)
    StateText.Position = UDim2.new(1, -110, 0, 50)
    StateText.BackgroundTransparency = 1
    StateText.Text = "OFF"
    StateText.TextColor3 = COLORS.RED
    StateText.TextSize = 14
    StateText.Font = Enum.Font.GothamBold
    StateText.TextXAlignment = Enum.TextXAlignment.Right
    StateText.Parent = Main

    -- Toggle Track
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0, 50, 0, 26)
    Track.Position = UDim2.new(1, -55, 0, 52)
    Track.BackgroundColor3 = COLORS.TRACK_OFF
    Track.BorderSizePixel = 0
    Track.Parent = Main

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    -- Toggle Knob
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 20, 0, 20)
    Knob.Position = UDim2.new(0, 3, 0.5, -10)
    Knob.BackgroundColor3 = COLORS.KNOB
    Knob.BorderSizePixel = 0
    Knob.Parent = Track

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    -- Click area (invisible button covering the toggle)
    local ToggleBtn = Instance.new("TextButton")
    ToggleBtn.Size = UDim2.new(0, 100, 0, 40)
    ToggleBtn.Position = UDim2.new(1, -105, 0, 45)
    ToggleBtn.BackgroundTransparency = 1
    ToggleBtn.Text = ""
    ToggleBtn.Parent = Main

    -- Status Label
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 90)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Loading..."
    Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    Status.TextSize = 12
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Main

    return {
        ScreenGui = ScreenGui,
        Main = Main,
        Track = Track,
        Knob = Knob,
        StateText = StateText,
        ToggleBtn = ToggleBtn,
        Status = Status,
        CloseBtn = CloseBtn
    }
end

-- ============================================
-- MAIN LOGIC
-- ============================================
utility.enabled = false
utility.walkspeed = 500
utility.heartbeatConn = nil
utility.bypassReady = false

function utility:startSpeedLoop()
    if self.heartbeatConn then
        self.heartbeatConn:Disconnect()
        self.heartbeatConn = nil
    end

    self.heartbeatConn = self.RunService.Heartbeat:Connect(function()
        if not self.enabled then return end

        local char = self.LocalPlayer.Character
        if not char then return end

        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end

        hum.WalkSpeed = self.walkspeed
    end)
end

function utility:stopSpeedLoop()
    if self.heartbeatConn then
        self.heartbeatConn:Disconnect()
        self.heartbeatConn = nil
    end
end

function utility:initbypass()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then
        return false, "No LocalPlayer"
    end

    if not getgc then
        self.LocalPlayer:Kick("UNSUPPORT EXECUTOR MISSING getgc")
        return false, "Missing getgc"
    end

    if not hookfunction then
        self.LocalPlayer:Kick("UNSUPPORT EXECUTOR MISSING hookfunction")
        return false, "Missing hookfunction"
    end

    if not islclosure then
        self.LocalPlayer:Kick("UNSUPPORT EXECUTOR MISSING islclosure")
        return false, "Missing islclosure"
    end

    local func3 = self:findfunction(19, 3)
    if not func3 then
        return false, "Failed to get func3"
    end

    local v7 = debug.getupvalue(func3, 2)
    if not v7 then
        return false, "Failed to get v7"
    end

    local hookedfunc3; hookedfunc3 = self.safehook(v7, function(p1, p2)
        if p2 and typeof(p2) == "table" then
            setmetatable(p2, {})
        end
        return hookedfunc3(p1, p2)
    end)

    self.bypassReady = true
    return true
end

-- ============================================
-- BUILD UI + WIRE EVENTS
-- ============================================
local ui = createUI()
local toggleTween = nil

local function setToggleVisual(on)
    local targetColor = on and COLORS.GREEN or COLORS.TRACK_OFF
    local targetPos = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)

    ui.Track.BackgroundColor3 = targetColor
    ui.Knob.Position = targetPos
    ui.StateText.Text = on and "ON" or "OFF"
    ui.StateText.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- Toggle click
ui.ToggleBtn.MouseButton1Click:Connect(function()
    if not utility.bypassReady then
        ui.Status.Text = "Status: ❌ Bypass not ready"
        ui.Status.TextColor3 = Color3.fromRGB(255, 60, 60)
        return
    end

    utility.enabled = not utility.enabled
    setToggleVisual(utility.enabled)

    if utility.enabled then
        utility:startSpeedLoop()
        ui.Status.Text = "Status: ✅ Bypass Active"
        ui.Status.TextColor3 = Color3.fromRGB(0, 220, 100)
    else
        utility:stopSpeedLoop()
        ui.Status.Text = "Status: ⏸ Bypass Disabled"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    end
end)

-- Close
ui.CloseBtn.MouseButton1Click:Connect(function()
    utility.enabled = false
    utility:stopSpeedLoop()
    ui.ScreenGui:Destroy()
end)

-- Init bypass (hindi pa naka-on ang speed loop)
local ok, err = utility:initbypass()
if ok then
    setToggleVisual(false)
    ui.Status.Text = "Status: Ready — Toggle to enable"
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
else
    ui.Status.Text = "Status: ❌ " .. tostring(err)
    ui.Status.TextColor3 = Color3.fromRGB(255, 60, 60)
end
