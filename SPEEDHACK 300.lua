local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local SpeedToggle = Instance.new("TextButton") -- Gagamitin bilang toggle

-- UI Setup
ScreenGui.Parent = game.CoreGui

MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

SpeedToggle.Size = UDim2.new(1, 0, 1, 0)
SpeedToggle.Position = UDim2.new(0, 0, 0, 0)
SpeedToggle.Text = "Speed OFF"
SpeedToggle.Parent = MainFrame

local speedOn = false
local defaultSpeed = 16 -- Default speed
local hackSpeed = 300 -- Naka-set nang speed na naka-on

local playerHumanoid = nil

local function getHumanoid()
    if game.Players.LocalPlayer and game.Players.LocalPlayer.Character then
        return game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function updateSpeed()
    local humanoid = getHumanoid()
    if humanoid then
        if speedOn then
            humanoid.WalkSpeed = hackSpeed
        else
            humanoid.WalkSpeed = defaultSpeed
        end
    end
end

SpeedToggle.MouseButton1Click:Connect(function()
    speedOn = not speedOn
    if speedOn then
        SpeedToggle.Text = "Speed ON"
    else
        SpeedToggle.Text = "Speed OFF"
    end
    updateSpeed()
end)

-- Siguraduhing mag-update ang speed kapag nag-respawn ang character
game.Players.LocalPlayer.CharacterAdded:Connect(function()
    wait(1) -- maliit na delay para sa respawn
    if not speedOn then
        local humanoid = getHumanoid()
        if humanoid then
            humanoid.WalkSpeed = defaultSpeed
        end
    end
end)

-- I-initialize ang speed kapag nagsimula ang game
wait(1)
updateSpeed()
    
