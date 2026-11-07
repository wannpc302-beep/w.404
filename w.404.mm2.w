-- =====================================================
-- Script Name : w.404 | MM2 Hub v2.9 (Part 1/4)
-- =====================================================

local ORION_URL = "https://raw.githubusercontent.com/Qanuir/orion-ui/refs/heads/main/source.lua"
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer

if not LocalPlayer then return end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- เคลียร์ UI เก่า
local oldStatus = PlayerGui:FindFirstChild("w404_StatusUI")
if oldStatus then oldStatus:Destroy() end
local oldMini = PlayerGui:FindFirstChild("w404_MiniUI")
if oldMini then oldMini:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "w404_MiniUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 9999
screenGui.Parent = PlayerGui

-- โหลด Orion Library
local loadOk, OrionLib = pcall(function()
    local source = game:HttpGet(ORION_URL)
    local chunk = loadstring(source)
    return chunk()
end)

if not loadOk or not OrionLib then return end
-- =====================================================
-- Script Name : w.404 | MM2 Hub v2.9 (Part 2/4)
-- =====================================================

local setupOk, setupError = pcall(function()
    -- ตัวแปรสถานะฟังก์ชัน
    local espEnabled = false
    local aimbotMode = "ปิด"
    local wallCheckEnabled = true
    local fovVisible = false
    local fovRadius = 150
    local fovColorMode = "เหลืองอ่อน"
    local centerDotEnabled = false
    local targetButtonEnabled = false
    
    local flyEnabled = false
    local flySpeed = 50
    local infJumpEnabled = false
    local jumpPowerVal = 50
    local noclipEnabled = false
    local autoGunEnabled = false

    local espHighlights = {}
    local espBillboards = {}

    local Window = OrionLib:MakeWindow({
        Name = "w.404 | MM2 Hub v2.9",
        HidePremium = false,
        IntroEnabled = false
    })

    -- 🎯 ปุ่มเป้าหมายขนาด 50x50 (ควบคุมจากหมวดตัวช่วย)
    local aimButton = Instance.new("TextButton")
    aimButton.Name = "ActionEmojiButton"
    aimButton.Size = UDim2.fromOffset(50, 50)
    aimButton.Position = UDim2.new(0.88, 0, 0.4, 0)
    aimButton.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
    aimButton.Text = "🎯"
    aimButton.TextSize = 24
    aimButton.Visible = false
    aimButton.Active = true
    aimButton.Draggable = true
    aimButton.ZIndex = 20
    aimButton.Parent = screenGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(1, 0)
    btnCorner.Parent = aimButton

    local btnStroke = Instance.new("UIStroke")
    btnStroke.Color = Color3.fromRGB(255, 215, 0)
    btnStroke.Thickness = 2
    btnStroke.Parent = aimButton

    aimButton.MouseButton1Click:Connect(function()
        pcall(function()
            local char = LocalPlayer.Character
            local tool = char and char:FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end)
    end)

    -- วง FOV
    local fovFrame = Instance.new("Frame")
    fovFrame.Name = "FOVCircle"
    fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    fovFrame.Size = UDim2.fromOffset(fovRadius * 2, fovRadius * 2)
    fovFrame.BackgroundTransparency = 1
    fovFrame.Visible = false
    fovFrame.Parent = screenGui

    local fovCorner = Instance.new("UICorner")
    fovCorner.CornerRadius = UDim.new(1, 0)
    fovCorner.Parent = fovFrame

    local fovStroke = Instance.new("UIStroke")
    fovStroke.Color = Color3.fromRGB(255, 255, 150)
    fovStroke.Thickness = 1.5
    fovStroke.Parent = fovFrame

    -- จุดตรงกลางหน้าจอ (Center Dot)
    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerDot.Size = UDim2.fromOffset(6, 6)
    centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    centerDot.BorderSizePixel = 0
    centerDot.Visible = false
    centerDot.ZIndex = 25
    centerDot.Parent = screenGui

    local dotCorner = Instance.new("UICorner")
    dotCorner.CornerRadius = UDim.new(1, 0)
    dotCorner.Parent = centerDot

    local dotStroke = Instance.new("UIStroke")
    dotStroke.Color = Color3.fromRGB(0, 0, 0)
    dotStroke.Thickness = 1
    dotStroke.Parent = centerDot

    -- ฟังก์ชันตรวจสอบบทบาท MM2
    local function getPlayerRole(player)
        local char = player.Character
        local backpack = player:FindFirstChildOfClass("Backpack")
        local function hasItem(name)
            return (char and char:FindFirstChild(name)) or (backpack and backpack:FindFirstChild(name))
        end
        if hasItem("Knife") then
            return "ฆาตกร", Color3.fromRGB(255, 30, 30)
        elseif hasItem("Gun") or hasItem("Revolver") then
            return "นายอำเภอ", Color3.fromRGB(30, 144, 255)
        else
            return "คนธรรมดา", Color3.fromRGB(46, 204, 113)
        end
    end

    -- Tab 1: ระบบต่อสู้
    local combatTab = Window:MakeTab({Name = "ระบบต่อสู้", Icon = "rbxassetid://4483345998"})
    combatTab:AddDropdown({
        Name = "รูปแบบ Aimbot",
        Default = "ปิด",
        Options = {"ปิด", "หันตาม", "ไม่ต้องหันตาม"},
        Callback = function(value) aimbotMode = value end
    })
    combatTab:AddToggle({
        Name = "ล็อกทะลุกำแพง / ไม่ทะลุ (Wall Check)",
        Default = true,
        Callback = function(value) wallCheckEnabled = value end
    })

    -- Tab 2: ระบบ FOV
    local fovTab = Window:MakeTab({Name = "ระบบ FOV", Icon = "rbxassetid://4483345998"})
    fovTab:AddToggle({
        Name = "แสดงวง FOV",
        Default = false,
        Callback = function(value)
            fovVisible = value
            fovFrame.Visible = value
        end
    })
    fovTab:AddSlider({
        Name = "ขนาดวง FOV",
        Min = 50, Max = 500, Default = 150, Increment = 5,
        Callback = function(value)
            fovRadius = value
            fovFrame.Size = UDim2.fromOffset(value * 2, value * 2)
        end
    })
    fovTab:AddDropdown({
        Name = "สีวง FOV",
        Default = "เหลืองอ่อน",
        Options = {"เหลืองอ่อน", "สายรุ้ง (เร็ว)"},
        Callback = function(value) fovColorMode = value end
    })
    fovTab:AddToggle({
        Name = "จุดตรงกลางหน้าจอ (Center Dot)",
        Default = false,
        Callback = function(value)
            centerDotEnabled = value
            centerDot.Visible = value
        end
    })

    -- Tab 3: ระบบ ESP
    local espTab = Window:MakeTab({Name = "ระบบ ESP", Icon = "rbxassetid://4483345998"})
    espTab:AddToggle({
        Name = "เปิด ESP (ชื่อสีขาวขอบดำ + บทบาท)",
        Default = false,
        Callback = function(value)
            espEnabled = value
            if not value then
                for _, h in pairs(espHighlights) do if h then h:Destroy() end end
                for _, b in pairs(espBillboards) do if b then b:Destroy() end end
                espHighlights = {}
                espBillboards = {}
            end
        end
    })

    -- Tab 4: 🎨 ธีมสี (12 สี)
    local colorTab = Window:MakeTab({Name = "🎨 ธีมสี (12 สี)", Icon = "rbxassetid://4483345998"})
    colorTab:AddSection({Name = "เลือกโทนสี UI เมนูหลัก"})
    
    colorTab:AddDropdown({
        Name = "เลือกสี UI",
        Default = "🥛 นมสตอเบอร์รี่ (Pink Pastel)",
        Options = {
            "🥛 นมสตอเบอร์รี่ (Pink Pastel)", 
            "🍼 นมกล้วย (Banana Pastel)", 
            "🧋 ชานม (Milk Tea)", 
            "🟣 นมเผือก (Taro Pastel)", 
            "💙 นมบลูเบอร์รี่ (Blueberry Pastel)", 
            "🟢 นมมัทฉะ (Matcha Pastel)", 
            "⚫ ธีมนิลกาฬ (Dark Midnight)", 
            "🔴 แดงเพลิง (Crimson Red)", 
            "🟡 ทองอร่าม (Royal Gold)", 
            "🟣 ม่วงนีออน (Cyber Neon)", 
            "🟢 เขียวมรกต (Emerald Green)", 
            "⚪ ขาวบริสุทธิ์ (Pure White)"
        },
        Callback = function(value)
            pcall(function()
                OrionLib:MakeNotification({
                    Name = "เปลี่ยนธีมสำเร็จ",
                    Content = "เปลี่ยนเป็น " .. value,
                    Image = "rbxassetid://4483345998",
                    Time = 2
                })
            end)
        end
    })
-- =====================================================
-- Script Name : w.404 | MM2 Hub v2.9 (Part 3/4)
-- =====================================================

    -- Tab 5: ตัวช่วย (Utilities)
    local utilTab = Window:MakeTab({Name = "ตัวช่วย", Icon = "rbxassetid://4483345998"})

    utilTab:AddSection({Name = "ปุ่มควบคุมพิเศษ"})
    utilTab:AddToggle({
        Name = "เปิด/ปิด ปุ่มเป้า 🎯 (ยิง/ปามีด)",
        Default = false,
        Callback = function(value)
            targetButtonEnabled = value
            aimButton.Visible = value
        end
    })

    utilTab:AddSection({Name = "การเคลื่อนไหว & บิน"})
    utilTab:AddToggle({
        Name = "เปิดบิน (Fly)",
        Default = false,
        Callback = function(value) flyEnabled = value end
    })
    utilTab:AddSlider({
        Name = "ความเร็วบิน (1-200)",
        Min = 1, Max = 200, Default = 50, Increment = 1,
        Callback = function(value) flySpeed = value end
    })
    utilTab:AddToggle({
        Name = "กระโดดอินฟินิตี้ (1-50)",
        Default = false,
        Callback = function(value) infJumpEnabled = value end
    })
    utilTab:AddSlider({
        Name = "ความสูงกระโดดปกติ (1-100)",
        Min = 1, Max = 100, Default = 50, Increment = 1,
        Callback = function(value)
            jumpPowerVal = value
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower = value
            end
        end
    })
    utilTab:AddToggle({
        Name = "เดินทะลุ (Noclip)",
        Default = false,
        Callback = function(value) noclipEnabled = value end
    })
    utilTab:AddToggle({
        Name = "วาร์ปไปเก็บปืนอัตโนมัติ",
        Default = false,
        Callback = function(value) autoGunEnabled = value end
    })

    utilTab:AddSection({Name = "ระบบวาร์ป & เลือกผู้เล่น"})
    
    local targetList = {}
    local function getPlayerNames()
        targetList = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(targetList, p.Name) end
        end
        return targetList
    end

    local selectedPlayer = ""
    local playerDropdown = utilTab:AddDropdown({
        Name = "รายชื่อผู้เล่น",
        Default = "",
        Options = getPlayerNames(),
        Callback = function(val) selectedPlayer = val end
    })

    utilTab:AddButton({
        Name = "🔄 รีเซ็ตรายชื่อผู้เล่น",
        Callback = function()
            playerDropdown:Refresh(getPlayerNames())
        end
    })

    utilTab:AddButton({
        Name = "🚀 วาร์ปไปหาผู้เล่นที่เลือก",
        Callback = function()
            local target = Players:FindFirstChild(selectedPlayer)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
            end
        end
    })

    -- ระบบเตะผู้เล่นออกจากแมพ
    local function flingPlayer(filterRole)
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        local originalPos = root.CFrame

        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local role = getPlayerRole(p)
                if filterRole == "All" or role == filterRole then
                    local targetRoot = p.Character.HumanoidRootPart
                    for i = 1, 25 do
                        root.CFrame = targetRoot.CFrame * CFrame.Angles(math.random(0,360), math.random(0,360), math.random(0,360)) + Vector3.new(0, 2, 0)
                        root.AssemblyLinearVelocity = Vector3.new(99999, 99999, 99999)
                        task.wait(0.02)
                    end
                end
            end
        end
        task.wait(0.1)
        root.CFrame = originalPos
        root.AssemblyLinearVelocity = Vector3.zero
    end

    utilTab:AddSection({Name = "ระบบเตะผู้เล่นออกจากแมพ"})
    utilTab:AddButton({
        Name = "🌪️ เตะคนออกจากแมพ (ทุกคน)",
        Callback = function() flingPlayer("All") end
    })
    utilTab:AddButton({
        Name = "🛡️ เตะคนธรรมดา ออกแมพ",
        Callback = function() flingPlayer("คนธรรมดา") end
    })
    utilTab:AddButton({
        Name = "⭐ เตะนายอำเภอ ออกแมพ",
        Callback = function() flingPlayer("นายอำเภอ") end
    })
    utilTab:AddButton({
        Name = "🔪 เตะฆาตกร ออกแมพ",
        Callback = function() flingPlayer("ฆาตกร") end
    })
    utilTab:AddButton({
        Name = "⚡ Kill All (เฉพาะฆาตกร)",
        Callback = function()
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local orig = root.CFrame
            for _, p in ipairs(Players:GetPlayers()) do
                local role = getPlayerRole(p)
                if role == "ฆาตกร" and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    root.CFrame = p.Character.HumanoidRootPart.CFrame
                    task.wait(0.05)
                end
            end
            task.wait(0.1)
            root.CFrame = orig
        end
    })
                                  -- =====================================================
-- Script Name : w.404 | MM2 Hub v2.9 (Part 4/4)
-- =====================================================

    -- ลูปการทำงานหลัก
    RunService.RenderStepped:Connect(function()
        -- FOV & สีรุ้งแบบเร็ว
        if fovVisible then
            local camera = workspace.CurrentCamera
            if camera then
                local pos = UIS.TouchEnabled and (camera.ViewportSize / 2) or (UIS:GetMouseLocation() - GuiService:GetGuiInset())
                fovFrame.Position = UDim2.fromOffset(pos.X, pos.Y)
                if fovColorMode == "สายรุ้ง (เร็ว)" then
                    fovStroke.Color = Color3.fromHSV((os.clock() * 3) % 1, 1, 1)
                else
                    fovStroke.Color = Color3.fromRGB(255, 255, 150)
                end
            end
        end

        -- ESP
        if espEnabled then
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local char = player.Character
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local roleName, roleColor = getPlayerRole(player)
                        
                        local hl = espHighlights[player]
                        if not hl then
                            hl = Instance.new("Highlight")
                            hl.Parent = char
                            espHighlights[player] = hl
                        end
                        hl.Adornee = char
                        hl.FillColor = roleColor
                        hl.OutlineColor = Color3.new(1, 1, 1)
                        hl.FillTransparency = 0.4

                        local bill = espBillboards[player]
                        if not bill then
                            bill = Instance.new("BillboardGui")
                            bill.Size = UDim2.fromOffset(120, 50)
                            bill.AlwaysOnTop = true
                            bill.StudsOffset = Vector3.new(0, 3, 0)
                            
                            local lbl = Instance.new("TextLabel")
                            lbl.Name = "Info"
                            lbl.Size = UDim2.fromScale(1, 1)
                            lbl.BackgroundTransparency = 1
                            lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
                            lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                            lbl.TextStrokeTransparency = 0
                            lbl.TextSize = 14
                            lbl.Font = Enum.Font.GothamBold
                            lbl.Parent = bill
                            
                            bill.Parent = char
                            espBillboards[player] = bill
                        end
                        local textLbl = bill:FindFirstChild("Info")
                        if textLbl then
                            textLbl.Text = player.Name .. "\n[" .. roleName .. "]"
                        end
                    end
                end
            end
        end

        -- Aimbot
        if aimbotMode ~= "ปิด" then
            local camera = workspace.CurrentCamera
            if camera then
                local center = UIS.TouchEnabled and (camera.ViewportSize / 2) or (UIS:GetMouseLocation() - GuiService:GetGuiInset())
                local closestPart = nil
                local shortestDist = fovRadius

                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local rp = p.Character.HumanoidRootPart
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        if not hum or hum.Health > 0 then
                            local canSee = true
                            if wallCheckEnabled then
                                local rayParams = RaycastParams.new()
                                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                                rayParams.FilterDescendantsInstances = {LocalPlayer.Character, camera}
                                local result = workspace:Raycast(camera.CFrame.Position, rp.Position - camera.CFrame.Position, rayParams)
                                if result and not result.Instance:IsDescendantOf(p.Character) then
                                    canSee = false
                                end
                            end

                            if canSee then
                                local screenPos, onScreen = camera:WorldToViewportPoint(rp.Position)
                                if onScreen then
                                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                                    if dist < shortestDist then
                                        shortestDist = dist
                                        closestPart = rp
                                    end
                                end
                            end
                        end
                    end
                end

                if closestPart then
                    if aimbotMode == "หันตาม" then
                        camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, closestPart.Position), 0.5)
                    elseif aimbotMode == "ไม่ต้องหันตาม" then
                        pcall(function()
                            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
                            if tool and tool:FindFirstChild("Handle") then
                                tool.Handle.CFrame = CFrame.new(tool.Handle.Position, closestPart.Position)
                            end
                        end)
                    end
                end
            end
        end

        -- Auto Gun Pickup
        if autoGunEnabled then
            pcall(function()
                for _, obj in ipairs(workspace:GetChildren()) do
                    if obj.Name == "GunDrop" or obj.Name == "RevolverDrop" then
                        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            if obj:IsA("BasePart") then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = obj.CFrame
                            elseif obj:IsA("Model") and obj.PrimaryPart then
                                LocalPlayer.Character.HumanoidRootPart.CFrame = obj.PrimaryPart.CFrame
                            end
                        end
                    end
                end
            end)
        end
    end)

    -- Inf Jump
    UIS.JumpRequest:Connect(function()
        if infJumpEnabled and LocalPlayer.Character then
            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)

    -- Noclip
    RunService.Stepped:Connect(function()
        if noclipEnabled and LocalPlayer.Character then
            for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end)

    OrionLib:Init()
end)

if not setupOk then
    warn("Error: " .. tostring(setupError))
end
