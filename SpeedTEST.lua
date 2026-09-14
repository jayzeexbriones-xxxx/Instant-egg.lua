local debug = "=== DEBUG ===\n"
debug = debug .. "Player: " .. game.Players.LocalPlayer.Name .. "\n"

local client = game:GetService("ReplicatedStorage"):FindFirstChild("Client")
debug = debug .. "Client: " .. tostring(client) .. "\n"

if client then
    local eggState = client:FindFirstChild("EggState")
    debug = debug .. "EggState: " .. tostring(eggState) .. "\n"
    
    if eggState then
        local s, r = pcall(require, eggState)
        if s then
            debug = debug .. "EggState: LOADED\n"
            local s2, r2 = pcall(function()
                return r.ReadFieldEggs().Records
            end)
            if s2 then
                local count = 0
                for k, v in next, r2 do count = count + 1 end
                debug = debug .. "Total Eggs: " .. count .. "\n"
            else
                debug = debug .. "ReadFieldEggs ERROR: " .. tostring(r2) .. "\n"
            end
        else
            debug = debug .. "Require ERROR: " .. tostring(r) .. "\n"
        end
    end
end

local carry = workspace:QueryDescendants("#CarryAreaEgg")
debug = debug .. "CarryAreaEgg: " .. #carry .. "\n"

-- 📋 I-copy sa clipboard
if setclipboard then
    setclipboard(debug)
    warn("✅ Debug info copied to clipboard! Paste mo dito.")
else
    warn(debug)
end
