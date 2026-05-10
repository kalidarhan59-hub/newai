-- SetupEvents: создаёт RemoteEvents и RemoteFunctions
-- Вставь ПЕРВЫМ в ServerScriptService (тип Script)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local events = {
	"PlayerDied",           -- Игрок умер
	"PlayerCheckpoint",     -- Игрок достиг чекпоинта
	"PlayerFinished",       -- Игрок дошёл до конца
	"TowerShuffled",        -- Башня обновилась
	"UpdateTimer",          -- Обновление таймера
	"UpdateFloor",          -- Обновление номера этажа
	"UpdateDeaths",         -- Обновление счётчика смертей
	"ShowNotification",     -- Показать уведомление
	"RequestRespawn",       -- Запрос респавна
}

for _, eventName in ipairs(events) do
	if not ReplicatedStorage:FindFirstChild(eventName) then
		local event = Instance.new("RemoteEvent")
		event.Name = eventName
		event.Parent = ReplicatedStorage
	end
end

print("[SetupEvents] Все RemoteEvents созданы (" .. #events .. " шт.)")
