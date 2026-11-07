-- =====================================================
-- w.404 | MM2 Hub - Gray UI Edition
-- Custom sidebar UI inspired by the user's reference image.
-- Executor: Delta (API support varies by version)
-- =====================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local MINI_IMAGE = "rbxassetid://116990467705581"
local COLORS = {
    background = Color3.fromRGB(31, 32, 35),
    panel = Color3.fromRGB(42, 43, 47),
    panel2 = Color3.fromRGB(51, 52, 57),
    sidebar = Color3.fromRGB(35, 36, 40),
    stroke = Color3.fromRGB(83, 85, 91),
    text = Color3.fromRGB(242, 242, 244),
    muted = Color3.fromRGB(164, 166, 172),
    accent = Color3.fromRGB(155, 158, 166),
    accentOn = Color3.fromRGB(205, 207, 212),
    red = Color3.fromRGB(190, 85, 85),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function corner(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, parent)
end
local function stroke(parent, color, thickness)
    make("UIStroke", {Color = color or COLORS.stroke, Thickness = thickness or 1}, parent)
end
local function addText(parent, text, size, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1, Text = text, TextSize = size or 13,
        TextColor3 = color or COLORS.text, Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    }, parent)
end

-- Remove previous copy if the script is executed again.
for _, name in ipairs({"w404_MainUI", "w404_FloatingUI", "w404_StatusUI"}) do
    local old = PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

local gui = make("ScreenGui", {
    Name = "w404_MainUI", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 9998,
}, PlayerGui)

local state = {
    esp = false, aimbot = false, lock = false, wallCheck = true,
    fov = false, fovRadius = 150, fovRainbow = false, farm = false,
}
local espHighlights = {}
local controls = {}
local currentTab = "หน้าหลัก"

-- FOV ring uses ordinary Roblox UI instead of executor Drawing API.
local fovCircle = make("Frame", {
    Name = "FOVCircle", AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(state.fovRadius * 2, state.fovRadius * 2),
    BackgroundTransparency = 1, BorderSizePixel = 0, Visible = false,
    ZIndex = 2,
}, gui)
corner(fovCircle, 999)
local fovStroke = stroke(fovCircle, COLORS.accentOn, 1.5)

-- Main window: gray/charcoal theme, left navigation and right settings area.
local main = make("Frame", {
    Name = "MainWindow", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(560, 365),
    BackgroundColor3 = COLORS.background, BorderSizePixel = 0,
    Visible = false, ClipsDescendants = true,
}, gui)
corner(main, 12)
stroke(main, COLORS.stroke, 1.2)

local top = make("Frame", {
    Name = "TopBar", Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
}, main)
corner(top, 12)
local topCover = make("Frame", {
    Position = UDim2.new(0, 0, 1, -12), Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
}, top)
local title = addText(top, "w.404  /  เมอร์เดอร์ มิสทรี 2", 14, COLORS.text, Enum.Font.GothamBold)
title.Position = UDim2.fromOffset(14, 0)
title.Size = UDim2.new(1, -100, 1, 0)
local version = addText(top, "ธีมสีเทา", 10, COLORS.muted, Enum.Font.GothamBold)
version.TextXAlignment = Enum.TextXAlignment.Right
version.Position = UDim2.new(1, -92, 0, 0)
version.Size = UDim2.fromOffset(42, 42)
local minimize = make("TextButton", {
    Text = "–", Size = UDim2.fromOffset(30, 28), Position = UDim2.new(1, -72, 0, 7),
    BackgroundColor3 = COLORS.panel2, TextColor3 = COLORS.text,
    TextSize = 20, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
}, top)
corner(minimize, 6)
local close = make("TextButton", {
    Text = "×", Size = UDim2.fromOffset(30, 28), Position = UDim2.new(1, -36, 0, 7),
    BackgroundColor3 = COLORS.panel2, TextColor3 = COLORS.text,
    TextSize = 19, Font = Enum.Font.GothamBold, BorderSizePixel = 0,
}, top)
corner(close, 6)

local sidebar = make("Frame", {
    Name = "Sidebar", Position = UDim2.fromOffset(0, 42),
    Size = UDim2.new(0, 142, 1, -42), BackgroundColor3 = COLORS.sidebar,
    BorderSizePixel = 0,
}, main)
local sideTitle = addText(sidebar, "เมนูหลัก", 11, COLORS.muted, Enum.Font.GothamBold)
sideTitle.Position = UDim2.fromOffset(13, 10)
sideTitle.Size = UDim2.new(1, -20, 0, 24)
local navHolder = make("Frame", {
    Position = UDim2.fromOffset(7, 40), Size = UDim2.new(1, -14, 1, -48),
    BackgroundTransparency = 1,
}, sidebar)
make("UIListLayout", {Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder}, navHolder)

