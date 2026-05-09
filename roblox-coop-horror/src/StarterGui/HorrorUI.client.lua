--[[
    HorrorUI.client.lua
    Все UI элементы — HUD, инвентарь, подсказки, лобби
    Расположение: StarterGui/HorrorUI.client.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local FearUpdated = Events:WaitForChild("FearUpdated")
local PlayerDamaged = Events:WaitForChild("PlayerDamaged")
local GameStateChanged = Events:WaitForChild("GameStateChanged")
local ShowHint = Events:WaitForChild("ShowHint")
local ItemPickedUp = Events:WaitForChild("ItemPickedUp")
local ItemUsed = Events:WaitForChild("ItemUsed")
local LobbyUpdate = Events:WaitForChild("LobbyUpdate")
local PlayerReady = Events:WaitForChild("PlayerReady")
local PuzzleInteraction = Events:WaitForChild("PuzzleInteraction")
local PuzzleCompleted = Events:WaitForChild("PuzzleCompleted")
local GameEnded = Events:WaitForChild("GameEnded")
local InteractionRequest = Events:WaitForChild("InteractionRequest")
local InventoryUpdate = Events:WaitForChild("InventoryUpdate")

---------------------------------------------------------------------
-- Основной ScreenGui
---------------------------------------------------------------------
local MainGui = Instance.new("ScreenGui")
MainGui.Name = "HorrorMainGui"
MainGui.ResetOnSpawn = false
MainGui.DisplayOrder = 10
MainGui.IgnoreGuiInset = true
MainGui.Parent = PlayerGui

---------------------------------------------------------------------
-- Виньетка (затемнение краёв экрана)
---------------------------------------------------------------------
local function createVignette()
    local vignetteFrame = Instance.new("ImageLabel")
    vignetteFrame.Name = "Vignette"
    vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
    vignetteFrame.BackgroundTransparency = 1
    vignetteFrame.Image = "rbxassetid://0" -- заменить на текстуру виньетки
    vignetteFrame.ImageColor3 = Color3.fromRGB(0, 0, 0)
    vignetteFrame.ImageTransparency = 0.7
    vignetteFrame.ZIndex = 5
    vignetteFrame.Parent = MainGui

    -- Если нет текстуры, используем градиент
    local gradient = Instance.new("UIGradient")
    gradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.3, 0.8),
        NumberSequenceKeypoint.new(0.7, 0.8),
        NumberSequenceKeypoint.new(1, 0),
    })
    gradient.Parent = vignetteFrame

    return vignetteFrame
end

local vignette = createVignette()

