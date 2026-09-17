-- ============================================================
-- 🕊️ FLY HACK — MOBILE VERSION (Touch Buttons)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ STATE ============
local Fly = {
    enabled = false,
    speed = 2,
    conn = nil,
    -- Mobile controls
    moveUp = false,
    moveDown = false,
    moveForward = false,
    moveBack = false,
    moveLeft = false,
    moveRight = false,
}

-- ============ HELPERS ============
local function getChar() return LocalPlayer.Character end
local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

-- ============ FLY START ============
function Fly.start()
    if Fly.enabled then return end

    local hrp = getHRP()
    local hum = getHum()
    if not hrp or not hum then
        warn("[FLY] Walang character!")
        return
    end

    Fly.enabled = true
    hum.PlatformStand = true

    Fly.conn = RunService.RenderStepped:Connect(function(dt)
        if not Fly.enabled then return end

        local h = getHRP()
        local hm = getHum()
        if not h or not h.Parent or not hm or hm.Health <= 0 then
            Fly.stop()
            return
        end

        local cam = workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)

        local move = Vector3.zero

        -- Mobile buttons
        if Fly.moveForward then move = move + look end
        if Fly.moveBack then move = move - look end
        if Fly.moveLeft then move = move - right end
        if Fly.moveRight then move = move + right end
        if Fly.moveUp then move = move + up end
        if Fly.moveDown then move = move - up end

        -- Keyboard (kung may keyboard pa rin)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + look end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - look end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + up end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - up end

        if move.Magnitude > 0 then
            move = move.Unit
        end

        local newPos = h.Position + (move * Fly.speed)
        h.CFrame = CFrame.new(newPos, newPos + look)
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end)

    print("[FLY] ✅ ON — Mobile controls active")
end

function Fly.stop()
    if not Fly.enabled then return end
    Fly.enabled = false

    if Fly.conn then
        Fly.conn:Disconnect()
        Fly.conn = nil
    end

    -- Reset mobile buttons
    Fly.moveUp = false
    Fly.moveDown = false
    Fly.moveForward = false
    Fly.moveBack = false
    Fly.moveLeft = false
    Fly.moveRight = false

    local hum = getHum()
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end

    print("[FLY] ❌ OFF")
end

LocalPlayer.CharacterAdded:Connect(function()
    if Fly.enabled then
        Fly.stop()
        task.wait(1.5)
        Fly.start()
    end
end)

-- ============ UI ============
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    TEXT = Color3.fromRGB(255, 255, 255),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
    YELLOW = Color3.fromRGB(255, 200, 0),
    CYAN = Color3.fromRGB(80, 200, 255),
    PURPLE = Color3.fromRGB(180, 100, 255),
    DARK_BTN = Color3.fromRGB(50, 50, 65),
    BTN_ACTIVE = Color3.fromRGB(0, 180, 90),
}

