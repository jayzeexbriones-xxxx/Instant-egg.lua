local ScreenGui = Instance.new("ScreenGui")
local MainFrame = Instance.new("Frame")
local SpeedButton = Instance.new("TextButton")
local HitButton = Instance.new("TextButton")

-- UI setup
ScreenGui.Parent = game.CoreGui

MainFrame.Size = UDim2.new(0, 200, 0, 100)
MainFrame.Position = UDim2.new(0.5, -100, 0.5, -50)
MainFrame.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

SpeedButton.Size = UDim2.new(1, 0, 0.5, 0)
SpeedButton.Position = UDim2.new(0, 0, 0, 0)
SpeedButton.Text = "Speed Hack 300"
SpeedButton.Parent = MainFrame

HitButton.Size = UDim2.new(1, 0, 0.5, 0)
HitButton.Position = UDim2.new(0, 0, 0.5, 0)
HitButton.Text = "Instant Hit"
HitButton.Parent = MainFrame

local player = game.Players.LocalPlayer
local function getHumanoid()
    if player.Character then
        return player.Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

-- Speed Hack Button
SpeedButton.MouseButton1Click:Connect(function()
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 300
    end
end)

-- Instant Hit Button
HitButton.MouseButton1Click:Connect(function()
    -- Example: Instant damage logic
    -- I-implement mo dito kung paano gawin ang instant hit depende sa game mechanics
    print("Instant Hit Activated")
    -- Halimbawa, kung merong damage system:
    -- local target = -- find target
    -- if target then
    --     target:TakeDamage(9999)
    -- end
end)

-- Siguraduhing mag-reset ang speed kapag nag-respawn ang player
player.CharacterAdded:Connect(function()
    wait(1)
    local humanoid = getHumanoid()
    if humanoid then
        humanoid.WalkSpeed = 16 -- default speed
    end
end)

-- Initialize
wait(1)
local humanoid = getHumanoid()
if humanoid then
    humanoid.WalkSpeed = 16
end
