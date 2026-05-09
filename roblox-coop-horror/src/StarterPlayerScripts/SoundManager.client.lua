--[[
    SoundManager.client.lua
    Управление звуками — эмбиент, монстр, эффекты, музыка
    Расположение: StarterPlayerScripts/SoundManager.client.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)

local LocalPlayer = Players.LocalPlayer

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local FearUpdated = Events:WaitForChild("FearUpdated")
local MonsterStateChanged = Events:WaitForChild("MonsterStateChanged")
local GameStateChanged = Events:WaitForChild("GameStateChanged")
local PlayerDamaged = Events:WaitForChild("PlayerDamaged")
local NoiseGenerated = Events:WaitForChild("NoiseGenerated")

---------------------------------------------------------------------
-- Звуковая библиотека
-- ВАЖНО: Замените rbxassetid://0 на реальные ID звуков из Roblox
-- Вы можете загрузить свои звуки или использовать из библиотеки Roblox
---------------------------------------------------------------------
local SoundLibrary = {
    -- Эмбиент
    Ambient = {
        HospitalHum = "rbxassetid://0",        -- гул вентиляции
        WaterDrip = "rbxassetid://0",           -- капающая вода
        DistantMoans = "rbxassetid://0",        -- далёкие стоны
        WindHowl = "rbxassetid://0",            -- вой ветра
        Creaking = "rbxassetid://0",            -- скрипы
    },

    -- Случайные звуки
    Random = {
        DoorSlam = "rbxassetid://0",            -- хлопанье двери
        GlassBreak = "rbxassetid://0",          -- разбитое стекло
        Whisper = "rbxassetid://0",             -- шёпот
        Footsteps = "rbxassetid://0",           -- далёкие шаги
        MetalClang = "rbxassetid://0",          -- металлический звук
        ChildLaugh = "rbxassetid://0",          -- детский смех (жуткий)
    },

    -- Монстр
    Monster = {
        Growl = "rbxassetid://0",               -- рычание (далеко)
        Breathing = "rbxassetid://0",           -- тяжёлое дыхание (близко)
        Scream = "rbxassetid://0",              -- крик монстра
        Chase = "rbxassetid://0",               -- музыка погони
    },

    -- Игрок
    Player = {
        Heartbeat = "rbxassetid://0",           -- сердцебиение
        HeavyBreathing = "rbxassetid://0",      -- тяжёлое дыхание
        Scream = "rbxassetid://0",              -- крик игрока
        FootstepConcrete = "rbxassetid://0",    -- шаги по бетону
        FootstepWood = "rbxassetid://0",        -- шаги по дереву
        FootstepMetal = "rbxassetid://0",       -- шаги по металлу
    },

    -- Интерфейс
    UI = {
        ItemPickup = "rbxassetid://0",          -- подбор предмета
        DoorOpen = "rbxassetid://0",            -- открытие двери
        PuzzleSolve = "rbxassetid://0",         -- решение головоломки
        Damage = "rbxassetid://0",              -- получение урона
    },

    -- Музыка
    Music = {
        Lobby = "rbxassetid://0",               -- музыка лобби
        Exploration = "rbxassetid://0",         -- исследование (тихая)
        Tension = "rbxassetid://0",             -- напряжённая
        Chase = "rbxassetid://0",               -- музыка погони
        Escape = "rbxassetid://0",              -- музыка побега
    },
}

---------------------------------------------------------------------
-- Состояние звукового менеджера
---------------------------------------------------------------------
local SoundState = {
    CurrentFear = 0,
    IsMonsterChasing = false,
    CurrentMusic = nil,
    AmbientSounds = {},
    ActiveSounds = {},
}

---------------------------------------------------------------------
-- Создание и воспроизведение звуков
---------------------------------------------------------------------
local function createSound(name, soundId, parent, properties)
    local sound = Instance.new("Sound")
    sound.Name = name
    sound.SoundId = soundId

    if properties then
        for key, value in pairs(properties) do
            sound[key] = value
        end
    end

    sound.Parent = parent or SoundService
    return sound
end

local function playSound(soundId, properties)
    if not soundId or soundId == "rbxassetid://0" then return nil end

    local sound = createSound("SFX_" .. os.clock(), soundId, SoundService, properties)
    sound:Play()

    if not (properties and properties.Looped) then
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end

    return sound
end

local function play3DSound(soundId, position, properties)
    if not soundId or soundId == "rbxassetid://0" then return nil end

    -- Создать Part для 3D звука
    local soundPart = Instance.new("Part")
    soundPart.Name = "SoundEmitter"
    soundPart.Anchored = true
    soundPart.CanCollide = false
    soundPart.Transparency = 1
    soundPart.Size = Vector3.new(1, 1, 1)
    soundPart.Position = position
    soundPart.Parent = workspace

    local sound = createSound("3DSound", soundId, soundPart, properties)
    sound.RollOffMode = Enum.RollOffMode.InverseTapered
    sound.RollOffMinDistance = 5
    sound.RollOffMaxDistance = 50
    sound:Play()

    if not (properties and properties.Looped) then
        sound.Ended:Connect(function()
            soundPart:Destroy()
        end)
    end

    return sound, soundPart
end

---------------------------------------------------------------------
-- Управление музыкой
---------------------------------------------------------------------
local function setMusic(musicKey, fadeTime)
    fadeTime = fadeTime or 2

    -- Fade out текущую музыку
    if SoundState.CurrentMusic then
        local oldMusic = SoundState.CurrentMusic
        local fadeOut = TweenService:Create(oldMusic, TweenInfo.new(fadeTime), {Volume = 0})
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            oldMusic:Stop()
            oldMusic:Destroy()
        end)
    end

    -- Запустить новую музыку
    local soundId = SoundLibrary.Music[musicKey]
    if not soundId or soundId == "rbxassetid://0" then
        SoundState.CurrentMusic = nil
        return
    end

    SoundState.CurrentMusic = createSound("Music_" .. musicKey, soundId, SoundService, {
        Looped = true,
        Volume = 0,
    })

    SoundState.CurrentMusic:Play()

    -- Fade in
    TweenService:Create(SoundState.CurrentMusic, TweenInfo.new(fadeTime), {
        Volume = 0.3
    }):Play()
