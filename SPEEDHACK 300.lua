-- // Grow a Garden 2 | Unified Auto Farm GUI
-- // Auto Harvest + Auto Sell + Auto Buy + Auto Plant

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local lp           = Players.LocalPlayer
local Event        = game:GetService("ReplicatedStorage").SharedModules.Packet.RemoteEvent
local Gardens      = workspace:WaitForChild("Gardens")

-- ══════════════════════════════════════
--             GLOBAL FLAGS
-- ══════════════════════════════════════
getgenv().AutoHarvest  = false
getgenv().AutoSell     = false
getgenv().AutoBuy      = false
getgenv().AutoPlant    = false
getgenv().SellInterval = 1
getgenv().BuyInterval  = 1
getgenv().CachedPlot   = nil

-- ══════════════════════════════════════
--          HARVEST PACKETS
-- ══════════════════════════════════════
local function buildProximityPacket(plantId, fruitId)
    return buffer.fromstring("\xB2\x00$" .. plantId .. "$" .. fruitId)
end

local function buildHarvestPacket(fruits)
    local payload = "a\x00\x1C"
    local idx = 1
    local shovelStr = "Shovel:Shovel"
    payload = payload .. "\x05" .. string.char(idx) .. "\x0B" .. string.char(#shovelStr) .. shovelStr
    idx += 1
    for _, f in ipairs(fruits) do
        local weight  = math.round(f.SizeMulti * 1000)
        local itemStr = "Fruit:" .. f.CorePartName .. ":" .. tostring(weight)
        payload = payload .. "\x05" .. string.char(idx) .. "\x0B" .. string.char(#itemStr) .. itemStr
        idx += 1
    end
    return buffer.fromstring(payload .. "\x00")
end

local function buildConfirmPacket(plantId, fruitId, pos)
    local b = buffer.create(12)
    buffer.writef32(b, 0, pos.X)
    buffer.writef32(b, 4, pos.Y)
    buffer.writef32(b, 8, pos.Z)
    return buffer.fromstring("\x08\x01$" .. plantId .. "$" .. fruitId .. buffer.tostring(b))
end

local function getPlantData()
    local plantMap = {}
    for _, plot in ipairs(Gardens:GetChildren()) do
        local plantsFolder = plot:FindFirstChild("Plants")
        if not plantsFolder then continue end
        for _, plant in ipairs(plantsFolder:GetChildren()) do
            local fruitsFolder = plant:FindFirstChild("Fruits")
            if not fruitsFolder then continue end
            for _, fruit in ipairs(fruitsFolder:GetChildren()) do
                local coreName  = fruit:GetAttribute("CorePartName")
                local sizeMulti = fruit:GetAttribute("SizeMulti")
                local plantId   = fruit:GetAttribute("PlantId")
                local fruitId   = fruit:GetAttribute("FruitId")
                local age       = fruit:GetAttribute("Age")
                local maxAge    = fruit:GetAttribute("MaxAge")
                if not (coreName and sizeMulti and plantId and fruitId) then continue end
                if age and maxAge and age < maxAge then continue end
                if not plantMap[plantId] then
                    local pos = Vector3.new(0, 0, 0)
                    if fruit:IsA("Model") then
                        local part = fruit:FindFirstChildWhichIsA("BasePart")
                        if part then pos = part.Position end
                    elseif fruit:IsA("BasePart") then
                        pos = fruit.Position
                    end
                    plantMap[plantId] = { plantId = plantId, firstFruit = { id = fruitId, pos = pos }, fruits = {} }
                end
                table.insert(plantMap[plantId].fruits, { CorePartName = coreName, SizeMulti = sizeMulti })
            end
        end
    end
    return plantMap
end

-- ══════════════════════════════════════
--           SELL PACKETS
-- ══════════════════════════════════════
local P1 = buffer.fromstring("\x9B\x00\x1F")
local P2 = buffer.fromstring("\x9A\x00\x20")
local P3 = buffer.fromstring("a\x00\x1C\x05\x01\x0B\x0DShovel:Shovel\x00")

-- ══════════════════════════════════════
--           BUY PACKETS
-- ══════════════════════════════════════
local function buyPacket(seedName)
    return buffer.fromstring("h\x00" .. string.char(#seedName) .. seedName)
end

getgenv().BuyTargets = {
    ["Carrot"] = true, ["Strawberry"] = true, ["Blueberry"] = true,
    ["Tulip"]  = true, ["Bamboo"]     = true, ["Mushroom"]  = true,
}

local Seeds = {
    "Carrot","Strawberry","Blueberry","Tomato","Apple","Tulip","Bamboo","Corn",
    "Cactus","Pineapple","Banana","Grape","Coconut","Green Bean","Mango",
    "Dragon Fruit","Acorn","Cherry","Mushroom","Poison Apple","Pomegranate",
    "Sunflower","Moon Bloom","Venus Fly Trap","Dragons Breath",
}

-- ══════════════════════════════════════
--           PLANT HELPERS
-- ══════════════════════════════════════
local SEED_SET = {}
for _, n in ipairs(Seeds) do SEED_SET[n] = true end

local function buildPlantPacket(seedName, pos)
    local b = buffer.create(12)
    buffer.writef32(b, 0, pos.X)
    buffer.writef32(b, 4, pos.Y)
    buffer.writef32(b, 8, pos.Z)
    return buffer.fromstring("\x04\x00" .. buffer.tostring(b) .. string.char(#seedName) .. seedName)
end

local function getOwnPlot()
    if getgenv().CachedPlot and getgenv().CachedPlot.Parent then
        return getgenv().CachedPlot
    end
    local uid = tostring(lp.UserId)
    for _, plot in ipairs(Gardens:GetChildren()) do
        local pf = plot:FindFirstChild("Plants")
        if pf then
            for _, plant in ipairs(pf:GetChildren()) do
                if plant.Name:sub(1, #uid) == uid then
                    getgenv().CachedPlot = plot
                    return plot
                end
            end
        end
    end
    if lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
        local myPos = lp.Character.HumanoidRootPart.Position
        local best, bestDist = nil, math.huge
        for _, plot in ipairs(Gardens:GetChildren()) do
            local sp = plot:FindFirstChild("SpawnPoint")
            if sp then
                local d = (sp.Position - myPos).Magnitude
                if d < bestDist then bestDist = d; best = plot end
            end
        end
        if best and bestDist < 150 then
            getgenv().CachedPlot = best
            return best
        end
    end
end

local SPACING = 5
local function columnToPositions(col)
    local positions = {}
    local cx, cy, cz = col.Position.X, col.Position.Y, col.Position.Z
    local sx, sz = col.Size.X, col.Size.Z
    local Y = cy + 0.25
    local x = cx - sx/2 + SPACING/2
    while x <= cx + sx/2 - SPACING/2 + 0.01 do
        local z = cz - sz/2 + SPACING/2
        while z <= cz + sz/2 - SPACING/2 + 0.01 do
            table.insert(positions, Vector3.new(x, Y, z))
            z = z + SPACING
        end
        x = x + SPACING
    end
    return positions
end

local function isOccupied(pos, plantsFolder, pending)
    for _, plant in ipairs(plantsFolder:GetChildren()) do
        local base = plant:FindFirstChildWhichIsA("BasePart", true)
        if base then
            local dx = base.Position.X - pos.X
            local dz = base.Position.Z - pos.Z
            if (dx*dx + dz*dz) < 9 then return true end
        end
    end
    for _, p in ipairs(pending) do
        local dx = p.X - pos.X
        local dz = p.Z - pos.Z
        if (dx*dx + dz*dz) < 9 then return true end
    end
    return false
end

local function nextSeed()
    for _, tool in ipairs(lp.Backpack:GetChildren()) do
        if SEED_SET[tool.Name] then return tool end
    end
    if lp.Character then
        for _, tool in ipairs(lp.Character:GetChildren()) do
            if tool:IsA("Tool") and SEED_SET[tool.Name] then return tool end
        end
    end
end

local function plantAt(pos)
    local tool = nextSeed()
    if not tool then return false end
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
    task.wait(0.08)
    if tool.Parent == lp.Backpack then
        hum:EquipTool(tool)
        task.wait(0.08)
    end
    local equipped = lp.Character:FindFirstChild(tool.Name)
    if not equipped then hum:UnequipTools(); return false end
    Event:FireServer(buildPlantPacket(equipped.Name, pos), {equipped})
    task.wait(0.08)
    hum:UnequipTools()
    return true
end

-- cache plot on load
task.defer(function() getOwnPlot() end)

-- ══════════════════════════════════════
--                GUI
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "GaG2FarmGui"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = game:GetService("CoreGui")

-- main frame
local Frame = Instance.new("Frame", ScreenGui)
Frame.Size             = UDim2.new(0, 240, 0, 330)
Frame.Position         = UDim2.new(0, 20, 0, 20)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BorderSizePixel  = 0
Frame.Active           = true
Frame.Draggable        = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 12)

-- title bar
local TitleBar = Instance.new("Frame", Frame)
TitleBar.Size             = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Size                   = UDim2.new(1, -10, 1, 0)
TitleLabel.Position               = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Font                   = Enum.Font.GothamBold
TitleLabel.TextColor3             = Color3.fromRGB(220, 220, 220)
TitleLabel.TextSize               = 14
TitleLabel.Text                   = "🌱 Grow a Garden 2"
TitleLabel.TextXAlignment         = Enum.TextXAlignment.Left

-- divider line
local Divider = Instance.new("Frame", Frame)
Divider.Size             = UDim2.new(1, -24, 0, 1)
Divider.Position         = UDim2.new(0, 12, 0, 40)
Divider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Divider.BorderSizePixel  = 0

-- helper to build each toggle row
local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad)

local function makeRow(parent, yPos, label, statusDefault)
    local row = Instance.new("Frame", parent)
    row.Size             = UDim2.new(1, -20, 0, 58)
    row.Position         = UDim2.new(0, 10, 0, yPos)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
    row.BorderSizePixel  = 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 8)

    local btn = Instance.new("TextButton", row)
    btn.Size             = UDim2.new(1, -10, 0, 32)
    btn.Position         = UDim2.new(0, 5, 0, 5)
    btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    btn.Font             = Enum.Font.GothamBold
    btn.TextColor3       = Color3.fromRGB(255, 255, 255)
    btn.TextSize         = 13
    btn.Text             = label .. ": OFF"
    btn.BorderSizePixel  = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    local status = Instance.new("TextLabel", row)
    status.Size                   = UDim2.new(1, 0, 0, 16)
    status.Position               = UDim2.new(0, 5, 0, 40)
    status.BackgroundTransparency = 1
    status.Font                   = Enum.Font.Gotham
    status.TextColor3             = Color3.fromRGB(110, 110, 130)
    status.TextSize               = 10
    status.Text                   = statusDefault or "Idle"
    status.TextXAlignment         = Enum.TextXAlignment.Left

    return btn, status
end

local harvestBtn, harvestStatus = makeRow(Frame, 50,  "Auto Harvest", "Idle")
local sellBtn,    sellStatus    = makeRow(Frame, 120, "Auto Sell",    "Idle")
local buyBtn,     buyStatus     = makeRow(Frame, 190, "Auto Buy",     "Idle")
local plantBtn,   plantStatus   = makeRow(Frame, 260, "Auto Plant",   "Idle")

local function toggle(btn, flag, onLabel, offLabel, onStatus, statusLabel)
    getgenv()[flag] = not getgenv()[flag]
    if getgenv()[flag] then
        btn.Text            = onLabel .. ": ON"
        statusLabel.Text    = onStatus
        statusLabel.TextColor3 = Color3.fromRGB(60, 210, 90)
        TweenService:Create(btn, tweenInfo, { BackgroundColor3 = Color3.fromRGB(50, 180, 50) }):Play()
    else
        btn.Text            = offLabel .. ": OFF"
        statusLabel.Text    = "Idle"
        statusLabel.TextColor3 = Color3.fromRGB(110, 110, 130)
        TweenService:Create(btn, tweenInfo, { BackgroundColor3 = Color3.fromRGB(200, 50, 50) }):Play()
    end
end

harvestBtn.MouseButton1Click:Connect(function() toggle(harvestBtn, "AutoHarvest", "Auto Harvest", "Auto Harvest", "Scanning...", harvestStatus) end)
sellBtn.MouseButton1Click:Connect(function()    toggle(sellBtn,    "AutoSell",    "Auto Sell",    "Auto Sell",    "Selling...",  sellStatus)    end)
buyBtn.MouseButton1Click:Connect(function()     toggle(buyBtn,     "AutoBuy",     "Auto Buy",     "Auto Buy",     "Buying...",   buyStatus)     end)
plantBtn.MouseButton1Click:Connect(function()   toggle(plantBtn,   "AutoPlant",   "Auto Plant",   "Auto Plant",   "Planting...", plantStatus)   end)

-- ══════════════════════════════════════
--           AUTO HARVEST LOOP
-- ══════════════════════════════════════
local harvestCount = 0
task.spawn(function()
    while true do
        if getgenv().AutoHarvest then
            local plantMap = getPlantData()
            local anyFound = false
            for _, data in pairs(plantMap) do
                if not getgenv().AutoHarvest then break end
                anyFound = true
                local pId = data.plantId
                local fId = data.firstFruit.id
                local pos = data.firstFruit.pos
                pcall(function() Event:FireServer(buildProximityPacket(pId, fId)) end)
                task.wait(0.01)
                pcall(function() Event:FireServer(buildHarvestPacket(data.fruits)) end)
                task.wait(0.01)
                pcall(function() Event:FireServer(buildConfirmPacket(pId, fId, pos)) end)
                harvestCount += #data.fruits
                harvestStatus.Text = "Harvested: " .. harvestCount
                task.wait(0.05)
            end
            if not anyFound then harvestStatus.Text = "Waiting for fruits..." end
            task.wait(0.1)
        else
            task.wait(0.2)
        end
    end
end)

-- ══════════════════════════════════════
--            AUTO SELL LOOP
-- ══════════════════════════════════════
local sellCount = 0
task.spawn(function()
    while true do
        if getgenv().AutoSell then
            pcall(function() Event:FireServer(P1) end)
            task.wait(0.01)
            pcall(function() Event:FireServer(P2) end)
            task.wait(0.01)
            pcall(function() Event:FireServer(P3) end)
            sellCount += 1
            sellStatus.Text = "Sold: " .. sellCount .. "x"
            task.wait(getgenv().SellInterval)
        else
            task.wait(0.2)
        end
    end
end)

-- ══════════════════════════════════════
--            AUTO BUY LOOP
-- ══════════════════════════════════════
local buyCount = 0
task.spawn(function()
    while true do
        if getgenv().AutoBuy then
            for _, name in ipairs(Seeds) do
                if not getgenv().AutoBuy then break end
                if getgenv().BuyTargets[name] then
                    pcall(function() Event:FireServer(buyPacket(name)) end)
                    buyCount += 1
                    buyStatus.Text = "Bought: " .. buyCount
                    task.wait(0.15)
                end
            end
            task.wait(getgenv().BuyInterval)
        else
            task.wait(0.2)
        end
    end
end)

-- ══════════════════════════════════════
--           AUTO PLANT LOOP
-- ══════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(0.1)
        if not getgenv().AutoPlant then continue end

        local plot = getOwnPlot()
        if not plot then
            plantStatus.Text = "No plot — stand in garden"
            task.wait(3)
            continue
        end

        local vis    = plot:FindFirstChild("Visual")
        local plants = plot:FindFirstChild("Plants")
        if not vis or not plants then task.wait(2); continue end

        local col1 = vis:FindFirstChild("PlantAreaColumn1")
        local col2 = vis:FindFirstChild("PlantAreaColumn2")

        local allPos = {}
        if col1 then for _, p in ipairs(columnToPositions(col1)) do table.insert(allPos, p) end end
        if col2 then for _, p in ipairs(columnToPositions(col2)) do table.insert(allPos, p) end end

        if #allPos == 0 then task.wait(2); continue end

        local pending  = {}
        local planted  = 0

        for _, tilePos in ipairs(allPos) do
            if not getgenv().AutoPlant then break end
            if isOccupied(tilePos, plants, pending) then continue end
            if not nextSeed() then
                plantStatus.Text = "Out of seeds"
                break
            end
            local ok = plantAt(tilePos)
            if ok then
                planted += 1
                table.insert(pending, tilePos)
                plantStatus.Text = "Planted: " .. planted
            end
            task.wait(0.35)
        end

        local sp = plot:FindFirstChild("SpawnPoint")
        if sp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
            lp.Character.HumanoidRootPart.CFrame = CFrame.new(sp.Position + Vector3.new(0, 3, 0))
        end

        task.wait(3)
    end
end)

print("[GaG2 Farm] Loaded — all four toggles ready")
