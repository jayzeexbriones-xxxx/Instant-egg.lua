-- ============================================================
-- ULTIMATE LAG REMOVER
-- Pader + Trees + Clouds + Moon + Guards + Lahat ng nagpapalag
-- ============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ============================================================
-- SETTINGS
-- ============================================================

-- ITO YUNG MGA HINDI TATANGGALIN (Importante)
local KEEP_KEYWORDS = {
    "Ground", "Floor", "Base", "Terrain",
    "Baseplate", "Platform", "Spawn", "Safe",
    "Path", "Road", "HumanoidRootPart"
}

-- ITO YUNG MGA TATANGGALIN (Lahat ng nagpapalag)
local REMOVE_KEYWORDS = {
    -- Pader at harang
    "Wall", "Fence", "Barrier", "Border",
    "Gate", "Door", "Building", "House",
    
    -- Puno at halaman
    "Tree", "Bush", "Plant", "Leaf", "Leaves",
    "Grass", "Flower", "Rock", "Stone", "Boulder",
    "Foliage", "Vegetation",
    
    -- Kalangitan
    "Cloud", "Clouds", "Sky", "Atmosphere", "Fog",
    "Moon", "Sun", "Star", "Stars", "Galaxy",
    "Nebula", "Aurora",
    
    -- Guards at NPC
    "Guard", "Security", "NPC", "Enemy", "Bot",
    "Monster", "Creature", "Animal",
    
    -- Effects na nagpapalag
    "Particle", "Smoke", "Fire", "Spark", "Beam",
    "Trail", "Explosion", "Effect",
    
    -- Generic names
    "Part", "Brick", "Model", "Decal", "Texture",
    "Mesh", "MeshPart", "Union", "Negate"
}

-- ============================================================
-- WORKSPACE REMOVER
-- ============================================================
local function RemoveWorkspaceLag()
    local count = 0
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        
        -- I-check ang klase ng object
        local isTarget = obj:IsA("BasePart") 
            or obj:IsA("Model") 
            or obj:IsA("Decal") 
            or obj:IsA("Texture")
            or obj:IsA("ParticleEmitter")
            or obj:IsA("Trail")
            or obj:IsA("Beam")
            or obj:IsA("Fire")
            or obj:IsA("Smoke")
            or obj:IsA("Sparkles")
            or obj:IsA("Explosion")
        
        if isTarget then
            
            -- I-check kung KEEP (hindi tatanggalin)
            local keep = false
            for _, keyword in pairs(KEEP_KEYWORDS) do
                if string.find(obj.Name:lower(), keyword:lower()) then
                    keep = true
                    break
                end
            end
            
            -- I-check kung REMOVE (tatanggalin)
            local remove = false
            for _, keyword in pairs(REMOVE_KEYWORDS) do
                if string.find(obj.Name:lower(), keyword:lower()) then
                    remove = true
                    break
                end
            end
            
            -- Tanggalin kung dapat i-remove at hindi dapat i-keep
            if not keep and remove then
                if obj:IsA("BasePart") then
                    obj.Transparency = 1
                    obj.CanCollide = false
                    count = count + 1
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                    count = count + 1
                elseif obj:IsA("ParticleEmitter") 
                    or obj:IsA("Trail") 
                    or obj:IsA("Beam")
                    or obj:IsA("Fire")
                    or obj:IsA("Smoke")
                    or obj:IsA("Sparkles") then
                    obj.Enabled = false
                    count = count + 1
                elseif obj:IsA("Model") then
                    for _, part in pairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Transparency = 1
                            part.CanCollide = false
                        elseif part:IsA("Decal") or part:IsA("Texture") then
                            part.Transparency = 1
                        elseif part:IsA("ParticleEmitter") 
                            or part:IsA("Trail") 
                            or part:IsA("Beam")
                            or part:IsA("Fire")
                            or part:IsA("Smoke")
                            or part:IsA("Sparkles") then
                            part.Enabled = false
                        end
                    end
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

-- ============================================================
-- LIGHTING REMOVER (Ulap, Buwan, Atmosphere)
-- ============================================================
local function RemoveLightingLag()
    local count = 0
    
    for _, obj in pairs(Lighting:GetDescendants()) do
        if obj:IsA("Clouds") then
            obj.Enabled = false
            count = count + 1
        elseif obj:IsA("Atmosphere") then
            obj.Density = 0
            obj.Haze = 0
            obj.Glare = 0
            count = count + 1
        elseif obj:IsA("Sky") then
            obj.Parent = nil
            count = count + 1
        elseif obj:IsA("BloomEffect") 
            or obj:IsA("BlurEffect") 
            or obj:IsA("SunRaysEffect") 
            or obj:IsA("DepthOfFieldEffect")
            or obj:IsA("ColorCorrectionEffect") then
            obj.Enabled = false
            count = count + 1
        end
    end
    
    return count
end

-- ============================================================
-- UI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LagRemoverUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 220, 0, 120)
Main.Position = UDim2.new(0.5, -110, 0.3, 0)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
Title.Text = "🚀 Ultimate Lag Remover"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 40)
ToggleBtn.Position = UDim2.new(0, 10, 0, 40)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ToggleBtn.Text = "REMOVE ALL LAG: OFF"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = Main

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent = ToggleBtn

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 90)
Status.BackgroundTransparency = 1
Status.Text = "Ready"
Status.TextColor3 = Color3.fromRGB(255, 200, 0)
Status.TextSize = 10
Status.Font = Enum.Font.Gotham
Status.Parent = Main

-- ============================================================
-- TOGGLE LOGIC
-- ============================================================
local isRemoved = false

ToggleBtn.MouseButton1Click:Connect(function()
    isRemoved = not isRemoved
    
    if isRemoved then
        ToggleBtn.Text = "REMOVE ALL LAG: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
        Status.Text = "Removing lag objects..."
        
        local wsCount = RemoveWorkspaceLag()
        local lightCount = RemoveLightingLag()
        
        Status.Text = "Removed " .. (wsCount + lightCount) .. " objects!"
    else
        ToggleBtn.Text = "REMOVE ALL LAG: OFF"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        Status.Text = "Rejoin to restore"
    end
end)
