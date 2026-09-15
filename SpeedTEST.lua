-- ============================================
-- 🌲 FOREST TP + CARRY EGG
-- ============================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ============================================
-- LOAD EGG STATE
-- ============================================

local EggState

pcall(function()
    local Client = ReplicatedStorage:FindFirstChild("Client")

    if Client then
        local ES = Client:FindFirstChild("EggState")

        if ES then
            EggState = require(ES)
        end
    end
end)

-- ============================================
-- FIND FOREST EGG
-- ============================================

local function findForestEgg()

    if not EggState then
        return nil
    end

    local data = EggState.ReadFieldEggs()

    if not data or not data.Records then
        return nil
    end

    local hrp =
        LocalPlayer.Character
        and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

    local closest = nil
    local closestDistance = math.huge

    for _, egg in ipairs(data.Records) do

        if egg.AreaId == "Forest"
        and (egg.State == "Slot" or egg.State == "Dropped")
        and egg.BoundsCFrame then

            if hrp then

                local distance =
                    (egg.BoundsCFrame.Position - hrp.Position).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closest = egg
                end

            else

                closest = egg
                break

            end
        end
    end

    return closest
end

-- ============================================
-- TP TO EGG
-- ============================================

local function tpToEgg(egg)

    local char = LocalPlayer.Character

    if not char then
        return false
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")

    if not hrp or not egg.BoundsCFrame then
        return false
    end

    local success = pcall(function()

        hrp.CFrame =
            CFrame.new(
                egg.BoundsCFrame.Position
                + Vector3.new(0, 3, 0)
            )

        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero

    end)

    return success
end

-- ============================================
-- CHECK IF CARRYING EGG
-- ============================================

local function hasEgg()

    local char = LocalPlayer.Character

    if not char then
        return false
    end

    for _, obj in ipairs(char:GetChildren()) do

        if obj:IsA("Tool")
        and obj:GetAttribute("ItemType") == "AssetEgg" then

            return true
        end

    end

    return false
end

-- ============================================
-- CARRY EGG
-- ============================================

local function carryEgg(egg)

    if not egg or not egg.Uid then
        return false
    end

    -- ========================================
    -- METHOD 1: CarryFieldEgg
    -- ========================================

    pcall(function()

        if EggState and EggState.CarryFieldEgg then
            EggState.CarryFieldEgg(egg.Uid)
        end

    end)

    task.wait(0.4)

    if hasEgg() then
        return true
    end

    -- ========================================
    -- METHOD 2: FIND EGG MODEL
    -- ========================================

    local slots =
        Workspace:FindFirstChild(
            "AreaEggSlotsClient",
            true
        )

    local model =
        slots and slots:FindFirstChild(egg.Uid)
        or Workspace:FindFirstChild(
            egg.Uid,
            true
        )

    if not model then
        return false
    end

    -- ========================================
    -- FIND PROMPT
    -- ========================================

    local prompt =
        model:FindFirstChildWhichIsA(
            "ProximityPrompt",
            true
        )

    if not prompt then
        return false
    end

    -- ========================================
    -- FIRE PROMPT
    -- ========================================

    pcall(function()

        prompt.Enabled = true
        prompt.HoldDuration = 0
        prompt.RequiresLineOfSight = false
        prompt.MaxActivationDistance = 9999

        if fireproximityprompt then
            fireproximityprompt(prompt, 0)
        end

    end)

    task.wait(0.5)

    if hasEgg() then
        return true
    end

    -- ========================================
    -- METHOD 3: RETRY
    -- ========================================

    for i = 1, 5 do

        if not enabled then
            return false
        end

        pcall(function()

            if fireproximityprompt then
                fireproximityprompt(prompt, 0)
            end

        end)

        pcall(function()

            if EggState and EggState.CarryFieldEgg then
                EggState.CarryFieldEgg(egg.Uid)
            end

        end)

        task.wait(0.3)

        if hasEgg() then
            return true
        end

    end

    return false
end

-- ============================================
-- STATE
-- ============================================

enabled = false
local loopThread = nil

-- ============================================
-- REMOVE OLD UI
-- ============================================

if CoreGui:FindFirstChild("ForestTPUI") then
    CoreGui.ForestTPUI:Destroy()
end

-- ============================================
-- UI
-- ============================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "ForestTPUI"
Gui.ResetOnSpawn = false
Gui.Parent = CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 260, 0, 130)
Main.Position = UDim2.new(0.5, -130, 0.5, -65)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = Gui

Instance.new("UICorner", Main).CornerRadius =
    UDim.new(0, 10)

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(60, 60, 70)
Stroke.Parent = Main

-- ============================================
-- TITLE
-- ============================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.new(0, 10, 0, 5)
Title.BackgroundTransparency = 1
Title.Text = "🌲 Forest Carry Egg"
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextSize = 14
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

-- ============================================
-- TP LABEL
-- ============================================