local content = make("Frame", {
    Name = "Content", Position = UDim2.fromOffset(151, 51),
    Size = UDim2.new(1, -160, 1, -60), BackgroundTransparency = 1,
}, main)
local pageTitle = addText(content, "หน้าหลัก", 16, COLORS.text, Enum.Font.GothamBold)
pageTitle.Size = UDim2.new(1, -8, 0, 30)
pageTitle.Position = UDim2.fromOffset(4, 0)
local pageSubtitle = addText(content, "เลือกหมวดหมู่จากเมนูด้านซ้าย", 11, COLORS.muted)
pageSubtitle.Position = UDim2.fromOffset(4, 28)
pageSubtitle.Size = UDim2.new(1, -8, 0, 22)
local scroll = make("ScrollingFrame", {
    Name = "SettingsList", Position = UDim2.fromOffset(0, 56),
    Size = UDim2.new(1, 0, 1, -56), BackgroundTransparency = 1,
    BorderSizePixel = 0, ScrollBarThickness = 3,
    ScrollBarImageColor3 = COLORS.accent,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, content)
make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, scroll)
make("UIPadding", {PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 7)}, scroll)

local pages = {}
local function clearPage()
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    controls = {}
end

local function section(text)
    local wrap = make("Frame", {Size = UDim2.new(1, -4, 0, 28), BackgroundTransparency = 1}, scroll)
    local label = addText(wrap, text, 11, COLORS.muted, Enum.Font.GothamBold)
    label.Size = UDim2.new(1, 0, 1, 0)
    return wrap
end

local function settingRow(labelText, description)
    local row = make("Frame", {
        Size = UDim2.new(1, -4, 0, description and 58 or 48),
        BackgroundColor3 = COLORS.panel, BorderSizePixel = 0,
    }, scroll)
    corner(row, 8)
    local label = addText(row, labelText, 12, COLORS.text, Enum.Font.GothamSemibold)
    label.Position = UDim2.fromOffset(12, description and 6 or 0)
    label.Size = UDim2.new(1, -105, 0, description and 23 or 48)
    if description then
        local desc = addText(row, description, 10, COLORS.muted)
        desc.Position = UDim2.fromOffset(12, 29)
        desc.Size = UDim2.new(1, -110, 0, 20)
    end
    return row
end

local function toggle(labelText, key, description, callback)
    local row = settingRow(labelText, description)
    local switch = make("TextButton", {
        Size = UDim2.fromOffset(43, 23), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0), Text = "",
        BackgroundColor3 = state[key] and COLORS.accent or COLORS.panel2,
        BorderSizePixel = 0, AutoButtonColor = false,
    }, row)
    corner(switch, 20)
    local knob = make("Frame", {
        Size = UDim2.fromOffset(17, 17), Position = state[key] and UDim2.new(1, -20, 0.5, -8) or UDim2.fromOffset(3, 3),
        BackgroundColor3 = COLORS.text, BorderSizePixel = 0,
    }, switch)
    corner(knob, 20)
    local function set(value, fire)
        state[key] = value == true
        switch.BackgroundColor3 = state[key] and COLORS.accentOn or COLORS.panel2
        knob.Position = state[key] and UDim2.new(1, -20, 0.5, -8) or UDim2.fromOffset(3, 3)
        if fire and callback then callback(state[key]) end
    end
    controls[key] = set
    switch.MouseButton1Click:Connect(function() set(not state[key], true) end)
end

