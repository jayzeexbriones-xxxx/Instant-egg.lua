-- ============================================================
-- 🥔🥔 ULTRA POTATO GRAPHICS (PINAKA-LOW)
-- Maximum FPS - sagad sa sagad
-- ============================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ STATE ============
local Ultra = {
    enabled = false,
    saved = {
        lighting = {},
        terrain = {},
        effects = {},
        materials = {},
        qualityLevel = nil,
        sky = nil,
        atmosphere = nil,
        clouds = nil,
        allChildren = {},
        playerChars = {},
        cameraFOV = nil,
    },
    conns = {},
}

-- ============================================================
-- 🥔🥔 ULTRA POTATO ENABLE
-- ============================================================
function Ultra.enable()
    if Ultra.enabled then return end
    Ultra.enabled = true
    
    -- ============ 1. LIGHTING (ALL) ============
    pcall(function()
        -- Save ALL lighting properties
        for _, prop in ipairs({
            "GlobalShadows", "FogEnd", "FogStart", "FogColor",
            "Brightness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
            "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom",
            "ShadowSoftness", "ExposureCompensation", "ClockTime", "GeographicLatitude",
        }) do
            Ultra.saved.lighting[prop] = Lighting[prop]
        end
        
        -- Apply potato values
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1000000
        Lighting.FogStart = 0
        Lighting.Brightness = 0
        Lighting.EnvironmentDiffuseScale = 0
        Lighting.EnvironmentSpecularScale = 0
        Lighting.Ambient = Color3.fromRGB(200, 200, 200)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
        Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
        Lighting.ShadowSoftness = 0
        Lighting.ExposureCompensation = 0
        Lighting.ClockTime = 12
        Lighting.GeographicLatitude = 0
    end)
    
    -- ============ 2. DELETE SKY + ATMOSPHERE + CLOUDS ============
    pcall(function()
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                Ultra.saved.sky = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            elseif obj:IsA("Atmosphere") then
                Ultra.saved.atmosphere = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            elseif obj:IsA("Clouds") then
                Ultra.saved.clouds = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            end
        end
    end)
    
    -- ============ 3. TERRAIN ============
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for _, prop in ipairs({
                "Decoration", "WaterWaveSize", "WaterWaveSpeed",
                "WaterReflectance", "WaterTransparency",
            }) do
                Ultra.saved.terrain[prop] = terrain[prop]
            end
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
        end
    end)
    
    -- ============ 4. RENDERING QUALITY (PINAKA-LOW) ============
    pcall(function()
        Ultra.saved.qualityLevel = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    
    -- ============ 5. REMOVE ALL EFFECTS (WORKSPACE) ============
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- Particles
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") 
               or obj:IsA("Smoke") or obj:IsA("Fire") 
               or obj:IsA("Sparkles") or obj:IsA("Beam")
               or obj:IsA("Highlight") or obj:IsA("SelectionBox") then
                if obj.Enabled then
                    Ultra.saved.effects[obj] = true
                    obj.Enabled = false
                end
            -- Textures/Decals
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                if obj.Transparency < 1 then
                    Ultra.saved.effects[obj] = obj.Transparency
                    obj.Transparency = 1
                end
            -- SurfaceAppearance
            elseif obj:IsA("SurfaceAppearance") then
                Ultra.saved.effects[obj] = obj.Parent
                obj.Parent = nil
            -- Lights
            elseif obj:IsA("PointLight") or obj:IsA("SpotLight") 
                or obj:IsA("SurfaceLight") then
                if obj.Enabled then
                    Ultra.saved.effects[obj] = true
                    obj.Enabled = false
                end
            -- Gui
            elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                if obj.Enabled then
                    Ultra.saved.effects[obj] = true
                    obj.Enabled = false
                end
            end
        end
    end)
    
    -- ============ 6. POST-PROCESSING (LIGHTING) ============
    pcall(function()
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if obj:IsA("PostEffect") and obj.Enabled then
                Ultra.saved.effects[obj] = true
                obj.Enabled = false
            end
        end
    end)
    
    -- ============ 7. MATERIALS (SMOOTHPLASTIC ALL) ============
    pcall(function()
        local count = 0
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                Ultra.saved.materials[part] = {
                    Material = part.Material,
                    Reflectance = part.Reflectance,
                    CastShadow = part.CastShadow,
                }
                part.Material = Enum.Material.SmoothPlastic
                part.Reflectance = 0
                part.CastShadow = false
                count = count + 1
                if count >= 10000 then break end
            end
        end
    end)
    
    -- ============ 8. FOV (MAX) ============
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            Ultra.saved.cameraFOV = cam.FieldOfView
            cam.FieldOfView = 120
        end
    end)
    
    -- ============ 9. HIDE OTHER PLAYERS ============
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                Ultra.saved.playerChars[plr.Character] = plr.Character.Parent
                plr.Character.Parent = nil
            end
        end
    end)
    
    -- ============ 10. STOP NEW EFFECTS ============
    local conn1 = Workspace.DescendantAdded:Connect(function(obj)
        if not Ultra.enabled then return end
        pcall(function()
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") 
               or obj:IsA("Smoke") or obj:IsA("Fire") 
               or obj:IsA("Sparkles") or obj:IsA("Beam")
               or obj:IsA("Highlight") or obj:IsA("SelectionBox")
               or obj:IsA("PointLight") or obj:IsA("SpotLight") 
               or obj:IsA("SurfaceLight") or obj:IsA("BillboardGui") 
               or obj:IsA("SurfaceGui") then
                obj.Enabled = false
            elseif obj:IsA("BasePart") then
                obj.Material = Enum.Material.SmoothPlastic
                obj.Reflectance = 0
                obj.CastShadow = false
            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                obj.Transparency = 1
            elseif obj:IsA("SurfaceAppearance") then
                obj.Parent = nil
            end
        end)
    end)
    table.insert(Ultra.conns, conn1)
    
    local conn2 = Lighting.DescendantAdded:Connect(function(obj)
        if not Ultra.enabled then return end
        if obj:IsA("PostEffect") or obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
            obj.Parent = nil
        end
    end)
    table.insert(Ultra.conns, conn2)
    
    -- Stop new players from spawning
    local conn3 = Players.PlayerAdded:Connect(function(plr)
        if not Ultra.enabled then return end
        task.wait(1)
        if plr.Character then
            Ultra.saved.playerChars[plr.Character] = plr.Character.Parent
            plr.Character.Parent = nil
        end
        plr.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if Ultra.enabled then
                Ultra.saved.playerChars[char] = char.Parent
                char.Parent = nil
            end
        end)
    end)
    table.insert(Ultra.conns, conn3)
    
    -- FPS cap (unlock)
    pcall(function()
        if setfpscap then setfpscap(240) end
    end)
    
    print("[ULTRA] 🥔🥔 ULTRA POTATO GRAPHICS ENABLED")
