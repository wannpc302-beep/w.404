-- =====================================================
-- Script Name : w.404 | MM2 Hub
-- Executor    : Delta (executor support varies by version)
-- Version     : 1.1 - startup, UI, input and feature fixes
-- =====================================================

-- Orion-compatible library fork. The old shlexware URL no longer resolves.
local ORION_URL = "https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"
local MINI_IMAGE = "rbxassetid://116990467705581"

-- -----------------------------------------------------
-- Services / early status panel (so startup errors are visible)
-- -----------------------------------------------------
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then
    warn("[w.404] LocalPlayer is unavailable. Run this after joining a game.")
    return
end

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local oldStatus = PlayerGui:FindFirstChild("w404_StatusUI")
if oldStatus then oldStatus:Destroy() end

local statusGui = Instance.new("ScreenGui")
statusGui.Name = "w404_StatusUI"
statusGui.ResetOnSpawn = false
statusGui.IgnoreGuiInset = true
statusGui.DisplayOrder = 10000
statusGui.Parent = PlayerGui

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.AnchorPoint = Vector2.new(0.5, 0)
statusLabel.Position = UDim2.new(0.5, 0, 0, 12)
statusLabel.Size = UDim2.new(0.94, 0, 0, 76)
statusLabel.BackgroundColor3 = Color3.fromRGB(15, 25, 42)
statusLabel.BackgroundTransparency = 0.08
statusLabel.BorderSizePixel = 0
statusLabel.TextColor3 = Color3.fromRGB(225, 242, 255)
statusLabel.TextSize = 15
statusLabel.Font = Enum.Font.GothamBold
statusLabel.TextWrapped = true
statusLabel.Text = "w.404: กำลังเริ่มต้น..."
statusLabel.Parent = statusGui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusLabel

local function showStatus(message, isError)
    statusLabel.Text = tostring(message)
    statusLabel.BackgroundColor3 = isError
        and Color3.fromRGB(110, 30, 35)
        or Color3.fromRGB(15, 75, 110)
    statusLabel.Visible = true
    if not isError then
        task.delay(3, function()
            if statusGui and statusGui.Parent then
                statusGui:Destroy()
            end
        end)
    end
end

-- -----------------------------------------------------
-- Load Orion with explicit checks (no silent startup failure)
-- -----------------------------------------------------
statusLabel.Text = "w.404: กำลังโหลด Orion..."

