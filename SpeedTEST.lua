-- ============================================
-- TP TEST + UI
-- ============================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- CONFIG
-- ============================================
local AREAS = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

local Config = {
    baitArea = "Forest",
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
-- FIND EGG SA FOREST
-- ============================================
local function findForestEgg()
    if not EggState then return nil end
    local s, r = pcall(function()
        local egg = nil
        local closestDist = math.huge
        local char = LocalPlayer.Character
        local myPos = char and char:FindFirstChild("HumanoidRootPart")
        if not myPos then return nil end
        myPos = myPos.Position

        for _, data in next, EggState.ReadFieldEggs().Records do
            if data.AreaId == Config.baitArea then
                local dist = (data.BoundsCFrame.Position - myPos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    egg = data
                end
            end
        end
        return egg
    end)
    if s then return r end
    return nil
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
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end)

    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero

    return true
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
    Title.Text = "🥚 TP Forest Test"
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

    -- Button: TP to Forest
    local TPButton = Instance.new("TextButton", Main)
    TPButton.Size = UDim2.new(1, -30, 0, 40)
    TPButton.Position = UDim2.new(0, 15, 0, 55)
    TPButton.BackgroundColor3 = COLORS.GREEN
    TPButton.Text = "🏞️ TP to Forest Egg"
    TPButton.TextColor3 = COLORS.TEXT
    TPButton.TextSize = 14
    TPButton.Font = Enum.Font.GothamBold
    TPButton.AutoButtonColor = false
    TPButton.Parent = Main

    Instance.new("UICorner", TPButton).CornerRadius = UDim.new(0, 8)

    -- Button: Check Position
    local CheckButton = Instance.new("TextButton", Main)
    CheckButton.Size = UDim2.new(1, -30, 0, 30)
    CheckButton.Position = UDim2.new(0, 15, 0, 100)
    CheckButton.BackgroundColor3 = COLORS.TITLE_BG
    CheckButton.Text = "📊 Check Position"
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
        TPButton = TPButton,
        CheckButton = CheckButton,
        Status = Status,
        CloseBtn = CloseBtn,
    }
end

local ui = createUI()

-- ============================================
-- WIRING
-- ============================================
ui.TPButton.MouseButton1Click:Connect(function()
    ui.Status.Text = "Status: 🔍 Finding Forest egg..."
    ui.Status.TextColor3 = COLORS.YELLOW

    local egg = findForestEgg()
    if not egg then
        ui.Status.Text = "Status: ❌ No Forest egg"
        ui.Status.TextColor3 = COLORS.RED
        return
    end

    ui.Status.Text = "Status: 🚀 TP to Forest..."
    ui.Status.TextColor3 = COLORS.GREEN

    tpTo(egg.BoundsCFrame.Position)

    task.wait(1)

    -- Check kung naka-TP
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        local dist = (hrp.Position - egg.BoundsCFrame.Position).Magnitude
        if dist < 15 then
            ui.Status.Text = "Status: ✅ TP OK (dist: " .. math.floor(dist) .. ")"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "Status: ❌ TP REVERTED (dist: " .. math.floor(dist) .. ")"
            ui.Status.TextColor3 = COLORS.RED
        end
    end
end)

ui.CheckButton.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        ui.Status.Text = "Pos: " .. math.floor(hrp.Position.X) .. ", " .. math.floor(hrp.Position.Y) .. ", " .. math.floor(hrp.Position.Z)
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
