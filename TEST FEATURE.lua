-- ============================================================
-- 🥔🥔🥔 SUPER POTATO GRAPHICS — SAFE VERSION
-- Removes VISUAL only — gameplay objects SAFE
-- ============================================================

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============ STATE ============
local Super = {
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
        playerChars = {},
        cameraFOV = nil,
        detached = {},
    },
    conns = {},
}

-- ============================================================
-- 🛡️ SAFE DETACH HELPERS
-- ============================================================

local function detach(obj, tag)
    if not obj or not obj.Parent then return end
    if Super.saved.detached[obj] then return end
    Super.saved.detached[obj] = obj.Parent
    obj.Parent = nil
end

-- 🛡️ SAFE: Placed eggs ONLY (hindi field eggs)
local function isPlacedEgg(obj)
    if not obj then return false end
    local placedParent = Workspace:FindFirstChild("PlacedEggRenders")
    if placedParent and obj:IsDescendantOf(placedParent) then
        return true
    end
    return false
end

-- 🛡️ SAFE: Base/Plots ONLY (hindi gameplay area)
local function isBaseModel(obj)
    if not obj then return false end
    -- Exclude kung nasa __OBJECTS.Areas (gameplay area — dapat i-keep)
    local objects = Workspace:FindFirstChild("__OBJECTS")
    if objects then
        local areas = objects:FindFirstChild("Areas")
        if areas and obj:IsDescendantOf(areas) then
            return false  -- ❌ Hindi ito base, gameplay area 'to
        end
    end
    
    local name = string.lower(obj.Name)
    return name:find("base") or name:find("plot") 
        or name:find("house") or name:find("pen")
end

-- 🛡️ SAFE: Accessories ONLY
local function isAccessory(obj)
    if not obj then return false end
    return obj:IsA("Accessory") or obj:IsA("Hat") 
        or obj:IsA("Shirt") or obj:IsA("Pants") 
        or obj:IsA("ShirtGraphic")
end