local function createUI()
    if CoreGui:FindFirstChild("FlyUI") then
        CoreGui.FlyUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FlyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    -- ============ MAIN PANEL ============
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 200, 0, 90)
    Main.Position = UDim2.new(0, 10, 0, 50)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = COLORS.PURPLE

    local Title = Instance.new("TextLabel", Main)
    Title.Size = UDim2.new(1, -30, 0, 24)
    Title.Position = UDim2.new(0, 8, 0, 2)
    Title.BackgroundTransparency = 1
    Title.Text = "🕊️ Fly Hack"
    Title.TextColor3 = COLORS.PURPLE
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    -- Toggle button
    local toggleBtn = Instance.new("TextButton", Main)
    toggleBtn.Size = UDim2.new(1, -16, 0, 30)
    toggleBtn.Position = UDim2.new(0, 8, 0, 30)
    toggleBtn.BackgroundColor3 = COLORS.DARK_BTN
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = "🕊️ Fly: OFF"
    toggleBtn.TextColor3 = COLORS.TEXT
    toggleBtn.TextSize = 12
    toggleBtn.Font = Enum.Font.GothamBold
    toggleBtn.AutoButtonColor = false
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 5)

    local statusLbl = Instance.new("TextLabel", Main)
    statusLbl.Size = UDim2.new(1, -16, 0, 16)
    statusLbl.Position = UDim2.new(0, 8, 0, 64)
    statusLbl.BackgroundTransparency = 1
    statusLbl.Text = "🎮 Mobile controls"
    statusLbl.TextColor3 = COLORS.CYAN
    statusLbl.TextSize = 9
    statusLbl.Font = Enum.Font.Gotham
    statusLbl.TextXAlignment = Enum.TextXAlignment.Left

    -- ============ MOBILE BUTTONS (Right side) ============
    -- Up button
    local upBtn = Instance.new("TextButton", ScreenGui)
    upBtn.Size = UDim2.new(0, 60, 0, 60)
    upBtn.Position = UDim2.new(1, -160, 1, -220)
    upBtn.BackgroundColor3 = COLORS.DARK_BTN
    upBtn.BackgroundTransparency = 0.3
    upBtn.BorderSizePixel = 0
    upBtn.Text = "⬆️"
    upBtn.TextSize = 24
    upBtn.TextColor3 = COLORS.TEXT
    upBtn.AutoButtonColor = false
    upBtn.Visible = false
    Instance.new("UICorner", upBtn).CornerRadius = UDim.new(0, 10)

    -- Down button
    local downBtn = Instance.new("TextButton", ScreenGui)
    downBtn.Size = UDim2.new(0, 60, 0, 60)
    downBtn.Position = UDim2.new(1, -160, 1, -140)
    downBtn.BackgroundColor3 = COLORS.DARK_BTN
    downBtn.BackgroundTransparency = 0.3
    downBtn.BorderSizePixel = 0
    downBtn.Text = "⬇️"
    downBtn.TextSize = 24
    downBtn.TextColor3 = COLORS.TEXT
    downBtn.AutoButtonColor = false
    downBtn.Visible = false
    Instance.new("UICorner", downBtn).CornerRadius = UDim.new(0, 10)

    -- Forward (up arrow on dpad)
    local fwdBtn = Instance.new("TextButton", ScreenGui)
    fwdBtn.Size = UDim2.new(0, 50, 0, 50)
    fwdBtn.Position = UDim2.new(0, 30, 1, -180)
    fwdBtn.BackgroundColor3 = COLORS.DARK_BTN
    fwdBtn.BackgroundTransparency = 0.3
    fwdBtn.BorderSizePixel = 0
    fwdBtn.Text = "▲"
    fwdBtn.TextSize = 20
    fwdBtn.TextColor3 = COLORS.TEXT
    fwdBtn.AutoButtonColor = false
    fwdBtn.Visible = false
    Instance.new("UICorner", fwdBtn).CornerRadius = UDim.new(0, 8)

    -- Back (down arrow)
    local backBtn = Instance.new("TextButton", ScreenGui)
    backBtn.Size = UDim2.new(0, 50, 0, 50)
    backBtn.Position = UDim2.new(0, 30, 1, -70)
    backBtn.BackgroundColor3 = COLORS.DARK_BTN
    backBtn.BackgroundTransparency = 0.3
    backBtn.BorderSizePixel = 0
    backBtn.Text = "▼"
    backBtn.TextSize = 20
    backBtn.TextColor3 = COLORS.TEXT
    backBtn.AutoButtonColor = false
    backBtn.Visible = false
    Instance.new("UICorner", backBtn).CornerRadius = UDim.new(0, 8)

    -- Left
    local leftBtn = Instance.new("TextButton", ScreenGui)
    leftBtn.Size = UDim2.new(0, 50, 0, 50)
    leftBtn.Position = UDim2.new(0, 88, 1, -125)
    leftBtn.BackgroundColor3 = COLORS.DARK_BTN
    leftBtn.BackgroundTransparency = 0.3
    leftBtn.BorderSizePixel = 0
    leftBtn.Text = "◀"
    leftBtn.TextSize = 20
    leftBtn.TextColor3 = COLORS.TEXT
    leftBtn.AutoButtonColor = false
    leftBtn.Visible = false
    Instance.new("UICorner", leftBtn).CornerRadius = UDim.new(0, 8)

    -- Right
    local rightBtn = Instance.new("TextButton", ScreenGui)
    rightBtn.Size = UDim2.new(0, 50, 0, 50)
    rightBtn.Position = UDim2.new(0, 146, 1, -125)
    rightBtn.BackgroundColor3 = COLORS.DARK_BTN
    rightBtn.BackgroundTransparency = 0.3
    rightBtn.BorderSizePixel = 0
    rightBtn.Text = "▶"
    rightBtn.TextSize = 20
    rightBtn.TextColor3 = COLORS.TEXT
    rightBtn.AutoButtonColor = false
    rightBtn.Visible = false
    Instance.new("UICorner", rightBtn).CornerRadius = UDim.new(0, 8)

    -- All buttons
    local allButtons = {upBtn, downBtn, fwdBtn, backBtn, leftBtn, rightBtn}

    local function setButtonsVisible(visible)
        for _, btn in ipairs(allButtons) do
            btn.Visible = visible
        end
    end

    -- ============ TOGGLE WIRING ============
    toggleBtn.MouseButton1Click:Connect(function()
        if not Fly.enabled then
            Fly.start()
            toggleBtn.Text = "🕊️ Fly: ON"
            toggleBtn.BackgroundColor3 = COLORS.BTN_ACTIVE
            statusLbl.Text = "🎮 Use buttons below"
            setButtonsVisible(true)
        else
            Fly.stop()
            toggleBtn.Text = "🕊️ Fly: OFF"
            toggleBtn.BackgroundColor3 = COLORS.DARK_BTN
            statusLbl.Text = "🎮 Mobile controls"
            setButtonsVisible(false)
        end
    end)

    -- ============ BUTTON HOLD LOGIC ============
    local function setupHold(btn, stateKey)
        btn.MouseButton1Down:Connect(function()
            Fly[stateKey] = true
            btn.BackgroundColor3 = COLORS.BTN_ACTIVE
            btn.BackgroundTransparency = 0
        end)
        btn.MouseButton1Up:Connect(function()
            Fly[stateKey] = false
            btn.BackgroundColor3 = COLORS.DARK_BTN
            btn.BackgroundTransparency = 0.3
        end)
        -- Touch support (para sigurado sa phone)
        btn.TouchLongPress:Connect(function()
            Fly[stateKey] = true
            btn.BackgroundColor3 = COLORS.BTN_ACTIVE
            btn.BackgroundTransparency = 0
        end)
        btn.TouchEnded:Connect(function()
            Fly[stateKey] = false
            btn.BackgroundColor3 = COLORS.DARK_BTN
            btn.BackgroundTransparency = 0.3
        end)
        -- Fallback: InputBegan/InputEnded
        btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
               or input.UserInputType == Enum.UserInputType.MouseButton1 then
                Fly[stateKey] = true
                btn.BackgroundColor3 = COLORS.BTN_ACTIVE
                btn.BackgroundTransparency = 0
            end
        end)
        btn.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch
               or input.UserInputType == Enum.UserInputType.MouseButton1 then
                Fly[stateKey] = false
                btn.BackgroundColor3 = COLORS.DARK_BTN
                btn.BackgroundTransparency = 0.3
            end
        end)
    end

    setupHold(fwdBtn, "moveForward")
    setupHold(backBtn, "moveBack")
    setupHold(leftBtn, "moveLeft")
    setupHold(rightBtn, "moveRight")
    setupHold(upBtn, "moveUp")
    setupHold(downBtn, "moveDown")

    return {
        ScreenGui = ScreenGui,
        Main = Main,
        toggleBtn = toggleBtn,
        statusLbl = statusLbl,
        buttons = allButtons,
    }
end

local ui = createUI()

print("[FLY] ✅ Mobile Fly UI ready — click toggle then use buttons")