---------------------------------------------------------------------
-- HUD — Здоровье
---------------------------------------------------------------------
local function createHealthUI()
    local container = Instance.new("Frame")
    container.Name = "HealthContainer"
    container.Size = UDim2.new(0, 150, 0, 40)
    container.Position = UDim2.new(0, 20, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = MainGui

    local hearts = {}
    for i = 1, GameConfig.Player.MaxHealth do
        local heart = Instance.new("TextLabel")
        heart.Name = "Heart" .. i
        heart.Size = UDim2.new(0, 35, 0, 35)
        heart.Position = UDim2.new(0, (i - 1) * 40, 0, 0)
        heart.BackgroundTransparency = 1
        heart.Text = "❤️"
        heart.TextScaled = true
        heart.Font = Enum.Font.GothamBold
        heart.Parent = container
        hearts[i] = heart
    end

    return container, hearts
end

local healthContainer, hearts = createHealthUI()

---------------------------------------------------------------------
-- HUD — Шкала страха
---------------------------------------------------------------------
local function createFearBar()
    local container = Instance.new("Frame")
    container.Name = "FearBarContainer"
    container.Size = UDim2.new(0, 200, 0, 16)
    container.Position = UDim2.new(0, 20, 0, 95)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    container.BackgroundTransparency = 0.3
    container.BorderSizePixel = 0
    container.Parent = MainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = container

    local label = Instance.new("TextLabel")
    label.Name = "FearLabel"
    label.Size = UDim2.new(0, 50, 0, 16)
    label.Position = UDim2.new(0, -55, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = "СТРАХ"
    label.TextColor3 = Color3.fromRGB(200, 80, 80)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Right
    label.Parent = container

    local fill = Instance.new("Frame")
    fill.Name = "FearFill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = GameConfig.UI.FearBarColor
    fill.BorderSizePixel = 0
    fill.Parent = container

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    return container, fill
end

local fearBarContainer, fearFill = createFearBar()

---------------------------------------------------------------------
-- HUD — Батарея фонарика
---------------------------------------------------------------------
local function createBatteryUI()
    local container = Instance.new("Frame")
    container.Name = "BatteryContainer"
    container.Size = UDim2.new(0, 120, 0, 30)
    container.Position = UDim2.new(1, -140, 1, -60)
    container.BackgroundTransparency = 1
    container.Parent = MainGui

    local icon = Instance.new("TextLabel")
    icon.Name = "BatteryIcon"
    icon.Size = UDim2.new(0, 25, 0, 25)
    icon.Position = UDim2.new(0, 0, 0, 0)
    icon.BackgroundTransparency = 1
    icon.Text = "🔋"
    icon.TextScaled = true
    icon.Parent = container

    local barBg = Instance.new("Frame")
    barBg.Name = "BatteryBarBg"
    barBg.Size = UDim2.new(0, 80, 0, 12)
    barBg.Position = UDim2.new(0, 30, 0, 7)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    barBg.BackgroundTransparency = 0.3
    barBg.BorderSizePixel = 0
    barBg.Parent = container

    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(0, 3)
    barCorner.Parent = barBg

    local fill = Instance.new("Frame")
    fill.Name = "BatteryFill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = GameConfig.UI.BatteryColor
    fill.BorderSizePixel = 0
    fill.Parent = barBg

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill

    return container, fill
end

local batteryContainer, batteryFill = createBatteryUI()

---------------------------------------------------------------------
-- HUD — Стамина
---------------------------------------------------------------------
local function createStaminaBar()
    local container = Instance.new("Frame")
    container.Name = "StaminaContainer"
    container.Size = UDim2.new(0, 200, 0, 6)
    container.Position = UDim2.new(0, 20, 0, 115)
    container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    container.BackgroundTransparency = 0.5
    container.BorderSizePixel = 0
    container.Parent = MainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 3)
    corner.Parent = container

    local fill = Instance.new("Frame")
    fill.Name = "StaminaFill"
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
    fill.BorderSizePixel = 0
    fill.Parent = container

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 3)
    fillCorner.Parent = fill

    return container, fill
end

local staminaContainer, staminaFill = createStaminaBar()

---------------------------------------------------------------------
-- HUD — Инвентарь
---------------------------------------------------------------------
local function createInventoryUI()
    local container = Instance.new("Frame")
    container.Name = "InventoryContainer"
    container.Size = UDim2.new(0, 240, 0, 60)
    container.Position = UDim2.new(0.5, -120, 1, -80)
    container.BackgroundTransparency = 1
    container.Parent = MainGui

    local slots = {}
    for i = 1, GameConfig.Player.InventorySlots do
        local slot = Instance.new("Frame")
        slot.Name = "Slot" .. i
        slot.Size = UDim2.new(0, 50, 0, 50)
        slot.Position = UDim2.new(0, (i - 1) * 58, 0, 0)
        slot.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        slot.BackgroundTransparency = 0.4
        slot.BorderSizePixel = 1
        slot.BorderColor3 = Color3.fromRGB(80, 80, 80)
        slot.Parent = container

        local slotCorner = Instance.new("UICorner")
        slotCorner.CornerRadius = UDim.new(0, 6)
        slotCorner.Parent = slot

        local itemLabel = Instance.new("TextLabel")
        itemLabel.Name = "ItemLabel"
        itemLabel.Size = UDim2.new(1, 0, 1, 0)
        itemLabel.BackgroundTransparency = 1
        itemLabel.Text = ""
        itemLabel.TextScaled = true
        itemLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        itemLabel.Font = Enum.Font.GothamBold
        itemLabel.Parent = slot

        local numberLabel = Instance.new("TextLabel")
        numberLabel.Name = "NumberLabel"
        numberLabel.Size = UDim2.new(0, 15, 0, 15)
        numberLabel.Position = UDim2.new(0, 2, 0, 2)
        numberLabel.BackgroundTransparency = 1
        numberLabel.Text = tostring(i)
        numberLabel.TextSize = 10
        numberLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        numberLabel.Font = Enum.Font.Gotham
        numberLabel.Parent = slot

        -- Кнопка для использования предмета
        local button = Instance.new("TextButton")
        button.Name = "UseButton"
        button.Size = UDim2.new(1, 0, 1, 0)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = slot

        button.Activated:Connect(function()
            InteractionRequest:FireServer(SharedTypes.InteractionType.UseItem, {Slot = i})
        end)

        slots[i] = {Frame = slot, Label = itemLabel}
    end

    return container, slots
