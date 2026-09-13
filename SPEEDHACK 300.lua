-- This file was generated at discord.gg/syncrypt

local t1 = {}
local v2 = unpack or table.unpack
local Players = game:GetService("Players")

t1.value1 = game:GetService("RunService")
t1.value2 = game:GetService("TweenService")
t1.value3 = game:GetService("UserInputService")
t1.value4 = game:GetService("Stats")
t1.value5 = game:GetService("ProximityPromptService")
game:GetService("HttpService")
t1.value6 = Players.LocalPlayer
local PlayerGui = t1.value6:WaitForChild("PlayerGui")

t1.value7 = nil
t1.value8 = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
pcall(function()
    if hookfunction and newcclosure then
        local u153
        u153 = hookfunction(Instance.new("RemoteEvent").FireServer, newcclosure(function(p1, ...)
            local v262 = not t1.value7

            if v262 then
                v262 = typeof(p1) == "Instance"

                if v262 then
                    v262 = p1:IsA("RemoteEvent")

                    if v262 then
                        v262 = p1.Name:sub(1, 3) == "RE/"
                    end
                end
            end

            if v262 then
                t1.value7 = p1
            end

            return u153(p1, ...)
        end))
    end
end)
task.spawn(function()
    task.wait(2)

    if t1.value7 then
        return
    end

    for _, descendant in ipairs(game:GetDescendants()) do
        local v156 = descendant:IsA("RemoteEvent")

        if v156 then
            v156 = descendant.Name:sub(1, 3) == "RE/"
        end

        if v156 then
            t1.value7 = descendant

            return
        end
    end
end)

function t1.value9()
    if not t1.value7 then
        for _, descendant in ipairs(game:GetDescendants()) do
            local v163 = descendant:IsA("RemoteEvent")

            if v163 then
                v163 = descendant.Name:sub(1, 3) == "RE/"
            end

            if v163 then
                t1.value7 = descendant

                break
            end
        end
    end

    if not t1.value7 then
        local Character = t1.value6.Character

        if Character then
            local Humanoid = Character:FindFirstChildOfClass("Humanoid")

            if Humanoid then
                Humanoid.Health = 0
            end
        end

        return
    end

    local Character = t1.value6.Character
    local v167 = Character

    if Character then
        v167 = Character:FindFirstChildOfClass("Humanoid")
    end

    local v168 = v167
    local v169 = v168

    if v169 then
        v169 = v168.Health <= 0
    end

    if v169 then
        pcall(function()
            t1.value7:FireServer(t1.value8, t1.value6, "balloon")
        end)

        return
    end

    local u170 = false
    local t2 = {}

    if v168 then
        table.insert(t2, v168.Died:Connect(function()
            u170 = true
        end))
        table.insert(t2, v168:GetPropertyChangedSignal("Health"):Connect(function()
            if v168.Health <= 0 then
                u170 = true
            end
        end))
    end

    if Character then
        table.insert(t2, Character.AncestryChanged:Connect(function(_, parent)
            if not parent then
                u170 = true
            end
        end))
    end

    task.spawn(function()
        for _ = 1, 50 do
            if u170 then
                break
            end

            pcall(function()
                t1.value7:FireServer(t1.value8, t1.value6, "balloon")
            end)
            task.wait()
        end

        for _, v in ipairs(t2) do
            local v270 = v

            pcall(function()
                v270:Disconnect()
            end)
        end
    end)
end
function t1.value10()
    return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(40, 80, 180)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
	})
end
function t1.value11(p3, p4, p5)
    local v160 = p5 or 45

    task.spawn(function()
        local n1 = 0

        while true do
            local v264 = p3

            if v264 then
                v264 = p3.Parent
            end

            if not v264 then
                break
            end

            n1 += t1.value1.Heartbeat:Wait()
            p3.Rotation = p4 + math.sin(n1 * (v160 / 50)) * 30
        end
    end)
end
local function v5()
    return ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 100, 200)),
		ColorSequenceKeypoint.new(0.35, Color3.fromRGB(60, 100, 200)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 220, 255)),
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(60, 100, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 100, 200))
	})
end
function t1.value12(p6)
    local p6BackgroundColor3 = p6.BackgroundColor3

    p6.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
    task.delay(0.12, function()
        local v273 = p6

        if v273 then
            v273 = p6.Parent
        end

        if v273 then
            p6.BackgroundColor3 = p6BackgroundColor3
        end
    end)
