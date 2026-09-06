repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local HS = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer

-- ============================================================
-- VARIABLES PRINCIPALES
-- ============================================================
local Steal = {
    AutoStealEnabled = false,
    StealRadius = 61,
    StealDuration = 1.3,
    StealDelay = 0.25,
    Data = {}
}

local isStealing = false
local autoGrabSetDelayRadius = 9
local autoGrabStopTime = 0.96
local autoGrabStopEnabled = true

local Conns = { autoSteal = nil }

local progressFill = nil
local progressPct = nil
local progressRadLbl = nil

-- ============================================================
-- VARIABLES DE ESCALA
-- ============================================================
local currentScale = 1.0
local mainFrame = nil
local mainFrameObjects = {}

-- ============================================================
-- FUNCIONES UTILITY
-- ============================================================
local function isMyPlotByName(plotName)
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return false end
    local plot = plots:FindFirstChild(plotName)
    if not plot then return false end
    local sign = plot:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then
            return yb.Enabled == true
        end
    end
    return false
end

local function findNearestPrompt()
    local char = LP.Character
    if not char then return nil, nil end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil, nil end
    local plots = workspace:FindFirstChild("Plots")
    if not plots then return nil, nil end

    local nearestPrompt, nearestDist, nearestName = nil, math.huge, nil

    for _, plot in ipairs(plots:GetChildren()) do
        if isMyPlotByName(plot.Name) then continue end
        local pods = plot:FindFirstChild("AnimalPodiums")
        if not pods then continue end
        for _, pod in ipairs(pods:GetChildren()) do
            pcall(function()
                local base = pod:FindFirstChild("Base")
                local spawn = base and base:FindFirstChild("Spawn")
                if spawn then
                    local dist = (spawn.Position - root.Position).Magnitude
                    if dist < nearestDist and dist <= Steal.StealRadius then
                        local att = spawn:FindFirstChild("PromptAttachment")
                        if att then
                            for _, child in ipairs(att:GetChildren()) do
                                if child:IsA("ProximityPrompt") and child.ActionText and child.ActionText:find("Steal") then
                                    nearestPrompt = child
                                    nearestDist = dist
                                    nearestName = pod.Name
                                    break
                                end
                            end
                        end
                    end
                end
            end)
        end
    end

    return nearestPrompt, nearestName
end

