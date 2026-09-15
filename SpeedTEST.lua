-- DEBUG: Check egg at prompt sa Forest
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

print("=== FOREST EGG DEBUG ===")

-- Load EggState
local EggState = nil
pcall(function()
    local client = ReplicatedStorage:FindFirstChild("Client")
    if client then
        local es = client:FindFirstChild("EggState")
        if es then EggState = require(es) end
    end
end)

if not EggState then
    print("❌ EggState not found")
    return
end

-- Get character position
local char = LocalPlayer.Character
local hrp = char and char:FindFirstChild("HumanoidRootPart")
if not hrp then
    print("❌ No HRP")
    return
end
print("Current position:", hrp.Position)
print("")

-- Find Forest eggs
local data = EggState.ReadFieldEggs()
if not data or not data.Records then
    print("❌ No records")
    return
end

print("=== FOREST EGGS ===")
for _, rec in ipairs(data.Records) do
    if rec.AreaId == "Forest" then
        print("Uid:", rec.Uid:sub(1,8))
        print("State:", rec.State)
        print("Position:", rec.BoundsCFrame.Position)
        
        local dist = (rec.BoundsCFrame.Position - hrp.Position).Magnitude
        print("Distance:", math.floor(dist))
        
        local slots = Workspace:FindFirstChild("AreaEggSlotsClient", true)
        local model = nil
        if slots then
            model = slots:FindFirstChild(rec.Uid)
        end
        if not model then
            model = Workspace:FindFirstChild(rec.Uid, true)
        end
        print("Model found:", model ~= nil)
        
        if model then
            print("Model name:", model.Name)
            print("Model class:", model.ClassName)
            
            local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
            print("Prompt:", prompt and prompt.Name or "❌ NONE")
            if prompt then
                print("  Prompt Enabled:", prompt.Enabled)
                print("  Prompt HoldDuration:", prompt.HoldDuration)
                print("  Prompt MaxActivationDistance:", prompt.MaxActivationDistance)
                print("  Prompt ActionText:", prompt.ActionText)
            end
            
            print("Model children:")
            for _, child in ipairs(model:GetChildren()) do
                print("  -", child.Name, "(" .. child.ClassName .. ")")
            end
        end
        print("")
    end
end

print("=== ALL PROMPTS (first 20) ===")
local count = 0
for _, p in ipairs(Workspace:GetDescendants()) do
    if p:IsA("ProximityPrompt") then
        count = count + 1
        if count <= 20 then
            local parent = p.Parent
            print(count .. ". Name:", p.Name, "| Enabled:", p.Enabled, "| Parent:", parent and parent.Name or "?")
        end
    end
end
print("Total prompts:", count)

print("=== END DEBUG ===")
