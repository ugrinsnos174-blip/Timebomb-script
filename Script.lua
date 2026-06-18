-- ============================================
-- 💣 TIME BOMB ULTIMATE v15 💣
-- ИСПРАВЛЕНА ПРОБЛЕМА С ЛИСТАНИЕМ
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- ========== НАСТРОЙКИ (ВСЁ ВЫКЛЮЧЕНО) ==========
local Settings = {
    TeleportRadius = 50,
    ESP = false,
    ShowLine = false,
    CustomTrackId = "",
}

local targetLine = nil
local followConn = nil
local isFollowing = false
local targetPlayer = nil
local originalCFrame = nil
local followTimer = 0
local espObjects = {}
local customSound = nil

-- ========== ЛИНИЯ ==========
local function UpdateLine()
    if targetLine then
        pcall(function() targetLine:Destroy() end)
        targetLine = nil
    end
    if not Settings.ShowLine then return end
    
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local nearest = nil
    local bestDist = Settings.TeleportRadius
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local d = (hrp.Position - char.HumanoidRootPart.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    nearest = plr
                end
            end
        end
    end
    if not nearest then return end
    
    local char = nearest.Character
    if not char then return end
    local targetPos = char:FindFirstChild("HumanoidRootPart")
    if not targetPos then return end
    
    local from = hrp.Position
    local to = targetPos.Position
    local dist = (to - from).Magnitude
    if dist < 60 then
        local part = Instance.new("Part")
        part.Name = "Line"
        part.Material = Enum.Material.Neon
        part.BrickColor = BrickColor.new("Bright red")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 0.1
        part.Size = Vector3.new(0.3, 0.3, dist)
        part.CFrame = CFrame.lookAt(from, to) * CFrame.new(0, 0, -dist/2)
        part.Parent = Workspace
        local glow = Instance.new("PointLight")
        glow.Color = Color3.fromRGB(255, 0, 0)
        glow.Range = 10
        glow.Brightness = 4
        glow.Parent = part
        targetLine = part
    end
end

RunService.RenderStepped:Connect(UpdateLine)

-- ========== ESP ==========
local function UpdateESP()
    if not Settings.ESP then
        for _, v in pairs(espObjects) do
            pcall(function() v:Destroy() end)
        end
        espObjects = {}
        return
    end
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                if not espObjects[plr] then
                    local box = Instance.new("BoxHandleAdornment")
                    box.Size = Vector3.new(4, 6, 2.5)
                    box.Adornee = hrp
                    box.AlwaysOnTop = true
                    box.ZIndex = 10
                    box.Color3 = Color3.fromRGB(255, 0, 0)
                    box.Transparency = 0.3
                    box.Parent = hrp
                    
                    local glow = Instance.new("BoxHandleAdornment")
                    glow.Size = Vector3.new(4.5, 6.5, 3)
                    glow.Adornee = hrp
                    glow.AlwaysOnTop = true
                    glow.ZIndex = 9
                    glow.Color3 = Color3.fromRGB(255, 50, 50)
                    glow.Transparency = 0.6
                    glow.Parent = hrp
                    
                    espObjects[plr] = {box, glow}
                end
            elseif espObjects[plr] then
                for _, v in ipairs(espObjects[plr]) do
                    pcall(function() v:Destroy() end)
                end
                espObjects[plr] = nil
            end
        end
    end
end

RunService.RenderStepped:Connect(UpdateESP)

-- ========== БЛИЖАЙШИЙ ==========
local function GetNearest()
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local nearest = nil
    local best = Settings.TeleportRadius
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local d = (hrp.Position - char.HumanoidRootPart.Position).Magnitude
                if d < best then
                    best = d
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

-- ========== ТЕЛЕПОРТ ==========
local function Teleport()
    if isFollowing then return end
    local target = GetNearest()
    if not target then return end
    
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local tHrp = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not hrp or not tHrp then return end
    
    originalCFrame = hrp.CFrame
    targetPlayer = target
    isFollowing = true
    followTimer = 0
    
    hrp.CFrame = tHrp.CFrame + Vector3.new(0, 2, 0)
    
    if followConn then followConn:Disconnect() end
    followConn = RunService.Heartbeat:Connect(function()
        if not isFollowing then return end
        followTimer = followTimer + 0.05
        
        if followTimer >= 2 or not targetPlayer or not targetPlayer.Character then
            if hrp and originalCFrame then
                hrp.CFrame = originalCFrame
            end
            isFollowing = false
            if followConn then
                followConn:Disconnect()
                followConn = nil
            end
            return
        end
        
        local newT = targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart")
        if newT and hrp then
            hrp.CFrame = newT.CFrame + Vector3.new(0, 2, 0)
        end
    end)
end

-- ========== ТРЕК ==========
local function PlayTrack(id)
    if customSound then
        customSound:Stop()
        customSound:Destroy()
        customSound = nil
    end
    if id == "" then return end
    customSound = Instance.new("Sound")
    customSound.SoundId = id
    customSound.Volume = 5
    customSound.Looped = true
    customSound.Parent = LP.Character or workspace
    customSound:Play()
end

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

-- ТЕЛЕПОРТ
local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(0, 65, 0, 65)
tpBtn.Position = UDim2.new(1, -75, 0.5, 0)
tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
tpBtn.Text = "🌀"
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.TextSize = 32
tpBtn.Font = Enum.Font.GothamBold
tpBtn.Parent = screenGui

local tpCorner = Instance.new("UICorner")
tpCorner.CornerRadius = UDim.new(1, 0)
tpCorner.Parent = tpBtn

tpBtn.MouseButton1Click:Connect(Teleport)

-- МЕНЮ
local menuBtn = Instance.new("TextButton")
menuBtn.Size = UDim2.new(0, 70, 0, 40)
menuBtn.Position = UDim2.new(1, -80, 0, 10)
menuBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
menuBtn.Text = "⚡ MENU"
menuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
menuBtn.TextSize = 14
menuBtn.Font = Enum.Font.GothamBold
menuBtn.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 10)
menuCorner.Parent = menuBtn