-- ============================================================
-- EXECUTE STEAL
-- ============================================================
local function executeSteal(prompt, podName)
    if isStealing then return end

    if not Steal.Data[prompt] then
        Steal.Data[prompt] = { hold = {}, trigger = {}, ready = true }
        pcall(function()
            if getconnections then
                for _, c in ipairs(getconnections(prompt.PromptButtonHoldBegan)) do
                    if c.Function then table.insert(Steal.Data[prompt].hold, c.Function) end
                end
                for _, c in ipairs(getconnections(prompt.Triggered)) do
                    if c.Function then table.insert(Steal.Data[prompt].trigger, c.Function) end
                end
            end
        end)
    end

    local data = Steal.Data[prompt]
    if not data.ready then return end
    data.ready = false
    isStealing = true

    if progressFill then
        progressFill.Size = UDim2.new(0, 0, 1, 0)
    end
    if progressPct then
        progressPct.Text = "0%"
    end

    task.spawn(function()
        for _, f in ipairs(data.hold) do task.spawn(f) end

        local startTime = tick()
        local duration = Steal.StealDuration
        local promptFired = false

        if autoGrabStopEnabled then
            while isStealing and Steal.AutoStealEnabled do
                local elapsed = tick() - startTime
                if elapsed >= autoGrabStopTime then break end
                if progressFill then
                    progressFill.Size = UDim2.new(math.clamp(elapsed / duration, 0, 1), 0, 1, 0)
                end
                if progressPct then
                    progressPct.Text = math.floor(math.clamp(elapsed / duration, 0, 1) * 100) .. "%"
                end
                if not prompt.Parent or not prompt.Parent.Parent then break end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - prompt.Parent.Parent.Position).Magnitude > Steal.StealRadius then
                    break
                end
                task.wait()
            end

            local stopProgress = math.clamp(autoGrabStopTime / duration, 0, 1)
            if progressFill then
                progressFill.Size = UDim2.new(stopProgress, 0, 1, 0)
            end
            if progressPct then
                progressPct.Text = math.floor(stopProgress * 100) .. "%"
            end

            local phase2Timeout = math.max(2.99 - autoGrabStopTime - math.max(duration - autoGrabStopTime, 0), 0.05)
            local phase2Start = tick()

            while isStealing and Steal.AutoStealEnabled do
                if tick() - phase2Start >= phase2Timeout then
                    if progressFill then progressFill.Size = UDim2.new(0, 0, 1, 0) end
                    if progressPct then progressPct.Text = "0%" end
                    data.ready = true
                    isStealing = false
                    task.wait()
                    local newPrompt, newName = findNearestPrompt()
                    if newPrompt then executeSteal(newPrompt, newName) end
                    return
                end
                if not prompt.Parent or not prompt.Parent.Parent then
                    isStealing = false
                    if progressFill then progressFill.Size = UDim2.new(0, 0, 1, 0) end
                    if progressPct then progressPct.Text = "0%" end
                    data.ready = true
                    return
                end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local dist = (hrp.Position - prompt.Parent.Parent.Position).Magnitude
                    if dist <= autoGrabSetDelayRadius then
                        break
                    elseif dist > Steal.StealRadius then
                        isStealing = false
                        if progressFill then progressFill.Size = UDim2.new(0, 0, 1, 0) end
                        if progressPct then progressPct.Text = "0%" end
                        data.ready = true
                        return
                    end
                end
                task.wait()
            end

            if isStealing and Steal.AutoStealEnabled then
                local fillStart = tick()
                local fillDuration = math.max(duration - autoGrabStopTime, 0.05)
                while true do
                    local fp = math.clamp((tick() - fillStart) / fillDuration, 0, 1)
                    if progressFill then
                        progressFill.Size = UDim2.new(stopProgress + fp * (1 - stopProgress), 0, 1, 0)
                    end
                    if progressPct then
                        progressPct.Text = math.floor((stopProgress + fp * (1 - stopProgress)) * 100) .. "%"
                    end
                    if fp >= 1 and not promptFired then
                        promptFired = true
                        pcall(function()
                            for _, f in ipairs(data.trigger) do task.spawn(f) end
                            local remote = ReplicatedStorage:FindFirstChild("StealAnimal")
                            if remote and podName then
                                remote:FireServer(podName)
                            end
                            if prompt then
                                prompt:Fire()
                            end
                        end)
                        break
                    end
                    task.wait()
                end
            end
        else
            while isStealing and Steal.AutoStealEnabled do
                local elapsed = tick() - startTime
                local progress = math.clamp(elapsed / duration, 0, 1)
                if progressFill then progressFill.Size = UDim2.new(progress, 0, 1, 0) end
                if progressPct then progressPct.Text = math.floor(progress * 100) .. "%" end
                if not prompt.Parent or not prompt.Parent.Parent then break end
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - prompt.Parent.Parent.Position).Magnitude > Steal.StealRadius then
                    break
                end
                if elapsed >= duration and not promptFired then
                    promptFired = true
                    pcall(function()
                        for _, f in ipairs(data.trigger) do task.spawn(f) end
                        local remote = ReplicatedStorage:FindFirstChild("StealAnimal")
                        if remote and podName then remote:FireServer(podName) end
                        if prompt then prompt:Fire() end
                    end)
                    break
                end
                task.wait()
            end
        end

        if progressFill then progressFill.Size = UDim2.new(0, 0, 1, 0) end
        if progressPct then progressPct.Text = "0%" end
        data.ready = true
        isStealing = false
    end)
end