end
local function v6(p7, _, p9)
    local uDim2 = UDim2.new(1, -14, 0.5, -6)
    local uDim2_2 = UDim2.new(0, 2, 0.5, -6)
    local color3 = Color3.fromRGB(100, 150, 255)
    local color3_2 = Color3.fromRGB(60, 80, 140)
    local v188 = p9 and uDim2 or uDim2_2
    local value2 = t1.value2
    local tweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad)
    local v191 = p9 and color3 or color3_2

    value2:Create(p7, tweenInfo, {
		Position = v188,
		BackgroundColor3 = v191
	}):Play()
end
local function v7(p10, p11)
    if not p11 then
        p11 = p10
    end
    local u194
    local inputPosition
    local p10Position
    p11.InputBegan:Connect(function(input)
        local v275 = input.UserInputType == Enum.UserInputType.MouseButton1

        if not v275 then
            v275 = input.UserInputType == Enum.UserInputType.Touch
        end

        if v275 then
            u194 = true
            inputPosition = input.Position
            p10Position = p10.Position
        end
    end)
    t1.value3.InputChanged:Connect(function(input)
        local v277 = u194

        if v277 then
            v277 = input.UserInputType == Enum.UserInputType.MouseMovement

            if not v277 then
                v277 = input.UserInputType == Enum.UserInputType.Touch
            end
        end

        if v277 then
            local v278 = input.Position - inputPosition

            p10.Position = UDim2.new(p10Position.X.Scale, p10Position.X.Offset + v278.X, p10Position.Y.Scale, p10Position.Y.Offset + v278.Y)
        end
    end)
    t1.value3.InputEnded:Connect(function(input)
        local v280 = input.UserInputType == Enum.UserInputType.MouseButton1

        if not v280 then
            v280 = input.UserInputType == Enum.UserInputType.Touch
        end

        if not v280 then
        end
    end)
end
local ScreenGui = Instance.new("ScreenGui")

ScreenGui.Name = "InfinHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui
local Frame = Instance.new("Frame")

Frame.Position = UDim2.new(0.5, -100, 0.3, 0)
Frame.Size = UDim2.new(0, 200, 0, 250)
Frame.BackgroundColor3 = Color3.fromRGB(10, 15, 30)
Frame.BackgroundTransparency = 0.3
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Name = "Frame"
Frame.Parent = ScreenGui
local UICorner = Instance.new("UICorner")

UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = Frame
local UIStroke = Instance.new("UIStroke")

UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Color = Color3.fromRGB(40, 80, 180)
UIStroke.Thickness = 2
UIStroke.Parent = Frame
local UIGradient = Instance.new("UIGradient")

UIGradient.Color = t1.value10()
UIGradient.Rotation = 203.25
UIGradient.Parent = UIStroke
t1.value11(UIGradient, 203.25)

local TextLabel = Instance.new("TextLabel")

TextLabel.Text = "Infin Hub"
TextLabel.TextColor3 = Color3.fromRGB(100, 150, 255)
TextLabel.TextSize = 12
TextLabel.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
TextLabel.TextXAlignment = Enum.TextXAlignment.Center
TextLabel.Position = UDim2.new(0, 8, 0, 4)
TextLabel.Size = UDim2.new(1, -40, 0, 14)
TextLabel.BackgroundTransparency = 1
TextLabel.Parent = Frame
local UIGradient2 = Instance.new("UIGradient")

UIGradient2.Color = v5()
UIGradient2.Offset = Vector2.new(0.996, 0)
UIGradient2.Parent = TextLabel
task.spawn(function()
    local n2 = 0

    while true do
        local v198 = UIGradient2

        if v198 then
            v198 = UIGradient2.Parent
        end

        if not v198 then
            break
        end

        n2 += t1.value1.Heartbeat:Wait()
        UIGradient2.Offset = Vector2.new(math.sin(n2 * 0.6) * 0.5, 0)
    end
end)

local TextLabel2 = Instance.new("TextLabel")

TextLabel2.Text = "Flash TP + Speed"
TextLabel2.TextColor3 = Color3.fromRGB(150, 180, 255)
TextLabel2.TextTransparency = 0.4
TextLabel2.TextSize = 9
TextLabel2.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
TextLabel2.TextXAlignment = Enum.TextXAlignment.Center
TextLabel2.Position = UDim2.new(0, 8, 0, 20)
TextLabel2.Size = UDim2.new(1, -40, 0, 10)
TextLabel2.BackgroundTransparency = 1
TextLabel2.Parent = Frame
local TextButton = Instance.new("TextButton")

