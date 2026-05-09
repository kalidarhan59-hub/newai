--[[
    GameManager.server.lua
    Главный серверный скрипт — управляет состоянием игры
    Расположение: ServerScriptService/GameManager.server.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)
local InventoryModule = require(ReplicatedStorage.Modules.InventoryModule)

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local GameStateChanged = Events:WaitForChild("GameStateChanged")
local PlayerStateChanged = Events:WaitForChild("PlayerStateChanged")
local PlayerDamaged = Events:WaitForChild("PlayerDamaged")
local ItemPickedUp = Events:WaitForChild("ItemPickedUp")
local ItemUsed = Events:WaitForChild("ItemUsed")
local ItemDropped = Events:WaitForChild("ItemDropped")
local ItemGiven = Events:WaitForChild("ItemGiven")
local InteractionRequest = Events:WaitForChild("InteractionRequest")
local FearUpdated = Events:WaitForChild("FearUpdated")
local ShowHint = Events:WaitForChild("ShowHint")
local PlayerRevived = Events:WaitForChild("PlayerRevived")
local NoiseGenerated = Events:WaitForChild("NoiseGenerated")
local MonsterAlert = Events:WaitForChild("MonsterAlert")
local GameEnded = Events:WaitForChild("GameEnded")

---------------------------------------------------------------------
-- Состояние игры
---------------------------------------------------------------------
local GameState = {
    CurrentState = SharedTypes.GameState.Lobby,
    StartTime = 0,
    ElapsedTime = 0,
    PlayerData = {}, -- [Player] = PlayerData
    Inventories = {}, -- [Player] = InventoryModule
    KeyItemsCollected = 0,
    PuzzlesCompleted = 0,
    MonsterSpawned = false,
}

---------------------------------------------------------------------
-- Вспомогательные функции
---------------------------------------------------------------------
local function getAlivePlayers()
    local alive = {}
    for player, data in pairs(GameState.PlayerData) do
        if data.State == SharedTypes.PlayerState.Alive then
            table.insert(alive, player)
        end
    end
    return alive
end

local function getPlayerCount()
    local count = 0
    for _ in pairs(GameState.PlayerData) do
        count = count + 1
    end
    return count
end

local function broadcastGameState()
    GameStateChanged:FireAllClients(GameState.CurrentState, {
        ElapsedTime = GameState.ElapsedTime,
        KeyItemsCollected = GameState.KeyItemsCollected,
        PuzzlesCompleted = GameState.PuzzlesCompleted,
        PlayersAlive = #getAlivePlayers(),
    })
end

local function sendHint(player, message, duration)
    ShowHint:FireClient(player, message, duration or GameConfig.UI.HintDuration)
end

local function sendHintToAll(message, duration)
    ShowHint:FireAllClients(message, duration or GameConfig.UI.HintDuration)
end

---------------------------------------------------------------------
-- Управление игроками
---------------------------------------------------------------------
local function initializePlayer(player)
    local data = SharedTypes.CreatePlayerData(player)
    GameState.PlayerData[player] = data
    GameState.Inventories[player] = InventoryModule.new(GameConfig.Player.InventorySlots)

    -- Установить скорость ходьбы
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.WalkSpeed = GameConfig.Player.WalkSpeed

    PlayerStateChanged:FireAllClients(player, data.State, data.Health)
    sendHint(player, "Добро пожаловать в «Тихую Гавань». Найдите выход...")
end

local function removePlayer(player)
    GameState.PlayerData[player] = nil
    GameState.Inventories[player] = nil

    -- Проверить конец игры
    if GameState.CurrentState == SharedTypes.GameState.Playing then
        local alive = getAlivePlayers()
        if #alive == 0 then
            endGame(SharedTypes.GameResult.AllDead)
        end
    end
end

---------------------------------------------------------------------
-- Система здоровья
---------------------------------------------------------------------
local function damagePlayer(player, amount)
    local data = GameState.PlayerData[player]
    if not data or data.State ~= SharedTypes.PlayerState.Alive then return end

    data.Health = math.max(0, data.Health - (amount or 1))
    PlayerDamaged:FireAllClients(player, data.Health)

    if data.Health <= 0 then
        data.State = SharedTypes.PlayerState.Ghost
        data.GhostTimer = GameConfig.Player.GhostDuration
        PlayerStateChanged:FireAllClients(player, data.State, 0)
        sendHintToAll(player.Name .. " погиб! У вас " .. data.GhostTimer .. " секунд чтобы воскресить.")

        -- Выбросить инвентарь
        local inventory = GameState.Inventories[player]
        if inventory then
            local items = inventory:GetAllItems()
            for _, item in pairs(items) do
                -- Спавнить предмет на карте в позиции игрока
                spawnDroppedItem(player, item.ItemType, item.ItemId)
            end
            inventory:Clear()
        end
    end
end

local function healPlayer(player, amount)
    local data = GameState.PlayerData[player]
    if not data or data.State ~= SharedTypes.PlayerState.Alive then return end

    data.Health = math.min(GameConfig.Player.MaxHealth, data.Health + (amount or 1))
    PlayerDamaged:FireAllClients(player, data.Health)
end

---------------------------------------------------------------------
-- Система воскрешения
---------------------------------------------------------------------
local function revivePlayer(reviver, target)
    local reviverData = GameState.PlayerData[reviver]
    local targetData = GameState.PlayerData[target]

    if not reviverData or reviverData.State ~= SharedTypes.PlayerState.Alive then return end
    if not targetData or targetData.State ~= SharedTypes.PlayerState.Ghost then return end

    -- Проверить расстояние (должны быть рядом)
    local reviverChar = reviver.Character
    local targetChar = target.Character
    if not reviverChar or not targetChar then return end

    local distance = (reviverChar.HumanoidRootPart.Position - targetChar.HumanoidRootPart.Position).Magnitude
    if distance > 10 then
        sendHint(reviver, "Подойдите ближе к " .. target.Name)
        return
    end

    -- Воскрешение
    targetData.State = SharedTypes.PlayerState.Alive
    targetData.Health = 1
    targetData.Fear = 50
    targetData.GhostTimer = nil

    PlayerRevived:FireAllClients(reviver, target)
    PlayerStateChanged:FireAllClients(target, targetData.State, targetData.Health)
    sendHintToAll(reviver.Name .. " воскресил " .. target.Name .. "!")

    -- Генерируем шум (воскрешение шумный процесс)
    generateNoise(reviver, GameConfig.NoiseLevel.Normal)
end

---------------------------------------------------------------------
-- Система предметов
---------------------------------------------------------------------
function spawnDroppedItem(player, itemType, itemId)
    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Создать предмет на карте (Part с BillboardGui)
    local itemPart = Instance.new("Part")
    itemPart.Name = "DroppedItem_" .. itemType
    itemPart.Size = Vector3.new(1, 1, 1)
    itemPart.Position = rootPart.Position + Vector3.new(math.random(-3, 3), 0, math.random(-3, 3))
    itemPart.Anchored = true
    itemPart.CanCollide = false
    itemPart.BrickColor = BrickColor.new("Bright yellow")
    itemPart.Material = Enum.Material.Neon

    -- Атрибуты для идентификации
    itemPart:SetAttribute("ItemType", itemType)
    itemPart:SetAttribute("ItemId", itemId)
    itemPart:SetAttribute("Interactable", true)

    -- Billboard для отображения имени
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 30)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = itemPart

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = GameConfig.Items[itemType] and GameConfig.Items[itemType].Name or itemType
    label.TextColor3 = Color3.fromRGB(255, 255, 100)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    -- ProximityPrompt для подбора
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Подобрать"
    prompt.ObjectText = label.Text
    prompt.HoldDuration = 0.3
    prompt.MaxActivationDistance = 8
    prompt.Parent = itemPart

    prompt.Triggered:Connect(function(triggerPlayer)
        local inventory = GameState.Inventories[triggerPlayer]
        if not inventory then return end

        local success, slot = inventory:AddItem(itemType, itemId)
        if success then
            itemPart:Destroy()
            ItemPickedUp:FireClient(triggerPlayer, itemType, slot)
            ItemPickedUp:FireAllClients(triggerPlayer, itemType)
            generateNoise(triggerPlayer, GameConfig.NoiseLevel.Quiet)

            -- Проверить ключевой предмет
            if itemType == SharedTypes.ItemType.KeyItem then
                GameState.KeyItemsCollected = GameState.KeyItemsCollected + 1
                sendHintToAll("Ключевой предмет найден! (" .. GameState.KeyItemsCollected .. "/" .. GameConfig.Puzzles.KeyItemsTotal .. ")")
            end
        else
            sendHint(triggerPlayer, "Инвентарь полон!")
        end
    end)

    itemPart.Parent = workspace:FindFirstChild("DroppedItems") or workspace
