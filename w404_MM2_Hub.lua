-- ==========================================
-- Script Name: w.404 | MM2 Hub
-- Executor: Delta
-- Floating W Image UI + Orion Library
-- ==========================================

-- รูป W ที่อัปโหลดไว้ใน Roblox
local MINI_IMAGE = "rbxassetid://116990467705581"

-- Load Orion Library
local OrionLib = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/shlexware/Orion/main/source"
))()

-- Services
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Create Main Window
local Window = OrionLib:MakeWindow({
    Name = "w.404 | ระบบช่วยเล่น MM2",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "w404_MM2"
})

-- Drag Main UI Support
pcall(function()
    for _, gui in ipairs(CoreGui:GetChildren()) do
        if gui:FindFirstChild("Main") or gui.Name == "Orion" then
            local mainFrame = gui:FindFirstChild("Main", true)
            if mainFrame then
                mainFrame.Active = true
                mainFrame.Draggable = true
            end
        end
    end
end)

-- ==========================================
-- Variables
-- ==========================================
local aimbotEnabled = false
local wallCheckEnabled = true
local fovVisible = false
local fovRadius = 150
local fovColorMode = "เหลืองอ่อน"

local espEnabled = false
local espHighlights = {}
local autoFarmEnabled = false

local subUICreated = false
local screenGui
local miniFrame
local aimButton
local miniPanel
local miniOpen = false

_G.LockTarget = false

-- Drawing API (executor-dependent)
local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Color = Color3.fromRGB(255, 255, 150)
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 60
    fovCircle.Radius = fovRadius
    fovCircle.Filled = false
    fovCircle.Visible = false
end)