TextButton.Text = "-"
TextButton.TextColor3 = Color3.fromRGB(100, 150, 255)
TextButton.TextSize = 14
TextButton.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
TextButton.Position = UDim2.new(1, -24, 0, 4)
TextButton.Size = UDim2.new(0, 20, 0, 20)
TextButton.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
TextButton.BorderSizePixel = 0
TextButton.Parent = Frame
local UICorner2 = Instance.new("UICorner")

UICorner2.CornerRadius = UDim.new(0, 5)
UICorner2.Parent = TextButton
local UIStroke2 = Instance.new("UIStroke")

UIStroke2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke2.Color = Color3.fromRGB(40, 80, 180)
UIStroke2.Thickness = 1.5
UIStroke2.Parent = TextButton
local UIGradient3 = Instance.new("UIGradient")

UIGradient3.Color = t1.value10()
UIGradient3.Rotation = 203.25
UIGradient3.Parent = UIStroke2
t1.value11(UIGradient3, 203.25)

local Frame2 = Instance.new("Frame")

Frame2.Position = UDim2.new(0, 6, 0, 34)
Frame2.Size = UDim2.new(1, -12, 0, 26)
Frame2.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
Frame2.BorderSizePixel = 0
Frame2.Parent = Frame
Instance.new("UICorner").Parent = Frame2
local UIStroke3 = Instance.new("UIStroke")

UIStroke3.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke3.Color = Color3.fromRGB(40, 80, 180)
UIStroke3.Thickness = 1.2
UIStroke3.Parent = Frame2
local UIGradient4 = Instance.new("UIGradient")

UIGradient4.Color = t1.value10()
UIGradient4.Rotation = 203.25
UIGradient4.Parent = UIStroke3
t1.value11(UIGradient4, 203.25)
t1.value13 = Instance.new("TextLabel")
t1.value13.Text = "Flash TP: OFF"
t1.value13.TextColor3 = Color3.fromRGB(150, 180, 255)
t1.value13.TextSize = 10
t1.value13.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
t1.value13.TextXAlignment = Enum.TextXAlignment.Left
t1.value13.Position = UDim2.new(0, 6, 0, 0)
t1.value13.Size = UDim2.new(1, -50, 1, 0)
t1.value13.BackgroundTransparency = 1
t1.value13.Parent = Frame2
t1.value14 = Instance.new("Frame")
t1.value14.Position = UDim2.new(1, -36, 0.5, -8)
t1.value14.Size = UDim2.new(0, 30, 0, 16)
t1.value14.BackgroundTransparency = 1
t1.value14.Parent = Frame2
Instance.new("UICorner").Parent = t1.value14
local UIStroke4 = Instance.new("UIStroke")

UIStroke4.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke4.Color = Color3.fromRGB(40, 80, 180)
UIStroke4.Thickness = 1.5
UIStroke4.Parent = t1.value14
local UIGradient5 = Instance.new("UIGradient")

UIGradient5.Color = t1.value10()
UIGradient5.Rotation = 203.25
UIGradient5.Parent = UIStroke4
t1.value11(UIGradient5, 203.25)
t1.value15 = Instance.new("Frame")
t1.value15.Position = UDim2.new(0, 2, 0.5, -6)
t1.value15.Size = UDim2.new(0, 12, 0, 12)
t1.value15.BackgroundColor3 = Color3.fromRGB(60, 80, 140)
t1.value15.Parent = t1.value14
local UICorner3 = Instance.new("UICorner")

UICorner3.CornerRadius = UDim.new(0, 6)
UICorner3.Parent = t1.value15
local TextButton2 = Instance.new("TextButton")

TextButton2.Text = ""
TextButton2.Size = UDim2.new(1, 0, 1, 0)
TextButton2.BackgroundTransparency = 1
TextButton2.Parent = Frame2
local Frame3 = Instance.new("Frame")

Frame3.Position = UDim2.new(0, 6, 0, 66)
Frame3.Size = UDim2.new(1, -12, 0, 34)
Frame3.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
Frame3.BorderSizePixel = 0
Frame3.Parent = Frame
Instance.new("UICorner").Parent = Frame3
local UIStroke5 = Instance.new("UIStroke")

