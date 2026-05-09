--[[
    GameConfig.lua
    Центральная конфигурация игры "Dead Silence"
    Расположение: ReplicatedStorage/Modules/GameConfig.lua
]]

local GameConfig = {}

-- Общие настройки
GameConfig.GAME_NAME = "Dead Silence"
GameConfig.MAX_PLAYERS = 4
GameConfig.MIN_PLAYERS_TO_START = 2
GameConfig.LOBBY_COUNTDOWN = 15 -- секунд до старта
GameConfig.SESSION_TIME_LIMIT = 1800 -- 30 минут в секундах
GameConfig.MONSTER_SPAWN_DELAY = 300 -- монстр появляется через 5 минут

-- Настройки игрока
GameConfig.Player = {
    MaxHealth = 3,
    WalkSpeed = 12,
    RunSpeed = 16,
    CrouchSpeed = 6,
    MaxStamina = 100,
    StaminaDrainRate = 20, -- единиц/сек при беге
    StaminaRegenRate = 10, -- единиц/сек при отдыхе
    InventorySlots = 4,
    ReviveTime = 5, -- секунд для воскрешения
    GhostDuration = 60, -- секунд в виде духа
}

-- Настройки страха
GameConfig.Fear = {
    MaxFear = 100,
    DarknessRate = 5, -- единиц/сек в темноте
    MonsterNearbyRate = 15, -- единиц/сек рядом с монстром
    AloneRate = 3, -- единиц/сек в одиночестве
    NearPlayerReduction = 4, -- снижение/сек рядом с другим игроком
    LightReduction = 3, -- снижение/сек на свету
    BreathingReduction = 8, -- снижение/сек при глубоком дыхании
    PanicThreshold = 80, -- порог искажений
    MaxPanicThreshold = 100, -- порог паники (крик)
    PanicScreamRadius = 80, -- studs - радиус крика для монстра
    InvertControlsDuration = 5, -- секунд инвертированного управления
}

-- Настройки фонарика
GameConfig.Flashlight = {
    MaxBattery = 100,
    DrainRate = 5, -- единиц/сек
    FlashDrainAmount = 15, -- за вспышку
    FlashCooldown = 2, -- секунд между вспышками
    Range = 60, -- studs
    Angle = 45, -- градусов
    BatteryRestoreAmount = 50, -- от одной батарейки
}

-- Настройки монстра
GameConfig.Monster = {
    PatrolSpeed = 8,
    InvestigateSpeed = 12,
    ChaseSpeed = 18,
    HearingRadius = 50, -- studs
    VisionRadius = 40, -- studs
    VisionAngle = 90, -- градусов (конус)
    LoseTargetTime = 8, -- секунд без видимости для потери цели
    DoorBreakTime = 10, -- секунд чтобы сломать дверь
    TeleportDistance = 150, -- если все игроки дальше этого расстояния
    AggressionPerItem = 0.15, -- +15% скорости за каждый найденный предмет
}

-- Звуковые уровни шума (для системы детекции монстра)
GameConfig.NoiseLevel = {
    Silent = 0, -- приседание
    Quiet = 15, -- ходьба
    Normal = 30, -- обычные действия
    Loud = 50, -- бег
    VeryLoud = 80, -- крик при панике, взрыв
}

-- Настройки головоломок
GameConfig.Puzzles = {
    FuseCount = 3,
    SafeCodeLength = 4,
    CandleCount = 4,
    ReagentCount = 3,
    KeyItemsTotal = 5,
    FinalDoorOpenTime = 30, -- секунд для открытия финальной двери
}

-- Настройки предметов
GameConfig.Items = {
    Battery = {
        Name = "Батарейка",
        Description = "Заряжает фонарик",
        Icon = "rbxassetid://0", -- заменить на реальный ID
        Stackable = false,
    },
    Bandage = {
        Name = "Бинт",
        Description = "Восстанавливает 1 здоровье",
        Icon = "rbxassetid://0",
        Stackable = false,
    },
    Key = {
        Name = "Ключ",
        Description = "Открывает запертую дверь",
        Icon = "rbxassetid://0",
        Stackable = false,
    },
    Fuse = {
        Name = "Предохранитель",
        Description = "Для электрощита",
        Icon = "rbxassetid://0",
        Stackable = false,
    },
    Note = {
        Name = "Записка",
        Description = "Содержит подсказку",
        Icon = "rbxassetid://0",
        Stackable = false,
    },
    Candle = {
        Name = "Свеча",
        Description = "Для ритуала",
        Icon = "rbxassetid://0",
        Stackable = false,
    },
    Reagent = {
        Name = "Реагент",
        Description = "Для лаборатории",
        Icon = "rbxassetid://0",
        Stackable = false,
    },
    KeyItem = {
        Name = "Ключевой предмет",
        Description = "Нужен для финальной двери",
        Icon = "rbxassetid://0",
        Stackable = false,
    },
}

-- Настройки UI
GameConfig.UI = {
    FearBarColor = Color3.fromRGB(180, 30, 30),
    HealthColor = Color3.fromRGB(30, 180, 30),
    BatteryColor = Color3.fromRGB(255, 200, 50),
    HintDuration = 5, -- секунд показа подсказки
    FadeInTime = 1,
    FadeOutTime = 0.5,
}

-- Настройки сложности (масштабируется по времени)
GameConfig.Difficulty = {
    -- Множители для монстра по прошедшему времени
    SpeedMultiplier = {
        {time = 0, mult = 1.0},
        {time = 300, mult = 1.1}, -- +10% через 5 мин
        {time = 600, mult = 1.2}, -- +20% через 10 мин
        {time = 900, mult = 1.35}, -- +35% через 15 мин
        {time = 1200, mult = 1.5}, -- +50% через 20 мин
    },
    -- Множитель агрессии по количеству найденных предметов
    AggressionMultiplier = {
        {items = 0, mult = 1.0},
        {items = 2, mult = 1.2},
        {items = 4, mult = 1.5},
        {items = 5, mult = 2.0}, -- финальная фаза
    },
}

return GameConfig
