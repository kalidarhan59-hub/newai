--[[
    LobbySystem.server.lua
    Система лобби — matchmaking и запуск игры
    Расположение: ServerScriptService/LobbySystem.server.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TeleportService = game:GetService("TeleportService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local LobbyUpdate = Events:WaitForChild("LobbyUpdate")
local PlayerReady = Events:WaitForChild("PlayerReady")
local GameStateChanged = Events:WaitForChild("GameStateChanged")
local ShowHint = Events:WaitForChild("ShowHint")

-- API GameManager
local GameManagerFunctions = ServerStorage:WaitForChild("GameManagerFunctions")

---------------------------------------------------------------------
-- Состояние лобби
---------------------------------------------------------------------
local LobbyState = {
    PlayersReady = {}, -- [Player] = true/false
    CountdownActive = false,
    CountdownTime = GameConfig.LOBBY_COUNTDOWN,
    IsGameRunning = false,
}

---------------------------------------------------------------------
-- Обновить UI лобби для всех игроков
---------------------------------------------------------------------
local function broadcastLobbyUpdate()
    local readyCount = 0
    local totalPlayers = #Players:GetPlayers()
    local playerList = {}

    for _, player in ipairs(Players:GetPlayers()) do
        local isReady = LobbyState.PlayersReady[player] or false
        if isReady then
            readyCount = readyCount + 1
        end
        table.insert(playerList, {
            Name = player.Name,
            DisplayName = player.DisplayName,
            IsReady = isReady,
        })
    end

    LobbyUpdate:FireAllClients({
        Players = playerList,
        ReadyCount = readyCount,
        TotalPlayers = totalPlayers,
        MinPlayers = GameConfig.MIN_PLAYERS_TO_START,
        MaxPlayers = GameConfig.MAX_PLAYERS,
        CountdownActive = LobbyState.CountdownActive,
        CountdownTime = LobbyState.CountdownTime,
    })
end

---------------------------------------------------------------------
-- Проверить готовность к старту
---------------------------------------------------------------------
local function checkStartConditions()
    if LobbyState.IsGameRunning then return end

    local readyCount = 0
    local totalPlayers = #Players:GetPlayers()

    for _, player in ipairs(Players:GetPlayers()) do
        if LobbyState.PlayersReady[player] then
            readyCount = readyCount + 1
        end
    end

    -- Нужно минимум MIN_PLAYERS и все должны быть готовы
    if totalPlayers >= GameConfig.MIN_PLAYERS_TO_START and readyCount == totalPlayers then
        startCountdown()
    elseif LobbyState.CountdownActive then
        cancelCountdown()
    end
end

---------------------------------------------------------------------
-- Обратный отсчёт
---------------------------------------------------------------------
function startCountdown()
    if LobbyState.CountdownActive then return end

    LobbyState.CountdownActive = true
    LobbyState.CountdownTime = GameConfig.LOBBY_COUNTDOWN

    broadcastLobbyUpdate()
    ShowHint:FireAllClients("Все готовы! Игра начнётся через " .. LobbyState.CountdownTime .. " секунд...")

    task.spawn(function()
        while LobbyState.CountdownActive and LobbyState.CountdownTime > 0 do
            task.wait(1)
            LobbyState.CountdownTime = LobbyState.CountdownTime - 1

            if LobbyState.CountdownTime <= 5 and LobbyState.CountdownTime > 0 then
                ShowHint:FireAllClients(tostring(LobbyState.CountdownTime) .. "...")
            end

            broadcastLobbyUpdate()
        end

        if LobbyState.CountdownActive then
            LobbyState.CountdownActive = false
            launchGame()
        end
    end)
end

function cancelCountdown()
    if not LobbyState.CountdownActive then return end

    LobbyState.CountdownActive = false
    LobbyState.CountdownTime = GameConfig.LOBBY_COUNTDOWN
    broadcastLobbyUpdate()
    ShowHint:FireAllClients("Обратный отсчёт отменён — не все игроки готовы.")
end

---------------------------------------------------------------------
-- Запуск игры
---------------------------------------------------------------------
function launchGame()
    LobbyState.IsGameRunning = true

    -- Уведомить всех
    ShowHint:FireAllClients("Игра начинается!")

    -- Затемнение экрана (клиент обработает)
    GameStateChanged:FireAllClients(SharedTypes.GameState.Starting, {
        Message = "Вы приезжаете к заброшенной больнице «Тихая Гавань»...",
        FadeTime = 3,
    })

    -- Подождать fade
    task.wait(3)

    -- Телепортировать игроков на карту
    local spawnPoints = workspace:FindFirstChild("GameSpawnPoints")
    local spawnList = {}

    if spawnPoints then
        for _, spawn in ipairs(spawnPoints:GetChildren()) do
            if spawn:IsA("BasePart") then
                table.insert(spawnList, spawn)
            end
        end
    end

    for i, player in ipairs(Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local spawnPoint
            if #spawnList > 0 then
                spawnPoint = spawnList[((i - 1) % #spawnList) + 1]
                character.HumanoidRootPart.CFrame = spawnPoint.CFrame + Vector3.new(0, 3, 0)
            else
                -- Спавн по умолчанию если нет точек
                character.HumanoidRootPart.CFrame = CFrame.new(0, 10, 0) + Vector3.new(i * 3, 0, 0)
            end
        end
    end

    -- Запустить GameManager
    GameManagerFunctions:Invoke("StartGame")

    print("[LobbySystem] Игра запущена с " .. #Players:GetPlayers() .. " игроками")
end

---------------------------------------------------------------------
-- Конец игры — возврат в лобби
---------------------------------------------------------------------
local function returnToLobby()
    LobbyState.IsGameRunning = false
    LobbyState.PlayersReady = {}
    LobbyState.CountdownActive = false
    LobbyState.CountdownTime = GameConfig.LOBBY_COUNTDOWN

    broadcastLobbyUpdate()
end

---------------------------------------------------------------------
-- Обработка действий игроков
---------------------------------------------------------------------
PlayerReady.OnServerEvent:Connect(function(player, isReady)
    if LobbyState.IsGameRunning then return end

    LobbyState.PlayersReady[player] = isReady
    broadcastLobbyUpdate()
    checkStartConditions()

    if isReady then
        ShowHint:FireAllClients(player.DisplayName .. " готов!")
    else
        ShowHint:FireAllClients(player.DisplayName .. " не готов.")
    end
end)

---------------------------------------------------------------------
-- Обработка входа/выхода игроков
---------------------------------------------------------------------
Players.PlayerAdded:Connect(function(player)
    LobbyState.PlayersReady[player] = false

    -- Подождать появления персонажа
    player.CharacterAdded:Connect(function(character)
        if not LobbyState.IsGameRunning then
            -- Телепортировать в лобби
            local lobbySpawn = workspace:FindFirstChild("LobbySpawn")
            if lobbySpawn then
                task.wait(0.5)
                local rootPart = character:WaitForChild("HumanoidRootPart")
                rootPart.CFrame = lobbySpawn.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end)

    task.wait(1) -- подождать загрузку
    broadcastLobbyUpdate()

    ShowHint:FireClient(player, "Добро пожаловать в Dead Silence! Нажмите 'Готов' для начала.")
    ShowHint:FireAllClients(player.DisplayName .. " присоединился. (" ..
        #Players:GetPlayers() .. "/" .. GameConfig.MAX_PLAYERS .. ")")
end)

Players.PlayerRemoving:Connect(function(player)
    LobbyState.PlayersReady[player] = nil

    if not LobbyState.IsGameRunning then
        checkStartConditions()
        broadcastLobbyUpdate()
    end
end)

---------------------------------------------------------------------
-- Слушаем конец игры от GameManager
---------------------------------------------------------------------
local GameEnded = Events:WaitForChild("GameEnded")
GameEnded.OnClientEvent:Connect(function(result, message)
    task.delay(15, function()
        returnToLobby()
    end)
end)

print("[LobbySystem] Система лобби инициализирована.")
print("[LobbySystem] Ожидание минимум " .. GameConfig.MIN_PLAYERS_TO_START .. " игроков...")