end

local function useItem(player, slot)
    local inventory = GameState.Inventories[player]
    local data = GameState.PlayerData[player]
    if not inventory or not data then return end

    local item = inventory:GetItem(slot)
    if not item then return end

    local used = false
    local itemType = item.ItemType

    if itemType == SharedTypes.ItemType.Battery then
        data.FlashlightBattery = math.min(GameConfig.Flashlight.MaxBattery,
            data.FlashlightBattery + GameConfig.Flashlight.BatteryRestoreAmount)
        sendHint(player, "Батарея фонарика заряжена")
        used = true

    elseif itemType == SharedTypes.ItemType.Bandage then
        if data.Health < GameConfig.Player.MaxHealth then
            healPlayer(player, 1)
            sendHint(player, "Здоровье восстановлено")
            used = true
        else
            sendHint(player, "Здоровье уже полное")
        end

    elseif itemType == SharedTypes.ItemType.Note then
        -- Показать текст записки (генерируется из головоломок)
        ItemUsed:FireClient(player, itemType, item.ItemId)
        used = true
    end

    if used then
        inventory:RemoveItem(slot)
        ItemUsed:FireAllClients(player, itemType)
        generateNoise(player, GameConfig.NoiseLevel.Quiet)
    end
end

local function giveItem(giver, receiver, slot)
    local giverInv = GameState.Inventories[giver]
    local receiverInv = GameState.Inventories[receiver]
    if not giverInv or not receiverInv then return end

    local item = giverInv:GetItem(slot)
    if not item then
        sendHint(giver, "Нет предмета в этом слоте")
        return
    end

    -- Проверить расстояние
    local giverChar = giver.Character
    local receiverChar = receiver.Character
    if not giverChar or not receiverChar then return end

    local distance = (giverChar.HumanoidRootPart.Position - receiverChar.HumanoidRootPart.Position).Magnitude
    if distance > 10 then
        sendHint(giver, "Подойдите ближе к " .. receiver.Name)
        return
    end

    local success, newSlot = receiverInv:AddItem(item.ItemType, item.ItemId)
    if success then
        giverInv:RemoveItem(slot)
        ItemGiven:FireClient(giver, receiver, item.ItemType, slot)
        ItemGiven:FireClient(receiver, giver, item.ItemType, newSlot)
        sendHint(giver, "Вы передали " .. (GameConfig.Items[item.ItemType] and GameConfig.Items[item.ItemType].Name or item.ItemType))
        sendHint(receiver, giver.Name .. " передал вам предмет")
    else
        sendHint(giver, "У " .. receiver.Name .. " полный инвентарь")
    end
