-- ============================================
-- TP CHICKEN EGG -> STEAL -> HATCH -> TP BEST EGG -> STAY
-- With UI (Rayfield) ON/OFF toggle
-- Executor: Delta (latest)
-- ============================================

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- ============ LOAD RAYFIELD UI ============
local Rayfield
do
    local ok, res = pcall(function()
        return game:HttpGet("https://sirius.menu/rayfield")
    end)
    if ok and type(res) == "string" and #res > 1000 then
        local okLoad, lib = pcall(function() return loadstring(res)() end)
        if okLoad and type(lib) == "table" then
            Rayfield = lib
        end
    end
    if not Rayfield then
        warn("[AUTO] Failed to load Rayfield UI")
        return
    end
end

-- ============ CONFIG ============
getgenv().config = {
    chickenArea = "Forest",
    minarea = 9,
    tpSpeed = 350,
    arriveDist = 5,
    hatchWait = 3,
}

local utility = {
    Workspace = Workspace,
    Players = Players,
    ReplicatedStorage = RS,
    running = false,
}

utility.areas = {
    "Forest", "Lake", "Desert", "Jungle", "Snow",
    "Volcano", "Abyss Ocean", "Prehistoric", "Cosmic",
    "Cherry Blossom", "Titan Temple",
}

-- ============ INIT ============
function utility:init()
    self.LocalPlayer = self.Players.LocalPlayer

    if not fireproximityprompt then
        return self.LocalPlayer:Kick("Executor missing fireproximityprompt")
    end

    self.Client = self.ReplicatedStorage:FindFirstChild("Client")
    if not self.Client then return warn("No Client") end

    self.EggState = require(self.Client:FindFirstChild("EggState"))
    if not self.EggState then return warn("No EggState") end

    local ok, AreaEggSlotIdentity = pcall(function()
        return require(self.ReplicatedStorage.Shared.Util.AreaEggSlotIdentity)
    end)
    self.AreaEggSlotIdentity = ok and AreaEggSlotIdentity or nil

    return true
end

-- ============ GET CHICKEN EGG ============
function utility:getChickenEgg()
    local s, r = pcall(function()
        for _, data in next, self.EggState.ReadFieldEggs().Records do
            if data.AreaId == getgenv().config.chickenArea then
                if data.State == "Slot" or data.State == "Dropped" then
                    return data
                end
            end
        end
        return nil
    end)
    if s and r then return r end
    return nil
end

-- ============ GET BEST EGG ============
function utility:getBestEgg()
    local s, r = pcall(function()
        local egg = nil
        local biggest = 0
        for _, data in next, self.EggState.ReadFieldEggs().Records do
            local idx = table.find(self.areas, data.AreaId)
            if idx and idx > getgenv().config.minarea then
                if data.State == "Slot" or data.State == "Dropped" then
                    if data.AssetScale > biggest then
                        biggest = data.AssetScale
                        egg = data
                    end
                end
            end
        end
        return egg
    end)
    if s and r then return r end
    return nil
end

-- ============ TP / GOTO ============
function utility:GoTo(pos)
    pcall(function()
        local dist = math.huge
        repeat
            if not self.running then return end
            local dt = task.wait(0.01)
            local hrp = self.LocalPlayer.Character
                and self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then break end
            local start = hrp.Position
            dist = (pos - start).Magnitude
            local half = start + (pos - start).Unit * dt * getgenv().config.tpSpeed
            self.LocalPlayer.Character:MoveTo(half)
        until dist <= getgenv().config.arriveDist
    end)
end

-- ============ PROXIMITY PROMPT ============
function utility:getPromptForEgg(egg)
    local s, r = pcall(function()
        local prompts = self.Workspace:QueryDescendants("#CarryAreaEgg")
        local closest, closestDist = nil, math.huge
        for _, prompt in next, prompts do
            local p = prompt.Parent
            if p and p:IsA("BasePart") then
                local d = (egg.BoundsCFrame.Position - p.Position).Magnitude
                if d < closestDist then
                    closestDist = d
                    closest = prompt
                end
            end
        end
        return closest
    end)
    return s and r or nil
end

