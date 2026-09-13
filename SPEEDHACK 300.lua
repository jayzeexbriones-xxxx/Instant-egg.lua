local mainFrame = script.Parent
local toggleButton = mainFrame:WaitForChild("ToggleButton")
local featurePanel = mainFrame:WaitForChild("FeaturePanel")
local instantPickupButton = featurePanel:WaitForChild("InstantPickupButton")

-- Hide feature panel initially
featurePanel.Visible = false

-- Toggle button to show/hide features
toggleButton.MouseButton1Click:Connect(function()
    featurePanel.Visible = not featurePanel.Visible
end)

-- Draggable UI implementation
local UserInputService = game:GetService("UserInputService")
local dragging = false
local dragStart = Vector2.new()
local startPos = UDim2.new()

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = startPos + UDim2.new(0, delta.X, 0, delta.Y)
    end
end)

-- Instant Pickup feature
local function instantPickup()
    -- Assumes you have a RemoteEvent named "PickupEvent" in ReplicatedStorage
    local remoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("PickupEvent")
    -- Palitan ang item name depende sa iyong game setup
    remoteEvent:FireServer("ExampleItem") 
end

instantPickupButton.MouseButton1Click:Connect(function()
    instantPickup()
end)