local function slider(labelText, key, minValue, maxValue, callback)
    local row = settingRow(labelText .. "  :  " .. tostring(state[key]))
    row.Size = UDim2.new(1, -4, 0, 66)
    local bar = make("Frame", {
        Position = UDim2.new(0, 12, 1, -20), Size = UDim2.new(1, -24, 0, 6),
        BackgroundColor3 = COLORS.panel2, BorderSizePixel = 0,
    }, row)
    corner(bar, 6)
    local fill = make("Frame", {
        Size = UDim2.new((state[key] - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = COLORS.accentOn, BorderSizePixel = 0,
    }, bar)
    corner(fill, 6)
    local dragging = false
    local function update(x)
        local ratio = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
        local value = math.floor((minValue + ratio * (maxValue - minValue)) / 5 + 0.5) * 5
        state[key] = math.clamp(value, minValue, maxValue)
        fill.Size = UDim2.new((state[key] - minValue) / (maxValue - minValue), 0, 1, 0)
        local lbl = row:FindFirstChild("ValueLabel")
        if lbl then lbl.Text = labelText .. "  :  " .. tostring(state[key]) end
        if callback then callback(state[key]) end
    end
    local valueLabel = row:FindFirstChildOfClass("TextLabel")
    if valueLabel then valueLabel.Name = "ValueLabel" end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(input.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input.Position.X) end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function buttonRow(labelText, buttonText, callback)
    local row = settingRow(labelText)
    local btn = make("TextButton", {
        Size = UDim2.fromOffset(82, 29), AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0), Text = buttonText,
        TextColor3 = COLORS.text, TextSize = 11, Font = Enum.Font.GothamBold,
        BackgroundColor3 = COLORS.panel2, BorderSizePixel = 0,
    }, row)
    corner(btn, 6)
    btn.MouseButton1Click:Connect(callback)
end

local function showPage(name)
    currentTab = name
    clearPage()
    local pageNames = {
        ["หน้าหลัก"] = "หน้าหลัก",
        ["ESP"] = "แสดงผู้เล่น",
        ["ต่อสู้"] = "ระบบช่วยเล็ง",
        ["FOV"] = "วงระยะ",
        ["ฟาร์ม"] = "เก็บเหรียญ",
        ["ตั้งค่า"] = "ตั้งค่า",
    }
    pageTitle.Text = pageNames[name] or name
    local subtitle = {
        ["หน้าหลัก"] = "w.404 | ศูนย์ควบคุมเกม",
        ["ESP"] = "แสดงผู้เล่นและข้อมูลตัวละคร",
        ["ต่อสู้"] = "ตั้งค่าระบบช่วยเล็งและล็อกเป้าหมาย",
        ["FOV"] = "ปรับขนาดวงระยะบนหน้าจอ",
        ["ฟาร์ม"] = "ตั้งค่าการเก็บเหรียญอัตโนมัติ",
        ["ตั้งค่า"] = "การแสดงผลและข้อมูลเมนู",
    }
    pageSubtitle.Text = subtitle[name] or "ตั้งค่าระบบ"

    if name == "หน้าหลัก" then
        section("ยินดีต้อนรับ")
        local row = settingRow("w.404 | ศูนย์ควบคุมเกม", "หน้าต่างสีเทา พร้อมเมนูหมวดหมู่ด้านซ้าย")
        section("ทางลัด")
        toggle("แสดงบทบาทผู้เล่น", "esp", "เน้นสีตัวละครเพื่อช่วยแยกผู้เล่น", function(v) state.esp = v end)
        toggle("ระบบช่วยเล็ง", "aimbot", "เปิดหรือปิดระบบช่วยเล็งเป้าหมาย", function(v) state.aimbot = v; if not v then state.lock = false end end)
        toggle("เก็บเหรียญอัตโนมัติ", "farm", "เปิดหรือปิดการเก็บเหรียญอัตโนมัติ", function(v) state.farm = v end)
    elseif name == "ESP" then
        section("แสดงข้อมูลผู้เล่น")
        toggle("เปิดระบบแสดงบทบาทผู้เล่น", "esp", "เน้นสีตัวละครตามอุปกรณ์ที่ตรวจพบ", function(v) state.esp = v end)
    elseif name == "ต่อสู้" then
        section("ระบบช่วยเล็ง")
        toggle("เปิดใช้งานระบบช่วยเล็ง", "aimbot", "ค้นหาผู้เล่นที่ถือมีดหรือปืน", function(v) state.aimbot = v; if not v then state.lock = false end end)
        toggle("ล็อกเป้าหมาย", "lock", "ให้กล้องติดตามเป้าหมายเมื่อเปิดระบบช่วยเล็ง", function(v) state.lock = v end)
        toggle("ตรวจสอบสิ่งกีดขวาง", "wallCheck", "เปิดไว้เพื่อเล็งเฉพาะเป้าหมายที่มองเห็น", function(v) state.wallCheck = v end)
    elseif name == "FOV" then
        section("ขอบเขตวงระยะ")
        toggle("แสดงวงระยะ", "fov", "แสดงวงระยะบริเวณกลางหน้าจอ", function(v) state.fov = v; fovCircle.Visible = v end)
        slider("ขนาดวงระยะ", "fovRadius", 50, 500, function(v) fovCircle.Size = UDim2.fromOffset(v * 2, v * 2) end)
        toggle("ใช้สีรุ้งกับวงระยะ", "fovRainbow", "ปิดเพื่อใช้สีเทาอ่อน", function(v) state.fovRainbow = v end)
    elseif name == "ฟาร์ม" then
        section("ระบบเก็บเหรียญ")
        toggle("เปิดเก็บเหรียญอัตโนมัติ", "farm", "เคลื่อนตัวละครไปยังเหรียญที่ตรวจพบในฉาก", function(v) state.farm = v end)
    elseif name == "ตั้งค่า" then
        section("การตั้งค่าหน้าต่าง")
        buttonRow("ซ่อนหน้าต่างหลัก", "ซ่อน", function() main.Visible = false end)
        buttonRow("ปิดเมนูทั้งหมด", "ปิดเมนู", function() gui:Destroy() end)
    end
end

local navItems = {
    {"หน้าหลัก", "⌂", "หน้าหลัก"},
    {"ESP", "◎", "แสดงผู้เล่น"},
    {"ต่อสู้", "✦", "ช่วยเล็ง"},
    {"FOV", "◉", "วงระยะ"},
    {"ฟาร์ม", "▣", "เก็บเหรียญ"},
    {"ตั้งค่า", "⚙", "ตั้งค่า"},
}
for index, item in ipairs(navItems) do
    local nav = make("TextButton", {
        Name = "Nav_" .. item[1], Size = UDim2.new(1, 0, 0, 37),
        BackgroundColor3 = COLORS.sidebar, BorderSizePixel = 0,
        Text = item[2] .. "   " .. item[3], TextColor3 = COLORS.muted,
        TextSize = 12, Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = index,
    }, navHolder)
    corner(nav, 7)
    make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, nav)
    nav.MouseButton1Click:Connect(function()
        for _, child in ipairs(navHolder:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = COLORS.sidebar
                child.TextColor3 = COLORS.muted
            end
        end
        nav.BackgroundColor3 = COLORS.panel2
        nav.TextColor3 = COLORS.text
        showPage(item[1])
    end)
end

-- Floating W launcher button.
local floating = make("Frame", {
    Name = "w404_FloatingUI", Size = UDim2.fromOffset(58, 58),
    Position = UDim2.new(0.84, 0, 0.42, 0), BackgroundColor3 = COLORS.panel,
    BorderSizePixel = 0, Active = true,
}, gui)
corner(floating, 14)
stroke(floating, COLORS.accentOn, 2)
local launcher = make("ImageButton", {
    Name = "WButton", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    Image = MINI_IMAGE, ScaleType = Enum.ScaleType.Crop, AutoButtonColor = false,
}, floating)
corner(launcher, 14)

local function toggleMain()
    main.Visible = not main.Visible
end
-- Launcher click is handled in the touch/mouse drag block below to avoid double toggles.
close.Activated:Connect(function() main.Visible = false end)
minimize.Activated:Connect(function() main.Visible = false end)

-- Drag main window by the title bar.
do
    local dragging, dragStart, startPosition = false, nil, nil
    top.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPosition = main.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

-- Drag floating W button; tap opens the menu.
do
    local dragging, moved, dragStart, startPos = false, false, nil, nil
    launcher.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; moved = false; dragStart = input.Position; startPos = floating.Position
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            if delta.Magnitude > 8 then moved = true end
            if moved then floating.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end
        end
    end)
    UIS.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if not moved then toggleMain() end
        end
    end)
