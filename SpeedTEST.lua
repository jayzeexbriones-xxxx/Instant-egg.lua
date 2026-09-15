-- ============================================
-- SERVICES
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- CONFIG
-- ============================================
local Config = {
    baitArea = "Forest",
    tpOffset = Vector3.new(0, 3, 0),
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
-- FIND FOREST EGG
-- ============================================
local function findForestEgg()
    if not EggState then return nil, nil end
    local s, r = pcall(function()
        local egg, model = nil, nil
        local closestDist = math.huge
        local char = LocalPlayer.Character
        local myPos = char and char:FindFirstChild("HumanoidRootPart")
        if not myPos then return nil, nil end
        myPos = myPos.Position

        for _, data in next, EggState.ReadFieldEggs().Records do
            if data.State == "Slot" or data.State == "Dropped" then
                if data.AreaId == Config.baitArea then
                    local m = Workspace:FindFirstChild("AreaEggSlotsClient", true)
                        and Workspace.AreaEggSlotsClient:FindFirstChild(data.Uid)
                        or Workspace:FindFirstChild(data.Uid, true)
                    if m then
                        local dist = (data.BoundsCFrame.Position - myPos).Magnitude
                        if dist < closestDist then
                            closestDist = dist
                            egg = data
                            model = m
                        end
                    end
                end
            end
        end
        return egg, model
    end)
    if s then return r end
    return nil, nil
end

-- ============================================
-- TP FUNCTION
-- ============================================
local function tpTo(pos)
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    pcall(function()
        hrp.CFrame = CFrame.new(pos + Config.tpOffset)
    end)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    return true
end

-- ============================================
-- GET PROMPT
-- ============================================
local function getPrompt(egg, model)
    local s, r = pcall(function()
        local eggPos = egg.BoundsCFrame.Position
        local closestPrompt = nil
        local closestDist = math.huge

        -- Try model first
        local prompt = model:FindFirstChild("CarryAreaEgg", true)
            or model:FindFirstChildWhichIsA("ProximityPrompt", true)
        if prompt then return prompt end

        -- Fallback: search all prompts
        for _, p in next, Workspace:GetDescendants() do
            if p:IsA("ProximityPrompt") and p.Enabled then
                local parent = p.Parent
                if parent then
                    local pPos = parent:IsA("BasePart") and parent.Position
                        or (parent:FindFirstChildWhichIsA("BasePart") and parent:FindFirstChildWhichIsA("BasePart").Position)
                    if pPos then
                        local dist = (eggPos - pPos).Magnitude
                        if dist < closestDist and dist < 15 then
                            closestDist = dist
                            closestPrompt = p
                        end
                    end
                end
            end
        end
        return closestPrompt
    end)
    if s then return r end
    return nil
end

-- ============================================
-- GRAB EGG
-- ============================================
local function grabEgg(egg, model)
    -- Try remote first
    pcall(function()
        if EggState and EggState.CarryFieldEgg then
            EggState.CarryFieldEgg(egg.Uid)
        end
    end)
    task.wait(0.1)

    -- Try prompt
    local prompt = getPrompt(egg, model)
    if prompt and fireproximityprompt then
        pcall(function()
            prompt.Enabled = true
            prompt.HoldDuration = 0
            prompt.RequiresLineOfSight = false
            prompt.MaxActivationDistance = 9999
            fireproximityprompt(prompt, 0)
        end)
    end
    task.wait(0.2)
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
    Main.Size = UDim2.new(0, 260, 0, 180)
    Main.Position = UDim2.new(0.5, -130, 0.5, -90)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = COLORS.STROKE

    -- Title
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
    Title.Text = "🥚 TP Forest → Grab"
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

    -- Button: TP + Grab
    local GrabButton = Instance.new("TextButton", Main)
    GrabButton.Size = UDim2.new(1, -30, 0, 40)
    GrabButton.Position = UDim2.new(0, 15, 0, 55)
    GrabButton.BackgroundColor3 = COLORS.GREEN
    GrabButton.Text = "🐔 TP Forest + Grab"
    GrabButton.TextColor3 = COLORS.TEXT
    GrabButton.TextSize = 14
    GrabButton.Font = Enum.Font.GothamBold
    GrabButton.AutoButtonColor = false
    GrabButton.Parent = Main
    Instance.new("UICorner", GrabButton).CornerRadius = UDim.new(0, 8)

    -- Button: Check
    local CheckButton = Instance.new("TextButton", Main)
    CheckButton.Size = UDim2.new(1, -30, 0, 30)
    CheckButton.Position = UDim2.new(0, 15, 0, 100)
    CheckButton.BackgroundColor3 = COLORS.TITLE_BG
    CheckButton.Text = "📊 Check if Has Egg"
    CheckButton.TextColor3 = COLORS.TEXT
    CheckButton.TextSize = 12
    CheckButton.Font = Enum.Font.GothamBold
    CheckButton.AutoButtonColor = false
    CheckButton.Parent = Main
    Instance.new("UICorner", CheckButton).CornerRadius = UDim.new(0, 6)

    -- Status
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -30, 0, 20)
    Status.Position = UDim2.new(0, 15, 0, 145)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 11
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui,
        GrabButton = GrabButton,
        CheckButton = CheckButton,
        Status = Status,
        CloseBtn = CloseBtn,
    }
end

local ui = createUI()

-- ============================================
-- HAS EGG CHECK
-- ============================================
local function hasEgg()
    local char = LocalPlayer.Character
    if not char then return false end
    for _, obj in next, char:GetChildren() do
        if obj:IsA("Tool") and obj:GetAttribute("ItemType") == "AssetEgg" then
            return true
        end
    end
    return false
end

-- ============================================
-- WIRING
-- ============================================
ui.GrabButton.MouseButton1Click:Connect(function()
    ui.Status.Text = "Status: 🔍 Finding Forest egg..."
    ui.Status.TextColor3 = COLORS.YELLOW

    local egg, model = findForestEgg()
    if not egg then
        ui.Status.Text = "Status: ❌ No Forest egg"
        ui.Status.TextColor3 = COLORS.RED
        return
    end

    ui.Status.Text = "Status: 🚀 TP to Forest..."
    ui.Status.TextColor3 = COLORS.GREEN

    tpTo(egg.BoundsCFrame.Position)
    task.wait(0.3)

    ui.Status.Text = "Status: 🥚 Grabbing..."
    grabEgg(egg, model)

    task.wait(0.5)

    if hasEgg() then
        ui.Status.Text = "Status: ✅ Grabbed Forest egg!"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.Status.Text = "Status: ⚠️ Grab failed — retry"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

ui.CheckButton.MouseButton1Click:Connect(function()
    if hasEgg() then
        ui.Status.Text = "Status: ✅ Has egg in hand"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        ui.Status.Text = "Status: ❌ No egg in hand"
        ui.Status.TextColor3 = COLORS.RED
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