end

---------------------------------------------------------------------
-- Система шума
---------------------------------------------------------------------
function generateNoise(player, noiseLevel)
    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Уведомить монстра через MonsterAlert
    MonsterAlert:Fire(rootPart.Position, noiseLevel, player)

    -- Уведомить клиентов о шуме (для визуальных эффектов)
    NoiseGenerated:FireAllClients(rootPart.Position, noiseLevel)
end

---------------------------------------------------------------------
-- Обновление страха (серверная логика)
---------------------------------------------------------------------
local function updateFear(player, deltaTime)
    local data = GameState.PlayerData[player]
    if not data or data.State ~= SharedTypes.PlayerState.Alive then return end

    local character = player.Character
    if not character then return end

    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local fearDelta = 0

    -- Темнота (проверяем освещённость зоны)
    -- Упрощённая проверка: если фонарик выключен, считаем что темно
    if not data.FlashlightOn then
        fearDelta = fearDelta + GameConfig.Fear.DarknessRate * deltaTime
    else
        fearDelta = fearDelta - GameConfig.Fear.LightReduction * deltaTime
    end

    -- Одиночество
    local nearbyPlayers = 0
    for otherPlayer, otherData in pairs(GameState.PlayerData) do
        if otherPlayer ~= player and otherData.State == SharedTypes.PlayerState.Alive then
            local otherChar = otherPlayer.Character
            if otherChar and otherChar:FindFirstChild("HumanoidRootPart") then
                local dist = (rootPart.Position - otherChar.HumanoidRootPart.Position).Magnitude
                if dist < 30 then
                    nearbyPlayers = nearbyPlayers + 1
                end
            end
        end
    end

    if nearbyPlayers == 0 then
        fearDelta = fearDelta + GameConfig.Fear.AloneRate * deltaTime
    else
        fearDelta = fearDelta - GameConfig.Fear.NearPlayerReduction * nearbyPlayers * deltaTime
    end

    -- Применить страх
    data.Fear = math.clamp(data.Fear + fearDelta, 0, GameConfig.Fear.MaxFear)
    FearUpdated:FireClient(player, data.Fear)

    -- Паника при максимальном страхе
    if data.Fear >= GameConfig.Fear.MaxPanicThreshold and not data.IsPanicking then
        data.IsPanicking = true
        sendHint(player, "ПАНИКА! Вы кричите!")
        generateNoise(player, GameConfig.NoiseLevel.VeryLoud)

        -- Сбросить панику через несколько секунд
        task.delay(GameConfig.Fear.InvertControlsDuration, function()
            if GameState.PlayerData[player] then
                data.IsPanicking = false
                data.Fear = GameConfig.Fear.PanicThreshold - 10
            end
        end)
    end
