-- ============================================
-- MAIN SCRIPT + SUPER POTATO INTEGRATED
-- ============================================

-- ============================================
-- 🥔 SUPER POTATO GRAPHICS (TOP)
-- ============================================
local PotatoGfx = {
    enabled = false,
    saved = {
        lighting = {}, terrain = {}, effects = {},
        materials = {}, qualityLevel = nil, sky = nil,
        atmosphere = nil, clouds = nil, playerChars = {},
        cameraFOV = nil, detached = {},
    },
    conns = {},
}

local function potatoDetach(obj, tag)
    if not obj or not obj.Parent then return end
    if PotatoGfx.saved.detached[obj] then return end
    PotatoGfx.saved.detached[obj] = obj.Parent
    obj.Parent = nil
end

local function isFieldEgg(obj)
    local eggSlots = Workspace:FindFirstChild("AreaEggSlotsClient")
    if eggSlots and obj:IsDescendantOf(eggSlots) then return true end
    return false
end

local function isPlacedEgg(obj)
    local placed = Workspace:FindFirstChild("PlacedEggRenders")
    if placed and obj:IsDescendantOf(placed) then return true end
    return false
end

local function isBaseModel(obj)
    if not obj then return false end
    local objects = Workspace:FindFirstChild("__OBJECTS")
    if objects then
        local areas = objects:FindFirstChild("Areas")
        if areas and obj:IsDescendantOf(areas) then return false end
    end
    local name = string.lower(obj.Name)
    return name:find("base") or name:find("plot") or name:find("house") or name:find("pen")
end

local function isAccessory(obj)
    if not obj then return false end
    return obj:IsA("Accessory") or obj:IsA("Hat") or obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic")
end

