

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local BG         = Color3.fromRGB(0, 0, 0)
local CARD_BG    = Color3.fromRGB(12, 12, 12)
local CARD_HOV   = Color3.fromRGB(20, 20, 20)
local BORDER     = Color3.fromRGB(35, 35, 35)
local BORDER2    = Color3.fromRGB(65, 65, 65)
local WHITE      = Color3.fromRGB(255, 255, 255)
local DIM        = Color3.fromRGB(160, 160, 160)
local KB_BG      = Color3.fromRGB(8, 8, 8)
local State = {
    autoBatToggled = false,
    hittingCooldown = false,
    guiVisible = true,
}
local Keys = {
    autoBat = Enum.KeyCode.V,
    autoBatType = "Keyboard",
    guiHide = Enum.KeyCode.LeftControl,
}
local h, hrp = nil, nil
local function saveConfig()
    local cfg = {
        autoBatKey = Keys.autoBat.Name,
        autoBatKeyType = Keys.autoBatType,
    }
    pcall(function()
        writefile("ZynoxAutoBatDesyncConfig.json", HttpService:JSONEncode(cfg))
    end)
end
local function loadConfig()
    local hasFile = false
    pcall(function() hasFile = isfile("ZynoxAutoBatDesyncConfig.json") end)
    if not hasFile then return end
    local ok, cfg = pcall(function()
        return HttpService:JSONDecode(readfile("ZynoxAutoBatDesyncConfig.json"))
    end)
    if not ok or not cfg then return end
    if cfg.autoBatKey and Enum.KeyCode[cfg.autoBatKey] then
        Keys.autoBat = Enum.KeyCode[cfg.autoBatKey]
    end
    if cfg.autoBatKeyType then
        Keys.autoBatType = cfg.autoBatKeyType
    end
end
loadConfig()
for _, name in pairs({"ZynoxAutoBatDesyncGUI", "MwvaneNewaBatDesyncGUI", "PhazeAutoBatDesyncGUI", "ZynoxDiscordLink"}) do
    local old = game:GetService("CoreGui"):FindFirstChild(name)
    if old then old:Destroy() end
    local pGui = LP:FindFirstChild("PlayerGui")
    if pGui then
        local oldPlayerGui = pGui:FindFirstChild(name)
        if oldPlayerGui then oldPlayerGui:Destroy() end
    end
end
local gui = Instance.new("ScreenGui")
gui.Name = "ZynoxAutoBatDesyncGUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 10
gui.IgnoreGuiInset = true
gui.Parent = LP:WaitForChild("PlayerGui")
local main = Instance.new("Frame", gui)
main.Name = "Main"
main.Size = UDim2.new(0, 320, 0, 160)
main.Position = UDim2.new(0.5, -160, 0.5, -80)
main.BackgroundColor3 = CARD_BG
main.BorderSizePixel = 0
main.Active = true
main.ClipsDescendants = true
local mainCorner = Instance.new("UICorner", main)
mainCorner.CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", main)
mainStroke.Color = BORDER
mainStroke.Thickness = 1
mainStroke.Transparency = 0.2
local shadow = Instance.new("ImageLabel", main)
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0.5, 0, 0.5, 3)
shadow.Size = UDim2.new(1, 30, 1, 30)
shadow.ZIndex = -1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 450, 450)
do
    local dragging, dragInput, dragStart, mainStart = false, nil, nil, nil
    main.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = inp.Position
            mainStart = main.Position
            inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    main.InputChanged:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            dragInput = inp
        end
    end)
    UIS.InputChanged:Connect(function(inp)
        if inp == dragInput and dragging then
            local dx = inp.Position.X - dragStart.X
            local dy = inp.Position.Y - dragStart.Y
            main.Position = UDim2.new(mainStart.X.Scale, mainStart.X.Offset + dx, mainStart.Y.Scale, mainStart.Y.Offset + dy)
        end
    end)
end
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1, 0, 0, 36)
header.BackgroundColor3 = BG
header.BorderSizePixel = 0
header.ZIndex = 2
local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1, -70, 1, 0)
titleLbl.Position = UDim2.new(0, 14, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "printed.vs ANTI - SPEED"
titleLbl.TextColor3 = WHITE
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 13
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.ZIndex = 3
local headerDiv = Instance.new("Frame", header)
headerDiv.Size = UDim2.new(1, 0, 0, 1)
headerDiv.Position = UDim2.new(0, 0, 1, 0)
headerDiv.BackgroundColor3 = BORDER
headerDiv.BorderSizePixel = 0
headerDiv.ZIndex = 3
local lockBtn = Instance.new("TextButton", header)
lockBtn.Size = UDim2.new(0, 24, 0, 24)
lockBtn.Position = UDim2.new(1, -58, 0.5, -12)
lockBtn.BackgroundColor3 = Color3.fromRGB(35, 30, 20)
lockBtn.Text = ""
lockBtn.ZIndex = 4
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)
local lockIcon = Instance.new("TextLabel", lockBtn)
lockIcon.Size = UDim2.new(1, 0, 1, 0)
lockIcon.BackgroundTransparency = 1
lockIcon.Text = "🔒"
lockIcon.TextSize = 12
lockIcon.ZIndex = 5
local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.new(0, 24, 0, 24)
closeBtn.Position = UDim2.new(1, -30, 0.5, -12)
closeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
closeBtn.Text = "×"
closeBtn.TextColor3 = WHITE
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 16
closeBtn.ZIndex = 4
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function()
    State.autoBatToggled = false
    gui:Destroy()
