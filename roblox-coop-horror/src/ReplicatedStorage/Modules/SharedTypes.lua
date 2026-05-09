--[[
    SharedTypes.lua
    Общие типы данных и enum'ы для игры "Dead Silence"
    Расположение: ReplicatedStorage/Modules/SharedTypes.lua
]]

local SharedTypes = {}

-- Состояния игры
SharedTypes.GameState = {
    Lobby = "Lobby",
    Starting = "Starting",
    Playing = "Playing",
    Ending = "Ending",
}

-- Состояния игрока
SharedTypes.PlayerState = {
    Alive = "Alive",
    Ghost = "Ghost",
    Dead = "Dead",
    Escaped = "Escaped",
}

-- Состояния монстра
SharedTypes.MonsterState = {
    Idle = "Idle",
    Patrol = "Patrol",
    Investigate = "Investigate",
    Chase = "Chase",
    BreakDoor = "BreakDoor",
    LostTarget = "LostTarget",
}

-- Типы предметов
SharedTypes.ItemType = {
    Battery = "Battery",
    Bandage = "Bandage",
    Key = "Key",
    Fuse = "Fuse",
    Note = "Note",
    Candle = "Candle",
    Reagent = "Reagent",
    KeyItem = "KeyItem",
}

-- Уровни шума
SharedTypes.NoiseType = {
    Silent = "Silent",
    Quiet = "Quiet",
    Normal = "Normal",
    Loud = "Loud",
    VeryLoud = "VeryLoud",
}

-- Типы головоломок
SharedTypes.PuzzleType = {
    FuseBox = "FuseBox",
    SafeCode = "SafeCode",
    MorgueRitual = "MorgueRitual",
    LabReagents = "LabReagents",
    FinalDoor = "FinalDoor",
}

-- Статус головоломки
SharedTypes.PuzzleStatus = {
    Locked = "Locked",
    Available = "Available",
    InProgress = "InProgress",
    Completed = "Completed",
}

-- Типы взаимодействий
SharedTypes.InteractionType = {
    PickupItem = "PickupItem",
    UseItem = "UseItem",
    OpenDoor = "OpenDoor",
    ReadNote = "ReadNote",
    RevivePlayer = "RevivePlayer",
    GiveItem = "GiveItem",
    SolvePuzzle = "SolvePuzzle",
    HideInLocker = "HideInLocker",
}

-- Результат игры
SharedTypes.GameResult = {
    Escaped = "Escaped",      -- хотя бы 1 игрок сбежал
    AllDead = "AllDead",       -- все погибли
    TimeOut = "TimeOut",       -- время вышло
}

-- Создание структуры данных игрока
function SharedTypes.CreatePlayerData(player)
    return {
        Player = player,
        State = SharedTypes.PlayerState.Alive,
        Health = 3,
        Fear = 0,
        Stamina = 100,
        FlashlightBattery = 100,
        FlashlightOn = false,
        IsSprinting = false,
        IsCrouching = false,
        Inventory = {},
        KeyItemsFound = 0,
    }
end

-- Создание структуры данных монстра
function SharedTypes.CreateMonsterData()
    return {
        State = SharedTypes.MonsterState.Idle,
        CurrentTarget = nil,
        LastKnownPosition = nil,
        InvestigatePosition = nil,
        PatrolWaypoints = {},
        CurrentWaypointIndex = 1,
        AggressionLevel = 1.0,
        LoseTargetTimer = 0,
        DoorBreakTimer = 0,
    }
end

return SharedTypes