end

-- ============================================================
-- 🥔🥔 DISABLE / RESTORE
-- ============================================================
function Ultra.disable()
    if not Ultra.enabled then return end
    Ultra.enabled = false
    
    -- Restore lighting
    pcall(function()
        for prop, value in pairs(Ultra.saved.lighting) do
            Lighting[prop] = value
        end
    end)
    
    -- Restore sky/atmosphere/clouds
    pcall(function()
        if Ultra.saved.sky and Ultra.saved.sky.instance then
            Ultra.saved.sky.instance.Parent = Ultra.saved.sky.parent
        end
        if Ultra.saved.atmosphere and Ultra.saved.atmosphere.instance then
            Ultra.saved.atmosphere.instance.Parent = Ultra.saved.atmosphere.parent
        end
        if Ultra.saved.clouds and Ultra.saved.clouds.instance then
            Ultra.saved.clouds.instance.Parent = Ultra.saved.clouds.parent
        end
    end)
    
    -- Restore terrain
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for prop, value in pairs(Ultra.saved.terrain) do
                terrain[prop] = value
            end
        end
    end)
    
    -- Restore quality
    pcall(function()
        if Ultra.saved.qualityLevel then
            settings().Rendering.QualityLevel = Ultra.saved.qualityLevel
        end
    end)
    
    -- Restore effects
    pcall(function()
        for obj, value in pairs(Ultra.saved.effects) do
            if obj and obj.Parent then
                if type(value) == "boolean" then
                    obj.Enabled = value
                elseif type(value) == "number" then
                    obj.Transparency = value
                elseif typeof(value) == "Instance" then
                    obj.Parent = value
                end
            end
        end
    end)
    
    -- Restore materials
    pcall(function()
        for part, data in pairs(Ultra.saved.materials) do
            if part and part.Parent then
                part.Material = data.Material
                part.Reflectance = data.Reflectance
                part.CastShadow = data.CastShadow
            end
        end
    end)
    
    -- Restore FOV
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and Ultra.saved.cameraFOV then
            cam.FieldOfView = Ultra.saved.cameraFOV
        end
    end)
    
    -- Restore players
    pcall(function()
        for char, parent in pairs(Ultra.saved.playerChars) do
            if char and char.Parent == nil and parent then
                char.Parent = parent
            end
        end
    end)
    
    -- Disconnect
    for _, conn in ipairs(Ultra.conns) do
        pcall(function() conn:Disconnect() end)
    end
    Ultra.conns = {}
    
    -- Clear
    Ultra.saved = {
        lighting = {}, terrain = {}, effects = {},
        materials = {}, qualityLevel = nil, sky = nil,
        atmosphere = nil, clouds = nil, allChildren = {},
        playerChars = {}, cameraFOV = nil,
    }
    
    print("[ULTRA] 🥔🥔 ULTRA POTATO DISABLED - restored")