-- ============================================================
-- 🥔🥔🥔 ENABLE
-- ============================================================
function Super.enable()
    if Super.enabled then return end
    Super.enabled = true
    
    -- ============ 1. LIGHTING ============
    pcall(function()
        for _, prop in ipairs({
            "GlobalShadows", "FogEnd", "FogStart", "FogColor",
            "Brightness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
            "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom",
            "ShadowSoftness", "ExposureCompensation", "ClockTime", "GeographicLatitude",
        }) do
            Super.saved.lighting[prop] = Lighting[prop]
        end
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
    
    -- ============ 2. SKY/ATMOSPHERE/CLOUDS ============
    pcall(function()
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                Super.saved.sky = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            elseif obj:IsA("Atmosphere") then
                Super.saved.atmosphere = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            elseif obj:IsA("Clouds") then
                Super.saved.clouds = { instance = obj, parent = obj.Parent }
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
                Super.saved.terrain[prop] = terrain[prop]
            end
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
        end
    end)
    
    -- ============ 4. QUALITY ============
    pcall(function()
        Super.saved.qualityLevel = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    
    -- ============ 5. 🛡️ SAFE REMOVE: PLACED EGGS ONLY ============
    pcall(function()
        -- PlacedEggRenders lang (placed eggs — safe)
        local placedEggs = Workspace:FindFirstChild("PlacedEggRenders")
        if placedEggs then
            detach(placedEggs, "placedEggs")
        end
        -- ❌ HINDI kasama:
        -- AreaEggSlotsClient (field eggs)
        -- __OBJECTS.AreaEggSlots (field eggs)
    end)
    
    -- ============ 6. 🛡️ SAFE REMOVE: BASE/PLOTS ONLY ============
    pcall(function()
        -- Workspace.Plots (base models — safe)
        local plots = Workspace:FindFirstChild("Plots")
        if plots then
            detach(plots, "plots")
        end
        
        -- __OBJECTS.Build (base structures — safe)
        local objects = Workspace:FindFirstChild("__OBJECTS")
        if objects then
            local build = objects:FindFirstChild("Build")
            if build then
                for _, child in ipairs(build:GetChildren()) do
                    if isBaseModel(child) then
                        detach(child, "build")
                    end
                end
            end
        end
        
        -- ❌ HINDI kasama:
        -- __OBJECTS.Areas (gameplay areas — dapat i-keep)
        -- __OBJECTS.Areas.GuardAreas (guard bounds — dapat i-keep)
    end)
    
    -- ============ 7. 🛡️ SAFE REMOVE: ACCESSORIES ONLY ============
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                for _, obj in ipairs(plr.Character:GetChildren()) do
                    if isAccessory(obj) then
                        detach(obj, "accessory")
                    end
                end
            end
        end
    end)
    
    -- ============ 8. REMOVE EFFECTS ============
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- Skip kung egg-related (para hindi ma-remove field egg effects)
            local isFieldEgg = false
            local eggSlots = Workspace:FindFirstChild("AreaEggSlotsClient")
            if eggSlots and obj:IsDescendantOf(eggSlots) then
                isFieldEgg = true
            end
            
            if not isFieldEgg then
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") 
                   or obj:IsA("Smoke") or obj:IsA("Fire") 
                   or obj:IsA("Sparkles") or obj:IsA("Beam")
                   or obj:IsA("Highlight") or obj:IsA("SelectionBox")
                   or obj:IsA("PointLight") or obj:IsA("SpotLight") 
                   or obj:IsA("SurfaceLight") then
                    if obj.Enabled then
                        Super.saved.effects[obj] = true
                        obj.Enabled = false
                    end
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if obj.Transparency < 1 then
                        Super.saved.effects[obj] = obj.Transparency
                        obj.Transparency = 1
                    end
                elseif obj:IsA("SurfaceAppearance") then
                    detach(obj, "surfaceAppearance")
                elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                    if obj.Enabled then
                        Super.saved.effects[obj] = true
                        obj.Enabled = false
                    end
                end
            end
        end
    end)
    
    -- ============ 9. POST-PROCESSING ============
    pcall(function()
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if obj:IsA("PostEffect") and obj.Enabled then
                Super.saved.effects[obj] = true
                obj.Enabled = false
            end
        end
    end)
    
    -- ============ 10. MATERIALS ============
    pcall(function()
        local count = 0
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                -- Skip kung field egg
                local isFieldEgg = false
                local eggSlots = Workspace:FindFirstChild("AreaEggSlotsClient")
                if eggSlots and part:IsDescendantOf(eggSlots) then
                    isFieldEgg = true
                end
                
                if not isFieldEgg then
                    Super.saved.materials[part] = {
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
        end
    end)
    
    -- ============ 11. CAMERA FOV ============
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            Super.saved.cameraFOV = cam.FieldOfView
            cam.FieldOfView = 120
        end
    end)
    
    -- ============ 12. HIDE OTHER PLAYERS ============
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                detach(plr.Character, "playerChar")
            end
        end
    end)
    
    -- ============ 13. WATCHERS ============
    local conn1 = Workspace.DescendantAdded:Connect(function(obj)
        if not Super.enabled then return end
        pcall(function()
            -- Skip kung field egg (safe)
            local isFieldEgg = false
            local eggSlots = Workspace:FindFirstChild("AreaEggSlotsClient")
            if eggSlots and obj:IsDescendantOf(eggSlots) then
                isFieldEgg = true
            end
            if isFieldEgg then return end
            
            -- Skip kung local character
            local isLocalChar = obj:IsDescendantOf(LocalPlayer.Character or game)
            
            -- Auto-remove placed eggs
            if isPlacedEgg(obj) then
                task.wait(0.1)
                detach(obj, "auto-placed")
                return
            end
            
            -- Auto-remove base
            if isBaseModel(obj) and not isLocalChar then
                task.wait(0.1)
                detach(obj, "auto-base")
                return
            end
            
            -- Effects
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") 
               or obj:IsA("Smoke") or obj:IsA("Fire") 
               or obj:IsA("Sparkles") or obj:IsA("Beam")
               or obj:IsA("Highlight") or obj:IsA("SelectionBox")
               or obj:IsA("PointLight") or obj:IsA("SpotLight") 
               or obj:IsA("SurfaceLight") or obj:IsA("BillboardGui") 
               or obj:IsA("SurfaceGui") then
                obj.Enabled = false
            elseif obj:IsA("BasePart") and not isLocalChar then
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
    table.insert(Super.conns, conn1)
    
    -- Watch new Plot/PlacedEgg
    local conn2 = Workspace.ChildAdded:Connect(function(obj)
        if not Super.enabled then return end
        task.wait(0.1)
        pcall(function()
            if isPlacedEgg(obj) then
                detach(obj, "auto-child-placed")
            elseif isBaseModel(obj) then
                detach(obj, "auto-child-base")
            end
        end)
    end)
    table.insert(Super.conns, conn2)
    
    -- Watch new players
    local conn3 = Players.PlayerAdded:Connect(function(plr)
        if not Super.enabled then return end
        plr.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            if not Super.enabled then return end
            for _, obj in ipairs(char:GetChildren()) do
                if isAccessory(obj) then
                    detach(obj, "auto-accessory")
                end
            end
            if plr ~= LocalPlayer then
                detach(char, "auto-playerChar")
            end
        end)
    end)
    table.insert(Super.conns, conn3)
    
    -- Watch local character
    local conn4 = LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if not Super.enabled then return end
        for _, obj in ipairs(char:GetChildren()) do
            if isAccessory(obj) then
                detach(obj, "auto-local-accessory")
            end
        end
    end)
    table.insert(Super.conns, conn4)
    
    -- FPS cap
    pcall(function()
        if setfpscap then setfpscap(240) end
    end)
    
    print("[SUPER] 🥔🥔🥔 SUPER POTATO ENABLED (SAFE MODE)")