function PotatoGfx.enable()
    if PotatoGfx.enabled then return end
    PotatoGfx.enabled = true
    
    -- Lighting
    pcall(function()
        for _, prop in ipairs({
            "GlobalShadows", "FogEnd", "FogStart", "FogColor",
            "Brightness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale",
            "Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom",
            "ShadowSoftness", "ExposureCompensation", "ClockTime", "GeographicLatitude",
        }) do
            PotatoGfx.saved.lighting[prop] = Lighting[prop]
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
    
    -- Sky/Atmosphere/Clouds
    pcall(function()
        for _, obj in ipairs(Lighting:GetChildren()) do
            if obj:IsA("Sky") then
                PotatoGfx.saved.sky = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            elseif obj:IsA("Atmosphere") then
                PotatoGfx.saved.atmosphere = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            elseif obj:IsA("Clouds") then
                PotatoGfx.saved.clouds = { instance = obj, parent = obj.Parent }
                obj.Parent = nil
            end
        end
    end)
    
    -- Terrain
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for _, prop in ipairs({
                "Decoration", "WaterWaveSize", "WaterWaveSpeed",
                "WaterReflectance", "WaterTransparency",
            }) do
                PotatoGfx.saved.terrain[prop] = terrain[prop]
            end
            terrain.Decoration = false
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
        end
    end)
    
    -- Quality
    pcall(function()
        PotatoGfx.saved.qualityLevel = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    
    -- Placed eggs (SAFE — hindi field eggs)
    pcall(function()
        local placedEggs = Workspace:FindFirstChild("PlacedEggRenders")
        if placedEggs then potatoDetach(placedEggs, "placedEggs") end
    end)
    
    -- Base/Plots (SAFE — hindi areas)
    pcall(function()
        local plots = Workspace:FindFirstChild("Plots")
        if plots then potatoDetach(plots, "plots") end
        local objects = Workspace:FindFirstChild("__OBJECTS")
        if objects then
            local build = objects:FindFirstChild("Build")
            if build then
                for _, child in ipairs(build:GetChildren()) do
                    if isBaseModel(child) then potatoDetach(child, "build") end
                end
            end
        end
    end)
    
    -- Accessories
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then
                for _, obj in ipairs(plr.Character:GetChildren()) do
                    if isAccessory(obj) then potatoDetach(obj, "accessory") end
                end
            end
        end
    end)
    
    -- Effects (skip field eggs)
    pcall(function()
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if not isFieldEgg(obj) then
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") 
                   or obj:IsA("Smoke") or obj:IsA("Fire") 
                   or obj:IsA("Sparkles") or obj:IsA("Beam")
                   or obj:IsA("Highlight") or obj:IsA("SelectionBox")
                   or obj:IsA("PointLight") or obj:IsA("SpotLight") 
                   or obj:IsA("SurfaceLight") then
                    if obj.Enabled then
                        PotatoGfx.saved.effects[obj] = true
                        obj.Enabled = false
                    end
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    if obj.Transparency < 1 then
                        PotatoGfx.saved.effects[obj] = obj.Transparency
                        obj.Transparency = 1
                    end
                elseif obj:IsA("SurfaceAppearance") then
                    potatoDetach(obj, "surfaceAppearance")
                elseif obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                    if obj.Enabled then
                        PotatoGfx.saved.effects[obj] = true
                        obj.Enabled = false
                    end
                end
            end
        end
    end)
    
    -- PostEffects
    pcall(function()
        for _, obj in ipairs(Lighting:GetDescendants()) do
            if obj:IsA("PostEffect") and obj.Enabled then
                PotatoGfx.saved.effects[obj] = true
                obj.Enabled = false
            end
        end
    end)
    
    -- Materials (skip field eggs)
    pcall(function()
        local count = 0
        for _, part in ipairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") and not isFieldEgg(part) then
                PotatoGfx.saved.materials[part] = {
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
    
    -- Camera FOV
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam then
            PotatoGfx.saved.cameraFOV = cam.FieldOfView
            cam.FieldOfView = 120
        end
    end)
    
    -- Hide other players
    pcall(function()
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                potatoDetach(plr.Character, "playerChar")
            end
        end
    end)
    
    -- Watchers
    local conn1 = Workspace.DescendantAdded:Connect(function(obj)
        if not PotatoGfx.enabled then return end
        pcall(function()
            if isFieldEgg(obj) then return end
            local isLocalChar = obj:IsDescendantOf(LocalPlayer.Character or game)
            if isPlacedEgg(obj) then
                task.wait(0.1)
                potatoDetach(obj, "auto-placed")
                return
            end
            if isBaseModel(obj) and not isLocalChar then
                task.wait(0.1)
                potatoDetach(obj, "auto-base")
                return
            end
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
    table.insert(PotatoGfx.conns, conn1)
    
    -- FPS cap
    pcall(function()
        if setfpscap then setfpscap(240) end
    end)
    
    print("[POTATO] 🥔 SUPER POTATO ENABLED (SAFE)")
end

function PotatoGfx.disable()
    if not PotatoGfx.enabled then return end
    PotatoGfx.enabled = false
    
    pcall(function()
        for prop, value in pairs(PotatoGfx.saved.lighting) do
            Lighting[prop] = value
        end
    end)
    pcall(function()
        if PotatoGfx.saved.sky and PotatoGfx.saved.sky.instance then
            PotatoGfx.saved.sky.instance.Parent = PotatoGfx.saved.sky.parent
        end
        if PotatoGfx.saved.atmosphere and PotatoGfx.saved.atmosphere.instance then
            PotatoGfx.saved.atmosphere.instance.Parent = PotatoGfx.saved.atmosphere.parent
        end
        if PotatoGfx.saved.clouds and PotatoGfx.saved.clouds.instance then
            PotatoGfx.saved.clouds.instance.Parent = PotatoGfx.saved.clouds.parent
        end
    end)
    pcall(function()
        local terrain = Workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            for prop, value in pairs(PotatoGfx.saved.terrain) do
                terrain[prop] = value
            end
        end
    end)
    pcall(function()
        if PotatoGfx.saved.qualityLevel then
            settings().Rendering.QualityLevel = PotatoGfx.saved.qualityLevel
        end
    end)
    pcall(function()
        for obj, value in pairs(PotatoGfx.saved.effects) do
            if obj and obj.Parent then
                if type(value) == "boolean" then
                    obj.Enabled = value
                elseif type(value) == "number" then
                    obj.Transparency = value
                end
            end
        end
    end)
    pcall(function()
        for part, data in pairs(PotatoGfx.saved.materials) do
            if part and part.Parent then
                part.Material = data.Material
                part.Reflectance = data.Reflectance
                part.CastShadow = data.CastShadow
            end
        end
    end)
    pcall(function()
        for obj, parent in pairs(PotatoGfx.saved.detached) do
            if obj and obj.Parent == nil and parent then
                pcall(function() obj.Parent = parent end)
            end
        end
    end)
    pcall(function()
        local cam = Workspace.CurrentCamera
        if cam and PotatoGfx.saved.cameraFOV then
            cam.FieldOfView = PotatoGfx.saved.cameraFOV
        end
    end)
    pcall(function()
        for obj, parent in pairs(PotatoGfx.saved.playerChars) do
            if obj and obj.Parent == nil and parent then
                obj.Parent = parent
            end
        end
    end)
    
    for _, conn in ipairs(PotatoGfx.conns) do
        pcall(function() conn:Disconnect() end)
    end
    PotatoGfx.conns = {}
    PotatoGfx.saved = {
        lighting = {}, terrain = {}, effects = {},
        materials = {}, qualityLevel = nil, sky = nil,
        atmosphere = nil, clouds = nil, playerChars = {},
        cameraFOV = nil, detached = {},
    }
    
    print("[POTATO] 🥔 SUPER POTATO DISABLED - restored")
end

-- ============================================
-- SERVICES
-- ============================================
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ============================================
-- STEP 1: SPEED BYPASS (300)
-- ============================================
local speedBypass = {
    RunService = RunService,
    Players = Players,
    speed = 300,
    active = false,
}

function speedBypass:findFunction(nups, linedefined)
    local s, r = pcall(function(...)
        for _, f in next, getgc() do
            if typeof(f) == 'function' and islclosure(f) then
                local upvs = debug.getupvalues(f)
                local line = debug.info(f, "l")
                if upvs and #upvs == nups and line == linedefined then
                    if nups == 10 then
                        local t = debug.getupvalue(f, 3)
                        if typeof(t) == "table" and rawget(t, "Humanoid") then
                            return f
                        end
                    else
                        return f
                    end
                end
            end
        end
        return nil
    end)
    if s and r then return r end
    return nil
end

function speedBypass:safehook(f, c)
    local s, r = pcall(function(...)
        return hookfunction(f, newlclosure(c))
    end)
    if s and r then return r end
    return warn("failed to hook: "..tostring(r))
end

function speedBypass:init()
    local LP = self.Players.LocalPlayer
    if not LP then return warn("no localplayer") end
    if not getgc or not hookfunction or not islclosure then
        return warn("UNSUPPORTED EXECUTOR")
    end
    local func3 = self:findFunction(19, 634)
    if not func3 then return warn("func3 not found") end
    local v7 = debug.getupvalue(func3, 2)
    if not v7 then return warn("v7 not found") end
    local hookedfunc3
    hookedfunc3 = self:safehook(v7, function(p1, p2)
        if p2 and typeof(p2) == "table" then
            setmetatable(p2, {})
        end
        return hookedfunc3(p1, p2)
    end)
    self.conn = self.RunService.Heartbeat:Connect(function()
        if not self.active then return end
        local char = LP.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        hum.WalkSpeed = self.speed
    end)
    print("[SpeedBypass] Hook installed")
    return true
end

speedBypass:init()

-- ============================================
-- CONFIG
-- ============================================
getgenv().config = {
    normalSpeed = 16,
    fastSpeed = 300,
}

-- ============================================
-- BIND/UNBIND
-- ============================================
local utility = {
    RunService = RunService,
    Players = Players,
    ProximityPromptService = ProximityPromptService,
    ReplicatedStorage = ReplicatedStorage,
    Workspace = Workspace,
    CoreGui = CoreGui,
    conns = {},
}

function utility:bind(connection, callback)
    local s, r = pcall(function(...)
        local conn = connection:Connect(callback)
        self.conns[conn] = conn
        return self.conns[conn]
    end)
    if s and r then return r end
    return warn('failed to bind: '..tostring(r))
end

function utility:unbind(connection)
    local s, r = pcall(function(...)
        local conn = self.conns[connection]
        if conn then
            conn:Disconnect()
            self.conns[connection] = nil
            return true
        end
        return false
    end)
    if s and r then return true end
    return warn("failed to unbind")
end

-- ============================================
-- INSTANT PICKUP
-- ============================================
function utility:startInstantPickup()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return warn('no localplayer') end

    self.instantConn = self:bind(self.ProximityPromptService.PromptButtonHoldBegan, function(ProximityPrompt, Player)
        if Player == self.LocalPlayer and tostring(ProximityPrompt) == "CarryAreaEgg" then
            ProximityPrompt.HoldDuration = 0
        end
    end)

    return self.instantConn ~= nil
end

function utility:stopInstantPickup()
    if self.instantConn then
        self:unbind(self.instantConn)
        self.instantConn = nil
    end
end

-- ============================================
-- ANTI-RAGDOLL
-- ============================================
utility.antiRagdollEnabled = false
utility.antiRagdollConn = nil
utility.ragdollConns = {}

function utility:startAntiRagdoll()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    if not getconnections then return false, "Missing getconnections" end
    self.Packages = self.ReplicatedStorage:FindFirstChild("Packages")
    if not self.Packages then return false, "No Packages" end
    self.Networking = self.Packages:FindFirstChild("Networking")
    if not self.Networking then return false, "No Networking" end
    self.RigSync = self.Networking:FindFirstChild("RE/RigSync/Refresh")
    if not self.RigSync then return false, "No RE/RigSync/Refresh" end
    local conns = getconnections(self.RigSync.OnClientEvent)
    if conns then
        for _, conn in next, conns do
            pcall(function()
                conn:Disconnect()
                table.insert(utility.ragdollConns, conn)
            end)
        end
    end
    utility.antiRagdollConn = self.RunService.Heartbeat:Connect(function()
        if not utility.antiRagdollEnabled then return end
        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        for _, obj in next, char:GetDescendants() do
            if obj:IsA("RagdollConstraint") or obj:IsA("BallSocketConstraint") then
                pcall(function() obj:Destroy() end)
            end
        end
        if hum:GetState() == Enum.HumanoidStateType.Physics or
           hum:GetState() == Enum.HumanoidStateType.Ragdoll then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
        for _, joint in next, char:GetDescendants() do
            if joint:IsA("Motor6D") and joint.Enabled == false then
                pcall(function() joint.Enabled = true end)
            end
        end
    end)
    return true
end

function utility:stopAntiRagdoll()
    if utility.antiRagdollConn then
        utility.antiRagdollConn:Disconnect()
        utility.antiRagdollConn = nil
    end
    utility.ragdollConns = {}
end

-- ============================================
-- ANTI-TRAP
-- ============================================
utility.antiTrapEnabled = false
utility.antiTrapConn = nil
utility.trapConns = {}

function utility:destroyTraps()
    local debris = self.Workspace:FindFirstChild("__DEBRIS")
    if not debris then return end
    for _, obj in next, debris:GetChildren() do
        if obj.Name == "PlayerTrap" then
            pcall(function() obj:Destroy() end)
        end
    end
end

function utility:startAntiTrap()
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then return false, "No LocalPlayer" end
    self:destroyTraps()
    local debris = self.Workspace:FindFirstChild("__DEBRIS")
    if debris then
        table.insert(utility.trapConns, debris.ChildAdded:Connect(function(child)
            if utility.antiTrapEnabled and child.Name == "PlayerTrap" then
                pcall(function() child:Destroy() end)
            end
        end))
    end
    utility.antiTrapConn = self.RunService.Heartbeat:Connect(function()
        if not utility.antiTrapEnabled then return end
        self:destroyTraps()
        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum.PlatformStand then
            pcall(function() hum.PlatformStand = false end)
        end
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Physics or
           state == Enum.HumanoidStateType.Ragdoll or
           state == Enum.HumanoidStateType.FallingDown or
           state == Enum.HumanoidStateType.PlatformStanding then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end)
        end
        for _, joint in next, char:GetDescendants() do
            if joint:IsA("Motor6D") and joint.Enabled == false then
                pcall(function() joint.Enabled = true end)
            end
        end
    end)
    return true
end

function utility:stopAntiTrap()
    if utility.antiTrapConn then
        utility.antiTrapConn:Disconnect()
        utility.antiTrapConn = nil
    end
    for _, conn in next, utility.trapConns do
        pcall(function() conn:Disconnect() end)
    end
    utility.trapConns = {}
end

-- ============================================
-- AUTO GRAB BEST EGG
-- ============================================
utility.autoGrabEnabled = false
utility.autoGrabConn = nil

local AREA_NAMES = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple", "Light Dark",
}

utility.EggState = nil
utility.AssetsDir = nil
utility.Mutations = nil
utility.AssetEarnings = nil

function utility:loadEggModules()
    if self.EggState then return true end
    local ok = pcall(function()
        local client = self.ReplicatedStorage:FindFirstChild("Client")
        if client then
            local es = client:FindFirstChild("EggState")
            if es then self.EggState = require(es) end
        end
        local data = self.ReplicatedStorage:FindFirstChild("Data")
        if data then
            local assets = data:FindFirstChild("Assets")
            if assets then
                local okA, mod = pcall(require, assets)
                if okA and mod then self.AssetsDir = mod.Directory end
            end
        end
        local shared = self.ReplicatedStorage:FindFirstChild("Shared")
        if shared then
            local modules = shared:FindFirstChild("Modules")
            if modules then
                local mut = modules:FindFirstChild("Mutations")
                if mut then
                    local okM, mod = pcall(require, mut)
                    if okM then self.Mutations = mod end
                end
            end
            local util = shared:FindFirstChild("Util")
            if util then
                local ae = util:FindFirstChild("AssetEarnings")
                if ae then
                    local okE, mod = pcall(require, ae)
                    if okE then self.AssetEarnings = mod end
                end
            end
        end
    end)
    return ok and self.EggState ~= nil
end

function utility:getRarityNumber(rec)
    if rec and rec.Rarity and type(rec.Rarity) == "table" then
        return rec.Rarity.RarityNumber or 0
    end
    return 0
end

function utility:getAssetScale(rec)
    return tonumber(rec.AssetScale) or 1
end

function utility:getEggPos(rec)
    if not rec then return nil end
    if rec.BoundsCFrame and rec.BoundsCFrame.Position then
        return rec.BoundsCFrame.Position
    end
    return nil
end

function utility:calcEggValue(rec)
    if not rec then return 0 end
    if self.AssetEarnings then
        local ok, rate = pcall(function()
            local item = {
                Category = rec.AssetCategory,
                Scale = tonumber(rec.AssetScale) or 1,
                Mutations = rec.Mutations or {},
            }
            return self.AssetEarnings.LiveRatePerSecond(item, nil, nil, self.Players.LocalPlayer)
        end)
        if ok and type(rate) == "number" and rate > 0 then return rate end
    end
    local rarity = self:getRarityNumber(rec)
    local scale = self:getAssetScale(rec)
    local mutMult = 1
    if rec.Mutations and #rec.Mutations > 0 and self.Mutations then
        pcall(function()
            local item = { Mutations = rec.Mutations }
            mutMult = self.Mutations.EarningsFor(item) or 1
        end)
    end
    local baseRate = 0
    if self.AssetsDir then
        local dir = self.AssetsDir[rec.AssetCategory]
        if dir then baseRate = tonumber(dir.EarningRate) or 0 end
    end
    local scaleFactor = scale <= 5 and scale ^ 1.85 or (scale / 5) ^ 1.2 * 19.637875755794113
    local value = baseRate * scaleFactor * mutMult
    return math.max(1, math.round(value))
end

function utility:findAllHighValueEggs()
    if not self.EggState then return {} end
    local ok, fieldEggs = pcall(function() return self.EggState.ReadFieldEggs() end)
    if not ok or not fieldEggs or not fieldEggs.Records then return {} end
    local eggs = {}
    local minValue = 5e7
    local minArea = 10
    for _, rec in ipairs(fieldEggs.Records) do
        if rec.State == "Slot" or rec.State == "Dropped" then
            local areaIdx = nil
            for i, name in ipairs(AREA_NAMES) do
                if rec.AreaId == name then areaIdx = i break end
            end
            if areaIdx and areaIdx >= minArea then
                local value = self:calcEggValue(rec)
                if value >= minValue then
                    eggs[#eggs + 1] = { rec = rec, value = value }
                end
            end
        end
    end
    table.sort(eggs, function(a, b) return a.value > b.value end)
    return eggs
end

function utility:fastGrabEgg(rec)
    if not rec then return false end
    local ok1, res1 = pcall(function()
        return self.EggState.CarryFieldEgg(rec.Uid)
    end)
    if ok1 and res1 == true then return true end
    local eggPos = self:getEggPos(rec)
    if not eggPos then return false end
    local CarryAreaEggs = self.Workspace:QueryDescendants("#CarryAreaEgg")
    local closetprompt, closetdist = nil, math.huge
    for _, prompt in next, CarryAreaEggs do
        local p = prompt.Parent
        if p then
            local dist = (eggPos - p.Position).Magnitude
            if dist < closetdist then
                closetdist = dist
                closetprompt = prompt
            end
        end
    end
    if closetprompt and fireproximityprompt then
        pcall(function()
            closetprompt.HoldDuration = 0
            fireproximityprompt(closetprompt, 0)
        end)
        return true
    end
    return false
end

function utility:startAutoGrab()
    if not self:loadEggModules() then
        return false, "EggState not found"
    end
    self.autoGrabLastGrabbed = {}
    self.autoGrabCount = 0
    self.autoGrabLastValue = 0
    local checkDelay = 0.1
    local grabCooldown = 2
    local postGrabWait = 0.3
    self.autoGrabConn = self.RunService.Heartbeat:Connect(function()
        if not self.autoGrabEnabled then return end
        local now = tick()
        if self.autoGrabLastCheck and (now - self.autoGrabLastCheck) < checkDelay then return end
        self.autoGrabLastCheck = now
        local eggs = self:findAllHighValueEggs()
        if #eggs > 0 then
            for _, item in ipairs(eggs) do
                if not self.autoGrabEnabled then break end
                local rec = item.rec
                local value = item.value
                local lastTime = self.autoGrabLastGrabbed[rec.Uid]
                if not lastTime or (tick() - lastTime) > grabCooldown then
                    self.autoGrabLastGrabbed[rec.Uid] = tick()
                    local ok = self:fastGrabEgg(rec)
                    if ok then
                        self.autoGrabCount = self.autoGrabCount + 1
                        self.autoGrabLastValue = value
                        print(("[AutoGrab #%d] %s /s (%s)"):format(
                            self.autoGrabCount,
                            string.format("%.2fM", value / 1e6),
                            rec.AreaId))
                        task.wait(postGrabWait)
                        break
                    end
                end
            end
        end
    end)
    return true
end

function utility:stopAutoGrab()
    if self.autoGrabConn then
        self.autoGrabConn:Disconnect()
        self.autoGrabConn = nil
    end
end

-- ============================================
-- UI (COMPACT — with Potato Graphics)
-- ============================================
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
    GOLD = Color3.fromRGB(255, 215, 0),
    BROWN = Color3.fromRGB(180, 130, 70),
    ORANGE = Color3.fromRGB(255, 140, 50),
}

local function createUI()
    if utility.CoreGui:FindFirstChild("StealEggUI") then
        utility.CoreGui.StealEggUI:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "StealEggUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = utility.CoreGui

    -    -- 🎯 COMPACT: 220 x 340 (kasama potato)
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 220, 0, 340)
    Main.Position = UDim2.new(0.5, -110, 0.5, -170)
    Main.BackgroundColor3 = COLORS.BG
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui

    local c1 = Instance.new("UICorner", Main)
    c1.CornerRadius = UDim.new(0, 8)
    local s1 = Instance.new("UIStroke", Main)
    s1.Color = COLORS.STROKE

    -- Title bar
    local TitleBar = Instance.new("Frame", Main)
    TitleBar.Size = UDim2.new(1, 0, 0, 28)
    TitleBar.BackgroundColor3 = COLORS.TITLE_BG
    TitleBar.BorderSizePixel = 0
    local c2 = Instance.new("UICorner", TitleBar)
    c2.CornerRadius = UDim.new(0, 8)
    local TitleCover = Instance.new("Frame", TitleBar)
    TitleCover.Size = UDim2.new(1, 0, 0, 8)
    TitleCover.Position = UDim2.new(0, 0, 1, -8)
    TitleCover.BackgroundColor3 = COLORS.TITLE_BG
    TitleCover.BorderSizePixel = 0

    local Title = Instance.new("TextLabel", TitleBar)
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🥚 Steal An Egg"
    Title.TextColor3 = COLORS.TEXT
    Title.TextSize = 12
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left

    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -25, 0, 4)
    CloseBtn.BackgroundColor3 = COLORS.RED
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = COLORS.TEXT
    CloseBtn.TextSize = 12
    CloseBtn.Font = Enum.Font.GothamBold
    local c3 = Instance.new("UICorner", CloseBtn)
    c3.CornerRadius = UDim.new(0, 5)

    -- Toggle helper
    local function makeToggle(y, label, icon)
        local lbl = Instance.new("TextLabel", Main)
        lbl.Size = UDim2.new(1, -105, 0, 22)
        lbl.Position = UDim2.new(0, 12, 0, y)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. " " .. label
        lbl.TextColor3 = COLORS.TEXT
        lbl.TextSize = 11
        lbl.Font = Enum.Font.GothamBold
        lbl.TextXAlignment = Enum.TextXAlignment.Left

        local state = Instance.new("TextLabel", Main)
        state.Size = UDim2.new(0, 35, 0, 22)
        state.Position = UDim2.new(1, -100, 0, y)
        state.BackgroundTransparency = 1
        state.Text = "OFF"
        state.TextColor3 = COLORS.RED
        state.TextSize = 10
        state.Font = Enum.Font.GothamBold
        state.TextXAlignment = Enum.TextXAlignment.Right

        local track = Instance.new("Frame", Main)
        track.Size = UDim2.new(0, 40, 0, 22)
        track.Position = UDim2.new(1, -55, 0, y)
        track.BackgroundColor3 = COLORS.TRACK_OFF
        track.BorderSizePixel = 0
        local tc = Instance.new("UICorner", track)
        tc.CornerRadius = UDim.new(1, 0)

        local knob = Instance.new("Frame", track)
        knob.Size = UDim2.new(0, 16, 0, 16)
        knob.Position = UDim2.new(0, 3, 0.5, -8)
        knob.BackgroundColor3 = COLORS.KNOB
        knob.BorderSizePixel = 0
        local kc = Instance.new("UICorner", knob)
        kc.CornerRadius = UDim.new(1, 0)

        local btn = Instance.new("TextButton", Main)
        btn.Size = UDim2.new(0, 105, 0, 30)
        btn.Position = UDim2.new(1, -110, 0, y - 4)
        btn.BackgroundTransparency = 1
        btn.Text = ""

        return {track = track, knob = knob, state = state, btn = btn}
    end

    -- 🥔 POTATO toggle (TOP!)
    local potatoToggle = makeToggle(38, "Potato Graphics", "🥔")

    -- Other toggles
    local speedToggle = makeToggle(72, "Speed Bypass (300)", "⚡")
    local pickupToggle = makeToggle(106, "Instant Pickup", "⚡")
    local ragdollToggle = makeToggle(140, "Anti-Ragdoll", "🛡️")
    local antiTrapToggle = makeToggle(174, "Anti-Trap", "🪤")
    local autoGrabToggle = makeToggle(208, "Auto Grab 50M+", "💰")

    -- Auto Grab info
    local GrabInfo = Instance.new("TextLabel", Main)
    GrabInfo.Size = UDim2.new(1, -20, 0, 16)
    GrabInfo.Position = UDim2.new(0, 12, 0, 238)
    GrabInfo.BackgroundTransparency = 1
    GrabInfo.Text = "Next: -- | Grabbed: 0"
    GrabInfo.TextColor3 = COLORS.GOLD
    GrabInfo.TextSize = 9
    GrabInfo.Font = Enum.Font.Gotham
    GrabInfo.TextXAlignment = Enum.TextXAlignment.Left

    -- Status
    local Status = Instance.new("TextLabel", Main)
    Status.Size = UDim2.new(1, -20, 0, 16)
    Status.Position = UDim2.new(0, 12, 0, 256)
    Status.BackgroundTransparency = 1
    Status.Text = "Status: Ready"
    Status.TextColor3 = COLORS.YELLOW
    Status.TextSize = 10
    Status.Font = Enum.Font.Gotham
    Status.TextXAlignment = Enum.TextXAlignment.Left

    -- Potato Info
    local PotatoInfo = Instance.new("TextLabel", Main)
    PotatoInfo.Size = UDim2.new(1, -20, 0, 14)
    PotatoInfo.Position = UDim2.new(0, 12, 0, 276)
    PotatoInfo.BackgroundTransparency = 1
    PotatoInfo.Text = "🥔 Field eggs safe"
    PotatoInfo.TextColor3 = COLORS.GREEN
    PotatoInfo.TextSize = 9
    PotatoInfo.Font = Enum.Font.Gotham
    PotatoInfo.TextXAlignment = Enum.TextXAlignment.Left

    -- Flow Hint
    local FlowHint = Instance.new("TextLabel", Main)
    FlowHint.Size = UDim2.new(1, -20, 0, 14)
    FlowHint.Position = UDim2.new(0, 12, 0, 294)
    FlowHint.BackgroundTransparency = 1
    FlowHint.Text = "💡 1B → 500M → 100M → 50M"
    FlowHint.TextColor3 = Color3.fromRGB(100, 200, 255)
    FlowHint.TextSize = 9
    FlowHint.Font = Enum.Font.Gotham
    FlowHint.TextXAlignment = Enum.TextXAlignment.Left

    return {
        ScreenGui = ScreenGui, Main = Main,
        potatoToggle = potatoToggle,
        speedToggle = speedToggle, pickupToggle = pickupToggle,
        ragdollToggle = ragdollToggle, antiTrapToggle = antiTrapToggle,
        autoGrabToggle = autoGrabToggle,
        GrabInfo = GrabInfo, Status = Status,
        CloseBtn = CloseBtn
    }
