local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local lp = Players.LocalPlayer

print("=== DEBUG ===")
print("Player:", lp.Name)

local client = ReplicatedStorage:FindFirstChild("Client")
print("Client:", client)

if client then
    local eggState = client:FindFirstChild("EggState")
    print("EggState:", eggState)
    if eggState then
        local s, r = pcall(require, eggState)
        if s then
            print("EggState loaded")
            local s2, r2 = pcall(function()
                return r.ReadFieldEggs().Records
            end)
            if s2 then
                local count = 0
                for k, v in next, r2 do
                    count = count + 1
                    if count <= 3 then
                        print("Sample:", v.AreaId, v.AssetScale)
                    end
                end
                print("Total eggs:", count)
            else
                print("ReadFieldEggs error:", r2)
            end
        else
            print("Require error:", r)
        end
    end
end

local carry = workspace:QueryDescendants("#CarryAreaEgg")
print("CarryAreaEgg count:", #carry)
for i, v in next, carry do
    if i <= 3 then print("Carry:", v.ClassName, v.Name) end
end
