--[[
    DataManager.lua
    Сохранение данных игроков (статистика, прогресс, достижения)
    Расположение: ServerStorage/DataManager.lua
]]

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local DataManager = {}

---------------------------------------------------------------------
-- DataStore
---------------------------------------------------------------------
local DATASTORE_NAME = "DeadSilence_PlayerData_v1"
local playerDataStore = nil

-- Попытка подключения к DataStore
local success, err = pcall(function()
    playerDataStore = DataStoreService:GetDataStore(DATASTORE_NAME)
end)

if not success then
    warn("[DataManager] Не удалось подключиться к DataStore: " .. tostring(err))
    warn("[DataManager] Данные не будут сохраняться (вероятно, Studio без API доступа)")
end

---------------------------------------------------------------------
-- Шаблон данных игрока
---------------------------------------------------------------------
local DEFAULT_DATA = {
    -- Статистика
    Stats = {
        GamesPlayed = 0,
        GamesWon = 0,        -- успешные побеги
        GamesLost = 0,
        TotalDeaths = 0,
        PuzzlesSolved = 0,
        ItemsCollected = 0,
        PlayersRevived = 0,
        TimePlayed = 0,       -- секунды
        MonsterEncounters = 0,
    },

    -- Достижения
    Achievements = {
        FirstEscape = false,          -- Первый побег
        PuzzleMaster = false,         -- Решить все головоломки за одну игру
        TeamPlayer = false,           -- Воскресить 3 игроков
        SurvivalExpert = false,       -- Выжить 20 минут
        SilentRunner = false,         -- Пройти игру без единого крика
        NightOwl = false,             -- Пройти без фонарика
        AllTogetherNow = false,       -- Побег всех 4 игроков
        SpeedRunner = false,          -- Побег за 10 минут
    },

    -- Косметика
    Cosmetics = {
        SelectedSkin = "Default",
        UnlockedSkins = {"Default"},
        SelectedFlashlight = "Default",
        UnlockedFlashlights = {"Default"},
    },

    -- Настройки
    Settings = {
        MusicVolume = 0.5,
        SFXVolume = 0.7,
        AmbientVolume = 0.5,
        Sensitivity = 1.0,
        ShowHints = true,
    },

    -- Метаданные
    Version = 1,
    FirstJoinDate = 0,
    LastJoinDate = 0,
}

---------------------------------------------------------------------
-- Кеш данных в памяти
---------------------------------------------------------------------
local playerCache = {} -- [userId] = data

---------------------------------------------------------------------
-- Глубокое копирование таблицы
---------------------------------------------------------------------
local function deepCopy(original)
    local copy = {}
    for key, value in pairs(original) do
        if type(value) == "table" then
            copy[key] = deepCopy(value)
        else
            copy[key] = value
        end
    end
    return copy
end

---------------------------------------------------------------------
-- Слияние данных (для обновления с новыми полями)
---------------------------------------------------------------------
local function mergeDefaults(data, defaults)
    for key, defaultValue in pairs(defaults) do
        if data[key] == nil then
            if type(defaultValue) == "table" then
                data[key] = deepCopy(defaultValue)
            else
                data[key] = defaultValue
            end
        elseif type(defaultValue) == "table" and type(data[key]) == "table" then
            mergeDefaults(data[key], defaultValue)
        end
    end
    return data
end

---------------------------------------------------------------------
-- Загрузка данных
---------------------------------------------------------------------
function DataManager.LoadData(player)
    local userId = player.UserId
    local data = nil

    if playerDataStore then
        local success, result = pcall(function()
            return playerDataStore:GetAsync("Player_" .. userId)
        end)

        if success and result then
            data = result
        elseif not success then
            warn("[DataManager] Ошибка загрузки данных для " .. player.Name .. ": " .. tostring(result))
        end
    end

    -- Если нет данных или первый вход — использовать значения по умолчанию
    if not data then
        data = deepCopy(DEFAULT_DATA)
        data.FirstJoinDate = os.time()
    end

    -- Слить с дефолтами (добавить новые поля)
    data = mergeDefaults(data, DEFAULT_DATA)
    data.LastJoinDate = os.time()

    playerCache[userId] = data
    print("[DataManager] Данные загружены для " .. player.Name)

    return data
end

---------------------------------------------------------------------
-- Сохранение данных
---------------------------------------------------------------------
function DataManager.SaveData(player)
    local userId = player.UserId
    local data = playerCache[userId]

    if not data then
        warn("[DataManager] Нет данных для сохранения: " .. player.Name)
        return false
    end

    if not playerDataStore then
        warn("[DataManager] DataStore недоступен, данные не сохранены")
        return false
    end

    local success, err = pcall(function()
        playerDataStore:SetAsync("Player_" .. userId, data)
    end)

    if success then
        print("[DataManager] Данные сохранены для " .. player.Name)
    else
        warn("[DataManager] Ошибка сохранения для " .. player.Name .. ": " .. tostring(err))
    end

    return success
end

---------------------------------------------------------------------
-- Получение данных из кеша
---------------------------------------------------------------------
function DataManager.GetData(player)
    return playerCache[player.UserId]
end

---------------------------------------------------------------------
-- Обновление статистики
---------------------------------------------------------------------
function DataManager.IncrementStat(player, statName, amount)
    local data = playerCache[player.UserId]
    if not data then return end

    if data.Stats[statName] ~= nil then
        data.Stats[statName] = data.Stats[statName] + (amount or 1)
    end
end

function DataManager.SetStat(player, statName, value)
    local data = playerCache[player.UserId]
    if not data then return end

    if data.Stats[statName] ~= nil then
        data.Stats[statName] = value
    end
end

---------------------------------------------------------------------
-- Достижения
---------------------------------------------------------------------
function DataManager.UnlockAchievement(player, achievementName)
    local data = playerCache[player.UserId]
    if not data then return false end

    if data.Achievements[achievementName] == false then
        data.Achievements[achievementName] = true
        print("[DataManager] Достижение разблокировано для " .. player.Name .. ": " .. achievementName)
        return true
    end

    return false
end

function DataManager.HasAchievement(player, achievementName)
    local data = playerCache[player.UserId]
    if not data then return false end
    return data.Achievements[achievementName] == true
end

---------------------------------------------------------------------
-- Настройки
---------------------------------------------------------------------
function DataManager.GetSetting(player, settingName)
    local data = playerCache[player.UserId]
    if not data then return nil end
    return data.Settings[settingName]
end

function DataManager.SetSetting(player, settingName, value)
    local data = playerCache[player.UserId]
    if not data then return end
    data.Settings[settingName] = value
end

---------------------------------------------------------------------
-- Обработка выхода игрока
---------------------------------------------------------------------
function DataManager.OnPlayerRemoving(player)
    DataManager.SaveData(player)
    playerCache[player.UserId] = nil
end

---------------------------------------------------------------------
-- Автосохранение
---------------------------------------------------------------------
function DataManager.StartAutoSave(interval)
    interval = interval or 300 -- каждые 5 минут

    task.spawn(function()
        while true do
            task.wait(interval)
            for _, player in ipairs(Players:GetPlayers()) do
                DataManager.SaveData(player)
            end
        end
    end)
end

---------------------------------------------------------------------
-- Обработчики
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    DataManager.LoadData(player)
end)

Players.PlayerRemoving:Connect(function(player)
    DataManager.OnPlayerRemoving(player)
end)

-- Сохранить все данные при закрытии сервера
game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        DataManager.SaveData(player)
    end
end)

-- Запустить автосохранение
DataManager.StartAutoSave(300)

print("[DataManager] Менеджер данных инициализирован.")

return DataManager