end

---------------------------------------------------------------------
-- Обновление духов (таймер воскрешения)
---------------------------------------------------------------------
local function updateGhosts(deltaTime)
    for player, data in pairs(GameState.PlayerData) do
        if data.State == SharedTypes.PlayerState.Ghost then
            data.GhostTimer = (data.GhostTimer or 0) - deltaTime
            if data.GhostTimer <= 0 then
                data.State = SharedTypes.PlayerState.Dead
                PlayerStateChanged:FireAllClients(player, data.State, 0)
                sendHintToAll(player.Name .. " окончательно погиб.")

                -- Проверить конец игры
                local alive = getAlivePlayers()
                if #alive == 0 then
                    endGame(SharedTypes.GameResult.AllDead)
                end
            end
        end
    end
end

---------------------------------------------------------------------
-- Управление состоянием игры
---------------------------------------------------------------------
local function startGame()
    GameState.CurrentState = SharedTypes.GameState.Playing
    GameState.StartTime = os.clock()
    GameState.KeyItemsCollected = 0
    GameState.PuzzlesCompleted = 0
    GameState.MonsterSpawned = false

    -- Инициализировать всех игроков
    for _, player in ipairs(Players:GetPlayers()) do
        initializePlayer(player)
    end

    broadcastGameState()
    sendHintToAll("Игра началась! Исследуйте больницу и найдите выход.")

    -- Запустить спавн монстра через задержку
    task.delay(GameConfig.MONSTER_SPAWN_DELAY, function()
        if GameState.CurrentState == SharedTypes.GameState.Playing then
            GameState.MonsterSpawned = true
            MonsterAlert:Fire(nil, 0, nil) -- Сигнал для спавна монстра
            sendHintToAll("Вы слышите тяжёлые шаги... Существо пробудилось!")
        end
    end)
end

function endGame(result)
    if GameState.CurrentState ~= SharedTypes.GameState.Playing then return end

    GameState.CurrentState = SharedTypes.GameState.Ending
    broadcastGameState()

    local message
    if result == SharedTypes.GameResult.Escaped then
        message = "Вы сбежали из больницы!"
    elseif result == SharedTypes.GameResult.AllDead then
        message = "Все игроки погибли... Больница поглотила вас."
    elseif result == SharedTypes.GameResult.TimeOut then
        message = "Время вышло... Двери захлопнулись навсегда."
    end

    GameEnded:FireAllClients(result, message)
    sendHintToAll(message, 10)

    -- Вернуться в лобби через 15 секунд
    task.delay(15, function()
        GameState.CurrentState = SharedTypes.GameState.Lobby
        GameState.PlayerData = {}
        GameState.Inventories = {}
        broadcastGameState()

        -- Телепортировать игроков в лобби
        for _, player in ipairs(Players:GetPlayers()) do
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                local lobbySpawn = workspace:FindFirstChild("LobbySpawn")
                if lobbySpawn then
                    character.HumanoidRootPart.CFrame = lobbySpawn.CFrame
                end
            end
        end
    end)
end