end

-- Responsive sizing for mobile screens.
local function resizeUI()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local width = math.min(560, math.max(300, viewport.X - 28))
    local height = math.min(365, math.max(260, viewport.Y - 100))
    main.Size = UDim2.fromOffset(width, height)
    sidebar.Size = UDim2.new(0, math.clamp(math.floor(width * 0.255), 88, 142), 1, -42)
    content.Position = UDim2.fromOffset(sidebar.Size.X.Offset + 9, 51)
    content.Size = UDim2.new(1, -(sidebar.Size.X.Offset + 18), 1, -60)
end
resizeUI()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resizeUI) end

-- Shared helpers for game features.
local function findTool(player, toolName)
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    return (character and character:FindFirstChild(toolName)) or (backpack and backpack:FindFirstChild(toolName))
end
local function clearESP()
    for player, highlight in pairs(espHighlights) do
        if highlight then pcall(function() highlight:Destroy() end) end
        espHighlights[player] = nil
    end
end
local function canSee(targetPart)
    if not state.wallCheck then return true end
    local camera = workspace.CurrentCamera
    if not camera or not targetPart then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local excluded = {camera}
    if LocalPlayer.Character then table.insert(excluded, LocalPlayer.Character) end
    params.FilterDescendantsInstances = excluded
    local result = workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, params)
    return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