end

local inventoryContainer, inventorySlots = createInventoryUI()

---------------------------------------------------------------------
-- Подсказки (центр экрана)
---------------------------------------------------------------------
local function createHintUI()
    local label = Instance.new("TextLabel")
    label.Name = "HintLabel"
    label.Size = UDim2.new(0.6, 0, 0, 40)
    label.Position = UDim2.new(0.2, 0, 0.15, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0.5
    label.Text = ""
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextSize = 18
    label.Font = Enum.Font.Gotham
    label.TextTransparency = 1
    label.TextWrapped = true
    label.ZIndex = 20
    label.Parent = MainGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = label

    return label
end

local hintLabel = createHintUI()
local hintQueue = {}
local isShowingHint = false

local function showHint(message, duration)
    table.insert(hintQueue, {message = message, duration = duration or GameConfig.UI.HintDuration})

    if isShowingHint then return end
    isShowingHint = true

    task.spawn(function()
        while #hintQueue > 0 do
            local hint = table.remove(hintQueue, 1)
            hintLabel.Text = hint.message

            -- Fade in
            TweenService:Create(hintLabel, TweenInfo.new(0.3), {
                TextTransparency = 0,
                BackgroundTransparency = 0.5,
            }):Play()

            task.wait(hint.duration)

            -- Fade out
            TweenService:Create(hintLabel, TweenInfo.new(0.5), {
                TextTransparency = 1,
                BackgroundTransparency = 1,
            }):Play()

            task.wait(0.5)
        end
        isShowingHint = false
    end)
end

---------------------------------------------------------------------
-- Индикатор команды
---------------------------------------------------------------------
local function createTeamIndicator()
    local container = Instance.new("Frame")
    container.Name = "TeamIndicator"
    container.Size = UDim2.new(0, 200, 0, 100)
    container.Position = UDim2.new(1, -220, 0, 50)
    container.BackgroundTransparency = 1
    container.Parent = MainGui

    return container
end

local teamContainer = createTeamIndicator()

local function updateTeamIndicator()
    -- Очистить
    for _, child in ipairs(teamContainer:GetChildren()) do
        child:Destroy()
    end

    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local myPos = character.HumanoidRootPart.Position

    local index = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local label = Instance.new("TextLabel")
            label.Name = player.Name
            label.Size = UDim2.new(1, 0, 0, 20)
            label.Position = UDim2.new(0, 0, 0, index * 22)
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.Gotham
            label.TextSize = 13
            label.TextXAlignment = Enum.TextXAlignment.Right

            local pChar = player.Character
            if pChar and pChar:FindFirstChild("HumanoidRootPart") then
                local dist = math.floor((myPos - pChar.HumanoidRootPart.Position).Magnitude)
                label.Text = player.DisplayName .. " — " .. dist .. "m"
                label.TextColor3 = dist < 30 and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(200, 200, 200)
            else
                label.Text = player.DisplayName .. " — ???"
                label.TextColor3 = Color3.fromRGB(150, 50, 50)
            end

            label.Parent = teamContainer
            index = index + 1
        end
    end
end

---------------------------------------------------------------------
-- Лобби UI
---------------------------------------------------------------------
local function createLobbyUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "LobbyGui"
    gui.DisplayOrder = 15
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local bgFrame = Instance.new("Frame")
    bgFrame.Name = "LobbyBg"
    bgFrame.Size = UDim2.new(0, 400, 0, 350)
    bgFrame.Position = UDim2.new(0.5, -200, 0.5, -175)
    bgFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    bgFrame.BackgroundTransparency = 0.1
    bgFrame.BorderSizePixel = 0
    bgFrame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = bgFrame

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "DEAD SILENCE"
    title.TextColor3 = Color3.fromRGB(200, 50, 50)
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.Parent = bgFrame

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "Subtitle"
    subtitle.Size = UDim2.new(1, 0, 0, 25)
    subtitle.Position = UDim2.new(0, 0, 0, 45)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Кооперативный хоррор"
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 160)
    subtitle.TextSize = 14
    subtitle.Font = Enum.Font.Gotham
    subtitle.Parent = bgFrame

    -- Список игроков
    local playerList = Instance.new("Frame")
    playerList.Name = "PlayerList"
    playerList.Size = UDim2.new(0.9, 0, 0, 150)
    playerList.Position = UDim2.new(0.05, 0, 0, 80)
    playerList.BackgroundTransparency = 1
    playerList.Parent = bgFrame

    -- Статус
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "Status"
    statusLabel.Size = UDim2.new(1, 0, 0, 25)
    statusLabel.Position = UDim2.new(0, 0, 0, 240)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ожидание игроков..."
    statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    statusLabel.TextSize = 14
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = bgFrame

    -- Кнопка "Готов"
    local readyButton = Instance.new("TextButton")
    readyButton.Name = "ReadyButton"
    readyButton.Size = UDim2.new(0.6, 0, 0, 45)
    readyButton.Position = UDim2.new(0.2, 0, 0, 280)
    readyButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
    readyButton.Text = "ГОТОВ"
    readyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    readyButton.TextSize = 18
    readyButton.Font = Enum.Font.GothamBold
    readyButton.Parent = bgFrame

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = readyButton

    local isReady = false
    readyButton.Activated:Connect(function()
        isReady = not isReady
        PlayerReady:FireServer(isReady)

        if isReady then
            readyButton.Text = "НЕ ГОТОВ"
            readyButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
        else
            readyButton.Text = "ГОТОВ"
            readyButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
        end
    end)

    return gui, playerList, statusLabel
