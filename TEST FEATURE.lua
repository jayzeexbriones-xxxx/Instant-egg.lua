-- ============================================================
-- FPS UNLOCKER (Max Frame Rate)
-- ============================================================

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- ============================================================
-- SETTINGS
-- ============================================================
local TARGET_FPS = 240 -- Palitan mo depende sa phone mo:
                       -- 60 = Normal
                       -- 120 = Smooth
                       -- 144 = Very Smooth
                       -- 240 = Ultra Smooth (kung kaya ng phone mo)
                       -- 360 = Extreme (kung gaming phone)

-- ============================================================
-- FPS UNLOCK FUNCTION
-- ============================================================
local function UnlockFPS()
    -- Method 1: Gamitin yung internal Roblox setting
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    
    -- Method 2: I-set yung Frame Rate Manager
    pcall(function()
        local fpsCap = settings().Rendering.FrameRateCap
        if fpsCap then
            fpsCap.Value = TARGET_FPS
        end
    end)
    
    -- Method 3: I-set yung max FPS sa lahat ng possible na lugar
    pcall(function()
        for _, v in pairs(getgc()) do
            if type(v) == "table" then
                pcall(function()
                    if v.FrameRateCap then
                        v.FrameRateCap = TARGET_FPS
                    end
                    if v.MaxFPS then
                        v.MaxFPS = TARGET_FPS
                    end
                end)
            end
        end
    end)
    
    -- Method 4: I-disable yung vsync at iba pang limiters
    pcall(function()
        if UserInputService.TouchEnabled then
            -- Mobile settings
            settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
            settings().Rendering.SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1
        end
    end)
end

-- ============================================================
-- FPS BOOSTER (Tanggalin lag sa rendering)
-- ============================================================
local function BoostPerformance()
    -- I-lower yung graphics quality para mas mabilis
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
    
    -- I-disable yung shadows
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.Brightness = 0
    end)
    
    -- I-disable yung post-processing effects
    local Lighting = game:GetService("Lighting")
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end
end

-- ============================================================
-- RUN
-- ============================================================
UnlockFPS()
BoostPerformance()

-- ============================================================
-- UI
-- ============================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FPSUnlockerUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = player:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 200, 0, 110)
Main.Position = UDim2.new(0.5, -100, 0.3, 0)
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
Title.Text = "⚡ FPS Unlocker"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local FPSLabel = Instance.new("TextLabel")
FPSLabel.Size = UDim2.new(1, -20, 0, 25)
FPSLabel.Position = UDim2.new(0, 10, 0, 35)
FPSLabel.BackgroundTransparency = 1
FPSLabel.Text = "FPS: 0"
FPSLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
FPSLabel.Font = Enum.Font.GothamBold
FPSLabel.TextSize = 16
FPSLabel.Parent = Main

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 20)
Status.Position = UDim2.new(0, 10, 0, 65)
Status.BackgroundTransparency = 1
Status.Text = "Unlocked: " .. TARGET_FPS .. " FPS"
Status.TextColor3 = Color3.fromRGB(255, 200, 0)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.Parent = Main

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(1, -20, 0, 25)
RefreshBtn.Position = UDim2.new(0, 10, 0, 85)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
RefreshBtn.Text = "RE-UNLOCK FPS"
RefreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.TextSize = 10
RefreshBtn.Parent = Main

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = RefreshBtn

-- ============================================================
-- FPS COUNTER
-- ============================================================
local frameCount = 0
local lastTime = tick()

RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    
    if currentTime - lastTime >= 1 then
        FPSLabel.Text = "FPS: " .. frameCount
        frameCount = 0
        lastTime = currentTime
    end
end)

-- ============================================================
-- REFRESH BUTTON
-- ============================================================
RefreshBtn.MouseButton1Click:Connect(function()
    UnlockFPS()
    BoostPerformance()
    Status.Text = "Re-unlocked: " .. TARGET_FPS .. " FPS"
end)