end

-- ============================================================
-- 🥔🥔 UI
-- ============================================================
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    STROKE = Color3.fromRGB(60, 60, 70),
    TEXT = Color3.fromRGB(255, 255, 255),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
    YELLOW = Color3.fromRGB(255, 200, 0),
    BROWN = Color3.fromRGB(180, 130, 70),
    DARK_BROWN = Color3.fromRGB(120, 80, 40),
}

local function createUltraUI()
    if CoreGui:FindFirstChild("UltraPotatoUI") then
        CoreGui.UltraPotatoUI:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "UltraPotatoUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 260, 0, 150)
    Main.Position = UDim2.new(0.5, -130, 0.5, -75)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = COLORS.DARK_BROWN
    
    -- Title
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
    Title.Text = "🥔🥔 ULTRA POTATO"
    Title.TextColor3 = COLORS.BROWN
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
    
    -- Toggle
    local lbl = Instance.new("TextLabel", Main)
    lbl.Size = UDim2.new(1, -100, 0, 25)
    lbl.Position = UDim2.new(0, 12, 0, 45)
    lbl.BackgroundTransparency = 1
    lbl.Text = "🥔 Ultra Mode"
    lbl.TextColor3 = COLORS.TEXT
    lbl.TextSize = 13
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
    
    -- Info lines
    local Info1 = Instance.new("TextLabel", Main)
    Info1.Size = UDim2.new(1, -24, 0, 18)
    Info1.Position = UDim2.new(0, 12, 0, 78)
    Info1.BackgroundTransparency = 1
    Info1.Text = "⚡ FPS cap: 240 (unlocked)"
    Info1.TextColor3 = COLORS.YELLOW
    Info1.TextSize = 10
    Info1.Font = Enum.Font.Gotham
    Info1.TextXAlignment = Enum.TextXAlignment.Left
    
    local Info2 = Instance.new("TextLabel", Main)
    Info2.Size = UDim2.new(1, -24, 0, 18)
    Info2.Position = UDim2.new(0, 12, 0, 95)
    Info2.BackgroundTransparency = 1
    Info2.Text = "🥔 Hide players + effects"
    Info2.TextColor3 = COLORS.CYAN or Color3.fromRGB(80, 200, 255)
    Info2.TextSize = 10
    Info2.Font = Enum.Font.Gotham
    Info2.TextXAlignment = Enum.TextXAlignment.Left
    
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -24, 0, 18)
    Status.Position = UDim2.new(0, 12, 0, 112)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 10
    Status.Font = Enum.Font.GothamBold
    Status.TextXAlignment = Enum.TextXAlignment.Left
    
    return {
        ScreenGui = ScreenGui,
        track = track,
        knob = knob,
        stateLbl = stateLbl,
        btn = btn,
        Status = Status,
        CloseBtn = CloseBtn,
    }
end

local ui = createUltraUI()

local function setUltraToggle(on)
    ui.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    ui.knob.Position = on and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    ui.stateLbl.Text = on and "ON" or "OFF"
    ui.stateLbl.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.btn.MouseButton1Click:Connect(function()
    if not Ultra.enabled then
        setUltraToggle(true)
        ui.Status.Text = "🥔 Enabling ULTRA..."
        ui.Status.TextColor3 = COLORS.YELLOW
        task.spawn(function()
            Ultra.enable()
            task.wait(1)
            ui.Status.Text = "🥔🥔 ULTRA ACTIVE | Max FPS"
            ui.Status.TextColor3 = COLORS.GREEN
        end)
    else
        setUltraToggle(false)
        ui.Status.Text = "Restoring..."
        ui.Status.TextColor3 = COLORS.YELLOW
        task.spawn(function()
            Ultra.disable()
            task.wait(1)
            ui.Status.Text = "⚡ Restored to normal"
            ui.Status.TextColor3 = COLORS.YELLOW
        end)
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    if Ultra.enabled then Ultra.disable() end
    ui.ScreenGui:Destroy()
end)