UIStroke5.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke5.Color = Color3.fromRGB(40, 80, 180)
UIStroke5.Thickness = 1.2
UIStroke5.Parent = Frame3
local UIGradient6 = Instance.new("UIGradient")

UIGradient6.Color = t1.value10()
UIGradient6.Rotation = 203.25
UIGradient6.Parent = UIStroke5
t1.value11(UIGradient6, 203.25)

local TextLabel3 = Instance.new("TextLabel")

TextLabel3.Text = "Trigger %"
TextLabel3.TextColor3 = Color3.fromRGB(150, 180, 255)
TextLabel3.TextSize = 10
TextLabel3.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
TextLabel3.TextXAlignment = Enum.TextXAlignment.Left
TextLabel3.Position = UDim2.new(0, 6, 0, 2)
TextLabel3.Size = UDim2.new(0, 55, 0, 14)
TextLabel3.BackgroundTransparency = 1
TextLabel3.Parent = Frame3
t1.value16 = Instance.new("TextLabel")
t1.value16.Text = "93%"
t1.value16.TextColor3 = Color3.fromRGB(100, 150, 255)
t1.value16.TextSize = 10
t1.value16.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
t1.value16.TextXAlignment = Enum.TextXAlignment.Right
t1.value16.Position = UDim2.new(1, -38, 0, 2)
t1.value16.Size = UDim2.new(0, 34, 0, 14)
t1.value16.BackgroundTransparency = 1
t1.value16.Parent = Frame3
t1.value17 = Instance.new("Frame")
t1.value17.Position = UDim2.new(0, 6, 0, 22)
t1.value17.Size = UDim2.new(1, -12, 0, 8)
t1.value17.BackgroundColor3 = Color3.fromRGB(40, 50, 70)
t1.value17.BorderSizePixel = 0
t1.value17.Parent = Frame3
local UICorner4 = Instance.new("UICorner")

UICorner4.CornerRadius = UDim.new(0, 4)
UICorner4.Parent = t1.value17
t1.value18 = Instance.new("Frame")
t1.value18.Size = UDim2.new(0.93, 0, 1, 0)
t1.value18.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
t1.value18.BorderSizePixel = 0
t1.value18.Parent = t1.value17
local UICorner5 = Instance.new("UICorner")

UICorner5.CornerRadius = UDim.new(0, 4)
UICorner5.Parent = t1.value18
t1.value19 = Instance.new("Frame")
t1.value19.Position = UDim2.new(0.93, 0, 0.5, 0)
t1.value19.Size = UDim2.new(0, 12, 0, 12)
t1.value19.AnchorPoint = Vector2.new(0.5, 0.5)
t1.value19.BackgroundColor3 = Color3.fromRGB(20, 50, 160)
t1.value19.BorderSizePixel = 0
t1.value19.Parent = t1.value17
local UICorner6 = Instance.new("UICorner")

UICorner6.CornerRadius = UDim.new(1, 0)
UICorner6.Parent = t1.value19
local Frame4 = Instance.new("Frame")

Frame4.Position = UDim2.new(0, 6, 0, 106)
Frame4.Size = UDim2.new(1, -12, 0, 26)
Frame4.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
Frame4.BorderSizePixel = 0
Frame4.Parent = Frame
Instance.new("UICorner").Parent = Frame4
local UIStroke6 = Instance.new("UIStroke")

UIStroke6.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke6.Color = Color3.fromRGB(40, 80, 180)
UIStroke6.Thickness = 1.2
UIStroke6.Parent = Frame4
local UIGradient7 = Instance.new("UIGradient")

UIGradient7.Color = t1.value10()
UIGradient7.Rotation = 203.25
UIGradient7.Parent = UIStroke6
t1.value11(UIGradient7, 203.25)
t1.value20 = Instance.new("TextLabel")
t1.value20.Text = "Speed Boost: OFF"
t1.value20.TextColor3 = Color3.fromRGB(150, 180, 255)
t1.value20.TextSize = 10
t1.value20.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
t1.value20.TextXAlignment = Enum.TextXAlignment.Left
t1.value20.Position = UDim2.new(0, 6, 0, 0)
t1.value20.Size = UDim2.new(1, -50, 1, 0)
t1.value20.BackgroundTransparency = 1
t1.value20.Parent = Frame4
t1.value21 = Instance.new("Frame")
t1.value21.Position = UDim2.new(1, -36, 0.5, -8)
t1.value21.Size = UDim2.new(0, 30, 0, 16)
t1.value21.BackgroundTransparency = 1
t1.value21.Parent = Frame4
Instance.new("UICorner").Parent = t1.value21
local UIStroke7 = Instance.new("UIStroke")