-- ==========================================
-- Floating W UI
-- กดค้างเพื่อลาก / แตะสั้น ๆ เพื่อเปิด-ปิดเมนู
-- ==========================================
local function createMiniUI()
    if subUICreated then
        if screenGui then
            screenGui.Enabled = true
        end
        return
    end

    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "w404_MiniUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = CoreGui

    -- Floating image frame
    miniFrame = Instance.new("Frame")
    miniFrame.Name = "WButtonFrame"
    miniFrame.Size = UDim2.fromOffset(62, 62)
    miniFrame.Position = UDim2.new(0.82, 0, 0.4, 0)
    miniFrame.BackgroundColor3 = Color3.fromRGB(8, 18, 38)
    miniFrame.BorderSizePixel = 0
    miniFrame.Active = true
    miniFrame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 14)
    frameCorner.Parent = miniFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(65, 175, 255)
    frameStroke.Thickness = 2
    frameStroke.Parent = miniFrame

    aimButton = Instance.new("ImageButton")
    aimButton.Name = "WImageButton"
    aimButton.Size = UDim2.fromScale(1, 1)
    aimButton.Position = UDim2.fromScale(0, 0)
    aimButton.BackgroundTransparency = 1
    aimButton.Image = MINI_IMAGE
    aimButton.ScaleType = Enum.ScaleType.Crop
    aimButton.AutoButtonColor = false
    aimButton.Parent = miniFrame

    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 14)
    imageCorner.Parent = aimButton

    -- Mini control panel
    miniPanel = Instance.new("Frame")
    miniPanel.Name = "MiniPanel"
    miniPanel.Size = UDim2.fromOffset(220, 218)
    miniPanel.Position = UDim2.new(0, -230, 0, 0)
    miniPanel.BackgroundColor3 = Color3.fromRGB(8, 15, 32)
    miniPanel.BorderSizePixel = 0
    miniPanel.Visible = false
    miniPanel.Parent = miniFrame

    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 12)
    panelCorner.Parent = miniPanel

    local panelStroke = Instance.new("UIStroke")
    panelStroke.Color = Color3.fromRGB(55, 155, 245)
    panelStroke.Thickness = 1.5
    panelStroke.Parent = miniPanel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -42, 0, 36)
    title.Position = UDim2.fromOffset(10, 0)
    title.BackgroundTransparency = 1
    title.Text = "w.404 | MM2 HUB"
    title.TextColor3 = Color3.fromRGB(135, 210, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = miniPanel

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.fromOffset(28, 28)
    closeButton.Position = UDim2.new(1, -33, 0, 4)
    closeButton.BackgroundColor3 = Color3.fromRGB(25, 65, 110)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 13
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = miniPanel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 7)
    closeCorner.Parent = closeButton

    closeButton.MouseButton1Click:Connect(function()
        miniOpen = false
        miniPanel.Visible = false
    end)

    local function makeMiniToggle(label, y, initialValue, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 34)
        button.Position = UDim2.fromOffset(10, y)
        button.BackgroundColor3 = Color3.fromRGB(20, 55, 100)
        button.BorderSizePixel = 0
        button.TextColor3 = Color3.fromRGB(225, 242, 255)
        button.TextSize = 12
        button.Font = Enum.Font.GothamBold
        button.Parent = miniPanel

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = button

        local enabled = initialValue

        local function refresh()
            button.Text = label .. (enabled and " : ON" or " : OFF")
            button.BackgroundColor3 = enabled
                and Color3.fromRGB(0, 105, 180)
                or Color3.fromRGB(20, 55, 100)
        end

        button.MouseButton1Click:Connect(function()
            enabled = not enabled
            refresh()
            callback(enabled)
        end)

        refresh()
        return button
    end

    makeMiniToggle("ROLE ESP", 42, espEnabled, function(value)
        espEnabled = value
        if not value then
            for _, highlight in pairs(espHighlights) do
                if highlight then
                    highlight:Destroy()
                end
            end
            espHighlights = {}
        end
    end)

    makeMiniToggle("AIMBOT", 82, aimbotEnabled, function(value)
        aimbotEnabled = value
        if not value then
            _G.LockTarget = false
        end
    end)

    makeMiniToggle("LOCK TARGET", 122, _G.LockTarget, function(value)
        _G.LockTarget = value
    end)

    makeMiniToggle("AUTO FARM", 162, autoFarmEnabled, function(value)
        autoFarmEnabled = value
    end)

    -- Drag support: touch and mouse
    local dragging = false
    local moved = false
    local dragStart
    local startPos
    local dragInput

    aimButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            moved = false
            dragStart = input.Position
            startPos = miniFrame.Position
        end
    end)

    aimButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if dragging and dragInput and input == dragInput then
            local delta = input.Position - dragStart

            if delta.Magnitude > 8 then
                moved = true
            end

            if moved then
                miniFrame.Position = UDim2.new(
                    startPos.X.Scale,
                    startPos.X.Offset + delta.X,
                    startPos.Y.Scale,
                    startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UIS.InputEnded:Connect(function(input)
        if dragging and (
            input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        ) then
            dragging = false

            if not moved then
                miniOpen = not miniOpen
                miniPanel.Visible = miniOpen
            end
        end
    end)

    subUICreated = true
end

local function hideMiniUI()
    if screenGui then
        screenGui.Enabled = false
    end
    _G.LockTarget = false
end

-- ==========================================
-- Visibility check
-- ==========================================
local function isVisible(targetPart, localChar)
    if wallCheckEnabled then
        return true
    end

    local camera = workspace.CurrentCamera
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {localChar, camera}
    raycastParams.IgnoreWater = true

    local rayResult = workspace:Raycast(
        camera.CFrame.Position,
        targetPart.Position - camera.CFrame.Position,
        raycastParams
    )

    if rayResult then
        return rayResult.Instance:IsDescendantOf(targetPart.Parent)
    end

    return false
end

-- ==========================================
-- TAB 1: ESP
-- ==========================================
local espTab = Window:MakeTab({
    Name = "ระบบ ESP",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

espTab:AddSection({
    Name = "แสดงตัวละครและบทบาท"
})

espTab:AddToggle({
    Name = "เปิดใช้งาน ESP บทบาท (Role ESP)",
    Default = false,
    Callback = function(value)
        espEnabled = value

        if not espEnabled then
            for _, highlight in pairs(espHighlights) do
                if highlight then
                    highlight:Destroy()
                end
            end
            espHighlights = {}
        end
    end
})

-- ==========================================
-- TAB 2: Combat / Aimbot
-- ==========================================
local combatTab = Window:MakeTab({
    Name = "ระบบต่อสู้",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

combatTab:AddSection({
    Name = "ระบบล็อกเป้า (Aimbot)"
})

combatTab:AddToggle({
    Name = "เปิดใช้งาน Aimbot",
    Default = false,
    Callback = function(value)
        aimbotEnabled = value
        if not value then
            _G.LockTarget = false
        end
    end
})

combatTab:AddToggle({
    Name = "ล็อกทะลุกำแพง (Wall Check)",
    Default = true,
    Callback = function(value)
        wallCheckEnabled = value
    end
})

combatTab:AddSection({
    Name = "การตั้งค่า FOV"
})

combatTab:AddToggle({
    Name = "แสดงวง FOV บนหน้าจอ",
    Default = false,
    Callback = function(value)
        fovVisible = value
        if fovCircle then
            fovCircle.Visible = value
        end
    end
})

combatTab:AddSlider({
    Name = "ขนาดวง FOV",
    Min = 50,
    Max = 500,
    Default = 150,
    Color = Color3.fromRGB(90, 180, 255),
    Increment = 5,
    ValueName = "Radius",
    Callback = function(value)
        fovRadius = value
        if fovCircle then
            fovCircle.Radius = value
        end
    end
})

combatTab:AddDropdown({
    Name = "สีของวง FOV",
    Default = "เหลืองอ่อน",
    Options = {"เหลืองอ่อน", "สายรุ้ง"},
    Callback = function(value)
        fovColorMode = value
    end
})

-- ==========================================
-- TAB 3: Auto Farm
-- ==========================================
local farmTab = Window:MakeTab({
    Name = "ระบบฟาร์ม",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

farmTab:AddSection({
    Name = "ระบบเก็บเหรียญอัตโนมัติ"
})

farmTab:AddToggle({
    Name = "เปิดใช้งาน Auto Farm Coins",
    Default = false,
    Callback = function(value)
        autoFarmEnabled = value
    end
})

-- ==========================================
-- Render loops
-- ==========================================

-- FOV position and color
RunService.RenderStepped:Connect(function()
    if not fovCircle then
        return
    end

    local mousePos = UIS:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y)
    fovCircle.Visible = fovVisible

    if fovVisible then
        if fovColorMode == "สายรุ้ง" then
            local hue = (tick() % 10) / 10
            fovCircle.Color = Color3.fromHSV(hue, 0.8, 1)
        else
            fovCircle.Color = Color3.fromRGB(255, 255, 150)
        end
    end
end)

-- Role ESP
RunService.RenderStepped:Connect(function()
    if not espEnabled then
        return
    end

    pcall(function()
        local localPlayer = Players.LocalPlayer

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= localPlayer and player.Character then
                local character = player.Character
                local rootPart = character:FindFirstChild("HumanoidRootPart")

                if rootPart then
                    local highlight = character:FindFirstChild("w404_Highlight")

                    if not highlight then
                        highlight = Instance.new("Highlight")
                        highlight.Name = "w404_Highlight"
                        highlight.Adornee = character
                        highlight.Parent = character
                        highlight.FillTransparency = 0.4
                        highlight.OutlineTransparency = 0.1
                        espHighlights[player] = highlight
                    end

                    local backpack = player:FindFirstChildOfClass("Backpack")
                    local hasKnife = character:FindFirstChild("Knife")
                        or (backpack and backpack:FindFirstChild("Knife"))

                    local hasGun = character:FindFirstChild("Gun")
                        or (backpack and backpack:FindFirstChild("Gun"))
                        or character:FindFirstChild("Revolver")
                        or (backpack and backpack:FindFirstChild("Revolver"))

                    if hasKnife then
                        highlight.FillColor = Color3.fromRGB(255, 100, 100)
                        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    elseif hasGun then
                        highlight.FillColor = Color3.fromRGB(50, 150, 255)
                        highlight.OutlineColor = Color3.fromRGB(0, 0, 255)
                    else
                        highlight.FillColor = Color3.fromRGB(100, 255, 100)
                        highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
                    end
                end
            end
        end
    end)
end)

-- Smart target selection
RunService.RenderStepped:Connect(function()
    if not (aimbotEnabled and _G.LockTarget) then
        return
    end

    pcall(function()
        local localPlayer = Players.LocalPlayer
        local camera = workspace.CurrentCamera
        local mousePos = UIS:GetMouseLocation()

        local closestTarget = nil
        local shortestDistance = fovRadius

        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if player ~= localPlayer and character then
                local rootPart = character:FindFirstChild("HumanoidRootPart")

                if rootPart then
                    local backpack = player:FindFirstChildOfClass("Backpack")
                    local hasKnife = character:FindFirstChild("Knife")
                        or (backpack and backpack:FindFirstChild("Knife"))

                    local hasGun = character:FindFirstChild("Gun")
                        or (backpack and backpack:FindFirstChild("Gun"))
                        or character:FindFirstChild("Revolver")
                        or (backpack and backpack:FindFirstChild("Revolver"))

                    if hasKnife or hasGun then
                        local screenPos, onScreen =
                            camera:WorldToViewportPoint(rootPart.Position)

                        if onScreen then
                            local distance = (
                                Vector2.new(screenPos.X, screenPos.Y) - mousePos
                            ).Magnitude

                            if distance < shortestDistance
                                and isVisible(rootPart, localPlayer.Character) then
                                shortestDistance = distance
                                closestTarget = rootPart
                            end
                        end
                    end
                end
            end
        end

        if closestTarget then
            camera.CFrame = CFrame.new(
                camera.CFrame.Position,
                closestTarget.Position
            )
        end
    end)
end)

-- Auto Farm Coins
task.spawn(function()
    while true do
        task.wait(0.5)

        if autoFarmEnabled then
            pcall(function()
                local localPlayer = Players.LocalPlayer
                local character = localPlayer.Character
                local rootPart = character
                    and character:FindFirstChild("HumanoidRootPart")
                local coinContainer = workspace:FindFirstChild("CoinContainer")

                if rootPart and coinContainer then
                    for _, coin in ipairs(coinContainer:GetChildren()) do
                        if not autoFarmEnabled then
                            break
                        end

                        local coinVisual = coin:FindFirstChild("CoinVisual")
                            or coin:FindFirstChild("Hitbox")
                            or coin

                        if coinVisual and coin:FindFirstChild("TouchInterest") then
                            rootPart.CFrame = coin.CFrame
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
    end
end)

-- ==========================================
-- Start floating W button immediately
-- ==========================================
createMiniUI()

-- Initialize Orion Library
OrionLib:Init()