-- ============================================================
-- START / STOP AUTO STEAL
-- ============================================================
local function startAutoSteal()
    if Conns.autoSteal then return end
    Conns.autoSteal = RunService.Heartbeat:Connect(function()
        if not Steal.AutoStealEnabled or isStealing then return end
        local p, n = findNearestPrompt()
        if p then executeSteal(p, n) end
    end)
end

local function stopAutoSteal()
    if Conns.autoSteal then
        Conns.autoSteal:Disconnect()
        Conns.autoSteal = nil
    end
    isStealing = false
    if progressFill then
        TS:Create(progressFill, TweenInfo.new(0.2), { Size = UDim2.new(0, 0, 1, 0) }):Play()
    end
    if progressPct then progressPct.Text = "0%" end
end

-- ============================================================
-- CREAR GUI
-- ============================================================
local function createGUI()
    local CoreGui = game:GetService("CoreGui")
    local oldGui = CoreGui:FindFirstChild("AutoStealBar")
    if oldGui then oldGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AutoStealBar"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 999
    gui.Parent = CoreGui

    -- ==========================================================
    -- BARRA PRINCIPAL
    -- ==========================================================
    local baseWidth = 250
    local baseHeight = 55
    local barWidth = baseWidth * currentScale
    local barHeight = baseHeight * currentScale
    
    mainFrame = Instance.new("Frame", gui)
    mainFrame.Size = UDim2.new(0, barWidth, 0, barHeight)
    mainFrame.Position = UDim2.new(0.5, -(barWidth / 2), 0.5, -(barHeight / 2))
    mainFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    mainFrame.BackgroundTransparency = 0.15
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 10
    mainFrame.Active = true
    mainFrame.Draggable = false
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)

    -- BORDE
    local border = Instance.new("UIStroke", mainFrame)
    border.Color = Color3.fromRGB(120, 120, 120)
    border.Thickness = 1.5

    -- ==========================================================
    -- CONTENIDO
    -- ==========================================================
    local fontSize = 14 * currentScale
    local smallFont = 10 * currentScale
    local pctFont = 12 * currentScale
    local labelSizeX = 70 * currentScale
    local labelSizeY = 18 * currentScale
    local radiusSizeX = 90 * currentScale
    local radiusSizeY = 14 * currentScale
    local barWidthPct = 0.78
    local barHeightPct = 14 * currentScale
    local barYPos = 28 * currentScale
    local pctXPos = 0.72
    local pctYPos = 27 * currentScale
    local pctSizeX = 40 * currentScale
    local pctSizeY = 16 * currentScale
    local lockSize = 16 * currentScale
    local lockYPos = 0.2
    local v1SizeX = 22 * currentScale
    local v1SizeY = 14 * currentScale
    local v1YOffset = -7 * currentScale
    local toggleW = 38 * currentScale
    local toggleH = 18 * currentScale
    local toggleX = -44 * currentScale
    local btnSize = 16 * currentScale

    -- ==========================================================
    -- Y/out + by Benja (abajo)
    -- ==========================================================
    -- Etiqueta "Y/out"
    local label = Instance.new("TextLabel", mainFrame)
    label.Size = UDim2.new(0, labelSizeX, 0, labelSizeY)
    label.Position = UDim2.new(0, 8 * currentScale, 0, 1 * currentScale)
    label.BackgroundTransparency = 1
    label.Text = "Y/out"
    label.TextColor3 = Color3.fromRGB(140, 140, 140)
    label.Font = Enum.Font.GothamBlack
    label.TextSize = fontSize
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 12
    table.insert(mainFrameObjects, label)

    -- Etiqueta "by Benja" (pequeño debajo de Y/out)
    local byLabel = Instance.new("TextLabel", mainFrame)
    byLabel.Size = UDim2.new(0, 60 * currentScale, 0, 12 * currentScale)
    byLabel.Position = UDim2.new(0, 8 * currentScale, 0, 16 * currentScale)
    byLabel.BackgroundTransparency = 1
    byLabel.Text = "by Benja"
    byLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
    byLabel.Font = Enum.Font.GothamBlack
    byLabel.TextSize = 7 * currentScale
    byLabel.TextXAlignment = Enum.TextXAlignment.Left
    byLabel.ZIndex = 12
    table.insert(mainFrameObjects, byLabel)

    -- Texto "Radius: 61"
    progressRadLbl = Instance.new("TextLabel", mainFrame)
    progressRadLbl.Size = UDim2.new(0, radiusSizeX, 0, radiusSizeY)
    progressRadLbl.Position = UDim2.new(1, -95 * currentScale, 0, 4 * currentScale)
    progressRadLbl.BackgroundTransparency = 1
    progressRadLbl.Text = string.format("Radius: %.2g", Steal.StealRadius)
    progressRadLbl.TextColor3 = Color3.fromRGB(120, 120, 120)
    progressRadLbl.Font = Enum.Font.GothamBlack
    progressRadLbl.TextSize = smallFont
    progressRadLbl.TextXAlignment = Enum.TextXAlignment.Right
    progressRadLbl.ZIndex = 12
    table.insert(mainFrameObjects, progressRadLbl)

    -- Fondo de la barra de progreso
    local barBg = Instance.new("Frame", mainFrame)
    barBg.Size = UDim2.new(barWidthPct, -10 * currentScale, 0, barHeightPct)
    barBg.Position = UDim2.new(0, 8 * currentScale, 0, barYPos)
    barBg.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    barBg.BackgroundTransparency = 0.2
    barBg.ZIndex = 11
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(1, 0)
    table.insert(mainFrameObjects, barBg)

    -- Barra de progreso (fill)
    progressFill = Instance.new("Frame", barBg)
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = Color3.fromRGB(140, 140, 140)
    progressFill.ZIndex = 12
    Instance.new("UICorner", progressFill).CornerRadius = UDim.new(1, 0)
    table.insert(mainFrameObjects, progressFill)

    -- Texto del porcentaje
    progressPct = Instance.new("TextLabel", mainFrame)
    progressPct.Size = UDim2.new(0, pctSizeX, 0, pctSizeY)
    progressPct.Position = UDim2.new(pctXPos, -15 * currentScale, 0, pctYPos)
    progressPct.BackgroundTransparency = 1
    progressPct.Text = "0%"
    progressPct.TextColor3 = Color3.fromRGB(140, 140, 140)
    progressPct.Font = Enum.Font.GothamBlack
    progressPct.TextSize = pctFont
    progressPct.ZIndex = 13
    table.insert(mainFrameObjects, progressPct)

    -- ==========================================================
    -- V1 (IZQUIERDA DEL CANDADO)
    -- ==========================================================
    local v1Frame = Instance.new("Frame", mainFrame)
    v1Frame.Size = UDim2.new(0, v1SizeX, 0, v1SizeY)
    v1Frame.Position = UDim2.new(0.5, -(lockSize / 2) - v1SizeX - 6 * currentScale, lockYPos, v1YOffset)
    v1Frame.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    v1Frame.BackgroundTransparency = 0.1
    v1Frame.BorderSizePixel = 0
    v1Frame.ZIndex = 14
    Instance.new("UICorner", v1Frame).CornerRadius = UDim.new(0, 3)
    table.insert(mainFrameObjects, v1Frame)
    
    local v1Border = Instance.new("UIStroke", v1Frame)
    v1Border.Color = Color3.fromRGB(140, 140, 140)
    v1Border.Thickness = 1.5
    
    local v1Label = Instance.new("TextLabel", v1Frame)
    v1Label.Size = UDim2.new(1, 0, 1, 0)
    v1Label.Position = UDim2.new(0, 0, 0, 0)
    v1Label.BackgroundTransparency = 1
    v1Label.Text = "V1"
    v1Label.TextColor3 = Color3.fromRGB(140, 140, 140)
    v1Label.Font = Enum.Font.GothamBlack
    v1Label.TextSize = 9 * currentScale
    v1Label.TextXAlignment = Enum.TextXAlignment.Center
    v1Label.TextYAlignment = Enum.TextYAlignment.Center
    v1Label.ZIndex = 15
    table.insert(mainFrameObjects, v1Label)

    -- ==========================================================
    -- CANDADO (CENTRO)
    -- ==========================================================
    local isLocked = true
    local lockBtn = Instance.new("TextButton", mainFrame)
    lockBtn.Size = UDim2.new(0, lockSize, 0, lockSize)
    lockBtn.Position = UDim2.new(0.5, -(lockSize / 2), lockYPos, -(lockSize / 2))
    lockBtn.BackgroundTransparency = 1
    lockBtn.Text = "🔒"
    lockBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
    lockBtn.Font = Enum.Font.GothamBlack
    lockBtn.TextSize = 12 * currentScale
    lockBtn.ZIndex = 15
    lockBtn.Visible = true
    table.insert(mainFrameObjects, lockBtn)

    -- ==========================================================
    -- BOTONES - Y + (DERECHA DEL CANDADO)
    -- ==========================================================
    local minusBtn = Instance.new("TextButton", mainFrame)
    minusBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    minusBtn.Position = UDim2.new(0.5, lockSize / 2 + 4 * currentScale, lockYPos, -(btnSize / 2))
    minusBtn.BackgroundTransparency = 1
    minusBtn.Text = "−"
    minusBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
    minusBtn.Font = Enum.Font.GothamBlack
    minusBtn.TextSize = 12 * currentScale
    minusBtn.ZIndex = 15
    minusBtn.Visible = true
    table.insert(mainFrameObjects, minusBtn)

    local plusBtn = Instance.new("TextButton", mainFrame)
    plusBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
    plusBtn.Position = UDim2.new(0.5, lockSize / 2 + btnSize + 10 * currentScale, lockYPos, -(btnSize / 2))
    plusBtn.BackgroundTransparency = 1
    plusBtn.Text = "+"
    plusBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
    plusBtn.Font = Enum.Font.GothamBlack
    plusBtn.TextSize = 12 * currentScale
    plusBtn.ZIndex = 15
    plusBtn.Visible = true
    table.insert(mainFrameObjects, plusBtn)

    -- ==========================================================
    -- BOTÓN ON/OFF
    -- ==========================================================
    local toggleBtn = Instance.new("TextButton", mainFrame)
    toggleBtn.Size = UDim2.new(0, toggleW, 0, toggleH)
    toggleBtn.Position = UDim2.new(1, toggleX, 0.5, -(toggleH / 2))
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    toggleBtn.BackgroundTransparency = 0.2
    toggleBtn.Text = "OFF"
    toggleBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
    toggleBtn.Font = Enum.Font.GothamBlack
    toggleBtn.TextSize = 10 * currentScale
    toggleBtn.ZIndex = 14
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 4)
    table.insert(mainFrameObjects, toggleBtn)
    
    local toggleBorder = Instance.new("UIStroke", toggleBtn)
    toggleBorder.Color = Color3.fromRGB(120, 120, 120)
    toggleBorder.Thickness = 1
    table.insert(mainFrameObjects, toggleBorder)

    -- ==========================================================
    -- FUNCIONES DE ESCALA
    -- ==========================================================
    local function actualizarEscala()
        local newWidth = baseWidth * currentScale
        local newHeight = baseHeight * currentScale
        mainFrame.Size = UDim2.new(0, newWidth, 0, newHeight)
        mainFrame.Position = UDim2.new(0.5, -(newWidth / 2), 0.5, -(newHeight / 2))
        
        local lockSize = 16 * currentScale
        local btnSize = 16 * currentScale
        local v1SizeX = 22 * currentScale
        
        lockBtn.Position = UDim2.new(0.5, -(lockSize / 2), lockYPos, -(lockSize / 2))
        lockBtn.Size = UDim2.new(0, lockSize, 0, lockSize)
        lockBtn.TextSize = 12 * currentScale
        
        v1Frame.Position = UDim2.new(0.5, -(lockSize / 2) - v1SizeX - 6 * currentScale, lockYPos, -7 * currentScale)
        v1Frame.Size = UDim2.new(0, v1SizeX, 0, 14 * currentScale)
        v1Label.TextSize = 9 * currentScale
        
        minusBtn.Position = UDim2.new(0.5, lockSize / 2 + 4 * currentScale, lockYPos, -(btnSize / 2))
        minusBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
        minusBtn.TextSize = 12 * currentScale
        
        plusBtn.Position = UDim2.new(0.5, lockSize / 2 + btnSize + 10 * currentScale, lockYPos, -(btnSize / 2))
        plusBtn.Size = UDim2.new(0, btnSize, 0, btnSize)
        plusBtn.TextSize = 12 * currentScale
        
        for _, obj in ipairs(mainFrameObjects) do
            if obj:IsA("TextLabel") then
                if obj.Text == "Y/out" then
                    obj.TextSize = 14 * currentScale
                    obj.Size = UDim2.new(0, 70 * currentScale, 0, 18 * currentScale)
                    obj.Position = UDim2.new(0, 8 * currentScale, 0, 1 * currentScale)
                elseif obj.Text == "by Benja" then
                    obj.TextSize = 7 * currentScale
                    obj.Size = UDim2.new(0, 60 * currentScale, 0, 12 * currentScale)
                    obj.Position = UDim2.new(0, 8 * currentScale, 0, 16 * currentScale)
                elseif obj.Text == "0%" or obj.Text:match("%d+%%") then
                    obj.TextSize = 12 * currentScale
                    obj.Size = UDim2.new(0, 40 * currentScale, 0, 16 * currentScale)
                    obj.Position = UDim2.new(0.72, -15 * currentScale, 0, 27 * currentScale)
                elseif obj.Text:match("Radius:") then
                    obj.TextSize = 10 * currentScale
                    obj.Size = UDim2.new(0, 90 * currentScale, 0, 14 * currentScale)
                    obj.Position = UDim2.new(1, -95 * currentScale, 0, 4 * currentScale)
                elseif obj.Text == "V1" then
                    obj.TextSize = 9 * currentScale
                end
            elseif obj:IsA("TextButton") then
                if obj.Text == "OFF" or obj.Text == "ON" then
                    obj.Size = UDim2.new(0, 38 * currentScale, 0, 18 * currentScale)
                    obj.TextSize = 10 * currentScale
                    obj.Position = UDim2.new(1, -44 * currentScale, 0.5, -(18 * currentScale / 2))
                end
            elseif obj:IsA("Frame") then
                if obj.Parent == mainFrame and obj:FindFirstChild("V1") then
                    -- Ya se actualizó arriba
                elseif obj.Parent == mainFrame and obj:FindFirstChildOfClass("Frame") then
                    obj.Size = UDim2.new(0.78, -10 * currentScale, 0, 14 * currentScale)
                    obj.Position = UDim2.new(0, 8 * currentScale, 0, 28 * currentScale)
                end
            end
        end
    end

    -- ==========================================================
    -- FUNCIONES DE COLORES (GRIS ↔ BLANCO)
    -- ==========================================================
    local function setColorsGray()
        local gray = Color3.fromRGB(120, 120, 120)
        local grayLight = Color3.fromRGB(140, 140, 140)
        local grayDark = Color3.fromRGB(60, 60, 60)
        
        border.Color = gray
        v1Border.Color = grayLight
        v1Label.TextColor3 = grayLight
        v1Frame.BackgroundColor3 = grayDark
        progressFill.BackgroundColor3 = grayLight
        barBg.BackgroundColor3 = grayDark
        label.TextColor3 = grayLight
        byLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
        progressRadLbl.TextColor3 = gray
        progressPct.TextColor3 = grayLight
        minusBtn.TextColor3 = grayLight
        plusBtn.TextColor3 = grayLight
        if isLocked then
            lockBtn.TextColor3 = gray
        end
        toggleBtn.TextColor3 = grayLight
        toggleBorder.Color = gray
        toggleBtn.BackgroundColor3 = grayDark
    end

    local function setColorsWhite()
        local white = Color3.fromRGB(220, 220, 220)
        local whiteDark = Color3.fromRGB(40, 40, 40)
        
        border.Color = Color3.fromRGB(200, 200, 200)
        v1Border.Color = white
        v1Label.TextColor3 = white
        v1Frame.BackgroundColor3 = whiteDark
        progressFill.BackgroundColor3 = white
        barBg.BackgroundColor3 = whiteDark
        label.TextColor3 = white
        byLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        progressRadLbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        progressPct.TextColor3 = white
        minusBtn.TextColor3 = white
        plusBtn.TextColor3 = white
        if isLocked then
            lockBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
        end
        toggleBtn.TextColor3 = white
        toggleBorder.Color = Color3.fromRGB(200, 200, 200)
        toggleBtn.BackgroundColor3 = whiteDark
    end

    -- ==========================================================
    -- FUNCIONALIDAD CANDADO
    -- ==========================================================
    local function actualizarCandado()
        if isLocked then
            lockBtn.Text = "🔒"
            if Steal.AutoStealEnabled then
                lockBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
            else
                lockBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
            end
            mainFrame.Draggable = false
        else
            lockBtn.Text = "🔓"
            lockBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
            mainFrame.Draggable = true
        end
    end

    lockBtn.MouseButton1Click:Connect(function()
        isLocked = not isLocked
        actualizarCandado()
        TS:Create(lockBtn, TweenInfo.new(0.2), {
            TextSize = isLocked and 12 * currentScale or 14 * currentScale
        }):Play()
    end)

    -- ==========================================================
    -- FUNCIONALIDAD DE ESCALA (- y +)
    -- ==========================================================
    minusBtn.MouseButton1Click:Connect(function()
        currentScale = math.max(0.5, currentScale - 0.1)
        actualizarEscala()
        print("📏 Escala: " .. string.format("%.1f", currentScale))
    end)

    plusBtn.MouseButton1Click:Connect(function()
        currentScale = math.min(2.0, currentScale + 0.1)
        actualizarEscala()
        print("📏 Escala: " .. string.format("%.1f", currentScale))
    end)

    -- ==========================================================
    -- FUNCIONALIDAD TOGGLE
    -- ==========================================================
    toggleBtn.MouseButton1Click:Connect(function()
        Steal.AutoStealEnabled = not Steal.AutoStealEnabled
        
        if Steal.AutoStealEnabled then
            toggleBtn.Text = "ON"
            toggleBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            toggleBtn.BackgroundTransparency = 0.2
            toggleBorder.Color = Color3.fromRGB(200, 200, 200)
            setColorsWhite()
            startAutoSteal()
            print("✅ AUTO STEAL ACTIVADO | Radius: 61 | Delay: 9 | Stop: 0.96")
        else
            toggleBtn.Text = "OFF"
            toggleBtn.TextColor3 = Color3.fromRGB(140, 140, 140)
            toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            toggleBtn.BackgroundTransparency = 0.2
            toggleBorder.Color = Color3.fromRGB(120, 120, 120)
            setColorsGray()
            stopAutoSteal()
            print("❌ AUTO STEAL DESACTIVADO")
        end
        actualizarCandado()
    end)

    -- ==========================================================
    -- ACTUALIZAR ESTADO INICIAL
    -- ==========================================================
    actualizarCandado()
    setColorsGray()
end

-- ============================================================
-- INICIAR
-- ============================================================
createGUI()

print("🚀 Y/out - AUTO GRAB CARGADO")
print("📊 Configuraciones:")
print("   Radius: 61")
print("   Duration: 1.3")
print("   Delay Radius: 9")
print("   Stop Time: 0.96")
print("   Stop Time Mode: ACTIVADO")
print("💡 Presiona el botón ON para activar el robo automático")
print("📏 Usa - y + para ajustar el tamaño")
    
