local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- Speed & Mode Variables
NS = 60                -- Normal speed
CS = 30                -- Carry speed
LAGGER_SPEED = 40      -- Lagger normal speed
LAGGER_CARRY_SPEED = 20 -- Lagger carry speed

-- Toggles
speedMode = false
autoCarrySpeedEnabled = false
instantPickupEnabled = false

-- Other game flags
laggerToggled = false
laggerPhase = 0
antiRagdollEnabled = true

-- =========================
-- GUI CREATION (same as before)
-- =========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnomalyHub_UltraUI"
ScreenGui.ResetOnSpawn = false
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LP:WaitForChild("PlayerGui")
end

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 270)
MainFrame.Position = UDim2.new(0.5, -140, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 2
MainStroke.Color = Color3.fromRGB(90, 60, 220)
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

-- Helper function to create toggle buttons
local function createToggle(yPos, labelText, defaultState, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -24, 0, 36)
    toggleFrame.Position = UDim2.new(0, 12, 0, yPos)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 32)
    toggleFrame.BackgroundTransparency = 0.25
    toggleFrame.BorderSizePixel = 0
    toggleFrame.ZIndex = 3
    toggleFrame.Parent = MainFrame

    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 8)
    toggleCorner.Parent = toggleFrame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.GothamSemibold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 4
    label.Parent = toggleFrame

    local toggleButton = Instance.new("TextButton")
    toggleButton.Size = UDim2.new(0, 50, 0, 20)
    toggleButton.Position = UDim2.new(1, -60, 0.5, -10)
    toggleButton.BackgroundColor3 = defaultState and Color3.fromRGB(90, 200, 90) or Color3.fromRGB(200, 90, 90)
    toggleButton.BorderSizePixel = 0
    toggleButton.Text = ""
    toggleButton.ZIndex = 4
    toggleButton.Parent = toggleFrame

    toggleButton.MouseButton1Click:Connect(function()
        local newState = not defaultState
        defaultState = newState
        toggleButton.BackgroundColor3 = newState and Color3.fromRGB(90, 200, 90) or Color3.fromRGB(200, 90, 90)
        callback(newState)
    end)
    return toggleButton
end

-- Create toggles
local speedModeToggle = createToggle(144, "Speed Mode (Carry / Normal)", speedMode, function(state)
    speedMode = state
end)

local autoCarryToggle = createToggle(180, "Auto Carry Speed", autoCarrySpeedEnabled, function(state)
    autoCarrySpeedEnabled = state
end)

local instantPickupToggle = createToggle(216, "Instant Pickup", instantPickupEnabled, function(state)
    instantPickupEnabled = state
end)

-- =========================
-- Your existing createInputRow, StatusText, and other setup code...
-- For brevity, assume they are same as previous and included here
-- =========================

-- Example: createInputRow, status setup, etc.
-- (You can re-use your earlier code here)

-- =========================
-- Main movement & pickup logic
-- =========================

local _linVel, _linVelAtt0, _linVelAtt1, _linVelChar = nil, nil, nil, nil
local spoofedVelocity = Vector3.zero

local function destroyLinVel()
    if _linVel then pcall(_linVel.Destroy, _linVel) end
    if _linVelAtt0 then pcall(_linVelAtt0.Destroy, _linVelAtt0) end
    if _linVelAtt1 then pcall(_linVelAtt1.Destroy, _linVelAtt1) end
    _linVel, _linVelAtt0, _linVelAtt1, _linVelChar = nil, nil, nil, nil
end

function setupLinearVelocity(char)
    destroyLinVel()
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then
        local ok, res = pcall(function() return char:WaitForChild("HumanoidRootPart", 5) end)
        if ok then hrp = res end
    end
    if not hrp then return end

    local att0 = Instance.new("Attachment")
    att0.Name = "OrvynLinVelAtt0"
    att0.Parent = hrp

    local att1 = Instance.new("Attachment")
    att1.Name = "OrvynLinVelAtt1"
    att1.Parent = hrp

    local lv = Instance.new("LinearVelocity")
    lv.Name = "OrvynLinVel"
    lv.Attachment0 = att0
    lv.Attachment1 = att1
    lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
    lv.PrimaryTangentAxis = Vector3.new(1, 0, 0)
    lv.SecondaryTangentAxis = Vector3.new(0, 0, 1)
    lv.RelativeTo = Enum.ActuatorRelativeTo.World
    lv.MaxForce = 1e6
    lv.PlaneVelocity = Vector2.new(0, 0)
    lv.Parent = hrp

    _linVel = lv
    _linVelAtt0 = att0
    _linVelAtt1 = att1
    _linVelChar = char