end

local ui = createUI()

local function setToggle(t, on)
    t.track.BackgroundColor3 = on and COLORS.GREEN or COLORS.TRACK_OFF
    t.knob.Position = on and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
    t.state.Text = on and "ON" or "OFF"
    t.state.TextColor3 = on and COLORS.GREEN or COLORS.RED
end

-- 🥔 POTATO TOGGLE
ui.potatoToggle.btn.MouseButton1Click:Connect(function()
    if not PotatoGfx.enabled then
        setToggle(ui.potatoToggle, true)
        ui.Status.Text = "🥔 Enabling..."
        ui.Status.TextColor3 = COLORS.YELLOW
        task.spawn(function()
            PotatoGfx.enable()
            task.wait(0.5)
            ui.Status.Text = "🥔 Potato Graphics ON"
            ui.Status.TextColor3 = COLORS.GREEN
        end)
    else
        setToggle(ui.potatoToggle, false)
        ui.Status.Text = "Restoring..."
        ui.Status.TextColor3 = COLORS.YELLOW
        task.spawn(function()
            PotatoGfx.disable()
            task.wait(0.5)
            ui.Status.Text = "⚡ Restored to normal"
            ui.Status.TextColor3 = COLORS.YELLOW
        end)
    end
end)

-- ⚡ Speed Bypass
utility.speedEnabled = false