end)
local content = Instance.new("Frame", main)
content.Size = UDim2.new(1, -24, 1, -85)
content.Position = UDim2.new(0, 12, 0, 46)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
local row1 = Instance.new("Frame", content)
row1.Size = UDim2.new(1, 0, 0, 38)
row1.Position = UDim2.new(0, 0, 0, 0)
row1.BackgroundColor3 = KB_BG
row1.BorderSizePixel = 0
Instance.new("UICorner", row1).CornerRadius = UDim.new(0, 8)
local row1Stroke = Instance.new("UIStroke", row1)
row1Stroke.Color = BORDER
row1Stroke.Thickness = 1
local r1Text = Instance.new("TextLabel", row1)
r1Text.Size = UDim2.new(1, -60, 1, 0)
r1Text.Position = UDim2.new(0, 12, 0, 0)
r1Text.BackgroundTransparency = 1
r1Text.Text = "ANTI-SPEED"
r1Text.TextColor3 = WHITE
r1Text.Font = Enum.Font.GothamBold
r1Text.TextSize = 12
r1Text.TextXAlignment = Enum.TextXAlignment.Left
local switchBg = Instance.new("TextButton", row1)
switchBg.Size = UDim2.new(0, 40, 0, 22)
switchBg.Position = UDim2.new(1, -48, 0.5, -11)
switchBg.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
switchBg.Text = ""
switchBg.AutoButtonColor = false
Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)
local switchThumb = Instance.new("Frame", switchBg)
switchThumb.Size = UDim2.new(0, 16, 0, 16)
switchThumb.Position = UDim2.new(0, 3, 0.5, -8)
switchThumb.BackgroundColor3 = DIM
switchThumb.BorderSizePixel = 0
Instance.new("UICorner", switchThumb).CornerRadius = UDim.new(1, 0)
local row2 = Instance.new("Frame", content)
row2.Size = UDim2.new(1, 0, 0, 38)
row2.Position = UDim2.new(0, 0, 0, 46)
row2.BackgroundColor3 = KB_BG
row2.BorderSizePixel = 0
Instance.new("UICorner", row2).CornerRadius = UDim.new(0, 8)
local row2Stroke = Instance.new("UIStroke", row2)
row2Stroke.Color = BORDER
row2Stroke.Thickness = 1
local r2Text = Instance.new("TextLabel", row2)
r2Text.Size = UDim2.new(1, -60, 1, 0)
r2Text.Position = UDim2.new(0, 12, 0, 0)
r2Text.BackgroundTransparency = 1
r2Text.Text = "KEYBIND"
r2Text.TextColor3 = WHITE
r2Text.Font = Enum.Font.GothamBold
r2Text.TextSize = 12
r2Text.TextXAlignment = Enum.TextXAlignment.Left
local keyBtn = Instance.new("TextButton", row2)
keyBtn.Size = UDim2.new(0, 32, 0, 24)
keyBtn.Position = UDim2.new(1, -40, 0.5, -12)
keyBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
keyBtn.Text = Keys.autoBat.Name
keyBtn.TextColor3 = WHITE
keyBtn.Font = Enum.Font.GothamBold
keyBtn.TextSize = 11
keyBtn.AutoButtonColor = false
Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)
local kStroke = Instance.new("UIStroke", keyBtn)
kStroke.Color = BORDER
local statusLbl = Instance.new("TextLabel", main)
statusLbl.Size = UDim2.new(1, 0, 0, 20)
statusLbl.Position = UDim2.new(0, 0, 1, -26)
statusLbl.BackgroundTransparency = 1
statusLbl.Text = "DISABLED"
statusLbl.TextColor3 = DIM
statusLbl.Font = Enum.Font.GothamBold
statusLbl.TextSize = 11
local kListening = false
local kConn
local function updateToggleVisuals(on)
    State.autoBatToggled = on
    TweenService:Create(switchThumb, TweenInfo.new(0.2), {
        Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = on and WHITE or DIM
    }):Play()
    TweenService:Create(switchBg, TweenInfo.new(0.2), {
        BackgroundColor3 = on and WHITE or Color3.fromRGB(25, 25, 25)
    }):Play()
    statusLbl.Text = on and "ENABLED" or "DISABLED"
    statusLbl.TextColor3 = on and WHITE or DIM