---------------------------------------------------------------------
-- Обработка взаимодействий от клиента
---------------------------------------------------------------------
InteractionRequest.OnServerEvent:Connect(function(player, interactionType, data)
    local playerData = GameState.PlayerData[player]
    if not playerData then return end

    if interactionType == SharedTypes.InteractionType.UseItem then
        useItem(player, data.Slot)

    elseif interactionType == SharedTypes.InteractionType.GiveItem then
        local receiver = Players:FindFirstChild(data.ReceiverName)
        if receiver then
            giveItem(player, receiver, data.Slot)
        end

    elseif interactionType == SharedTypes.InteractionType.RevivePlayer then
        local target = Players:FindFirstChild(data.TargetName)
        if target then
            revivePlayer(player, target)
        end

    elseif interactionType == SharedTypes.InteractionType.OpenDoor then
        -- Обработка открытия дверей
        local door = workspace:FindFirstChild(data.DoorName)
        if door then
            local locked = door:GetAttribute("Locked")
            if locked then
                local requiredKey = door:GetAttribute("RequiredKey")
                local inventory = GameState.Inventories[player]
                if inventory and inventory:HasItem(requiredKey or SharedTypes.ItemType.Key) then
                    inventory:RemoveItemByType(requiredKey or SharedTypes.ItemType.Key)
                    door:SetAttribute("Locked", false)
                    sendHintToAll(player.Name .. " открыл дверь!")
                    generateNoise(player, GameConfig.NoiseLevel.Normal)
                else
                    sendHint(player, "Дверь заперта. Нужен ключ.")
                end
            else
                generateNoise(player, GameConfig.NoiseLevel.Quiet)
            end
        end
    end
end)

---------------------------------------------------------------------
-- Обработка входа/выхода игроков
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    if GameState.CurrentState == SharedTypes.GameState.Lobby then
        sendHint(player, "Ожидание игроков... (" .. #Players:GetPlayers() .. "/" .. GameConfig.MIN_PLAYERS_TO_START .. ")")
    end

    player.CharacterAdded:Connect(function(character)
        if GameState.CurrentState == SharedTypes.GameState.Playing then
            initializePlayer(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayer(player)
end)

---------------------------------------------------------------------
-- Главный игровой цикл
---------------------------------------------------------------------
local lastUpdate = os.clock()

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    local deltaTime = now - lastUpdate
    lastUpdate = now

    if GameState.CurrentState ~= SharedTypes.GameState.Playing then return end

    -- Обновить прошедшее время
    GameState.ElapsedTime = now - GameState.StartTime

    -- Проверить лимит времени
    if GameState.ElapsedTime >= GameConfig.SESSION_TIME_LIMIT then
        endGame(SharedTypes.GameResult.TimeOut)
        return
    end

    -- Обновить страх для каждого игрока
    for player, _ in pairs(GameState.PlayerData) do
        if player.Parent then -- игрок ещё в игре
            updateFear(player, deltaTime)
        end
    end

    -- Обновить духов
    updateGhosts(deltaTime)
end)

---------------------------------------------------------------------
-- Экспорт для других серверных скриптов
---------------------------------------------------------------------
-- BindableEvent для коммуникации между серверными скриптами
local GameManagerAPI = Instance.new("BindableEvent")
GameManagerAPI.Name = "GameManagerAPI"
GameManagerAPI.Parent = ServerStorage

-- Функция для внешнего обращения
local GameManagerFunctions = Instance.new("BindableFunction")
GameManagerFunctions.Name = "GameManagerFunctions"
GameManagerFunctions.Parent = ServerStorage

GameManagerFunctions.OnInvoke = function(action, ...)
    if action == "DamagePlayer" then
        local player, amount = ...
        damagePlayer(player, amount)
    elseif action == "GetPlayerData" then
        local player = ...
        return GameState.PlayerData[player]
    elseif action == "GetGameState" then
        return GameState.CurrentState
    elseif action == "GetAlivePlayers" then
        return getAlivePlayers()
    elseif action == "GenerateNoise" then
        local player, level = ...
        generateNoise(player, level)
    elseif action == "StartGame" then
        startGame()
    elseif action == "EndGame" then
        local result = ...
        endGame(result)
    elseif action == "KeyItemCollected" then
        GameState.KeyItemsCollected = GameState.KeyItemsCollected + 1
        if GameState.KeyItemsCollected >= GameConfig.Puzzles.KeyItemsTotal then
            sendHintToAll("Все ключевые предметы собраны! Бегите к финальной двери!")
        end
    elseif action == "PuzzleCompleted" then
        GameState.PuzzlesCompleted = GameState.PuzzlesCompleted + 1
    elseif action == "GetMonsterAggression" then
        -- Вычислить множитель агрессии
        local aggression = 1.0
        for _, entry in ipairs(GameConfig.Difficulty.AggressionMultiplier) do
            if GameState.KeyItemsCollected >= entry.items then
                aggression = entry.mult
            end
        end
        -- Добавить множитель по времени
        for _, entry in ipairs(GameConfig.Difficulty.SpeedMultiplier) do
            if GameState.ElapsedTime >= entry.time then
                aggression = aggression * entry.mult
            end
        end
        return aggression
    end
end

print("[GameManager] Инициализирован. Ожидание игроков...")