end

local lobbyGui, lobbyPlayerList, lobbyStatus = createLobbyUI()

---------------------------------------------------------------------
-- Экран конца игры
---------------------------------------------------------------------
local function showEndScreen(result, message)
    local gui = Instance.new("ScreenGui")
    gui.Name = "EndScreenGui"
    gui.DisplayOrder = 50
    gui.IgnoreGuiInset = true
    gui.Parent = PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.3
    bg.Parent = gui

    local resultLabel = Instance.new("TextLabel")
    resultLabel.Size = UDim2.new(0.8, 0, 0, 60)
    resultLabel.Position = UDim2.new(0.1, 0, 0.3, 0)
    resultLabel.BackgroundTransparency = 1
    resultLabel.TextSize = 36
    resultLabel.Font = Enum.Font.GothamBold
    resultLabel.TextWrapped = true
    resultLabel.Parent = bg

    if result == SharedTypes.GameResult.Escaped then
        resultLabel.Text = "ВЫ СБЕЖАЛИ!"
        resultLabel.TextColor3 = Color3.fromRGB(50, 200, 50)
    elseif result == SharedTypes.GameResult.AllDead then
        resultLabel.Text = "ВСЕ ПОГИБЛИ"
        resultLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
    else
        resultLabel.Text = "ВРЕМЯ ВЫШЛО"
        resultLabel.TextColor3 = Color3.fromRGB(200, 150, 50)
    end

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(0.8, 0, 0, 40)
    msgLabel.Position = UDim2.new(0.1, 0, 0.4, 0)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message or ""
    msgLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    msgLabel.TextSize = 18
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextWrapped = true
    msgLabel.Parent = bg

    -- Убрать через 15 секунд
    task.delay(15, function()
        gui:Destroy()
    end)
end

