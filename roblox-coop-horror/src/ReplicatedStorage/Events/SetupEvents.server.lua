--[[
    SetupEvents.server.lua
    Создаёт все RemoteEvents и BindableEvents
    ВАЖНО: Этот скрипт нужно поместить в ServerScriptService, 
    но он создаёт события в ReplicatedStorage/Events
    Расположение: ServerScriptService/SetupEvents.server.lua (создаёт в ReplicatedStorage/Events)
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Создать папку Events если не существует
local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
if not eventsFolder then
    eventsFolder = Instance.new("Folder")
    eventsFolder.Name = "Events"
    eventsFolder.Parent = ReplicatedStorage
end

---------------------------------------------------------------------
-- Список RemoteEvents (сервер ↔ клиент)
---------------------------------------------------------------------
local remoteEvents = {
    -- Состояние игры
    "GameStateChanged",     -- сервер → клиент: изменение состояния игры
    "PlayerStateChanged",   -- сервер → клиент: изменение состояния игрока
    "GameEnded",            -- сервер → клиент: конец игры

    -- Лобби
    "LobbyUpdate",          -- сервер → клиент: обновление лобби
    "PlayerReady",           -- клиент → сервер: игрок готов/не готов

    -- Здоровье и страх
    "PlayerDamaged",         -- сервер → клиент: игрок получил урон
    "FearUpdated",           -- сервер → клиент: обновление уровня страха
    "PlayerRevived",         -- сервер → клиент: игрок воскрешён

    -- Предметы
    "ItemPickedUp",          -- сервер → клиент: предмет подобран
    "ItemUsed",              -- сервер → клиент: предмет использован
    "ItemDropped",           -- сервер → клиент: предмет выброшен
    "ItemGiven",             -- сервер → клиент: предмет передан

    -- Взаимодействие
    "InteractionRequest",    -- клиент → сервер: запрос взаимодействия

    -- Монстр
    "MonsterStateChanged",   -- сервер → клиент: состояние монстра
    "NoiseGenerated",        -- сервер → клиент: шум на карте

    -- Головоломки
    "PuzzleInteraction",     -- клиент → сервер: взаимодействие с головоломкой
    "PuzzleCompleted",       -- сервер → клиент: головоломка решена
    "PuzzleHint",            -- сервер → клиент: подсказка головоломки

    -- UI
    "ShowHint",              -- сервер → клиент: показать подсказку
    "InventoryUpdate",       -- сервер → клиент: обновление инвентаря
}

---------------------------------------------------------------------
-- Список BindableEvents (сервер ↔ сервер)
---------------------------------------------------------------------
local bindableEvents = {
    "MonsterAlert",          -- серверные скрипты: уведомление монстра о шуме
}

---------------------------------------------------------------------
-- Создание RemoteEvents
---------------------------------------------------------------------
for _, eventName in ipairs(remoteEvents) do
    if not eventsFolder:FindFirstChild(eventName) then
        local event = Instance.new("RemoteEvent")
        event.Name = eventName
        event.Parent = eventsFolder
    end
end

---------------------------------------------------------------------
-- Создание BindableEvents
---------------------------------------------------------------------
for _, eventName in ipairs(bindableEvents) do
    if not eventsFolder:FindFirstChild(eventName) then
        local event = Instance.new("BindableEvent")
        event.Name = eventName
        event.Parent = eventsFolder
    end
end

print("[SetupEvents] Все события созданы: " .. #remoteEvents .. " RemoteEvents, " .. #bindableEvents .. " BindableEvents")