end

-- ============================================================
-- DISABLE
-- ============================================================
function Super.disable()
    if not Super.enabled then return end
    Super.enabled = false
    
    -- Restore lighting
    pcall(function()
        for prop, value in pairs(Super.saved.lighting) do
            Lighting[prop] = value
        end
    end)
    
    -- Restore sky/atmosphere/clouds
    pcall(function()
        if Super.saved.sky and Super.saved.sky.instance then
            Super.saved.sky.instance.Parent = Super.saved.sky.parent
        end
        if Super.saved.atmosphere and Super.saved.atmosphere.instance then
            Super.saved.atmosphere.instance.Parent = Super.saved.atmosphere.parent
        end
        if Super.saved.clouds and Super.saved.clouds.instance then
            Super.saved.clouds.instance.Parent = Super.saved.clouds.parent
        end
    end)
    
    -- Restore terrain
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for prop, value in pairs(Super.saved.terrain) do
                terrain[prop] = value
            end
        end
    end)
    
    -- Restore quality
    pcall(function()
        if Super.saved.qualityLevel then
            settings().Rendering.QualityLevel = Super.saved.qualityLevel
        end
    end)
    
    -- Restore effects
    pcall(function()
        for obj, value in pairs(Super.saved.effects) do
            if obj and obj.Parent then
                if type(value) == "boolean" then
                    obj.Enabled = value
                elseif type(value) == "number" then
                    obj.Transparency = value
                end
            end
        end
    end)
    
    -- Restore materials
    pcall(function()
        for part, data in pairs(Super.saved.materials) do
            if part and part.Parent then
                part.Material = data.Material
                part.Reflectance = data.Reflectance
                part.CastShadow = data.CastShadow
            end
        end
    end)
    
    -- Restore detached
    pcall(function()
        for obj, parent in pairs(Super.saved.detached) do
            if obj and obj.Parent == nil and parent then
                pcall(function() obj.Parent = parent end)
            end
        end
    end)
    
    -- Restore camera
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and Super.saved.cameraFOV then
            cam.FieldOfView = Super.saved.cameraFOV
        end
    end)
    
    -- Restore players
    pcall(function()
        for obj, parent in pairs(Super.saved.playerChars) do
            if obj and obj.Parent == nil and parent then
                obj.Parent = parent
            end
        end
    end)
    
    -- Disconnect
    for _, conn in ipairs(Super.conns) do
        pcall(function() conn:Disconnect() end)
    end
    Super.conns = {}
    
    -- Clear
    Super.saved = {
        lighting = {}, terrain = {}, effects = {},
        materials = {}, qualityLevel = nil, sky = nil,
        atmosphere = nil, clouds = nil, playerChars = {},
        cameraFOV = nil, detached = {},
    }
    
    print("[SUPER] 🥔🥔🥔 SUPER POTATO DISABLED - restored")
end