---------------------------------------------------------------------
-- Головоломка: UI ввода кода сейфа
---------------------------------------------------------------------
local function showSafeCodeUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SafeCodeGui"
    gui.DisplayOrder = 30
    gui.Parent = PlayerGui

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 300, 0, 250)
    bg.Position = UDim2.new(0.5, -150, 0.5, -125)
    bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    bg.BorderSizePixel = 0
    bg.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = bg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundTransparency = 1
    title.Text = "ВВЕДИТЕ КОД"
    title.TextColor3 = Color3.fromRGB(200, 200, 200)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = bg

    -- Поле ввода (4 цифры)
    local codeDisplay = Instance.new("TextLabel")
    codeDisplay.Size = UDim2.new(0.8, 0, 0, 40)
    codeDisplay.Position = UDim2.new(0.1, 0, 0, 35)
    codeDisplay.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    codeDisplay.Text = "____"
    codeDisplay.TextColor3 = Color3.fromRGB(100, 255, 100)
    codeDisplay.TextSize = 28
    codeDisplay.Font = Enum.Font.Code
    codeDisplay.Parent = bg

    local codeCorner = Instance.new("UICorner")
    codeCorner.CornerRadius = UDim.new(0, 5)
    codeCorner.Parent = codeDisplay

    local currentCode = ""

    -- Кнопки цифр
    for row = 0, 2 do
        for col = 0, 2 do
            local num = row * 3 + col + 1
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 55, 0, 40)
            btn.Position = UDim2.new(0, 40 + col * 65, 0, 85 + row * 45)
            btn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            btn.Text = tostring(num)
            btn.TextColor3 = Color3.fromRGB(200, 200, 200)
            btn.TextSize = 20
            btn.Font = Enum.Font.GothamBold
            btn.Parent = bg

            local btnCorner = Instance.new("UICorner")
            btnCorner.CornerRadius = UDim.new(0, 6)
            btnCorner.Parent = btn

            btn.Activated:Connect(function()
                if #currentCode < GameConfig.Puzzles.SafeCodeLength then
                    currentCode = currentCode .. tostring(num)
                    local display = currentCode .. string.rep("_", GameConfig.Puzzles.SafeCodeLength - #currentCode)
                    codeDisplay.Text = display
                end
            end)
        end
    end

    -- Кнопка 0
    local zeroBtn = Instance.new("TextButton")
    zeroBtn.Size = UDim2.new(0, 55, 0, 40)
    zeroBtn.Position = UDim2.new(0, 105, 0, 85 + 3 * 45)
    zeroBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    zeroBtn.Text = "0"
    zeroBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    zeroBtn.TextSize = 20
    zeroBtn.Font = Enum.Font.GothamBold
    zeroBtn.Parent = bg

    local zeroCorner = Instance.new("UICorner")
    zeroCorner.CornerRadius = UDim.new(0, 6)
    zeroCorner.Parent = zeroBtn

    zeroBtn.Activated:Connect(function()
        if #currentCode < GameConfig.Puzzles.SafeCodeLength then
            currentCode = currentCode .. "0"
            local display = currentCode .. string.rep("_", GameConfig.Puzzles.SafeCodeLength - #currentCode)
            codeDisplay.Text = display
        end
    end)

    -- Кнопка подтверждения
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0, 120, 0, 35)
    confirmBtn.Position = UDim2.new(0.5, -60, 1, -45)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
    confirmBtn.Text = "ВВЕСТИ"
    confirmBtn.TextColor3 = Color3.new(1, 1, 1)
    confirmBtn.TextSize = 16
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.Parent = bg

    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, 6)
    confirmCorner.Parent = confirmBtn

    confirmBtn.Activated:Connect(function()
        if #currentCode == GameConfig.Puzzles.SafeCodeLength then
            PuzzleInteraction:FireServer(SharedTypes.PuzzleType.SafeCode, "EnterCode", {Code = currentCode})
            gui:Destroy()
        end
    end)

    -- Кнопка закрытия
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(200, 100, 100)
    closeBtn.TextSize = 20
    closeBtn.Parent = bg

    closeBtn.Activated:Connect(function()
        gui:Destroy()
    end)
end

---------------------------------------------------------------------
-- Обработка событий
---------------------------------------------------------------------
FearUpdated.OnClientEvent:Connect(function(fearLevel)
    -- Обновить шкалу страха
    local normalized = fearLevel / GameConfig.Fear.MaxFear
    TweenService:Create(fearFill, TweenInfo.new(0.3), {
        Size = UDim2.new(normalized, 0, 1, 0),
    }):Play()

    -- Менять цвет по уровню
    if fearLevel >= GameConfig.Fear.PanicThreshold then
        fearFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    elseif fearLevel >= 50 then
        fearFill.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
    else
        fearFill.BackgroundColor3 = GameConfig.UI.FearBarColor
    end

    -- Обновить виньетку
    vignette.ImageTransparency = 1 - (normalized * 0.5)
end)

PlayerDamaged.OnClientEvent:Connect(function(player, health)
    if player == LocalPlayer then
        for i = 1, GameConfig.Player.MaxHealth do
            if i <= health then
                hearts[i].Text = "❤️"
            else
                hearts[i].Text = "🖤"
            end
        end

        -- Анимация тряски сердца
        if health > 0 and health <= GameConfig.Player.MaxHealth then
            local heart = hearts[health + 1]
            if heart then
                local tween = TweenService:Create(heart, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {
                    Size = UDim2.new(0, 45, 0, 45)
                })
                tween:Play()
                task.delay(0.2, function()
                    TweenService:Create(heart, TweenInfo.new(0.2), {
                        Size = UDim2.new(0, 35, 0, 35)
                    }):Play()
                end)
            end
        end
    end
end)