end

---------------------------------------------------------------------
-- Эмбиент звуки
---------------------------------------------------------------------
local function startAmbient()
    -- Постоянные фоновые звуки
    for name, soundId in pairs(SoundLibrary.Ambient) do
        if soundId ~= "rbxassetid://0" then
            local sound = createSound("Ambient_" .. name, soundId, SoundService, {
                Looped = true,
                Volume = 0.15,
            })
            sound:Play()
            table.insert(SoundState.AmbientSounds, sound)
        end
    end

    -- Случайные звуки
    task.spawn(function()
        local randomSounds = {}
        for name, soundId in pairs(SoundLibrary.Random) do
            if soundId ~= "rbxassetid://0" then
                table.insert(randomSounds, {Name = name, SoundId = soundId})
            end
        end

        while true do
            task.wait(math.random(15, 60)) -- каждые 15-60 секунд

            if #randomSounds == 0 then continue end

            local randomSound = randomSounds[math.random(1, #randomSounds)]
            local character = LocalPlayer.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                -- Звук с случайного направления
                local offset = Vector3.new(
                    math.random(-40, 40),
                    math.random(-5, 5),
                    math.random(-40, 40)
                )
                local soundPos = character.HumanoidRootPart.Position + offset

                play3DSound(randomSound.SoundId, soundPos, {
                    Volume = 0.2 + SoundState.CurrentFear / GameConfig.Fear.MaxFear * 0.3,
                })
            end
        end
    end)
end

local function stopAmbient()
    for _, sound in ipairs(SoundState.AmbientSounds) do
        sound:Stop()
        sound:Destroy()
    end
    SoundState.AmbientSounds = {}
end

---------------------------------------------------------------------
-- Звуки на основе страха
---------------------------------------------------------------------
local heartbeatSound = nil
local breathingSound = nil

local function updateFearSounds(fearLevel)
    SoundState.CurrentFear = fearLevel
    local normalized = fearLevel / GameConfig.Fear.MaxFear

    -- Сердцебиение (начинается при страхе > 40)
    if fearLevel > 40 then
        if not heartbeatSound then
            heartbeatSound = createSound("Heartbeat", SoundLibrary.Player.Heartbeat, SoundService, {
                Looped = true,
                Volume = 0,
            })
            heartbeatSound:Play()
        end

        -- Громкость и скорость зависят от страха
        heartbeatSound.Volume = (normalized - 0.4) * 0.8
        heartbeatSound.PlaybackSpeed = 0.8 + normalized * 0.6
    else
        if heartbeatSound then
            heartbeatSound:Stop()
            heartbeatSound:Destroy()
            heartbeatSound = nil
        end
    end

    -- Тяжёлое дыхание (при страхе > 60)
    if fearLevel > 60 then
        if not breathingSound then
            breathingSound = createSound("Breathing", SoundLibrary.Player.HeavyBreathing, SoundService, {
                Looped = true,
                Volume = 0,
            })
            breathingSound:Play()
        end
        breathingSound.Volume = (normalized - 0.6) * 0.5
    else
        if breathingSound then
            breathingSound:Stop()
            breathingSound:Destroy()
            breathingSound = nil
        end
    end

    -- Смена музыки по уровню страха
    if fearLevel >= GameConfig.Fear.PanicThreshold then
        if not SoundState.IsMonsterChasing then
            setMusic("Tension", 1)
        end
    elseif fearLevel > 30 then
        if not SoundState.IsMonsterChasing then
            setMusic("Exploration", 3)
        end
    end
end

---------------------------------------------------------------------
-- Звуки шагов
---------------------------------------------------------------------
local lastFootstepTime = 0
local function playFootstep()
    local now = os.clock()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    -- Определить интервал между шагами
    local speed = humanoid.WalkSpeed
    local interval
    if speed <= GameConfig.Player.CrouchSpeed then
        interval = 0.7
    elseif speed <= GameConfig.Player.WalkSpeed then
        interval = 0.45
    else
        interval = 0.3
    end

    if now - lastFootstepTime < interval then return end
    if humanoid.MoveDirection.Magnitude < 0.1 then return end

    lastFootstepTime = now

    -- Определить тип поверхности (Raycast вниз)
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local ray = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0))
    local soundId = SoundLibrary.Player.FootstepConcrete

    if ray then
        local material = ray.Material
        if material == Enum.Material.Wood or material == Enum.Material.WoodPlanks then
            soundId = SoundLibrary.Player.FootstepWood
        elseif material == Enum.Material.Metal or material == Enum.Material.DiamondPlate then
            soundId = SoundLibrary.Player.FootstepMetal
        end
    end

    if soundId ~= "rbxassetid://0" then
        playSound(soundId, {
            Volume = speed > GameConfig.Player.WalkSpeed and 0.4 or 0.2,
            PlaybackSpeed = 0.9 + math.random() * 0.2,
        })
    end
