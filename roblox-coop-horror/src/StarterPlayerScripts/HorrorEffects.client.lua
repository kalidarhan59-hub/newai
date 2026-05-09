--[[
    HorrorEffects.client.lua
    Визуальные эффекты хоррора — искажения, тряска камеры, затемнение
    Расположение: StarterPlayerScripts/HorrorEffects.client.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local FearUpdated = Events:WaitForChild("FearUpdated")
local MonsterStateChanged = Events:WaitForChild("MonsterStateChanged")
local GameStateChanged = Events:WaitForChild("GameStateChanged")
local PlayerDamaged = Events:WaitForChild("PlayerDamaged")

---------------------------------------------------------------------
-- Настройки эффектов
---------------------------------------------------------------------
local Effects = {
    CurrentFear = 0,
    IsMonsterChasing = false,
    ScreenShake = 0,
    VignetteIntensity = 0,
    ColorCorrectionEffect = nil,
    BlurEffect = nil,
    ColorShiftEffect = nil,
}

---------------------------------------------------------------------
-- Создание пост-процесс эффектов
---------------------------------------------------------------------
local function setupEffects()
    -- Цветокоррекция (для страха)
    Effects.ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")
    Effects.ColorCorrectionEffect.Name = "HorrorColorCorrection"
    Effects.ColorCorrectionEffect.Brightness = 0
    Effects.ColorCorrectionEffect.Contrast = 0
    Effects.ColorCorrectionEffect.Saturation = 0
    Effects.ColorCorrectionEffect.TintColor = Color3.fromRGB(255, 255, 255)
    Effects.ColorCorrectionEffect.Parent = Lighting

    -- Размытие (для потери сознания / высокого страха)
    Effects.BlurEffect = Instance.new("BlurEffect")
    Effects.BlurEffect.Name = "HorrorBlur"
    Effects.BlurEffect.Size = 0
    Effects.BlurEffect.Parent = Lighting

    -- Атмосфера (туман)
    local atmosphere = Lighting:FindFirstChild("HorrorAtmosphere")
    if not atmosphere then
        atmosphere = Instance.new("Atmosphere")
        atmosphere.Name = "HorrorAtmosphere"
        atmosphere.Density = 0.3
        atmosphere.Offset = 0
        atmosphere.Color = Color3.fromRGB(20, 20, 30)
        atmosphere.Decay = Color3.fromRGB(30, 30, 40)
        atmosphere.Glare = 0
        atmosphere.Haze = 8
        atmosphere.Parent = Lighting
    end

    -- Настройки освещения
    Lighting.Ambient = Color3.fromRGB(10, 10, 15)
    Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 20)
    Lighting.Brightness = 0.2
    Lighting.ClockTime = 0 -- полночь
    Lighting.FogEnd = 200
    Lighting.FogStart = 50
    Lighting.FogColor = Color3.fromRGB(10, 10, 15)
end

---------------------------------------------------------------------
-- Эффект тряски камеры
---------------------------------------------------------------------
local shakeOffset = CFrame.new()

local function updateCameraShake(deltaTime)
    if Effects.ScreenShake <= 0 then
        shakeOffset = CFrame.new()
        return
    end

    local intensity = Effects.ScreenShake
    local shakeX = (math.random() - 0.5) * 2 * intensity * 0.03
    local shakeY = (math.random() - 0.5) * 2 * intensity * 0.03
    local shakeZ = (math.random() - 0.5) * 2 * intensity * 0.01

    shakeOffset = CFrame.new(shakeX, shakeY, shakeZ)

    -- Затухание тряски
    Effects.ScreenShake = math.max(0, Effects.ScreenShake - deltaTime * 5)
end

-- Вызвать тряску
local function triggerShake(intensity, duration)
    Effects.ScreenShake = intensity
    task.delay(duration or 0.5, function()
        Effects.ScreenShake = 0
    end)
end

---------------------------------------------------------------------
-- Эффекты страха
---------------------------------------------------------------------
local function updateFearEffects(fearLevel)
    local normalizedFear = fearLevel / GameConfig.Fear.MaxFear

    -- Цветокоррекция: десатурация + красный оттенок
    if Effects.ColorCorrectionEffect then
        Effects.ColorCorrectionEffect.Saturation = -normalizedFear * 0.6
        Effects.ColorCorrectionEffect.Contrast = normalizedFear * 0.3

        -- Красный оттенок при высоком страхе
        if fearLevel >= GameConfig.Fear.PanicThreshold then
            local redIntensity = (fearLevel - GameConfig.Fear.PanicThreshold) /
                (GameConfig.Fear.MaxPanicThreshold - GameConfig.Fear.PanicThreshold)
            Effects.ColorCorrectionEffect.TintColor = Color3.fromRGB(
                255,
                math.floor(255 - redIntensity * 100),
                math.floor(255 - redIntensity * 100)
            )
        else
            Effects.ColorCorrectionEffect.TintColor = Color3.fromRGB(255, 255, 255)
        end
    end

    -- Размытие краёв при высоком страхе
    if Effects.BlurEffect then
        if fearLevel >= GameConfig.Fear.PanicThreshold then
            local blurAmount = (fearLevel - GameConfig.Fear.PanicThreshold) /
                (GameConfig.Fear.MaxPanicThreshold - GameConfig.Fear.PanicThreshold)
            Effects.BlurEffect.Size = blurAmount * 12
        else
            Effects.BlurEffect.Size = 0
        end
    end

    -- Тряска камеры при высоком страхе
    if fearLevel >= GameConfig.Fear.PanicThreshold then
        local shakeIntensity = (fearLevel - GameConfig.Fear.PanicThreshold) /
            (GameConfig.Fear.MaxPanicThreshold - GameConfig.Fear.PanicThreshold)
        Effects.ScreenShake = shakeIntensity * 3
    end

    -- Виньетка (затемнение краёв) — обрабатывается в UI
    Effects.VignetteIntensity = normalizedFear * 0.7
end

---------------------------------------------------------------------
-- Эффект появления/исчезновения (Fade)
---------------------------------------------------------------------
local function fadeScreen(fadeIn, duration, callback)
    local screenGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not screenGui then return end

    local fadeFrame = screenGui:FindFirstChild("FadeFrame")
    if not fadeFrame then
        local gui = Instance.new("ScreenGui")
        gui.Name = "FadeGui"
        gui.DisplayOrder = 100
        gui.IgnoreGuiInset = true
        gui.Parent = screenGui

        fadeFrame = Instance.new("Frame")
        fadeFrame.Name = "FadeFrame"
        fadeFrame.Size = UDim2.new(1, 0, 1, 0)
        fadeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        fadeFrame.BackgroundTransparency = fadeIn and 1 or 0
        fadeFrame.BorderSizePixel = 0
        fadeFrame.ZIndex = 100
        fadeFrame.Parent = gui
    end

    local targetTransparency = fadeIn and 0 or 1
    local tween = TweenService:Create(fadeFrame, TweenInfo.new(duration or 1), {
        BackgroundTransparency = targetTransparency
    })

    tween:Play()
    tween.Completed:Connect(function()
        if callback then callback() end
        if not fadeIn then
            fadeFrame.Parent:Destroy()
        end
    end)
end

---------------------------------------------------------------------
-- Случайные хоррор-события (скримеры, звуки)
---------------------------------------------------------------------
local function startRandomEvents()
    task.spawn(function()
        while true do
            task.wait(math.random(30, 90)) -- каждые 30-90 секунд

            if Effects.CurrentFear < 20 then continue end

            local eventType = math.random(1, 5)

            if eventType == 1 then
                -- Мерцание света
                for i = 1, math.random(2, 5) do
                    Lighting.Brightness = math.random() * 2
                    task.wait(0.05 + math.random() * 0.1)
                end
                Lighting.Brightness = 0.2

            elseif eventType == 2 then
                -- Кратковременная тряска
                triggerShake(2, 0.3)

            elseif eventType == 3 then
                -- Краткое затемнение
                if Effects.ColorCorrectionEffect then
                    local originalBrightness = Effects.ColorCorrectionEffect.Brightness
                    Effects.ColorCorrectionEffect.Brightness = -0.5
                    task.wait(0.2)
                    Effects.ColorCorrectionEffect.Brightness = originalBrightness
                end

            elseif eventType == 4 then
                -- Шёпот (визуальный индикатор — текст на экране)
                local whispers = {
                    "...уходите...",
                    "...он здесь...",
                    "...не оборачивайтесь...",
                    "...помогите...",
                    "...тихо...",
                }
                -- Отправить текст через UI (обработается в HorrorUI)
                local screenGui = LocalPlayer:FindFirstChild("PlayerGui")
                if screenGui then
                    local whisperGui = screenGui:FindFirstChild("WhisperGui")
                    if not whisperGui then
                        whisperGui = Instance.new("ScreenGui")
                        whisperGui.Name = "WhisperGui"
                        whisperGui.DisplayOrder = 50
                        whisperGui.Parent = screenGui
                    end

                    local label = Instance.new("TextLabel")
                    label.Size = UDim2.new(0.5, 0, 0.1, 0)
                    label.Position = UDim2.new(
                        math.random() * 0.5,
                        0,
                        math.random() * 0.8 + 0.1,
                        0
                    )
                    label.BackgroundTransparency = 1
                    label.Text = whispers[math.random(1, #whispers)]
                    label.TextColor3 = Color3.fromRGB(180, 180, 200)
                    label.TextTransparency = 0.3
                    label.TextScaled = true
                    label.Font = Enum.Font.Antique
                    label.Rotation = math.random(-5, 5)
                    label.Parent = whisperGui

                    -- Fade out
                    local tween = TweenService:Create(label, TweenInfo.new(3), {
                        TextTransparency = 1
                    })
                    tween:Play()
                    tween.Completed:Connect(function()
                        label:Destroy()
                    end)
                end

            elseif eventType == 5 then
                -- Искажение FOV
                local originalFOV = Camera.FieldOfView
                TweenService:Create(Camera, TweenInfo.new(0.2), {FieldOfView = 80}):Play()
                task.wait(0.3)
                TweenService:Create(Camera, TweenInfo.new(0.5), {FieldOfView = originalFOV}):Play()
            end
        end
    end)
end

---------------------------------------------------------------------
-- Обработка событий
---------------------------------------------------------------------
FearUpdated.OnClientEvent:Connect(function(fearLevel)
    Effects.CurrentFear = fearLevel
    updateFearEffects(fearLevel)
end)

MonsterStateChanged.OnClientEvent:Connect(function(state, position)
    Effects.IsMonsterChasing = (state == SharedTypes.MonsterState.Chase)

    if state == SharedTypes.MonsterState.Chase then
        -- Усилить эффекты при преследовании
        triggerShake(4, 0.5)
    end
end)

GameStateChanged.OnClientEvent:Connect(function(state, data)
    if state == SharedTypes.GameState.Starting then
        fadeScreen(true, data and data.FadeTime or 2, function()
            task.wait(2)
            fadeScreen(false, 1)
        end)
    elseif state == SharedTypes.GameState.Ending then
        fadeScreen(true, 2)
    end
end)

PlayerDamaged.OnClientEvent:Connect(function(player, health)
    if player == LocalPlayer then
        -- Красная вспышка при получении урона
        triggerShake(5, 0.3)

        if Effects.ColorCorrectionEffect then
            Effects.ColorCorrectionEffect.TintColor = Color3.fromRGB(255, 50, 50)
            task.delay(0.3, function()
                Effects.ColorCorrectionEffect.TintColor = Color3.fromRGB(255, 255, 255)
            end)
        end
    end
end)

---------------------------------------------------------------------
-- Главный цикл обновления
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function(deltaTime)
    updateCameraShake(deltaTime)

    -- Применить тряску к камере
    if Camera and Effects.ScreenShake > 0 then
        Camera.CFrame = Camera.CFrame * shakeOffset
    end
end)

---------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------
setupEffects()
startRandomEvents()

print("[HorrorEffects] Визуальные эффекты хоррора активированы.")