local loadOk, OrionLibOrError = pcall(function()
    assert(type(loadstring) == "function", "Executor ไม่มี loadstring")

    local source = game:HttpGet(ORION_URL)
    assert(type(source) == "string" and #source > 1000, "ดาวน์โหลด Orion ไม่สำเร็จหรือไฟล์ว่าง")

    -- Delta variants expose different GUI helpers; make optional helpers safe.
    source = source:gsub("if syn then", 'if syn and type(syn.protect_gui) == "function" then', 1)
    source = source:gsub(
        "Orion.Parent = gethui%(%) or game.CoreGui",
        'Orion.Parent = (type(gethui) == "function" and gethui()) or game.CoreGui',
        1
    )

    local chunk, compileError = loadstring(source)
    assert(type(chunk) == "function", tostring(compileError or "คอมไพล์ Orion ไม่สำเร็จ"))

    local library = chunk()
    assert(type(library) == "table", "Orion ไม่ได้คืนค่าเป็น library")
    assert(type(library.MakeWindow) == "function", "Orion fork นี้ไม่มี MakeWindow")
    return library
end)

if not loadOk then
    local errText = "W404 ERROR: โหลด Orion ไม่สำเร็จ\n" .. tostring(OrionLibOrError)
    warn(errText)
    showStatus(errText, true)
    return
end

local OrionLib = OrionLibOrError

-- -----------------------------------------------------
-- Main setup - all setup errors are shown on screen
-- -----------------------------------------------------
local setupOk, setupError = pcall(function()
    -- Feature state
    local espEnabled = false
    local aimbotEnabled = false
    local lockTargetEnabled = false
    local wallCheckEnabled = true
    local fovVisible = false
    local fovRadius = 150
    local fovColorMode = "เหลืองอ่อน"
    local autoFarmEnabled = false
    local autoKnifeThrowEnabled = false
    local flyFarmSpeed = 50
    local noclipEnabled = false
    local aimbotIndicator = nil

    local espHighlights = {}
    local miniToggleSetters = {}

    local function clearESP()
        for player, highlight in pairs(espHighlights) do
            if highlight then
                pcall(function() highlight:Destroy() end)
            end
            espHighlights[player] = nil
        end
    end

    local function setMiniToggle(key, value)
        local setter = miniToggleSetters[key]
        if setter then setter(value) end
    end

    local function setESP(value)
        espEnabled = value == true
        setMiniToggle("esp", espEnabled)
        if not espEnabled then clearESP() end
    end

    local function setAimbot(value)
        aimbotEnabled = value == true
        setMiniToggle("aimbot", aimbotEnabled)
        if aimbotIndicator then aimbotIndicator.Visible = aimbotEnabled end
        if not aimbotEnabled then
            lockTargetEnabled = false
            _G.LockTarget = false
            setMiniToggle("lock", false)
        end
    end

    local function setLockTarget(value)
        lockTargetEnabled = value == true
        _G.LockTarget = lockTargetEnabled
        setMiniToggle("lock", lockTargetEnabled)
    end

    local function setAutoFarm(value)
        autoFarmEnabled = value == true
        setMiniToggle("farm", autoFarmEnabled)
    end

    _G.LockTarget = false

    -- Window. Saving is enabled only if this executor provides the required file APIs.
    local canSaveConfig = type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(writefile) == "function"
        and type(isfile) == "function"
        and type(readfile) == "function"

    local Window = OrionLib:MakeWindow({
        Name = "w.404 | ระบบช่วยเล่น MM2",
        HidePremium = false,
        SaveConfig = canSaveConfig,
        ConfigFolder = "w404_MM2",
        IntroEnabled = false
    })

    -- -------------------------------------------------
    -- Floating W UI (PlayerGui, confirmed by the user's test)
    -- -------------------------------------------------
    local oldMini = PlayerGui:FindFirstChild("w404_MiniUI")
    if oldMini then oldMini:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "w404_MiniUI"
    screenGui.ResetOnSpawn = false
    screenGui.IgnoreGuiInset = true
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 9999
    screenGui.Parent = PlayerGui

    -- Native UI FOV ring; does not depend on executor Drawing API.
    local fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVCircle"
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
    fovFrame.BackgroundTransparency = 1
    fovFrame.BorderSizePixel = 0
    fovFrame.Visible = false
    fovFrame.ZIndex = 1
    fovFrame.Parent = screenGui

    local fovCorner = Instance.new("UICorner")
    fovCorner.CornerRadius = UDim.new(1, 0)
    fovCorner.Parent = fovFrame

    local fovStroke = Instance.new("UIStroke")
    fovStroke.Color = Color3.fromRGB(255, 255, 150)
    fovStroke.Thickness = 1.5
    fovStroke.Parent = fovFrame

    local miniFrame = Instance.new("Frame")
    miniFrame.Name = "WButtonFrame"
    miniFrame.Size = UDim2.fromOffset(62, 62)
    miniFrame.Position = UDim2.new(0.82, 0, 0.4, 0)
    miniFrame.BackgroundColor3 = Color3.fromRGB(8, 18, 38)
    miniFrame.BorderSizePixel = 0
    miniFrame.Active = true
    miniFrame.ZIndex = 10
    miniFrame.Parent = screenGui

    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 14)
    frameCorner.Parent = miniFrame

    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Color3.fromRGB(65, 175, 255)
    frameStroke.Thickness = 2
    frameStroke.Parent = miniFrame

    local aimButton = Instance.new("ImageButton")
    aimButton.Name = "WImageButton"
    aimButton.Size = UDim2.fromScale(1, 1)
    aimButton.BackgroundTransparency = 1
    aimButton.Image = MINI_IMAGE
    aimButton.ScaleType = Enum.ScaleType.Crop
    aimButton.AutoButtonColor = false
    aimButton.ZIndex = 11
    aimButton.Parent = miniFrame

    local imageCorner = Instance.new("UICorner")
    imageCorner.CornerRadius = UDim.new(0, 14)
    imageCorner.Parent = aimButton

    aimbotIndicator = Instance.new("TextLabel")
    aimbotIndicator.Name = "AimbotIndicator"
    aimbotIndicator.AnchorPoint = Vector2.new(1, 1)
    aimbotIndicator.Position = UDim2.new(1, -1, 1, -1)
    aimbotIndicator.Size = UDim2.fromOffset(25, 23)
    aimbotIndicator.BackgroundColor3 = Color3.fromRGB(25, 28, 34)
    aimbotIndicator.BackgroundTransparency = 0.08
    aimbotIndicator.Text = "🎯"
    aimbotIndicator.TextSize = 16
    aimbotIndicator.Visible = aimbotEnabled
    aimbotIndicator.ZIndex = 15
    aimbotIndicator.Parent = miniFrame

    local miniPanel = Instance.new("Frame")
    miniPanel.Name = "MiniPanel"
    miniPanel.Size = UDim2.fromOffset(220, 258)
    miniPanel.Position = UDim2.new(0, -230, 0, 0)
    miniPanel.BackgroundColor3 = Color3.fromRGB(8, 15, 32)
    miniPanel.BorderSizePixel = 0
    miniPanel.Visible = false
    miniPanel.ZIndex = 12
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
    title.ZIndex = 13
    title.Parent = miniPanel

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.fromOffset(28, 28)
    closeButton.Position = UDim2.new(1, -33, 0, 4)
    closeButton.BackgroundColor3 = Color3.fromRGB(25, 65, 110)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.new(1, 1, 1)
    closeButton.TextSize = 13
    closeButton.Font = Enum.Font.GothamBold
    closeButton.ZIndex = 14
    closeButton.Parent = miniPanel

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 7)
    closeCorner.Parent = closeButton

    local miniOpen = false
    closeButton.MouseButton1Click:Connect(function()
        miniOpen = false
        miniPanel.Visible = false
    end)

    local function positionMiniPanel()
        local camera = workspace.CurrentCamera
        if not camera then return end
        if miniFrame.AbsolutePosition.X < camera.ViewportSize.X / 2 then
            miniPanel.Position = UDim2.new(1, 10, 0, 0)
        else
            miniPanel.Position = UDim2.new(0, -230, 0, 0)
        end
    end

    local function makeMiniToggle(key, label, y, initialValue, callback)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, -20, 0, 34)
        button.Position = UDim2.fromOffset(10, y)
        button.BackgroundColor3 = Color3.fromRGB(20, 55, 100)
        button.BorderSizePixel = 0
        button.TextColor3 = Color3.fromRGB(225, 242, 255)
        button.TextSize = 12
        button.Font = Enum.Font.GothamBold
        button.ZIndex = 13
        button.Parent = miniPanel

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = button

        local enabled = initialValue == true
        local function refresh()
            button.Text = label .. (enabled and " : ON" or " : OFF")
            button.BackgroundColor3 = enabled
                and Color3.fromRGB(0, 105, 180)
                or Color3.fromRGB(20, 55, 100)
        end

        miniToggleSetters[key] = function(value)
            enabled = value == true
            refresh()
        end

        button.MouseButton1Click:Connect(function()
            enabled = not enabled
            refresh()
            callback(enabled)
        end)
        refresh()
    end

    makeMiniToggle("esp", "ROLE ESP", 42, espEnabled, setESP)
    makeMiniToggle("aimbot", "AIMBOT", 82, aimbotEnabled, setAimbot)
    makeMiniToggle("lock", "LOCK TARGET", 122, lockTargetEnabled, setLockTarget)
    makeMiniToggle("farm", "FLY FARM", 162, autoFarmEnabled, setAutoFarm)
    makeMiniToggle("knife", "AUTO KNIFE", 202, autoKnifeThrowEnabled, function(value)
        autoKnifeThrowEnabled = value == true
    end)

    -- Tap toggles the panel; hold for 0.35s before dragging.
    local pressActive = false
    local pressMoved = false
    local pressStartTime = 0
    local dragStart = nil
    local startPos = nil
    local activeTouch = nil
    local HOLD_TO_DRAG = 0.35
    local MOVE_THRESHOLD = 8

    aimButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            pressActive = true
            pressMoved = false
            pressStartTime = os.clock()
            dragStart = input.Position
            startPos = miniFrame.Position
            activeTouch = input.UserInputType == Enum.UserInputType.Touch and input or nil
        end
    end)

    UIS.InputChanged:Connect(function(input)
        if not pressActive or not dragStart or not startPos then return end
        local isRelevant = input.UserInputType == Enum.UserInputType.MouseMovement
            or (activeTouch and input == activeTouch)
        if not isRelevant then return end

        local delta = input.Position - dragStart
        if delta.Magnitude > MOVE_THRESHOLD then
            pressMoved = true
        end

        if pressMoved and os.clock() - pressStartTime >= HOLD_TO_DRAG then
            miniFrame.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
            positionMiniPanel()
        end
    end)

    UIS.InputEnded:Connect(function(input)
        local ended = input.UserInputType == Enum.UserInputType.MouseButton1
            or (activeTouch and input == activeTouch)
        if not pressActive or not ended then return end

        local heldFor = os.clock() - pressStartTime
        pressActive = false
        activeTouch = nil

        if not pressMoved and heldFor < HOLD_TO_DRAG then
            miniOpen = not miniOpen
            miniPanel.Visible = miniOpen
            if miniOpen then positionMiniPanel() end
        end
    end)

    -- -------------------------------------------------
    -- Helpers shared by ESP / Aimbot / Auto Farm
    -- -------------------------------------------------
    local function findTool(player, toolName)
        local character = player.Character
        local backpack = player:FindFirstChildOfClass("Backpack")
        return (character and character:FindFirstChild(toolName))
            or (backpack and backpack:FindFirstChild(toolName))
    end

    local function isVisible(targetPart)
        if not wallCheckEnabled then return true end
        local camera = workspace.CurrentCamera
        if not camera or not targetPart then return false end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local excluded = {camera}
        if LocalPlayer.Character then
            table.insert(excluded, LocalPlayer.Character)
        end
        params.FilterDescendantsInstances = excluded
        params.IgnoreWater = true

        local origin = camera.CFrame.Position
        local direction = targetPart.Position - origin
        local result = workspace:Raycast(origin, direction, params)
        return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
    end

    -- -------------------------------------------------
    -- Tab 1: ESP
    -- -------------------------------------------------
    local espTab = Window:MakeTab({
        Name = "ระบบ ESP",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    espTab:AddSection({Name = "แสดงตัวละครและบทบาท"})
    espTab:AddToggle({
        Name = "เปิดใช้งาน ESP บทบาท (Role ESP)",
        Default = false,
        Callback = setESP
    })

    -- -------------------------------------------------
    -- Tab 2: Combat / Aimbot
    -- -------------------------------------------------
    local combatTab = Window:MakeTab({
        Name = "ระบบต่อสู้",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    combatTab:AddSection({Name = "ระบบล็อกเป้า (Aimbot)"})
    combatTab:AddToggle({
        Name = "เปิดใช้งาน Aimbot",
        Default = false,
        Callback = setAimbot
    })
    combatTab:AddToggle({
        Name = "ล็อกเป้าหมาย",
        Default = false,
        Callback = setLockTarget
    })
    combatTab:AddToggle({
        Name = "ตรวจสอบกำแพง (Wall Check)",
        Default = true,
        Callback = function(value)
            wallCheckEnabled = value == true
        end
    })
    combatTab:AddToggle({
        Name = "ปามีดอัตโนมัติ (ต้องถือมีด)",
        Default = false,
        Callback = function(value)
            autoKnifeThrowEnabled = value == true
            setMiniToggle("knife", autoKnifeThrowEnabled)
        end
    })

    -- -------------------------------------------------
    -- Tab 3: FOV (separated from combat for easier access)
    -- -------------------------------------------------
    local fovTab = Window:MakeTab({
        Name = "ระบบ FOV",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    fovTab:AddSection({Name = "การตั้งค่าวง FOV"})
    fovTab:AddToggle({
        Name = "แสดงวง FOV บนหน้าจอ",
        Default = false,
        Callback = function(value)
            fovVisible = value == true
            fovFrame.Visible = fovVisible
        end
    })
    fovTab:AddSlider({
        Name = "ขนาดวง FOV",
        Min = 50,
        Max = 500,
        Default = 150,
        Increment = 5,
        ValueName = "Radius",
        Color = Color3.fromRGB(90, 180, 255),
        Callback = function(value)
            fovRadius = tonumber(value) or 150
            fovFrame.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
        end
    })
    fovTab:AddDropdown({
        Name = "สีของวง FOV",
        Default = "เหลืองอ่อน",
        Options = {"เหลืองอ่อน", "สายรุ้ง"},
        Callback = function(value)
            fovColorMode = value
        end
    })

    -- -------------------------------------------------
    -- Tab 4: Auto Farm
    -- -------------------------------------------------
    local farmTab = Window:MakeTab({
        Name = "ระบบฟาร์ม",
        Icon = "rbxassetid://4483345998",
        PremiumOnly = false
    })

    farmTab:AddSection({Name = "ระบบเก็บเหรียญอัตโนมัติ"})
    farmTab:AddToggle({
        Name = "เปิดบินฟาร์มเหรียญ (Fly Farm)",
        Default = false,
        Callback = setAutoFarm
    })
    farmTab:AddToggle({
        Name = "บินทะลุสิ่งกีดขวาง (Noclip)",
        Default = false,
        Callback = function(value)
            noclipEnabled = value == true
        end
    })
    farmTab:AddSlider({
        Name = "ความเร็วบิน",
        Min = 10,
        Max = 100,
        Default = 50,
        Increment = 5,
        ValueName = "Speed",
        Callback = function(value)
            flyFarmSpeed = tonumber(value) or 50
        end
    })

    -- -------------------------------------------------
    -- Render: FOV ring
    -- -------------------------------------------------
    local lastFOVUpdate = 0
    RunService.RenderStepped:Connect(function()
        if not fovVisible then return end
        local now = os.clock()
        if now - lastFOVUpdate < 0.02 then return end
        lastFOVUpdate = now

        local camera = workspace.CurrentCamera
        if not camera then return end

        local position
        if UIS.TouchEnabled then
            position = camera.ViewportSize / 2
        else
            local inset = GuiService:GetGuiInset()
            local mousePosition = UIS:GetMouseLocation()
            position = mousePosition - Vector2.new(inset.X, inset.Y)
        end
        fovFrame.Position = UDim2.fromOffset(position.X, position.Y)

        if fovColorMode == "สายรุ้ง" then
            fovStroke.Color = Color3.fromHSV((os.clock() % 1.2) / 1.2, 0.8, 1)
        else
            fovStroke.Color = Color3.fromRGB(255, 255, 150)
        end
    end)

    -- -------------------------------------------------
    -- Render: Role ESP (tool-name heuristic)
    -- -------------------------------------------------
    local lastESPUpdate = 0
    RunService.RenderStepped:Connect(function()
        if not espEnabled then return end
        if os.clock() - lastESPUpdate < 0.2 then return end
        lastESPUpdate = os.clock()

        local activePlayers = {}
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local character = player.Character
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")

                if rootPart and (not humanoid or humanoid.Health > 0) then
                    activePlayers[player] = true
                    local highlight = espHighlights[player]
                    if not highlight or not highlight.Parent then
                        highlight = character:FindFirstChild("w404_Highlight")
                        if not highlight then
                            highlight = Instance.new("Highlight")
                            highlight.Name = "w404_Highlight"
                            highlight.Parent = character
                        end
                        highlight.Adornee = character
                        highlight.FillTransparency = 0.4
                        highlight.OutlineTransparency = 0.1
                        espHighlights[player] = highlight
                    elseif highlight.Adornee ~= character then
                        highlight.Adornee = character
                        highlight.Parent = character
                    end

                    local hasKnife = findTool(player, "Knife") ~= nil
                    local hasGun = findTool(player, "Gun") ~= nil
                        or findTool(player, "Revolver") ~= nil

                    if hasKnife then
                        highlight.FillColor = Color3.fromRGB(255, 25, 25)
                        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    elseif hasGun then
                        highlight.FillColor = Color3.fromRGB(0, 170, 255)
                        highlight.OutlineColor = Color3.fromRGB(0, 90, 255)
                    else
                        highlight.FillColor = Color3.fromRGB(0, 255, 45)
                        highlight.OutlineColor = Color3.fromRGB(0, 210, 25)
                    end
                end
            end
        end

        for player, highlight in pairs(espHighlights) do
            if not activePlayers[player] then
                if highlight then highlight:Destroy() end
                espHighlights[player] = nil
            end
        end
    end)

    Players.PlayerRemoving:Connect(function(player)
        local highlight = espHighlights[player]
        if highlight then highlight:Destroy() end
        espHighlights[player] = nil
    end)

    -- -------------------------------------------------
    -- Render: Aimbot target selection
    -- -------------------------------------------------
    RunService.RenderStepped:Connect(function()
        if not (aimbotEnabled and lockTargetEnabled) then return end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local center
        if UIS.TouchEnabled then
            center = camera.ViewportSize / 2
        else
            local inset = GuiService:GetGuiInset()
            local mousePosition = UIS:GetMouseLocation()
            center = mousePosition - Vector2.new(inset.X, inset.Y)
        end

        local closestPart = nil
        local shortestDistance = fovRadius

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local character = player.Character
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local hasKnife = findTool(player, "Knife") ~= nil
                local hasGun = findTool(player, "Gun") ~= nil
                    or findTool(player, "Revolver") ~= nil

                if rootPart and (not humanoid or humanoid.Health > 0) and (hasKnife or hasGun) then
                    local screenPosition, onScreen = camera:WorldToViewportPoint(rootPart.Position)
                    if onScreen then
                        local distance = (
                            Vector2.new(screenPosition.X, screenPosition.Y) - center
                        ).Magnitude
                        if distance < shortestDistance and isVisible(rootPart) then
                            shortestDistance = distance
                            closestPart = rootPart
                        end
                    end
                end
            end
        end

        if closestPart then
            local desired = CFrame.new(camera.CFrame.Position, closestPart.Position)
            camera.CFrame = camera.CFrame:Lerp(desired, 0.35)
        end
    end)

    -- Auto knife activation: only while a Knife tool is equipped.
    task.spawn(function()
        local lastThrow = 0
        while screenGui.Parent do
            task.wait(0.12)
            if autoKnifeThrowEnabled and aimbotEnabled and lockTargetEnabled then
                local character = LocalPlayer.Character
                local knife = character and character:FindFirstChild("Knife")
                if knife and knife:IsA("Tool") and os.clock() - lastThrow >= 0.9 then
                    lastThrow = os.clock()
                    pcall(function()
                        knife:Activate()
                    end)
                end
            end
        end
    end)

    -- -------------------------------------------------
    -- Auto Farm: safely resolve a BasePart from each coin
    -- -------------------------------------------------
    local function getCoinPart(coin)
        if coin:IsA("BasePart") then return coin end
        if coin:IsA("Model") and coin.PrimaryPart then
            return coin.PrimaryPart
        end
        return coin:FindFirstChildWhichIsA("BasePart", true)
    end

    -- Fly farm: move toward coins using velocity; no direct CFrame teleport.
    local originalCollision = {}
    local function setCharacterNoclip(character, enabled)
        for _, part in ipairs(character:GetDescendants()) do
            if part:IsA("BasePart") then
                if enabled then
                    if originalCollision[part] == nil then
                        originalCollision[part] = part.CanCollide
                    end
                    part.CanCollide = false
                elseif originalCollision[part] ~= nil then
                    part.CanCollide = originalCollision[part]
                    originalCollision[part] = nil
                end
            end
        end
    end

    task.spawn(function()
        while screenGui.Parent do
            task.wait(0.08)
            local character = LocalPlayer.Character
            local rootPart = character and character:FindFirstChild("HumanoidRootPart")

            if character and noclipEnabled then
                setCharacterNoclip(character, true)
            elseif character then
                setCharacterNoclip(character, false)
            end

            if autoFarmEnabled and rootPart then
                local coinContainer = workspace:FindFirstChild("CoinContainer", true)
                local nearestPart, nearestDistance = nil, math.huge

                if coinContainer then
                    for _, coin in ipairs(coinContainer:GetChildren()) do
                        local coinPart = getCoinPart(coin)
                        if coinPart and coinPart:IsDescendantOf(workspace) then
                            local distance = (coinPart.Position - rootPart.Position).Magnitude
                            if distance < nearestDistance then
                                nearestDistance = distance
                                nearestPart = coinPart
                            end
                        end
                    end
                end

                if nearestPart then
                    local offset = nearestPart.Position - rootPart.Position
                    if offset.Magnitude > 2 then
                        local speed = math.clamp(flyFarmSpeed, 10, 100)
                        rootPart.AssemblyLinearVelocity = offset.Unit * speed
                    else
                        rootPart.AssemblyLinearVelocity = Vector3.zero
                    end
                else
                    rootPart.AssemblyLinearVelocity = Vector3.zero
                end
            end
        end
        if LocalPlayer.Character then
            setCharacterNoclip(LocalPlayer.Character, false)
        end
    end)

    -- Initialize Orion after all tabs and callbacks are ready.
    OrionLib:Init()

    showStatus("w.404 | MM2 Hub โหลดสำเร็จ", false)
end)

if not setupOk then
    local errText = "W404 SETUP ERROR:\n" .. tostring(setupError)
    warn(errText)
    showStatus(errText, true)
end