-- ============ STEAL EGG ============
function utility:stealEgg(egg, label)
    if not egg then return false end
    label = label or "egg"

    warn(("[AUTO] TP sa %s..."):format(label))
    local pos = egg.BoundsCFrame and egg.BoundsCFrame.Position
    if not pos then return false end

    self:GoTo(pos)
    if not self.running then return false end
    task.wait(0.3)

    local slotKey = nil
    if self.AreaEggSlotIdentity
        and self.AreaEggSlotIdentity.LooksLikeFirstAreaUid
        and self.AreaEggSlotIdentity.LooksLikeFirstAreaUid(egg.Uid) then
        slotKey = self.AreaEggSlotIdentity.SlotKey(egg.AreaId, egg.NestId)
    end

    local ok, res = pcall(function()
        return self.EggState.CarryFieldEgg(egg.Uid, slotKey)
    end)
    if ok and res == true then
        warn(("[AUTO] Na-steal %s (instant)"):format(label))
        return true
    end

    local prompt = self:getPromptForEgg(egg)
    if prompt then
        pcall(function() fireproximityprompt(prompt) end)
        task.wait(0.3)
        warn(("[AUTO] Na-steal %s (prompt)"):format(label))
        return true
    end

    warn(("[AUTO] Failed i-steal %s"):format(label))
    return false
end

-- ============ WAIT FOR HATCH ============
function utility:waitForHatch(uid)
    local maxWait = getgenv().config.hatchWait
    local t0 = os.clock()

    warn("[AUTO] Hinihintay ma-tuka...")
    repeat
        if not self.running then return false end
        task.wait(0.2)
        local stillThere = false
        pcall(function()
            local rec = self.EggState.ReadFieldEgg and self.EggState.ReadFieldEgg(uid)
            if rec and (rec.State == "Slot" or rec.State == "Dropped") then
                stillThere = true
            end
        end)
        if not stillThere then
            warn("[AUTO] Na-tuka na!")
            return true
        end
    until (os.clock() - t0) > maxWait

    warn("[AUTO] Hatch timeout - tuloy pa rin sa best egg")
    return false
end

-- ============ MAIN FLOW ============
function utility:run()
    if not self:init() then return end
    self.running = true

    warn("=== AUTO TP CHICKEN EGG START ===")

    -- STEP 1: Chicken Egg
    local chicken = self:getChickenEgg()
    if not chicken then
        warn("[AUTO] Walang chicken egg sa Forest!")
        self.running = false
        return
    end
    local chickenUid = chicken.Uid
    self:stealEgg(chicken, "Chicken Egg")

    if not self.running then return end

    -- STEP 2: Wait hatch
    self:waitForHatch(chickenUid)

    if not self.running then return end

    -- STEP 3: Best Egg
    local best = self:getBestEgg()
    if not best then
        warn("[AUTO] Walang best egg na nahanap!")
        self.running = false
        return
    end
    self:stealEgg(best, "Best Egg")

    -- STEP 4: STAY
    warn("=== TAPOS — NASA BEST EGG AREA NA, STAY LANG DITO ===")
    self.running = false
end

-- ============ UI ============
local Window = Rayfield:CreateWindow({
    name = "Auto TP Chicken Egg",
    loadingTitle = "Loading...",
    loadingSubtitle = "by Blyxo-style logic",
    configurationSaving = {
        Enabled = false,
    },
    discord = {
        Enabled = false,
    },
    keySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)

MainTab:CreateSection("Auto TP")

MainTab:CreateToggle({
    name = "Auto TP Chicken Egg",
    currentValue = false,
    flag = "AutoTPChickenEgg",
    callback = function(value)
        if value then
            if utility.running then
                warn("[AUTO] Already running!")
                return
            end
            task.spawn(function()
                utility:run()
            end)
        else
            utility.running = false
            warn("[AUTO] Stopped.")
        end
    end,
})

MainTab:CreateSection("Info")

MainTab:CreateParagraph({
    Title = "Flow",
    Content = "TP Chicken Egg → Steal → Wait Hatch → TP Best Egg → Stay",
})

MainTab:CreateButton({
    name = "Refresh Eggs",
    callback = function()
        if not utility.EggState then utility:init() end
        local chicken = utility:getChickenEgg()
        local best = utility:getBestEgg()
        if chicken then
            warn(("[REFRESH] Chicken Egg: %s"):format(chicken.Uid))
        else
            warn("[REFRESH] Walang chicken egg.")
        end
        if best then
            warn(("[REFRESH] Best Egg: %s (%s)"):format(best.Uid, best.AreaId))
        else
            warn("[REFRESH] Walang best egg.")
        end
    end,
})
