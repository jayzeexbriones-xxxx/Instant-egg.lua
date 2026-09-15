-- ============================================
-- AUTO FARM FOREST → BEST EGG (Working Version)
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- CONFIG
-- ============================================
local Config = {
    baitArea = "Forest",
    minArea = 9,
    knockbackThreshold = 25,
    tpOffset = Vector3.new(0, 3, 0),  -- ✅ 3 studs
    settleWait = 0.5,                -- ✅ 0.5s wait
}

local AREAS = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

-- ============================================
-- LOAD EGG STATE
-- ============================================
local EggState = nil
pcall(function()
    local client = ReplicatedStorage:FindFirstChild("Client")
    if client then
        local es = client:FindFirstChild("EggState")
        if es then EggState = require(es) end
    end
end)

-- ============================================
-- HELPERS
-- ============================================
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function hasEgg()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") and obj:GetAttribute("ItemType") == "AssetEgg" then
            return true
        end
    end
    return false
end

local function tpTo(pos)
    local hrp = getHRP()
    if not hrp then return end
    pcall(function()
        hrp.CFrame = CFrame.new(pos + Config.tpOffset)
    end)
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

-- ============================================
-- FIND EGGS
-- ============================================
local function findBaitEgg()
    if not EggState then return nil end
    local egg = nil
    local closestDist = math.huge
    local hrp = getHRP()
    if not hrp then return nil end
    
    for _, data in next, EggState.ReadFieldEggs().Records do
        if data.State == "Slot" or data.State == "Dropped" then
            if data.AreaId == Config.baitArea then
                local dist = (data.BoundsCFrame.Position - hrp.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    egg = data
                end
            end
        end
    end
    return egg
end

local function findBestEgg()
    if not EggState then return nil end
    local egg = nil
    local biggestegg = 0
    for _, data in next, EggState.ReadFieldEggs().Records do
        local idx = table.find(AREAS, data.AreaId)
        if idx and idx > Config.minArea then
            if data.AssetScale > biggestegg then
                biggestegg = data.AssetScale
                egg = data
            end
        end
    end
    return egg
end

-- ============================================
-- FORCE GRAB (exact same as working)
-- ============================================
local function forceGrab(egg)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- TP to egg (with 3-stud offset)
    hrp.CFrame = CFrame.new(egg.BoundsCFrame.Position + Config.tpOffset)
    task.wait(Config.settleWait)  -- ✅ 0.5s settle

    -- METHOD 1: CarryFieldEgg remote
    pcall(function()
        EggState.CarryFieldEgg(egg.Uid)
    end)
    task.wait(0.3)
    if hasEgg() then return true end

    -- METHOD 2: Direct prompt
    local slots = Workspace:FindFirstChild("AreaEggSlotsClient", true)
    local model = slots and slots:FindFirstChild(egg.Uid) or Workspace:FindFirstChild(egg.Uid, true)

    if model then
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function()
                prompt.Enabled = true
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 9999
            end)
            
            pcall(function()
                fireproximityprompt(prompt, 0)
            end)
            task.wait(0.5)
            
            if hasEgg() then return true end
        end
    end

    -- METHOD 3: TP closer + fire
    local closePos = egg.BoundsCFrame.Position + (hrp.Position - egg.BoundsCFrame.Position).Unit * 2
    hrp.CFrame = CFrame.new(closePos)
    task.wait(0.3)

    if model then
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function()
                prompt.Enabled = true
                prompt.HoldDuration = 0
                prompt.RequiresLineOfSight = false
                prompt.MaxActivationDistance = 9999
                fireproximityprompt(prompt, 0)
            end)
            task.wait(0.5)
            if hasEgg() then return true end
        end
    end

    -- METHOD 4: InputHold
    if model then
        local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then
            pcall(function()
                prompt.Enabled = true
                prompt.HoldDuration = 0
                prompt:InputHoldBegin()
                task.wait(0.1)
                prompt:InputHoldEnd()
            end)
            task.wait(0.5)
            if hasEgg() then return true end
        end
    end

    -- METHOD 5: Retry loop
    for i = 1, 5 do
        if model then
            local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                pcall(function()
                    prompt.HoldDuration = 0
                    fireproximityprompt(prompt, 0)
                end)
            end
        end
        pcall(function()
            EggState.CarryFieldEgg(egg.Uid)
        end)
        task.wait(0.3)
        if hasEgg() then return true end
    end

    return false
end

