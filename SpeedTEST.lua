local utility = {}

-- Initialize bypass function
function utility:initbypass()
    print("Initializing bypass...")

    -- Get local player
    local player = game:GetService("Players").LocalPlayer
    if not player then
        warn("Cannot find LocalPlayer")
        return
    end

    -- Check if functions are available
    if not getgc or not hookfunction or not islclosure then
        warn("Your executor does not support required functions.")
        return
    end

    -- Find specific function
    local targetFunc
    for _, f in ipairs(getgc(true) or {}) do
        if typeof(f) == "function" and islclosure(f) then
            local info = debug.info(f, "l")
            if info == 3 then -- line number check, adjust if needed
                -- Check upvalues
                local upvalues = {debug.getupvalues(f)}
                if #upvalues >= 3 then
                    local upv = upvalues[3]
                    if typeof(upv) == "table" and rawget(upv, "Humanoid") then
                        targetFunc = f
                        break
                    end
                end
            end
        end
    end

    if not targetFunc then
        warn("Failed to find target function.")
        return
    end

    -- Hook to disable character metatable modifications
    local original = hookfunction(targetFunc, function(p1, p2)
        if p2 and typeof(p2) == "table" then
            setmetatable(p2, {})
        end
        return original(p1, p2)
    end)

    -- Speed boost
    game:GetService("RunService").Heartbeat:Connect(function()
        local char = player.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 500
        end
    end)

    print("Bypass initialized.")
end

-- Run the bypass
utility:initbypass()