ui.speedToggle.btn.MouseButton1Click:Connect(function()
    utility.speedEnabled = not utility.speedEnabled
    setToggle(ui.speedToggle, utility.speedEnabled)
    if utility.speedEnabled then
        speedBypass.active = true
        ui.Status.Text = "⚡ Speed ON (300)"
        ui.Status.TextColor3 = COLORS.GREEN
    else
        speedBypass.active = false
        local char = utility.Players.LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
        ui.Status.Text = "⚡ Speed OFF"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

-- ⚡ Instant Pickup
utility.pickupEnabled = false

ui.pickupToggle.btn.MouseButton1Click:Connect(function()
    utility.pickupEnabled = not utility.pickupEnabled
    setToggle(ui.pickupToggle, utility.pickupEnabled)
    if utility.pickupEnabled then
        local ok = utility:startInstantPickup()
        if ok then
            ui.Status.Text = "⚡ Instant Pickup ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ Pickup failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.pickupEnabled = false
            setToggle(ui.pickupToggle, false)
        end
    else
        utility:stopInstantPickup()
        ui.Status.Text = "⚡ Instant Pickup OFF"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

-- 🛡️ Anti-Ragdoll
utility.antiRagdollEnabled = false

ui.ragdollToggle.btn.MouseButton1Click:Connect(function()
    utility.antiRagdollEnabled = not utility.antiRagdollEnabled
    setToggle(ui.ragdollToggle, utility.antiRagdollEnabled)
    if utility.antiRagdollEnabled then
        local ok, err = utility:startAntiRagdoll()
        if ok then
            ui.Status.Text = "🛡️ Anti-Ragdoll ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ Anti-Ragdoll failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.antiRagdollEnabled = false
            setToggle(ui.ragdollToggle, false)
        end
    else
        utility:stopAntiRagdoll()
        ui.Status.Text = "🛡️ Anti-Ragdoll OFF"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

-- 🪤 Anti-Trap
utility.antiTrapEnabled = false

ui.antiTrapToggle.btn.MouseButton1Click:Connect(function()
    utility.antiTrapEnabled = not utility.antiTrapEnabled
    setToggle(ui.antiTrapToggle, utility.antiTrapEnabled)
    if utility.antiTrapEnabled then
        local ok = utility:startAntiTrap()
        if ok then
            ui.Status.Text = "🪤 Anti-Trap ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ Anti-Trap failed"
            ui.Status.TextColor3 = COLORS.RED
            utility.antiTrapEnabled = false
            setToggle(ui.antiTrapToggle, false)
        end
    else
        utility:stopAntiTrap()
        ui.Status.Text = "🪤 Anti-Trap OFF"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

-- 💰 Auto Grab
ui.autoGrabToggle.btn.MouseButton1Click:Connect(function()
    utility.autoGrabEnabled = not utility.autoGrabEnabled
    setToggle(ui.autoGrabToggle, utility.autoGrabEnabled)
    if utility.autoGrabEnabled then
        local ok, err = utility:startAutoGrab()
        if ok then
            ui.Status.Text = "💰 Auto Grab ON"
            ui.Status.TextColor3 = COLORS.GREEN
        else
            ui.Status.Text = "❌ " .. tostring(err)
            ui.Status.TextColor3 = COLORS.RED
            utility.autoGrabEnabled = false
            setToggle(ui.autoGrabToggle, false)
        end
    else
        utility:stopAutoGrab()
        ui.Status.Text = "💰 Auto Grab OFF"
        ui.Status.TextColor3 = COLORS.YELLOW
    end
end)

-- Live update para sa GrabInfo
utility.RunService.Heartbeat:Connect(function()
    if not utility.autoGrabEnabled then return end
    local now = tick()
    if utility.lastGrabInfoUpdate and (now - utility.lastGrabInfoUpdate) < 0.5 then return end
    utility.lastGrabInfoUpdate = now
    local eggs = utility:findAllHighValueEggs()
    if #eggs > 0 then
        local top = eggs[1]
        ui.GrabInfo.Text = ("Next: %s | Grabbed: %d"):format(
            string.format("%.2fM", top.value / 1e6),
            utility.autoGrabCount or 0)
    else
        ui.GrabInfo.Text = ("Next: -- | Grabbed: %d"):format(utility.autoGrabCount or 0)
    end
end)

-- Close
ui.CloseBtn.MouseButton1Click:Connect(function()
    if PotatoGfx.enabled then PotatoGfx.disable() end
    utility.speedEnabled = false
    utility.pickupEnabled = false
    utility.antiRagdollEnabled = false
    utility.antiTrapEnabled = false
    utility.autoGrabEnabled = false
    speedBypass.active = false
    utility:stopInstantPickup()
    utility:stopAntiRagdoll()
    utility:stopAntiTrap()
    utility:stopAutoGrab()
    ui.ScreenGui:Destroy()
end)

ui.Status.Text = "Status: ✅ Ready"
ui.Status.TextColor3 = COLORS.GREEN