end
switchBg.MouseButton1Click:Connect(function()
    updateToggleVisuals(not State.autoBatToggled)
end)
local function stopListen(key)
    kListening = false
    if kConn then kConn:Disconnect(); kConn = nil end
    if key then
        Keys.autoBat = key
        keyBtn.Text = key.Name
        saveConfig()
    else
        keyBtn.Text = Keys.autoBat.Name
    end
end
keyBtn.MouseButton1Click:Connect(function()
    if kListening then stopListen(nil); return end
    kListening = true
    keyBtn.Text = "..."
    kConn = UIS.InputBegan:Connect(function(inp)
        if not kListening then return end
        if inp.UserInputType == Enum.UserInputType.Keyboard then
            if inp.KeyCode == Enum.KeyCode.Escape then stopListen(nil); return end
            Keys.autoBatType = "Keyboard"
            stopListen(inp.KeyCode)
        elseif inp.UserInputType == Enum.UserInputType.Gamepad1 then
            Keys.autoBatType = "Gamepad"
            stopListen(inp.KeyCode)
        end
    end)
end)
local function getBat()
    local char = LP.Character
    if not char then return nil end
    local tool = char:FindFirstChild("Bat")
    if tool then return tool end
    local bp2 = LP:FindFirstChild("Backpack")
    if bp2 then
        tool = bp2:FindFirstChild("Bat")
        if tool then
            tool.Parent = char
            return tool
        end
    end
    return nil
end
local function tryHitBat()
    if State.hittingCooldown then return end
    State.hittingCooldown = true
    pcall(function()
        local bat = getBat()
        if bat then
            bat:Activate()
            local ev = bat:FindFirstChildWhichIsA("RemoteEvent")
            if ev then ev:FireServer() end
        end
    end)
    task.delay(0.08, function() State.hittingCooldown = false end)
end
local function getClosestPlayer()
    if not hrp then return nil, math.huge end
    local cp, cd = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local tr = p.Character:FindFirstChild("HumanoidRootPart")
            if tr then
                local d = (hrp.Position - tr.Position).Magnitude
                if d < cd then
                    cd = d
                    cp = p
                end
            end
        end
    end
    return cp, cd
end
local function applyAntiDie(char, hum)
    pcall(function() hum.BreakJointsOnDeath = false end)
    pcall(function() char.Archivable = true end)
    hum:GetPropertyChangedSignal("Health"):Connect(function()
        if hum.Health <= hum.MaxHealth * 0.15 then
            pcall(function() hum.Health = hum.MaxHealth end)
        end
    end)
    hum.Died:Connect(function()
        pcall(function() hum.Health = hum.MaxHealth end)
    end)
end
local function setupChar(char)
    task.wait(0.1)
    h = char:WaitForChild("Humanoid", 5)
    hrp = char:WaitForChild("HumanoidRootPart", 5)
    if not h or not hrp then return end
    applyAntiDie(char, h)
end
LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end
RunService.Heartbeat:Connect(function()
    if not (State.autoBatToggled and h and hrp) then return end
    local target, dist = getClosestPlayer()
    if target and target.Character then
        local tr = target.Character:FindFirstChild("HumanoidRootPart")
        if tr then
            if sethiddenproperty then
                sethiddenproperty(hrp, "PhysicsRepRootPart", tr)
            end
            local targetPos = tr.Position + Vector3.new(0, 0.9, 0)
            if (hrp.Position - targetPos).Magnitude > 8 then
                hrp.CFrame = CFrame.new(targetPos)
            end
            local cam = workspace.CurrentCamera
            cam.CFrame = CFrame.new(cam.CFrame.Position, tr.Position)
            tryHitBat()
        end
    end
end)
UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if kListening then return end
    if Keys.autoBatType == "Keyboard" and inp.UserInputType == Enum.UserInputType.Keyboard then
        if inp.KeyCode == Keys.autoBat then
            updateToggleVisuals(not State.autoBatToggled)
        elseif inp.KeyCode == Keys.guiHide then
            State.guiVisible = not State.guiVisible
            main.Visible = State.guiVisible
        end
    elseif Keys.autoBatType == "Gamepad" and inp.UserInputType == Enum.UserInputType.Gamepad1 then
        if inp.KeyCode == Keys.autoBat then
            updateToggleVisuals(not State.autoBatToggled)
        end
    end
end)
print("[printed.vs Anti-Desync] Loaded successfully!")
