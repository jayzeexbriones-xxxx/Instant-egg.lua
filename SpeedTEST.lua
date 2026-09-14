local utility = {
    RunService = game:GetService("RunService"),
    Players = game:GetService("Players")
}

-- Collect garbage function
utility.collectgarbage = function()
    local s, r = pcall(function()
        return getgc()
    end)
    if s and r then
        return r    
    end
    warn("failed to get garbage: "..tostring(r))
    return nil
end

-- Safe hook function
utility.safehook = function(f, c)
    local s, r = pcall(function()
        return hookfunction(f, newcclosure(c))
    end)
    if s and r then
        return r    
    end
    warn("failed to hook function: "..tostring(r))
    return nil
end

-- Function to find specific functions by upvalues and line number
function utility:findfunction(nups, linedefined)
    local gc = self.collectgarbage()
    if not gc then
        warn("No garbage collected functions")
        return nil
    end
    for _, f in ipairs(gc) do
        if typeof(f) == 'function' and islclosure(f) then
            local info = debug.info(f, "l")
            if info == linedefined then
                local upvs = {debug.getupvalues(f)}
                if #upvs == nups then
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
    end
    return nil
end

-- Initialization function
function utility:initbypass()
    print("Initializing bypass...")
    self.LocalPlayer = self.Players.LocalPlayer
    if not self.LocalPlayer then
        warn("failed to get localplayer")
        return
    end

    if not getgc then
        self.LocalPlayer:Kick("UNSUPPORTED EXECUTOR: missing getgc")
        return
    end

    if not hookfunction then
        self.LocalPlayer:Kick("UNSUPPORTED EXECUTOR: missing hookfunction")
        return
    end

    if not islclosure then
        self.LocalPlayer:Kick("UNSUPPORTED EXECUTOR: missing islclosure")
        return
    end

    local func3 = self:findfunction(19, 3)
    if not func3 then
        warn("failed to get function 3")
        return
    end

    local v7 = debug.getupvalue(func3, 2)
    if not v7 then
        warn("failed to get v7")
        return
    end

    -- Hook to disable character metatable modifications
    self.safehook(v7, function(p1, p2)
        if p2 and typeof(p2) == "table" then
            setmetatable(p2, {})
        end
        return v7(p1, p2) -- call original
    end)

    -- Speed boost
    self.speedConnection = self.RunService.Heartbeat:Connect(function()
        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        hum.WalkSpeed = 500
    end)
    print("Bypass setup complete.")
end

-- Run main code
print("Starting main script...")
for _, obj in ipairs(getgc(true) or {}) do
    if typeof(obj) ~= "table" or getrawmetatable(obj) then continue end
    local mainrun = false
    for _, v in pairs(obj) do
        if v == obj then mainrun = true break end
    end
    if not mainrun then continue end
    for _, v in pairs(obj) do
        if typeof(v) == "number" and v >= 1 and v <= 3 and obj[v] == nil then
            setmetatable(obj, {__newindex = function() end})
            break
        end
    end
end

-- Call to initialize bypass
utility:initbypass()
print("Script execution complete.")