UIStroke7.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke7.Color = Color3.fromRGB(40, 80, 180)
UIStroke7.Thickness = 1.5
UIStroke7.Parent = t1.value21
local UIGradient8 = Instance.new("UIGradient")

UIGradient8.Color = t1.value10()
UIGradient8.Rotation = 203.25
UIGradient8.Parent = UIStroke7
t1.value11(UIGradient8, 203.25)
t1.value22 = Instance.new("Frame")
t1.value22.Position = UDim2.new(0, 2, 0.5, -6)
t1.value22.Size = UDim2.new(0, 12, 0, 12)
t1.value22.BackgroundColor3 = Color3.fromRGB(60, 80, 140)
t1.value22.Parent = t1.value21
local UICorner7 = Instance.new("UICorner")

UICorner7.CornerRadius = UDim.new(0, 6)
UICorner7.Parent = t1.value22
local TextButton3 = Instance.new("TextButton")

TextButton3.Text = ""
TextButton3.Size = UDim2.new(1, 0, 1, 0)
TextButton3.BackgroundTransparency = 1
TextButton3.Parent = Frame4
local Frame5 = Instance.new("Frame")

Frame5.Position = UDim2.new(0, 6, 0, 138)
Frame5.Size = UDim2.new(1, -12, 0, 34)
Frame5.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
Frame5.BorderSizePixel = 0
Frame5.Parent = Frame
Instance.new("UICorner").Parent = Frame5
local UIStroke8 = Instance.new("UIStroke")

UIStroke8.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke8.Color = Color3.fromRGB(40, 80, 180)
UIStroke8.Thickness = 1.2
UIStroke8.Parent = Frame5
local UIGradient9 = Instance.new("UIGradient")

UIGradient9.Color = t1.value10()
UIGradient9.Rotation = 203.25
UIGradient9.Parent = UIStroke8
t1.value11(UIGradient9, 203.25)

local TextLabel4 = Instance.new("TextLabel")

TextLabel4.Text = "Speed:"
TextLabel4.TextColor3 = Color3.fromRGB(150, 180, 255)
TextLabel4.TextSize = 9
TextLabel4.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal)
TextLabel4.TextXAlignment = Enum.TextXAlignment.Left
TextLabel4.Position = UDim2.new(0, 6, 0, 10)
TextLabel4.Size = UDim2.new(0, 42, 0, 14)
TextLabel4.BackgroundTransparency = 1
TextLabel4.Parent = Frame5
t1.value23 = Instance.new("TextBox")
t1.value23.Text = "27"
t1.value23.TextColor3 = Color3.fromRGB(100, 150, 255)
t1.value23.TextSize = 10
t1.value23.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
t1.value23.Position = UDim2.new(0, 50, 0, 8)
t1.value23.Size = UDim2.new(0, 50, 0, 20)
t1.value23.BackgroundColor3 = Color3.fromRGB(15, 20, 40)
t1.value23.BorderSizePixel = 0
t1.value23.Parent = Frame5
local UICorner8 = Instance.new("UICorner")

UICorner8.CornerRadius = UDim.new(0, 4)
UICorner8.Parent = t1.value23
local UIStroke9 = Instance.new("UIStroke")

UIStroke9.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke9.Color = Color3.fromRGB(40, 80, 180)
UIStroke9.Parent = t1.value23
local UIGradient10 = Instance.new("UIGradient")

UIGradient10.Color = t1.value10()
UIGradient10.Rotation = 203.25
UIGradient10.Parent = UIStroke9
t1.value11(UIGradient10, 203.25)
t1.value24 = Instance.new("TextButton")
t1.value24.Text = "Auto Position"
t1.value24.TextColor3 = Color3.fromRGB(100, 150, 255)
t1.value24.TextSize = 9
t1.value24.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
t1.value24.Position = UDim2.new(0.5, -50, 0, 178)
t1.value24.Size = UDim2.new(0, 100, 0, 24)
t1.value24.BackgroundColor3 = Color3.fromRGB(20, 30, 50)
t1.value24.BorderSizePixel = 0
t1.value24.Parent = Frame
local UICorner9 = Instance.new("UICorner")

UICorner9.CornerRadius = UDim.