-- ОКНО МЕНЮ
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 350)
mainFrame.Position = UDim2.new(0.5, -140, 0.1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 14)
mainCorner.Parent = mainFrame

-- ЗАГОЛОВОК
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
titleBar.Parent = mainFrame
local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 14)
titleCorner.Parent = titleBar

local titleText = Instance.new("TextLabel")
titleText.Size = UDim2.new(1, -60, 1, 0)
titleText.Position = UDim2.new(0, 12, 0, 0)
titleText.BackgroundTransparency = 1
titleText.Text = "💣 TIME BOMB v15"
titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.Font = Enum.Font.GothamBold
titleText.TextSize = 14
titleText.Parent = titleBar

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0, 2.5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = titleBar
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

-- КОНТЕНТ
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -12, 1, -55)
scroll.Position = UDim2.new(0, 6, 0, 50)
scroll.BackgroundColor3 = Color3.fromRGB(15, 12, 35)
scroll.BackgroundTransparency = 0.4
scroll.Parent = mainFrame

-- БЛОКИРУЕМ ПРУЖИНИСТОСТЬ: устанавливаем CanvasSize и включаем скролл
scroll.ScrollBarThickness = 4
scroll.ScrollingEnabled = true
scroll.CanvasSize = UDim2.new(0, 0, 0, 0) -- будет обновлено ниже

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 5)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scroll

-- Функция обновления CanvasSize (чтобы скролл работал)
local function UpdateCanvas()
    task.wait(0.1)
    local totalHeight = 0
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("Frame") or child:IsA("TextLabel") then
            totalHeight = totalHeight + child.Size.Y.Offset + 6
        end
    end
    scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 30)
end

local function AddSection(t)
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, 0, 0, 24)
    s.BackgroundColor3 = Color3.fromRGB(40, 30, 75)
    s.Text = "  ✦ " .. t
    s.TextColor3 = Color3.fromRGB(220, 170, 255)
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Font = Enum.Font.GothamBold
    s.TextSize = 11
    s.Parent = scroll
end

local function AddToggle(name, flag)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 35)
    f.BackgroundColor3 = Color3.fromRGB(25, 22, 50)
    f.BackgroundTransparency = 0.3
    f.Parent = scroll
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.55, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = Color3.fromRGB(230, 230, 250)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 11
    l.Parent = f
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 55, 0, 26)
    btn.Position = UDim2.new(1, -65, 0.5, -13)
    btn.BackgroundColor3 = Settings[flag] and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(220, 50, 70)
    btn.Text = Settings[flag] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = f
    
    btn.MouseButton1Click:Connect(function()
        Settings[flag] = not Settings[flag]
        btn.BackgroundColor3 = Settings[flag] and Color3.fromRGB(0, 220, 100) or Color3.fromRGB(220, 50, 70)
        btn.Text = Settings[flag] and "ON" or "OFF"
    end)
