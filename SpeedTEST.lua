-- DEBUG with clipboard
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local output = "=== EGG DEBUG ===\n"

-- Get current egg tool
local char = LocalPlayer.Character
local eggTool = nil
for _, tool in ipairs(char:GetChildren()) do
    if tool:IsA("Tool") and tool:GetAttribute("ItemType") == "AssetEgg" then
        eggTool = tool
        break
    end
end

if not eggTool then
    output = output .. "❌ Walang egg tool\n"
    output = output .. "Kunin mo muna yung egg, tapos i-run ulit.\n"
else
    output = output .. "✅ Egg tool: " .. eggTool.Name .. "\n\n"
    output = output .. "=== EGG TOOL ATTRIBUTES ===\n"
    for name, value in pairs(eggTool:GetAttributes()) do
        output = output .. "  " .. name .. " = " .. tostring(value) .. "\n"
    end
end

-- Workspace eggs
output = output .. "\n=== WORKSPACE EGGS (first 5) ===\n"
local count = 0
for _, obj in ipairs(Workspace:GetDescendants()) do
    if obj:IsA("BasePart") and obj.Name:lower():find("egg") then
        count = count + 1
        if count <= 5 then
            output = output .. "---\n"
            output = output .. "Name: " .. obj.Name .. "\n"
            output = output .. "Position: " .. tostring(obj.Position) .. "\n"
            
            local attrs = obj:GetAttributes()
            if next(attrs) then
                output = output .. "Attributes:\n"
                for name, value in pairs(attrs) do
                    output = output .. "  " .. name .. " = " .. tostring(value) .. "\n"
                end
            else
                output = output .. "❌ Walang attributes\n"
            end
            
            if obj.Parent then
                output = output .. "Parent: " .. obj.Parent.Name .. "\n"
            end
        end
    end
end

output = output .. "\nTotal: " .. count .. " egg parts\n"

-- Copy sa clipboard
if setclipboard then
    setclipboard(output)
    print("✅ Output copied to clipboard! Paste mo dito.")
else
    print(output)
end
