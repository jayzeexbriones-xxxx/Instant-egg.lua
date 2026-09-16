pcall(function(...)
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Lutosys/opensrc/refs/heads/main/stealaeggspeedbypass.lua"))()
end)

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
    spawnCF = CFrame.new(514, 71, -368),  -- Forest spawn / bypass point
    chickenArea = "Forest",
    minarea = 10,
    tpSpeed = 430,
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
    "Forest",         -- 1
    "Lake",           -- 2
    "Desert",         -- 3
    "Jungle",         -- 4
    "Snow",           -- 5
    "Volcano",        -- 6
    "Abyss Ocean",    -- 7
    "Prehistoric",    -- 8
    "Cosmic",         -- 9
    "Cherry Blossom", -- 10
    "Titan Temple",   -- 11
    "Light Dark",     -- 12
}

-- ============ GET CHICKEN EGG (any sa Forest) ============
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
        local bestarea = 0
        for _, data in next, self.EggState.ReadFieldEggs().Records do
            local idx = table.find(self.areas, data.AreaId)
            if idx and idx >= getgenv().config.minarea then
                if idx > bestarea then
                    bestarea = idx
                    egg = data
                end
            end
        end
        return egg
    end)
    if s and r then return r end
    return nil
end

-- ============ GOTO ============
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
            dist = (pos.BoundsCFrame.Position - start).Magnitude
            local half = start + (pos.BoundsCFrame.Position - start).Unit * dt * getgenv().config.tpSpeed
            self.LocalPlayer.Character:MoveTo(half)
        until dist <= getgenv().config.arriveDist
    end)
end

-- ============ PROMPT ============
function utility:getproximitypromptforegg(egg)
    local s, r = pcall(function()
        local CarryAreaEggs = self.Workspace:QueryDescendants("#CarryAreaEgg")
        local closetprompt, closetdist = nil, math.huge
        for _, prompt in next, CarryAreaEggs do
            local p = prompt.Parent
            if p then
                local dist = (egg.BoundsCFrame.Position - p.Position).Magnitude
                if dist < closetdist then
                    closetdist = dist
                    closetprompt = prompt
                end
            end
        end
        return closetprompt
    end)
    if s and r then return r end
    return nil
end

-- ============ WAIT HATCH ============
function utility:waitForHatch(uid)
    local maxWait = getgenv().config.hatchWait
    local t0 = os.clock()

    warn("[AUTO] Hinihintay ma-tuka...")
    repeat
        if not self.running then return false end
        task.wait(0.2)
        local stillThere = false
        pcall(function()
            for _, data in next, self.EggState.ReadFieldEggs().Records do
                if data.Uid == uid then
                    if data.State == "Slot" or data.State == "Dropped" then
                        stillThere = true
                    end
                    break
                end
            end
        end)
        if not stillThere then
            warn("[AUTO] Na-tuka na!")
            return true
        end
    until (os.clock() - t0) > maxWait

    warn("[AUTO] Hatch timeout")
    return false
end

-- ============ INIT ============
function utility:init()
    self.LocalPlayer = self.Players.LocalPlayer
    if not fireproximityprompt then
        self.LocalPlayer:Kick("Unsupported executor: missing fireproximityprompt")
        return false
    end
    self.Client = self.ReplicatedStorage:FindFirstChild("Client")
    if not self.Client then warn("failed to get Client") return false end
    self.EggState = require(self.Client:FindFirstChild("EggState"))
    if not self.EggState then warn("failed to get EggState") return false end
    return true
end

-- ============ MAIN FLOW ============
-- Spawn → Chicken Egg → Wait Hatch → Best Egg → Stay
function utility:run()
    if not utility.EggState then
        if not self:init() then return end
    end
    self.running = true

    warn("=== AUTO START ===")

    -- ========== STEP 1: TP sa Spawn ==========
    warn("[AUTO] TP sa spawn...")
    self:GoTo({["BoundsCFrame"] = getgenv().config.spawnCF})
    if not self.running then return end
    task.wait(0.3)

    -- ========== STEP 2: Chicken Egg ==========
    warn("[AUTO] Hinahanap chicken egg sa Forest...")
    local chicken = self:getChickenEgg()
    if not chicken then
        warn("[AUTO] Walang chicken egg sa Forest!")
        self.running = false
        return
    end
    local chickenUid = chicken.Uid

    warn("[AUTO] TP sa chicken egg...")
    self:GoTo(chicken)
    if not self.running then return end
    task.wait(0.5)

    local p = self:getproximitypromptforegg(chicken)
    if p then
        fireproximityprompt(p)
        warn("[AUTO] Na-grab chicken egg")
    else
        warn("[AUTO] Walang prompt para sa chicken egg")
    end

    -- ========== STEP 3: Wait Hatch ==========
    self:waitForHatch(chickenUid)
    if not self.running then return end

    -- ========== STEP 4: Best Egg ==========
    warn("[AUTO] Hinahanap best egg...")
    local best = self:getBestEgg()
    if not best then
        warn("[AUTO] Walang best egg!")
        self.running = false
        return
    end
    warn(("[AUTO] Best Egg: %s (%s)"):format(best.Uid, best.AreaId))

    warn("[AUTO] TP sa best egg...")
    self:GoTo(best)
    if not self.running then return end
    task.wait(0.5)

    local bp = self:getproximitypromptforegg(best)
    if bp then
        fireproximityprompt(bp)
        warn("[AUTO] Na-steal best egg")
    end

    -- ========== STEP 5: STAY ==========
    warn("=== TAPOS — STAY SA BEST EGG AREA ===")
    self.running = false
end

-- ============ UI ============
local Window = Rayfield:CreateWindow({
    name = "Auto TP Chicken Egg",
    loadingTitle = "Loading...",
    loadingSubtitle = "Steal An Egg",
    configurationSaving = { Enabled = false },
    discord = { Enabled = false },
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
    Content = "Spawn → Chicken Egg → Wait Hatch → Best Egg → Stay",
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
