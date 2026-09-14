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
        return hookfunction(f, newlclosure(c))
    end)
    if s and r then
        return r    
    end
    warn("failed to hook function: "..tostring(r))
    return nil
end

-- Function to find specific functions by upvalues and line number
function utility:findfunction(nups, linedefined)
    local s, r = pcall(function()
        for _, f in next, self.collectgarbage() or {} do
            if typeof(f) == 'function' and islclosure(f) then
                local upvs = debug.getupvalues(f)
                local line = debug.info(f, "l")
                if upvs and #upvs == nups and line == linedefined then
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
        return nil
    end)

    if s and r then
        return r
    end
    return nil
end

-- Initialization function
function utility:initbypass()
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

    local hookedfunc3
    hookedfunc3 = self.safehook(v7, function(p1, p2)
        if p2 and typeof(p2) == "table" then
            setmetatable(p2, {})
        end
        return hookedfunc3(p1, p2)
    end)

    -- Set speed to 500 continuously
    self.speedconn = self.RunService.Heartbeat:Connect(function()
        local char = self.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChild("Humanoid")
        if not hum then return end
        hum.WalkSpeed = 500
    end)
end

-- Main code execution
for _, obj in getgc(true) do
    if typeof(obj) ~= "table" or getrawmetatable(obj) then continue end
    local mainrun = false
    for _, v in obj do
        if v == obj then mainrun = true break end
    end
    if not mainrun then continue end
    for _, v in obj do
        if typeof(v) == "number" and v >= 1 and v <= 3 and obj[v] == nil then
            setmetatable(obj, {__newindex = function() end})
            break
        end
    end
end

-- Initialize bypass
utility:initbypass()