end

local function AddSlider(name, flag, minV, maxV, suffix)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 50)
    f.BackgroundColor3 = Color3.fromRGB(25, 22, 50)
    f.BackgroundTransparency = 0.3
    f.Parent = scroll
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 18)
    l.Position = UDim2.new(0, 6, 0, 2)
    l.BackgroundTransparency = 1
    l.Text = name .. ": " .. tostring(Settings[flag]) .. " " .. suffix
    l.TextColor3 = Color3.fromRGB(200, 200, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.Parent = f
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.4, 0, 0, 24)
    box.Position = UDim2.new(0.55, 0, 0.55, -12)
    box.BackgroundColor3 = Color3.fromRGB(50, 45, 80)
    box.Text = tostring(Settings[flag])
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.Parent = f
    
    box.FocusLost:Connect(function()
        local val = tonumber(box.Text)
        if val then
            val = math.clamp(val, minV, maxV)
            Settings[flag] = val
            l.Text = name .. ": " .. val .. " " .. suffix
            box.Text = tostring(val)
        else
            box.Text = tostring(Settings[flag])
        end
    end)
end

local function AddTrack()
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 55)
    f.BackgroundColor3 = Color3.fromRGB(25, 22, 50)
    f.BackgroundTransparency = 0.3
    f.Parent = scroll
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 0, 18)
    l.Position = UDim2.new(0, 6, 0, 2)
    l.BackgroundTransparency = 1
    l.Text = "🎵 ID трека:"
    l.TextColor3 = Color3.fromRGB(200, 200, 220)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Font = Enum.Font.Gotham
    l.TextSize = 10
    l.Parent = f
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.8, 0, 0, 28)
    box.Position = UDim2.new(0.1, 0, 0.55, -14)
    box.BackgroundColor3 = Color3.fromRGB(50, 45, 80)
    box.Text = Settings.CustomTrackId
    box.PlaceholderText = "rbxassetid://123"
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.Parent = f
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 28)
    btn.Position = UDim2.new(0.92, 0, 0.55, -14)
    btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    btn.Text = "▶"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 14
    btn.Font = Enum.Font.GothamBold
    btn.Parent = f
    
    btn.MouseButton1Click:Connect(function()
        local id = box.Text
        if id ~= "" then
            Settings.CustomTrackId = id
            PlayTrack(id)
        end
    end)
end

-- ПОСТРОЕНИЕ МЕНЮ
AddSection("🌀 ТЕЛЕПОРТ")
AddToggle("Показать линию", "ShowLine")
AddSlider("Радиус", "TeleportRadius", 20, 100, "ст")

AddSection("👁️ ESP")
AddToggle("Красные рамки", "ESP")

AddSection("🎵 СВОЙ ТРЕК")
AddTrack()

-- ОБНОВЛЯЕМ CANVAS ПОСЛЕ ПОСТРОЕНИЯ
task.wait(0.1)
local totalHeight = 0
for _, child in ipairs(scroll:GetChildren()) do
    if child:IsA("Frame") or child:IsA("TextLabel") then
        totalHeight = totalHeight + child.Size.Y.Offset + 6
    end
end
scroll.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 40)

-- УПРАВЛЕНИЕ МЕНЮ
local menuOpen = false
menuBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    mainFrame.Visible = menuOpen
    menuBtn.Visible = not menuOpen
end)

closeBtn.MouseButton1Click:Connect(function()
    menuOpen = false
    mainFrame.Visible = false
    menuBtn.Visible = true
end)

UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode == Enum.KeyCode.P then
        menuOpen = not menuOpen
        mainFrame.Visible = menuOpen
        menuBtn.Visible = not menuOpen
    end
end)

print("========================================")
print("💣 TIME BOMB v15 ЗАГРУЖЕН")
print("✅ ИСПРАВЛЕНО ЛИСТАНИЕ")
print("✅ КРАСНЫЕ РАМКИ | ТЕЛЕПОРТ | ЛИНИЯ | ТРЕК")
print("========================================")