-- FOV ring positioning and color.
RunService.RenderStepped:Connect(function()
    if not state.fov then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local center = camera.ViewportSize / 2
    fovCircle.Position = UDim2.fromOffset(center.X, center.Y)
    if state.fovRainbow then
        fovStroke.Color = Color3.fromHSV((os.clock() % 5) / 5, 0.7, 0.95)
    else
        fovStroke.Color = COLORS.accentOn
    end
end)

-- Role ESP. Tool-name detection is heuristic and may differ from MM2 updates.
local lastESP = 0
RunService.RenderStepped:Connect(function()
    if not state.esp or os.clock() - lastESP < 0.2 then return end
    lastESP = os.clock()
    local active = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                active[player] = true
                local highlight = espHighlights[player]
                if not highlight or not highlight.Parent then
                    highlight = character:FindFirstChild("w404_Highlight") or Instance.new("Highlight")
                    highlight.Name = "w404_Highlight"; highlight.Adornee = character; highlight.Parent = character
                    espHighlights[player] = highlight
                end
                local hasKnife = findTool(player, "Knife") ~= nil
                local hasGun = findTool(player, "Gun") ~= nil or findTool(player, "Revolver") ~= nil
                if hasKnife then
                    highlight.FillColor = Color3.fromRGB(220, 105, 105); highlight.OutlineColor = COLORS.red
                elseif hasGun then
                    highlight.FillColor = Color3.fromRGB(110, 145, 190); highlight.OutlineColor = Color3.fromRGB(150, 180, 220)
                else
                    highlight.FillColor = Color3.fromRGB(145, 165, 145); highlight.OutlineColor = Color3.fromRGB(185, 205, 185)
                end
                highlight.FillTransparency = 0.4; highlight.OutlineTransparency = 0.1
            end
        end
    end
    for player, highlight in pairs(espHighlights) do
        if not active[player] then if highlight then highlight:Destroy() end; espHighlights[player] = nil end
    end
end)
Players.PlayerRemoving:Connect(function(player)
    if espHighlights[player] then espHighlights[player]:Destroy() end
    espHighlights[player] = nil
end)

-- Target selection; only activates when both toggles are on.
RunService.RenderStepped:Connect(function()
    if not (state.aimbot and state.lock) then return end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local center = camera.ViewportSize / 2
    local best, bestDistance = nil, state.fovRadius
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local hasKnife = findTool(player, "Knife") ~= nil
            local hasGun = findTool(player, "Gun") ~= nil or findTool(player, "Revolver") ~= nil
            if root and (not humanoid or humanoid.Health > 0) and (hasKnife or hasGun) then
                local point, visible = camera:WorldToViewportPoint(root.Position)
                if visible then
                    local distance = (Vector2.new(point.X, point.Y) - center).Magnitude
                    if distance < bestDistance and canSee(root) then bestDistance = distance; best = root end
                end
            end
        end
    end
    if best then camera.CFrame = camera.CFrame:Lerp(CFrame.new(camera.CFrame.Position, best.Position), 0.3) end
end)

-- Coin collection helper. The game may change the CoinContainer structure.
local function getCoinPart(coin)
    if coin:IsA("BasePart") then return coin end
    if coin:IsA("Model") and coin.PrimaryPart then return coin.PrimaryPart end
    return coin:FindFirstChildWhichIsA("BasePart", true)
end
task.spawn(function()
    while gui.Parent do
        task.wait(0.5)
        if state.farm then
            local ok, err = pcall(function()
                local character = LocalPlayer.Character
                local root = character and character:FindFirstChild("HumanoidRootPart")
                local container = workspace:FindFirstChild("CoinContainer", true)
                if not root or not container then return end
                for _, coin in ipairs(container:GetChildren()) do
                    if not state.farm or not gui.Parent then break end
                    local part = getCoinPart(coin)
                    if part then
                        root.CFrame = CFrame.new(part.Position + Vector3.new(0, 2, 0))
                        task.wait(0.15)
                    end
                end
            end)
            if not ok then warn("[w.404] Auto Farm error: " .. tostring(err)) end
        end
    end
end)

-- Start on the home page; the W avatar opens the main window.
showPage("หน้าหลัก")
for _, child in ipairs(navHolder:GetChildren()) do
    if child:IsA("TextButton") and child.Name == "Nav_หน้าหลัก" then
        child.BackgroundColor3 = COLORS.panel2; child.TextColor3 = COLORS.text
    end
end
print("[w.404] โหลดเมนูภาษาไทยธีมสีเทาเรียบร้อย")