GameStateChanged.OnClientEvent:Connect(function(state)
    if state == SharedTypes.GameState.Lobby then
        lobbyGui.Enabled = true
        MainGui.Enabled = false
    elseif state == SharedTypes.GameState.Playing then
        lobbyGui.Enabled = false
        MainGui.Enabled = true
    elseif state == SharedTypes.GameState.Ending then
        -- UI обрабатывается через GameEnded
    end
end)

ShowHint.OnClientEvent:Connect(function(message, duration)
    showHint(message, duration)
end)

ItemPickedUp.OnClientEvent:Connect(function(player, itemType, slot)
    if player == LocalPlayer and slot then
        -- Обновить слот инвентаря
        local itemConfig = GameConfig.Items[itemType]
        if itemConfig and inventorySlots[slot] then
            inventorySlots[slot].Label.Text = itemConfig.Name
        end
    end
end)

ItemUsed.OnClientEvent:Connect(function(player, itemType)
    if player == LocalPlayer then
        -- Обновить инвентарь (очистить слот)
        for _, slotData in pairs(inventorySlots) do
            if slotData.Label.Text == (GameConfig.Items[itemType] and GameConfig.Items[itemType].Name or "") then
                slotData.Label.Text = ""
                break
            end
        end
    end
end)

LobbyUpdate.OnClientEvent:Connect(function(data)
    -- Обновить список игроков в лобби
    for _, child in ipairs(lobbyPlayerList:GetChildren()) do
        child:Destroy()
    end

    for i, playerInfo in ipairs(data.Players) do
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 25)
        label.Position = UDim2.new(0, 0, 0, (i - 1) * 28)
        label.BackgroundTransparency = 1
        label.TextSize = 14
        label.Font = Enum.Font.Gotham

        if playerInfo.IsReady then
            label.Text = "✓ " .. playerInfo.DisplayName
            label.TextColor3 = Color3.fromRGB(100, 255, 100)
        else
            label.Text = "○ " .. playerInfo.DisplayName
            label.TextColor3 = Color3.fromRGB(200, 200, 200)
        end

        label.Parent = lobbyPlayerList
    end

    -- Обновить статус
    if data.CountdownActive then
        lobbyStatus.Text = "Начало через " .. data.CountdownTime .. " секунд!"
        lobbyStatus.TextColor3 = Color3.fromRGB(255, 200, 50)
    else
        lobbyStatus.Text = "Игроки: " .. data.TotalPlayers .. "/" .. data.MaxPlayers ..
            " | Готовы: " .. data.ReadyCount .. "/" .. data.TotalPlayers
    end
end)

GameEnded.OnClientEvent:Connect(function(result, message)
    showEndScreen(result, message)
end)

PuzzleCompleted.OnClientEvent:Connect(function(puzzleType)
    showHint("Головоломка решена: " .. puzzleType, 5)
end)

---------------------------------------------------------------------
-- Обновление UI каждый кадр
---------------------------------------------------------------------
local teamUpdateTimer = 0

RunService.RenderStepped:Connect(function(deltaTime)
    -- Обновить батарею фонарика
    local flashlightAPI = LocalPlayer:FindFirstChild("FlashlightAPI")
    if flashlightAPI then
        local battery = flashlightAPI:Invoke("GetBattery")
        if battery then
            local normalized = battery / GameConfig.Flashlight.MaxBattery
            batteryFill.Size = UDim2.new(normalized, 0, 1, 0)

            if normalized < 0.2 then
                batteryFill.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
            elseif normalized < 0.5 then
                batteryFill.BackgroundColor3 = Color3.fromRGB(255, 150, 50)
            else
                batteryFill.BackgroundColor3 = GameConfig.UI.BatteryColor
            end
        end
    end

    -- Обновить стамину
    local clientStateAPI = LocalPlayer:FindFirstChild("ClientStateAPI")
    if clientStateAPI then
        local stamina = clientStateAPI:Invoke("GetStamina")
        if stamina then
            local normalized = stamina / GameConfig.Player.MaxStamina
            staminaFill.Size = UDim2.new(normalized, 0, 1, 0)
        end
    end

    -- Обновить индикатор команды (каждые 0.5 сек)
    teamUpdateTimer = teamUpdateTimer + deltaTime
    if teamUpdateTimer >= 0.5 then
        teamUpdateTimer = 0
        updateTeamIndicator()
    end
end)

---------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------
MainGui.Enabled = false -- скрыть до начала игры
lobbyGui.Enabled = true

print("[HorrorUI] Интерфейс инициализирован.")