-- ============================================
-- VELOCITY WATCHER
-- ============================================
local function waitForHit(timeout)
    timeout = timeout or 8
    local hrp = getHRP()
    if not hrp then return false end
    
    local lastPos = hrp.Position
    local t0 = tick()
    local hit = false
    
    local conn = RunService.Heartbeat:Connect(function()
        local h = getHRP()
        if not h then return end
        local vel = h.AssemblyLinearVelocity
        local speed = vel.Magnitude
        local delta = (h.Position - lastPos).Magnitude
        local vVel = math.abs(vel.Y)
        
        if speed > Config.knockbackThreshold or delta > 2 or vVel > 20 then
            hit = true
        end
        lastPos = h.Position
    end)
    
    while tick() - t0 < timeout and not hit do
        if not farmEnabled then break end
        task.wait(0.05)
    end
    
    conn:Disconnect()
    return hit
end

-- ============================================
-- MAIN FARM CYCLE
-- ============================================
farmEnabled = false
local farmThread = nil

local function farmCycle()
    -- Step 1: TP sa Forest
    ui.Status.Text = "Status: 🏞️ TP to Forest..."
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
    
    local baitEgg = findBaitEgg()
    if not baitEgg then
        ui.Status.Text = "Status: ⚠️ No Forest egg"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        task.wait(0.5)
        return
    end
    
    -- Grab Forest egg (with full force grab)
    ui.Status.Text = "Status: 🥚 Grabbing Forest..."
    local grabbed = forceGrab(baitEgg)
    
    if not grabbed then
        ui.Status.Text = "Status: ⚠️ Grab failed"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        task.wait(0.5)
        return
    end
    
    ui.Status.Text = "Status: ✅ Forest grabbed"
    ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
    
    -- Step 3: Wait for hit
    ui.Status.Text = "Status: ⚡ Waiting for hit..."
    ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    local hit = waitForHit(8)
    
    -- Step 4: If hit → TP best egg
    if hit then
        ui.Status.Text = "Status: 🎯 TP to best egg..."
        ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
        
        local bestEgg = findBestEgg()
        if bestEgg then
            forceGrab(bestEgg)
            
            ui.Status.Text = "Status: 🏠 Stay at best egg"
            ui.Status.TextColor3 = Color3.fromRGB(0, 180, 90)
            task.wait(1)
        else
            ui.Status.Text = "Status: ⚠️ No best egg"
            ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
        end
    else
        ui.Status.Text = "Status: ⚠️ No hit — retry"
        ui.Status.TextColor3 = Color3.fromRGB(255, 200, 0)
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
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    YELLOW = Color3.fromRGB(255, 200, 0),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
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
    Main.Size = UDim2.new(0, 260, 0, 135)
    Main.Position = UDim2.new(0.5, -130, 0.5, -68)
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
    Title.Text = "🥚 Auto Farm"
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

    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -120, 0, 25)
    lbl.Position = UDim2.new(0, 15, 0, 55)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🎯 Auto Farm"
    lbl.TextColor3 = COLORS.TEXT
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local state = Instance.new("TextLabel", Main)
    state.Size = UDim2.new(0, 45, 0, 25)
    state.Position = UDim2.new(1, -120, 0, 55)
    state.BackgroundTransparency = 1
    state.Text = "OFF"
    state.TextColor3 = COLORS.RED
    state.TextSize = 13
    state.Font = Enum.Font.GothamBold
    state.TextXAlignment = Enum.TextXAlignment.Right

    local track = Instance.new("Frame", Main)
    track.Size = UDim2.new(0, 50, 0, 26)
    track.Position = UDim2.new(1, -65, 0, 55)
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
    btn.Position = UDim2.new(1, -120, 0, 50)
    btn.BackgroundTransparency = 1
    btn.Text = ""

    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 100)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui,
        track = track, knob = knob, state = state, btn = btn,
        Status = Status, CloseBtn = CloseBtn
    }
end

local ui = createUI()

local function setToggle(on)
    ui.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    ui.knob.Position = on and UDim2.new(0, 27, 0.5, -10) or UDim2.new(0, 3, 0.5, -10)
    ui.state.Text = on and "ON" or "OFF"
    ui.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.btn.MouseButton1Click:Connect(function()
    if not farmEnabled then
        if not EggState then
            ui.Status.Text = "Status: ❌ EggState not found"
            ui.Status.TextColor3 = COLORS.RED
            return
        end
        
        farmEnabled = true
        setToggle(true)
        ui.Status.Text = "Status: 🎯 Starting..."
        ui.Status.TextColor3 = COLORS.GREEN
        
        farmThread = task.spawn(function()
            while farmEnabled do
                pcall(farmCycle)
                task.wait(0.3)
            end
        end)
    else
        farmEnabled = false
        setToggle(false)
        if farmThread then
            pcall(function() task.cancel(farmThread) end)
            farmThread = nil
        end
        ui.Status.Text = "Status: ⏸ Stopped"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    farmEnabled = false
    if farmThread then pcall(function() task.cancel(farmThread) end) end
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