-- ============================================================
-- UI
-- ============================================================
local COLORS = {
    BG = Color3.fromRGB(25, 25, 30),
    TITLE_BG = Color3.fromRGB(35, 35, 42),
    TEXT = Color3.fromRGB(255, 255, 255),
    GREEN = Color3.fromRGB(0, 180, 90),
    RED = Color3.fromRGB(200, 50, 50),
    KNOB = Color3.fromRGB(255, 255, 255),
    TRACK_OFF = Color3.fromRGB(70, 70, 80),
    YELLOW = Color3.fromRGB(255, 200, 0),
    BROWN = Color3.fromRGB(180, 130, 70),
    DARK_BROWN = Color3.fromRGB(120, 80, 40),
    ORANGE = Color3.fromRGB(255, 140, 50),
    CYAN = Color3.fromRGB(80, 200, 255),
    PINK = Color3.fromRGB(255, 150, 200),
    PURPLE = Color3.fromRGB(200, 150, 255),
}

local function createSuperUI()
    if CoreGui:FindFirstChild("SuperPotatoUI") then
        CoreGui.SuperPotatoUI:Destroy()
    end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "SuperPotatoUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui
    
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 280, 0, 240)
    Main.Position = UDim2.new(0.5, -140, 0.5, -120)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", Main)
    stroke.Color = COLORS.DARK_BROWN
    stroke.Thickness = 2
    
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
    Title.Text = "🥔🥔🥔 SUPER POTATO (SAFE)"
    Title.TextColor3 = COLORS.ORANGE
    Title.TextSize = 12
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
    lbl.Text = "🥔 Super Mode"
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
    local function makeInfo(y, text, color)
        local lbl = Instance.new("TextLabel", Main)
        lbl.Size = UDim2.new(1, -24, 0, 18)
        lbl.Position = UDim2.new(0, 12, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = text
        lbl.TextColor3 = color or COLORS.YELLOW
        lbl.TextSize = 10
        lbl.Font = Enum.Font.Gotham
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        return lbl
    end
    
    makeInfo(78, "🏠 Remove base/plots (safe)", COLORS.CYAN)
    makeInfo(95, "🥚 Remove PLACED eggs only", COLORS.PINK)
    makeInfo(112, "🎩 Remove accessories", COLORS.BROWN)
    makeInfo(129, "💡 Remove lights/effects", COLORS.YELLOW)
    makeInfo(146, "👻 Hide other players", COLORS.PURPLE)
    makeInfo(163, "⚡ FPS cap: 240", COLORS.GREEN)
    
    local Warning = Instance.new("TextLabel", Main)
    Warning.Size = UDim2.new(1, -24, 0, 18)
    Warning.Position = UDim2.new(0, 12, 0, 185)
    Warning.BackgroundTransparency = 1
    Warning.Text = "🛡️ Field eggs SAFE — hindi ma-remove"
    Warning.TextColor3 = COLORS.GREEN
    Warning.TextSize = 9
    Warning.Font = Enum.Font.GothamBold
    Warning.TextXAlignment = Enum.TextXAlignment.Left
    
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -24, 0, 18)
    Status.Position = UDim2.new(0, 12, 0, 205)
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

local ui = createSuperUI()

local function setSuperToggle(on)
    ui.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    ui.knob.Position = on and UDim2.new(0, 25, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
    ui.stateLbl.Text = on and "ON" or "OFF"
    ui.stateLbl.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

ui.btn.MouseButton1Click:Connect(function()
    if not Super.enabled then
        setSuperToggle(true)
        ui.Status.Text = "🥔 Enabling SUPER..."
        ui.Status.TextColor3 = COLORS.YELLOW
        task.spawn(function()
            Super.enable()
            task.wait(1)
            ui.Status.Text = "🥔🥔🥔 SUPER ACTIVE (field eggs safe)"
            ui.Status.TextColor3 = COLORS.GREEN
        end)
    else
        setSuperToggle(false)
        ui.Status.Text = "Restoring..."
        ui.Status.TextColor3 = COLORS.YELLOW
        task.spawn(function()
            Super.disable()
            task.wait(1)
            ui.Status.Text = "⚡ Restored to normal"
            ui.Status.TextColor3 = COLORS.YELLOW
        end)
    end
end)

ui.CloseBtn.MouseButton1Click:Connect(function()
    if Super.enabled then Super.disable() end
    ui.ScreenGui:Destroy()
end)