end

function setLinVelXZ(x, z)
    if _linVel and _linVel.Parent then
        pcall(function()
            _linVel.PlaneVelocity = Vector2.new(x, z)
        end)
    end
end

function clearLinVel()
    if _linVel and _linVel.Parent then
        pcall(function()
            _linVel.PlaneVelocity = Vector2.new(0, 0)
        end)
    end
end

function ensureLinVel()
    local char = LP.Character
    if not char then return false end
    if _linVel and _linVel.Parent and _linVelChar == char then
        return true
    end
    setupLinearVelocity(char)
    return _linVel ~= nil and _linVel.Parent ~= nil
end

-- Spoof velocity for anti-cheat
pcall(function()
    if not (getrawmetatable and setreadonly and newcclosure) then return end
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldIndex = mt.__index
    mt.__index = newcclosure(function(self, key)
        if key == "AssemblyLinearVelocity" or key == "Velocity" then
            if typeof(self) == "Instance" and self:IsA("BasePart")
                and self.Name == "HumanoidRootPart"
                and LP.Character and self:IsDescendantOf(LP.Character) then
                return spoofedVelocity
            end
        end
        return oldIndex(self, key)
    end)
    local oldNewIndex = mt.__newindex
    mt.__newindex = newcclosure(function(self, key, value)
        if key == "AssemblyLinearVelocity" or key == "Velocity" then
            if typeof(self) == "Instance" and self:IsA("BasePart")
                and self.Name == "HumanoidRootPart"
                and LP.Character and self:IsDescendantOf(LP.Character) then
                return
            end
        end
        return oldNewIndex(self, key, value)
    end)
    setreadonly(mt, true)
end)

RunService.Heartbeat:Connect(function()
    spoofedVelocity = Vector3.zero
end)

-- =========================
-- Main movement loop
-- =========================
local lastMoveDir = Vector3.zero

RunService.RenderStepped:Connect(function()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end

    -- Detect speed mode
    local ws = hum.WalkSpeed
    if ws > 18 and ws < 25 then
        speedMode = true
    else
        speedMode = false
    end

    if isRagdollState(hum) then
        lastMoveDir = Vector3.zero
        clearLinVel()
        return
    end

    ensureLinVel()

    local md = hum.MoveDirection
    local spd = getActiveMoveSpeed()

    -- Handle instant pickup
    if instantPickupEnabled then
        -- Perform a radius check for items
        local radius = 5 -- adjust as needed
        for _, item in pairs(workspace:GetChildren()) do
            if item:IsA("BasePart") and item:FindFirstChildOfClass("Tool") then
                local dist = (item.Position - hrp.Position).Magnitude
                if dist <= radius then
                    -- "Pick up" the item (e.g., move it to character)
                    -- For example, if it's a tool, parent it to the character
                    local tool = item:FindFirstChildOfClass("Tool")
                    if tool and not tool.Parent:IsA("Backpack") then
                        -- Parent tool to character's Backpack or handle
                        local backpack = LP:FindFirstChildOfClass("Backpack")
                        if backpack then
                            tool.Parent = backpack
                        end
                    end
                end
            end
        end
    end

    -- Movement
    if md.Magnitude > 0 then
        lastMoveDir = md
        setLinVelXZ(md.X * spd, md.Z * spd)
    elseif antiRagdollEnabled and lastMoveDir.Magnitude > 0 then
        local anyHeld = false
        for key in pairs(MOVE_KEYS) do
            if UIS:IsKeyDown(key) then
                anyHeld = true
                break
            end
        end
        if anyHeld then
            setLinVelXZ(lastMoveDir.X * spd, lastMoveDir.Z * spd)
        else
            clearLinVel()
        end
    else
        clearLinVel()
    end
end)

LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    pcall(setupLinearVelocity, char)
end)

task.defer(function()
    if LP.Character then
        task.wait(0.3)
        pcall(setupLinearVelocity, LP.Character)
    end
end)