end

---------------------------------------------------------------------
-- Обработка событий
---------------------------------------------------------------------
FearUpdated.OnClientEvent:Connect(function(fearLevel)
    updateFearSounds(fearLevel)
end)

MonsterStateChanged.OnClientEvent:Connect(function(state, position)
    SoundState.IsMonsterChasing = (state == SharedTypes.MonsterState.Chase)

    if state == SharedTypes.MonsterState.Chase then
        setMusic("Chase", 0.5)

        -- Звук рычания монстра
        if position then
            play3DSound(SoundLibrary.Monster.Scream, position, {Volume = 0.8})
        end
    elseif state == SharedTypes.MonsterState.Patrol then
        if SoundState.CurrentFear > 30 then
            setMusic("Tension", 2)
        else
            setMusic("Exploration", 3)
        end
    end
end)

GameStateChanged.OnClientEvent:Connect(function(state)
    if state == SharedTypes.GameState.Lobby then
        stopAmbient()
        setMusic("Lobby", 2)
    elseif state == SharedTypes.GameState.Playing then
        startAmbient()
        setMusic("Exploration", 3)
    elseif state == SharedTypes.GameState.Ending then
        stopAmbient()
        setMusic("Escape", 1)
    end
end)

PlayerDamaged.OnClientEvent:Connect(function(player, health)
    if player == LocalPlayer then
        playSound(SoundLibrary.UI.Damage, {Volume = 0.6})
    end
end)

NoiseGenerated.OnClientEvent:Connect(function(position, noiseLevel)
    -- Воспроизвести 3D звук в позиции шума (для других игроков)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end

    local dist = (character.HumanoidRootPart.Position - position).Magnitude
    if dist > 5 and dist < 80 then -- не свой шум, в пределах слышимости
        -- Тихий индикатор направления звука
        play3DSound(SoundLibrary.Random.Footsteps, position, {
            Volume = math.clamp(noiseLevel / 100, 0.1, 0.5),
        })
    end
end)

---------------------------------------------------------------------
-- Главный цикл
---------------------------------------------------------------------
RunService.Heartbeat:Connect(function()
    playFootstep()
end)

---------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------
setMusic("Lobby", 0)

print("[SoundManager] Звуковой менеджер инициализирован.")
