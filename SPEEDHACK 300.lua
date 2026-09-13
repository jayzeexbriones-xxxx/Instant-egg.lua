-- Script na ito ay naka-setup sa isang LocalScript sa StarterPlayerScripts o sa UI

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Gumawa ng ScreenGui at Frame para sa UI
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local draggableFrame = Instance.new("Frame", screenGui)
draggableFrame.Size = UDim2.new(0, 300, 0, 150)
draggableFrame.Position = UDim2.new(0.5, -150, 0.5, -75)
draggableFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
draggableFrame.BorderSizePixel = 2
draggableFrame.BorderColor3 = Color3.fromRGB(255, 255, 255)

-- Function para gawing draggable ang UI
local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if dragging then
                local delta = input.Position - dragStart
                frame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)
end

makeDraggable(draggableFrame)

-- Magdagdag ng Button para sa pag-trigger ng instant pickup
local pickupButton = Instance.new("TextButton", draggableFrame)
pickupButton.Size = UDim2.new(1, -20, 0, 50)
pickupButton.Position = UDim2.new(0, 10, 0, 50)
pickupButton.Text = "Instant Pickup"
pickupButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
pickupButton.TextColor3 = Color3.new(1, 1, 1)
pickupButton.Font = Enum.Font.SourceSansBold
pickupButton.TextSize = 24

-- Example item na gustong i-pick up
local itemName = "YourItemName" -- Palitan ito sa pangalan ng item mo
local item = workspace:WaitForChild(itemName)

-- Function para sa instant pickup
local function instantPickup(item)
    local function setupTouch()
        if item:IsA("BasePart") then
            item.Touched:Connect(function(hit)
                local hitPlayer = game.Players:GetPlayerFromCharacter(hit.Parent)
                if hitPlayer then
                    local backpack = hitPlayer:FindFirstChild("Backpack")
                    if backpack then
                        -- Ilipat ang item sa backpack
                        item.CFrame = hitPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 2)
                        -- Gamitin ang :Clone() kung gusto mong panatilihin ang original
                        local clone = item:Clone()
                        clone.Parent = backpack
                        -- Optional: i-destroy ang original item
                        -- item:Destroy()
                    end
                end
            end)
        end
    end

    setupTouch()
end

-- I-trigger ang instant pickup kapag nag-click ang button
pickupButton.MouseButton1Click:Connect(function()
    instantPickup(item)
    print("Instant pickup activated for " .. itemName)
end)
