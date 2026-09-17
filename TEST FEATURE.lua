-- ============================================================
-- 🕊️ FLY HACK — CFrame-based (Working)
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ STATE ============
local Fly = {
    enabled = false,
    speed = 2,              -- 🎯 Studs per frame (2 = ~120 studs/s at 60fps)
    conn = nil,
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
    
    -- Stop humanoid physics (para hindi mag-collide)
    hum.PlatformStand = true
    
    -- Fly loop via CFrame
    Fly.conn = RunService.RenderStepped:Connect(function(dt)
        if not Fly.enabled then return end
        
        local h = getHRP()
        local hm = getHum()
        if not h or not h.Parent or not hm or hm.Health <= 0 then
            Fly.stop()
            return
        end
        
        -- Camera direction
        local cam = workspace.CurrentCamera
        local look = cam.CFrame.LookVector
        local right = cam.CFrame.RightVector
        local up = Vector3.new(0, 1, 0)
        
        -- Build direction
        local move = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            move = move + look
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            move = move - look
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            move = move - right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            move = move + right
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            move = move + up
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            move = move - up
        end
        
        -- Normalize
        if move.Magnitude > 0 then
            move = move.Unit
        end
        
        -- 🎯 CFrame write — direct position update
        local newPos = h.Position + (move * Fly.speed)
        h.CFrame = CFrame.new(newPos, newPos + look)
        
        -- Kill gravity/velocity (para steady)
        h.AssemblyLinearVelocity = Vector3.zero
        h.AssemblyAngularVelocity = Vector3.zero
    end)
    
    print("[FLY] ✅ ON — Speed: " .. Fly.speed .. " studs/frame")
end

-- ============ FLY STOP ============
function Fly.stop()
    if not Fly.enabled then return end
    Fly.enabled = false
    
    if Fly.conn then
        Fly.conn:Disconnect()
        Fly.conn = nil
    end
    
    local hum = getHum()
    if hum then
        pcall(function()
            hum.PlatformStand = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end)
    end
    
    print("[FLY] ❌ OFF")
end

-- Respawn handler
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
}

local function createUI()
    if CoreGui:FindFirstChild("FlyUI") then
        CoreGui.FlyUI:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FlyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 240, 0, 160)
    Main.Position = UDim2.new(0.5, -120, 0.5, -80)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = COLORS.PURPLE
    
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 32)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)
    
    local TitleCover = Instance.new("Frame", TitleBar)
    TitleCover.Size = UDim2.new(1, 0, 0, 10)
    TitleCover.Position = UDim2.new(0, 0, 1, -10)
    TitleCover.BackgroundColor3 = COLORS.TITLE_BG
    TitleCover.BorderSizePixel = 0
    
    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🕊️ Fly Hack"
    Title.TextColor3 = COLORS.PURPLE
    Title.TextSize = 13
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 22, 0, 22)
    CloseBtn.Position = UDim2.new(1, -27, 0, 5)
    CloseBtn.BackgroundColor3 = COLORS.RED
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = COLORS.TEXT
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 5)
    
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -100, 0, 25)
    lbl.Position = UDim2.new(0, 15, 0, 45)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🕊️ Fly Mode"
    lbl.TextColor3 = COLORS.TEXT
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    
    local stateLbl = Instance.new("TextLabel", Main)
    stateLbl.Size = UDim2.new(0, 40, 0, 25)
    stateLbl.Position = UDim2.new(1, -100, 0, 45)
    stateLbl.BackgroundTransparency = 1
    stateLbl.Text = "OFF"
    stateLbl.TextColor3 = COLORS.RED
    stateLbl.TextSize = 12
    stateLbl.Font = Enum.Font.GothamBold
    stateLbl.TextXAlignment = Enum.TextXAlignment.Right
    
    local track = Instance.new("Frame", Main)
    track.Size = UDim2.new(0, 46, 0, 24)
    track.Position = UDim2.new(1, -58, 0, 45)
    track.BackgroundColor3 = COLORS.TRACK_OFF
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = COLORS.KNOB
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local btn = Instance.new("TextButton", Main)
    btn.Size = UDim2.new(0, 110, 0, 30)
    btn.Position = UDim2.new(1, -115, 0, 40)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    
    local Info1 = Instance.new("TextLabel", Main)
    Info1.Size = UDim2.new(1, -24, 0, 16)
    Info1.Position = UDim2.new(0, 12, 0, 78)
    Info1.BackgroundTransparency = 1
    Info1.Text = "⚡ Speed: 2 studs/frame"
    Info1.TextColor3 = COLORS.CYAN
    Info1.TextSize = 10
    Info1.Font = Enum.Font.Gotham
    Info1.TextXAlignment = Enum.TextXAlignment.Left
    
    local Info2 = Instance.new("TextLabel", Main)
    Info2.Size = UDim2.new(1, -24, 0, 16)
    Info2.Position = UDim2.new(0, 12, 0, 96)
    Info2.BackgroundTransparency = 1
    Info2.Text = "🎮 WASD + Space/LCtrl"
    Info2.TextColor3 = COLORS.YELLOW
    Info2.TextSize = 10
    Info2.Font = Enum.Font.Gotham
    Info2.TextXAlignment = Enum.TextXAlignment.Left
    
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -24, 0, 16)
    Status.Position = UDim2.new(0, 12, 0, 120)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = COLORS.GREEN
    Status.TextSize = 10
    Status.Font = Enum.Font.GothamBold
    Status.TextXAlignment = Enum.TextXAlignment.Left
    
    return {
        ScreenGui = ScreenGui,
        track = track, knob = knob, stateLbl = stateLbl,
        btn = btn, Status = Status, CloseBtn = CloseBtn,
    }
end

local ui = createUI()

local function setToggle(on)
    ui.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    ui.knob.Position = on and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    ui.stateLbl.Text = on and "ON" or "OFF"
    ui.stateLbl.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.btn.MouseButton1Click:Connect(function()
    if not Fly.enabled then
        setToggle(true)
        ui.Status.Text = "🕊️ Flying..."
        ui.Status.TextColor3 = COLORS.GREEN
        Fly.start()
    else
        setToggle(false)
        ui.Status.Text = "Status: Stopped"
        ui.Status.TextColor3 = COLORS.YELLOW
        Fly.stop()
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    Fly.stop()
    ui.ScreenGui:Destroy()
end)

print("[FLY] ✅ CFrame-based Fly UI ready")
