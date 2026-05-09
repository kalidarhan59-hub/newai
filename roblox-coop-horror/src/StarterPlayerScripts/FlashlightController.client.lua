--[[
    FlashlightController.client.lua
    Управление фонариком — включение/выключение, батарея, вспышка
    Расположение: StarterPlayerScripts/FlashlightController.client.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local LocalPlayer = Players.LocalPlayer

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local NoiseGenerated = Events:WaitForChild("NoiseGenerated")

---------------------------------------------------------------------
-- Состояние фонарика
---------------------------------------------------------------------
local Flashlight = {
    IsOn = false,
    Battery = GameConfig.Flashlight.MaxBattery,
    LastFlashTime = 0,
    SpotLight = nil,
    Attachment = nil,
}

---------------------------------------------------------------------
-- Создание фонарика
---------------------------------------------------------------------
local function createFlashlight()
    local character = LocalPlayer.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    -- Удалить старый фонарик если есть
    local existing = head:FindFirstChild("FlashlightAttachment")
    if existing then existing:Destroy() end

    -- Attachment на голове
    Flashlight.Attachment = Instance.new("Attachment")
    Flashlight.Attachment.Name = "FlashlightAttachment"
    Flashlight.Attachment.Position = Vector3.new(0, 0.5, -0.5)
    Flashlight.Attachment.Parent = head

    -- SpotLight
    Flashlight.SpotLight = Instance.new("SpotLight")
    Flashlight.SpotLight.Name = "Flashlight"
    Flashlight.SpotLight.Angle = GameConfig.Flashlight.Angle
    Flashlight.SpotLight.Range = GameConfig.Flashlight.Range
    Flashlight.SpotLight.Brightness = 2
    Flashlight.SpotLight.Color = Color3.fromRGB(255, 245, 220) -- тёплый свет
    Flashlight.SpotLight.Enabled = false
    Flashlight.SpotLight.Face = Enum.NormalId.Front
    Flashlight.SpotLight.Parent = Flashlight.Attachment

    -- Добавить слабый свечение вокруг
    local pointLight = Instance.new("PointLight")
    pointLight.Name = "FlashlightGlow"
    pointLight.Range = 8
    pointLight.Brightness = 0.3
    pointLight.Color = Color3.fromRGB(255, 245, 220)
    pointLight.Enabled = false
    pointLight.Parent = Flashlight.Attachment

    Flashlight.PointLight = pointLight
end

---------------------------------------------------------------------
-- Переключение фонарика
---------------------------------------------------------------------
local function toggleFlashlight()
    if Flashlight.Battery <= 0 then
        -- Нет батареи
        return
    end

    Flashlight.IsOn = not Flashlight.IsOn

    if Flashlight.SpotLight then
        Flashlight.SpotLight.Enabled = Flashlight.IsOn
    end
    if Flashlight.PointLight then
        Flashlight.PointLight.Enabled = Flashlight.IsOn
    end

    -- Уведомить сервер о состоянии фонарика
    local interactionEvent = Events:FindFirstChild("InteractionRequest")
    if interactionEvent then
        interactionEvent:FireServer("FlashlightToggle", {IsOn = Flashlight.IsOn})
    end
end

---------------------------------------------------------------------
-- Вспышка фонарика
---------------------------------------------------------------------
local function flashFlashlight()
    if Flashlight.Battery <= GameConfig.Flashlight.FlashDrainAmount then return end

    local now = os.clock()
    if now - Flashlight.LastFlashTime < GameConfig.Flashlight.FlashCooldown then return end

    Flashlight.LastFlashTime = now
    Flashlight.Battery = Flashlight.Battery - GameConfig.Flashlight.FlashDrainAmount

    -- Яркая вспышка
    if Flashlight.SpotLight then
        local originalBrightness = Flashlight.SpotLight.Brightness
        local originalRange = Flashlight.SpotLight.Range

        Flashlight.SpotLight.Enabled = true
        Flashlight.SpotLight.Brightness = 8
        Flashlight.SpotLight.Range = GameConfig.Flashlight.Range * 1.5

        -- Вернуть к нормальному
        task.delay(0.15, function()
            if Flashlight.SpotLight then
                Flashlight.SpotLight.Brightness = originalBrightness
                Flashlight.SpotLight.Range = originalRange
                Flashlight.SpotLight.Enabled = Flashlight.IsOn
            end
        end)
    end

    -- Генерация шума от вспышки
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("HumanoidRootPart") then
        NoiseGenerated:FireServer(character.HumanoidRootPart.Position, GameConfig.NoiseLevel.Normal)
    end
end

---------------------------------------------------------------------
-- Обновление батареи
---------------------------------------------------------------------
local function updateBattery(deltaTime)
    if not Flashlight.IsOn then return end

    Flashlight.Battery = Flashlight.Battery - GameConfig.Flashlight.DrainRate * deltaTime

    if Flashlight.Battery <= 0 then
        Flashlight.Battery = 0
        toggleFlashlight() -- автоматически выключить

        -- Мерцание перед выключением
        if Flashlight.SpotLight then
            task.spawn(function()
                for i = 1, 3 do
                    Flashlight.SpotLight.Enabled = true
                    task.wait(0.1)
                    Flashlight.SpotLight.Enabled = false
                    task.wait(0.1)
                end
            end)
        end
    end

    -- Мерцание при низком заряде
    if Flashlight.Battery > 0 and Flashlight.Battery < 20 and Flashlight.SpotLight then
        if math.random() < 0.05 then -- 5% шанс каждый кадр
            Flashlight.SpotLight.Enabled = false
            task.delay(0.05 + math.random() * 0.1, function()
                if Flashlight.IsOn and Flashlight.SpotLight then
                    Flashlight.SpotLight.Enabled = true
                end
            end)
        end
    end

    -- Обновить яркость по уровню батареи
    if Flashlight.SpotLight and Flashlight.IsOn then
        local batteryPercent = Flashlight.Battery / GameConfig.Flashlight.MaxBattery
        Flashlight.SpotLight.Brightness = 1 + batteryPercent
        Flashlight.SpotLight.Range = GameConfig.Flashlight.Range * (0.5 + batteryPercent * 0.5)
    end
end

---------------------------------------------------------------------
-- Направление фонарика по мыши
---------------------------------------------------------------------
local function updateFlashlightDirection()
    if not Flashlight.IsOn or not Flashlight.Attachment then return end

    local character = LocalPlayer.Character
    if not character then return end

    local head = character:FindFirstChild("Head")
    if not head then return end

    -- Фонарик следует за направлением камеры
    local camera = workspace.CurrentCamera
    if camera then
        local lookVector = camera.CFrame.LookVector
        Flashlight.Attachment.CFrame = CFrame.new(
            Flashlight.Attachment.Position,
            Flashlight.Attachment.Position + lookVector
        )
    end
end

---------------------------------------------------------------------
-- Ввод
---------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.F then
        toggleFlashlight()
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        flashFlashlight()
    end
end)

-- Мобильная кнопка
local function createMobileButton()
    if not UserInputService.TouchEnabled then return end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "FlashlightMobileGui"
    gui.Parent = playerGui

    local button = Instance.new("ImageButton")
    button.Name = "FlashlightButton"
    button.Size = UDim2.new(0, 60, 0, 60)
    button.Position = UDim2.new(1, -80, 0.5, -30)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.BackgroundTransparency = 0.3
    button.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = button

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🔦"
    label.TextScaled = true
    label.Parent = button

    button.Activated:Connect(function()
        toggleFlashlight()
    end)

    -- Кнопка вспышки
    local flashButton = button:Clone()
    flashButton.Name = "FlashButton"
    flashButton.Position = UDim2.new(1, -80, 0.5, 40)
    flashButton.Parent = gui

    local flashLabel = flashButton:FindFirstChild("TextLabel")
    if flashLabel then
        flashLabel.Text = "⚡"
    end

    flashButton.Activated:Connect(function()
        flashFlashlight()
    end)
end

---------------------------------------------------------------------
-- Главный цикл
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    updateBattery(deltaTime)
    updateFlashlightDirection()
end)

---------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1) -- подождать загрузку
    createFlashlight()
end)

if LocalPlayer.Character then
    createFlashlight()
end

createMobileButton()

-- Экспорт для других скриптов
local FlashlightAPI = Instance.new("BindableFunction")
FlashlightAPI.Name = "FlashlightAPI"
FlashlightAPI.OnInvoke = function(action)
    if action == "GetBattery" then
        return Flashlight.Battery
    elseif action == "IsOn" then
        return Flashlight.IsOn
    elseif action == "ChargeBattery" then
        Flashlight.Battery = math.min(
            GameConfig.Flashlight.MaxBattery,
            Flashlight.Battery + GameConfig.Flashlight.BatteryRestoreAmount
        )
        return Flashlight.Battery
    end
end
FlashlightAPI.Parent = LocalPlayer

print("[FlashlightController] Фонарик инициализирован.")
