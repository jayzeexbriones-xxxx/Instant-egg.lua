
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

-- Colors
local BG = Color3.fromRGB(0, 0, 0)
local CARD_BG = Color3.fromRGB(12, 12, 12)
local CARD_HOV = Color3.fromRGB(20, 20, 20)
local BORDER = Color3.fromRGB(35, 35, 35)
local BORDER2 = Color3.fromRGB(65, 65, 65)
local WHITE = Color3.fromRGB(255, 255, 255)
local DIM = Color3.fromRGB(160, 160, 160)
local KB_BG = Color3.fromRGB(8, 8, 8)

-- State variables
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

-- Config save/load functions (unchanged)
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

-- Remove existing GUIs if any
for _, name in pairs({"ZynoxAutoBatDesyncGUI", "MwvaneNewaBatDesyncGUI", "PhazeAutoBatDesyncGUI", "ZynoxDiscordLink"}) do
    local old = game:GetService("CoreGui"):FindFirstChild(name)
    if old then old:Destroy() end
    local pGui = LP:FindFirstChild("PlayerGui")
    if pGui then
        local oldPlayerGui = pGui:FindFirstChild(name)
        if oldPlayerGui then oldPlayerGui:Destroy() end
    end
end

-- Create GUI (unchanged, omitted for brevity)

-- [Insert your existing GUI creation code here]

-- Speed Hack variables
local speedHackEnabled = false
local originalWalkSpeed = 16 -- default speed, can be adjusted
local speedMultiplier = 2 -- speed factor

-- Function to toggle speed hack
local function toggleSpeedHack(state)
    local humanoid = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if state then
            humanoid.WalkSpeed = originalWalkSpeed * speedMultiplier
        else
            humanoid.WalkSpeed = originalWalkSpeed
        end
        speedHackEnabled = state
    end
end

-- UI switch for speed hack
-- Assuming switchBg and statusLbl are already defined in your UI code
switchBg.MouseButton1Click:Connect(function()
    local newState = not speedHackEnabled
    toggleSpeedHack(newState)
    -- Update UI visuals
    TweenService:Create(switchThumb, TweenInfo.new(0.2), {
        Position = newState and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8),
        BackgroundColor3 = newState and WHITE or DIM
    }):Play()
    TweenService:Create(switchBg, TweenInfo.new(0.2), {
        BackgroundColor3 = newState and WHITE or Color3.fromRGB(25, 25, 25)
    }):Play()
    statusLbl.Text = newState and "ENABLED" or "DISABLED"
    statusLbl.TextColor3 = newState and WHITE or DIM
end)

-- Remove anti-hit and anti-die functions
-- (No need to include them)

-- Rest of your existing code...

-- Main heartbeat to control auto-bat and speed hack
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

-- Keyboard input for toggling auto-bat and GUI visibility
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