local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(0, 100, 0, 30)
Label.Position = UDim2.new(0, 15, 0, 50)
Label.BackgroundTransparency = 1
Label.Text = "TP"
Label.TextColor3 = Color3.fromRGB(255,255,255)
Label.TextSize = 14
Label.Font = Enum.Font.GothamBold
Label.TextXAlignment = Enum.TextXAlignment.Left
Label.Parent = Main

-- ============================================
-- STATE TEXT
-- ============================================

local State = Instance.new("TextLabel")
State.Size = UDim2.new(0, 45, 0, 30)
State.Position = UDim2.new(1, -115, 0, 50)
State.BackgroundTransparency = 1
State.Text = "OFF"
State.TextColor3 = Color3.fromRGB(200,50,50)
State.TextSize = 13
State.Font = Enum.Font.GothamBold
State.Parent = Main

-- ============================================
-- TOGGLE TRACK
-- ============================================

local Track = Instance.new("Frame")
Track.Size = UDim2.new(0, 50, 0, 26)
Track.Position = UDim2.new(1, -65, 0, 52)
Track.BackgroundColor3 = Color3.fromRGB(70,70,80)
Track.BorderSizePixel = 0
Track.Parent = Main

Instance.new("UICorner", Track).CornerRadius =
    UDim.new(1,0)

local Knob = Instance.new("Frame")
Knob.Size = UDim2.new(0,20,0,20)
Knob.Position = UDim2.new(0,3,0.5,-10)
Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
Knob.BorderSizePixel = 0
Knob.Parent = Track

Instance.new("UICorner", Knob).CornerRadius =
    UDim.new(1,0)

-- ============================================
-- BUTTON
-- ============================================

local Button = Instance.new("TextButton")
Button.Size = UDim2.new(0,110,0,45)
Button.Position = UDim2.new(1,-120,0,43)
Button.BackgroundTransparency = 1
Button.Text = ""
Button.Parent = Main

-- ============================================
-- STATUS
-- ============================================

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1,-30,0,25)
Status.Position = UDim2.new(0,15,0,95)
Status.BackgroundTransparency = 1
Status.Text = "Status: Ready"
Status.TextColor3 = Color3.fromRGB(255,200,0)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

-- ============================================
-- TOGGLE VISUAL
-- ============================================

local function setToggle(value)

    if value then

        Track.BackgroundColor3 =
            Color3.fromRGB(0,180,90)

        Knob.Position =
            UDim2.new(0,27,0.5,-10)

        State.Text = "ON"
        State.TextColor3 =
            Color3.fromRGB(0,180,90)

    else

        Track.BackgroundColor3 =
            Color3.fromRGB(70,70,80)

        Knob.Position =
            UDim2.new(0,3,0.5,-10)

        State.Text = "OFF"
        State.TextColor3 =
            Color3.fromRGB(200,50,50)

    end
end

-- ============================================
-- MAIN LOOP
-- ============================================

local function run()

    local egg = findForestEgg()

    if not egg then

        Status.Text =
            "Status: ⚠️ No Forest egg"

        Status.TextColor3 =
            Color3.fromRGB(255,200,0)

        return
    end

    -- TP
    Status.Text =
        "Status: 🌲 TP Forest..."

    Status.TextColor3 =
        Color3.fromRGB(0,180,90)

    if not tpToEgg(egg) then

        Status.Text =
            "Status: ❌ TP failed"

        Status.TextColor3 =
            Color3.fromRGB(200,50,50)

        return
    end

    task.wait(0.3)

    if not enabled then
        return
    end

    -- CARRY
    Status.Text =
        "Status: 🥚 Carrying..."

    Status.TextColor3 =
        Color3.fromRGB(255,200,0)

    local grabbed = carryEgg(egg)

    if grabbed then

        Status.Text =
            "Status: ✅ Egg carried"

        Status.TextColor3 =
            Color3.fromRGB(0,180,90)

    else

        Status.Text =
            "Status: ❌ Carry failed"

        Status.TextColor3 =
            Color3.fromRGB(200,50,50)

    end
end

-- ============================================
-- TOGGLE
-- ============================================

Button.MouseButton1Click:Connect(function()

    enabled = not enabled

    setToggle(enabled)

    if enabled then

        Status.Text =
            "Status: 🎯 Starting..."

        Status.TextColor3 =
            Color3.fromRGB(0,180,90)

        loopThread = task.spawn(function()

            while enabled do

                pcall(run)

                task.wait(1)

            end

        end)

    else

        Status.Text =
            "Status: ⏸ Stopped"

        Status.TextColor3 =
            Color3.fromRGB(255,200,0)

        if loopThread then

            pcall(function()
                task.cancel(loopThread)
            end)

            loopThread = nil

        end
    end
end)

-- ============================================
-- READY
-- ============================================

Status.Text = "Status: ✅ Ready"
Status.TextColor3 = Color3.fromRGB(0,180,90)
