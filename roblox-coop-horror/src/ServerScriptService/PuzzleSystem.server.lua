--[[
    PuzzleSystem.server.lua
    Система головоломок — управляет всеми головоломками на карте
    Расположение: ServerScriptService/PuzzleSystem.server.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local PuzzleInteraction = Events:WaitForChild("PuzzleInteraction")
local PuzzleCompleted = Events:WaitForChild("PuzzleCompleted")
local PuzzleHint = Events:WaitForChild("PuzzleHint")
local ShowHint = Events:WaitForChild("ShowHint")
local MonsterAlert = Events:WaitForChild("MonsterAlert")

-- API GameManager
local GameManagerFunctions = ServerStorage:WaitForChild("GameManagerFunctions")

---------------------------------------------------------------------
-- Состояние головоломок
---------------------------------------------------------------------
local Puzzles = {
    -- Головоломка 1: Предохранители
    FuseBox = {
        Type = SharedTypes.PuzzleType.FuseBox,
        Status = SharedTypes.PuzzleStatus.Available,
        FusesInserted = 0,
        FusesRequired = GameConfig.Puzzles.FuseCount,
        Reward = "KeyItem", -- при завершении выдаёт ключевой предмет
    },

    -- Головоломка 2: Код от сейфа
    SafeCode = {
        Type = SharedTypes.PuzzleType.SafeCode,
        Status = SharedTypes.PuzzleStatus.Available,
        CorrectCode = nil, -- генерируется при старте
        Attempts = 0,
        MaxAttempts = 5,
        NotesFound = {},
        Reward = "KeyItem",
    },

    -- Головоломка 3: Ритуал в морге
    MorgueRitual = {
        Type = SharedTypes.PuzzleType.MorgueRitual,
        Status = SharedTypes.PuzzleStatus.Available,
        CandlesPlaced = {},
        CorrectOrder = nil, -- генерируется при старте
        RequiresPlayers = 2,
        Reward = "KeyItem",
    },

    -- Головоломка 4: Лаборатория
    LabReagents = {
        Type = SharedTypes.PuzzleType.LabReagents,
        Status = SharedTypes.PuzzleStatus.Available,
        CorrectSequence = nil, -- генерируется при старте
        CurrentMix = {},
        Reward = "KeyItem",
    },

    -- Головоломка 5: Финальная дверь
    FinalDoor = {
        Type = SharedTypes.PuzzleType.FinalDoor,
        Status = SharedTypes.PuzzleStatus.Locked, -- открывается после сбора всех предметов
        KeyItemsRequired = GameConfig.Puzzles.KeyItemsTotal,
        IsOpening = false,
        OpenTimer = 0,
        Reward = "Escape",
    },
}

---------------------------------------------------------------------
-- Генерация случайных данных при старте
---------------------------------------------------------------------
local function generatePuzzleData()
    -- Код сейфа (4 случайные цифры)
    local code = ""
    for i = 1, GameConfig.Puzzles.SafeCodeLength do
        code = code .. tostring(math.random(0, 9))
    end
    Puzzles.SafeCode.CorrectCode = code

    -- Записки с подсказками (каждая содержит одну цифру и позицию)
    Puzzles.SafeCode.NoteHints = {}
    for i = 1, #code do
        table.insert(Puzzles.SafeCode.NoteHints, {
            Position = i,
            Digit = code:sub(i, i),
            HintText = "Цифра " .. i .. " кода: " .. code:sub(i, i) ..
                       " (запись пациента #" .. math.random(100, 999) .. ")",
        })
    end

    -- Порядок свечей для ритуала
    local candlePositions = {"Север", "Юг", "Запад", "Восток"}
    Puzzles.MorgueRitual.CorrectOrder = {}
    local shuffled = {table.unpack(candlePositions)}
    for i = #shuffled, 2, -1 do
        local j = math.random(1, i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    Puzzles.MorgueRitual.CorrectOrder = shuffled

    -- Последовательность реагентов
    local reagentColors = {"Красный", "Синий", "Зелёный"}
    local shuffledReagents = {table.unpack(reagentColors)}
    for i = #shuffledReagents, 2, -1 do
        local j = math.random(1, i)
        shuffledReagents[i], shuffledReagents[j] = shuffledReagents[j], shuffledReagents[i]
    end
    Puzzles.LabReagents.CorrectSequence = shuffledReagents

    print("[PuzzleSystem] Данные головоломок сгенерированы")
    print("  Код сейфа: " .. code)
    print("  Порядок свечей: " .. table.concat(Puzzles.MorgueRitual.CorrectOrder, ", "))
    print("  Реагенты: " .. table.concat(Puzzles.LabReagents.CorrectSequence, ", "))
end

---------------------------------------------------------------------
-- Головоломка: Предохранители
---------------------------------------------------------------------
local function handleFuseBox(player, action, data)
    local puzzle = Puzzles.FuseBox
    if puzzle.Status == SharedTypes.PuzzleStatus.Completed then
        ShowHint:FireClient(player, "Электрощит уже работает.")
        return
    end

    if action == "InsertFuse" then
        -- Проверить есть ли предохранитель у игрока (через GameManager)
        local playerData = GameManagerFunctions:Invoke("GetPlayerData", player)
        if not playerData then return end

        -- Проверка инвентаря (отправляем запрос)
        PuzzleInteraction:FireClient(player, "CheckInventory", {
            ItemType = SharedTypes.ItemType.Fuse,
            PuzzleType = SharedTypes.PuzzleType.FuseBox,
        })

    elseif action == "ConfirmFuse" then
        puzzle.FusesInserted = puzzle.FusesInserted + 1
        ShowHint:FireAllClients("Предохранитель вставлен! (" ..
            puzzle.FusesInserted .. "/" .. puzzle.FusesRequired .. ")")

        -- Шум от вставки предохранителя
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            MonsterAlert:Fire(character.HumanoidRootPart.Position, GameConfig.NoiseLevel.Normal, player)
        end

        if puzzle.FusesInserted >= puzzle.FusesRequired then
            puzzle.Status = SharedTypes.PuzzleStatus.Completed
            PuzzleCompleted:FireAllClients(SharedTypes.PuzzleType.FuseBox)
            ShowHint:FireAllClients("Электричество восстановлено! Свет загорелся на 2 этаже.")
            GameManagerFunctions:Invoke("PuzzleCompleted")
            GameManagerFunctions:Invoke("KeyItemCollected")

            -- Включить свет на этаже (настраивается в Roblox Studio)
            local floor2Lights = workspace:FindFirstChild("Floor2Lights")
            if floor2Lights then
                for _, light in ipairs(floor2Lights:GetDescendants()) do
                    if light:IsA("PointLight") or light:IsA("SpotLight") then
                        light.Enabled = true
                    end
                end
            end
        end
    end
end

---------------------------------------------------------------------
-- Головоломка: Код от сейфа
---------------------------------------------------------------------
local function handleSafeCode(player, action, data)
    local puzzle = Puzzles.SafeCode
    if puzzle.Status == SharedTypes.PuzzleStatus.Completed then
        ShowHint:FireClient(player, "Сейф уже открыт.")
        return
    end

    if action == "EnterCode" then
        local enteredCode = data.Code
        if not enteredCode then return end

        puzzle.Attempts = puzzle.Attempts + 1

        if enteredCode == puzzle.CorrectCode then
            puzzle.Status = SharedTypes.PuzzleStatus.Completed
            PuzzleCompleted:FireAllClients(SharedTypes.PuzzleType.SafeCode)
            ShowHint:FireAllClients(player.Name .. " открыл сейф! Получен ключевой предмет.")
            GameManagerFunctions:Invoke("PuzzleCompleted")
            GameManagerFunctions:Invoke("KeyItemCollected")
        else
            -- Подсказка: сколько цифр правильно
            local correct = 0
            for i = 1, math.min(#enteredCode, #puzzle.CorrectCode) do
                if enteredCode:sub(i, i) == puzzle.CorrectCode:sub(i, i) then
                    correct = correct + 1
                end
            end
            ShowHint:FireClient(player, "Неверный код. Правильных цифр на своих местах: " .. correct ..
                " (Попытка " .. puzzle.Attempts .. "/" .. puzzle.MaxAttempts .. ")")

            -- Шум от неудачной попытки
            local character = player.Character
            if character and character:FindFirstChild("HumanoidRootPart") then
                MonsterAlert:Fire(character.HumanoidRootPart.Position, GameConfig.NoiseLevel.Normal, player)
            end

            if puzzle.Attempts >= puzzle.MaxAttempts then
                ShowHint:FireClient(player, "Сейф заблокирован! Подождите 30 секунд...")
                task.delay(30, function()
                    puzzle.Attempts = 0
                    ShowHint:FireClient(player, "Сейф снова доступен для попыток.")
                end)
            end
        end

    elseif action == "ReadNote" then
        -- Показать подсказку из записки
        local noteIndex = data.NoteIndex
        if noteIndex and puzzle.NoteHints[noteIndex] then
            local hint = puzzle.NoteHints[noteIndex]
            PuzzleHint:FireClient(player, hint.HintText)
            puzzle.NotesFound[player] = puzzle.NotesFound[player] or {}
            puzzle.NotesFound[player][noteIndex] = true
        end
    end
end

---------------------------------------------------------------------
-- Головоломка: Ритуал в морге
---------------------------------------------------------------------
local function handleMorgueRitual(player, action, data)
    local puzzle = Puzzles.MorgueRitual
    if puzzle.Status == SharedTypes.PuzzleStatus.Completed then
        ShowHint:FireClient(player, "Ритуал уже завершён.")
        return
    end

    if action == "PlaceCandle" then
        local position = data.Position -- "Север", "Юг", "Запад", "Восток"
        if not position then return end

        -- Проверить количество игроков рядом
        local nearbyPlayers = 0
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local alivePlayers = GameManagerFunctions:Invoke("GetAlivePlayers")
        if alivePlayers then
            for _, p in ipairs(alivePlayers) do
                local pChar = p.Character
                if pChar and pChar:FindFirstChild("HumanoidRootPart") then
                    local dist = (character.HumanoidRootPart.Position - pChar.HumanoidRootPart.Position).Magnitude
                    if dist < 20 then
                        nearbyPlayers = nearbyPlayers + 1
                    end
                end
            end
        end

        if nearbyPlayers < puzzle.RequiresPlayers then
            ShowHint:FireClient(player, "Для ритуала нужно минимум " .. puzzle.RequiresPlayers .. " игрока рядом!")
            return
        end

        table.insert(puzzle.CandlesPlaced, position)
        ShowHint:FireAllClients("Свеча установлена на позицию: " .. position ..
            " (" .. #puzzle.CandlesPlaced .. "/" .. #puzzle.CorrectOrder .. ")")

        -- Проверить правильность
        if #puzzle.CandlesPlaced == #puzzle.CorrectOrder then
            local correct = true
            for i, pos in ipairs(puzzle.CandlesPlaced) do
                if pos ~= puzzle.CorrectOrder[i] then
                    correct = false
                    break
                end
            end

            if correct then
                puzzle.Status = SharedTypes.PuzzleStatus.Completed
                PuzzleCompleted:FireAllClients(SharedTypes.PuzzleType.MorgueRitual)
                ShowHint:FireAllClients("Ритуал завершён! Дух указывает путь...")
                GameManagerFunctions:Invoke("PuzzleCompleted")
                GameManagerFunctions:Invoke("KeyItemCollected")
            else
                ShowHint:FireAllClients("Неверный порядок свечей! Ритуал нужно начать заново.")
                puzzle.CandlesPlaced = {}

                -- Громкий шум — привлекает монстра
                MonsterAlert:Fire(character.HumanoidRootPart.Position, GameConfig.NoiseLevel.Loud, player)
            end
        end
    end
end

---------------------------------------------------------------------
-- Головоломка: Лаборатория
---------------------------------------------------------------------
local function handleLabReagents(player, action, data)
    local puzzle = Puzzles.LabReagents
    if puzzle.Status == SharedTypes.PuzzleStatus.Completed then
        ShowHint:FireClient(player, "Формула уже создана.")
        return
    end

    if action == "AddReagent" then
        local reagent = data.Reagent -- "Красный", "Синий", "Зелёный"
        if not reagent then return end

        table.insert(puzzle.CurrentMix, reagent)
        ShowHint:FireClient(player, "Добавлен реагент: " .. reagent ..
            " (" .. #puzzle.CurrentMix .. "/" .. #puzzle.CorrectSequence .. ")")

        if #puzzle.CurrentMix == #puzzle.CorrectSequence then
            local correct = true
            for i, r in ipairs(puzzle.CurrentMix) do
                if r ~= puzzle.CorrectSequence[i] then
                    correct = false
                    break
                end
            end

            if correct then
                puzzle.Status = SharedTypes.PuzzleStatus.Completed
                PuzzleCompleted:FireAllClients(SharedTypes.PuzzleType.LabReagents)
                ShowHint:FireAllClients("Формула создана! Получен антидот-ключ.")
                GameManagerFunctions:Invoke("PuzzleCompleted")
                GameManagerFunctions:Invoke("KeyItemCollected")
            else
                ShowHint:FireAllClients("Неверная комбинация! Взрыв!")
                puzzle.CurrentMix = {}

                -- Очень громкий шум — взрыв
                local character = player.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    MonsterAlert:Fire(character.HumanoidRootPart.Position, GameConfig.NoiseLevel.VeryLoud, player)
                end

                -- Урон от взрыва
                GameManagerFunctions:Invoke("DamagePlayer", player, 1)
            end
        end

    elseif action == "ResetMix" then
        puzzle.CurrentMix = {}
        ShowHint:FireClient(player, "Смесь сброшена.")
    end
end

---------------------------------------------------------------------
-- Головоломка: Финальная дверь
---------------------------------------------------------------------
local function handleFinalDoor(player, action, data)
    local puzzle = Puzzles.FinalDoor

    if action == "Activate" then
        -- Проверить собраны ли все ключевые предметы
        local completedPuzzles = 0
        for name, p in pairs(Puzzles) do
            if name ~= "FinalDoor" and p.Status == SharedTypes.PuzzleStatus.Completed then
                completedPuzzles = completedPuzzles + 1
            end
        end

        if completedPuzzles < 4 then -- нужно решить все 4 головоломки
            ShowHint:FireClient(player, "Нужно решить все головоломки! (" ..
                completedPuzzles .. "/4)")
            return
        end

        if puzzle.IsOpening then
            ShowHint:FireClient(player, "Дверь уже открывается!")
            return
        end

        puzzle.IsOpening = true
        puzzle.Status = SharedTypes.PuzzleStatus.InProgress
        ShowHint:FireAllClients("ФИНАЛЬНАЯ ДВЕРЬ ОТКРЫВАЕТСЯ! Бегите к выходу! (" ..
            GameConfig.Puzzles.FinalDoorOpenTime .. " секунд)")

        -- Обратный отсчёт
        task.spawn(function()
            for i = GameConfig.Puzzles.FinalDoorOpenTime, 1, -1 do
                task.wait(1)
                puzzle.OpenTimer = i

                if i <= 10 then
                    ShowHint:FireAllClients("Дверь закроется через " .. i .. " секунд!")
                end
            end

            -- Дверь закрылась
            puzzle.IsOpening = false
            puzzle.Status = SharedTypes.PuzzleStatus.Available
            puzzle.OpenTimer = 0
            ShowHint:FireAllClients("Дверь захлопнулась!")
        end)

    elseif action == "Escape" then
        if not puzzle.IsOpening then
            ShowHint:FireClient(player, "Дверь закрыта!")
            return
        end

        -- Игрок сбежал!
        local playerData = GameManagerFunctions:Invoke("GetPlayerData", player)
        if playerData and playerData.State == SharedTypes.PlayerState.Alive then
            playerData.State = SharedTypes.PlayerState.Escaped
            ShowHint:FireAllClients(player.Name .. " СБЕЖАЛ!")

            -- Проверить, все ли живые сбежали
            local alivePlayers = GameManagerFunctions:Invoke("GetAlivePlayers")
            if not alivePlayers or #alivePlayers == 0 then
                GameManagerFunctions:Invoke("EndGame", SharedTypes.GameResult.Escaped)
            end
        end
    end
end

---------------------------------------------------------------------
-- Обработка запросов от клиентов
---------------------------------------------------------------------
PuzzleInteraction.OnServerEvent:Connect(function(player, puzzleType, action, data)
    data = data or {}

    if puzzleType == SharedTypes.PuzzleType.FuseBox then
        handleFuseBox(player, action, data)
    elseif puzzleType == SharedTypes.PuzzleType.SafeCode then
        handleSafeCode(player, action, data)
    elseif puzzleType == SharedTypes.PuzzleType.MorgueRitual then
        handleMorgueRitual(player, action, data)
    elseif puzzleType == SharedTypes.PuzzleType.LabReagents then
        handleLabReagents(player, action, data)
    elseif puzzleType == SharedTypes.PuzzleType.FinalDoor then
        handleFinalDoor(player, action, data)
    end
end)

---------------------------------------------------------------------
-- Инициализация при старте игры
---------------------------------------------------------------------
-- Слушаем событие начала игры
local GameStateChanged = Events:WaitForChild("GameStateChanged")
GameStateChanged.OnClientEvent:Connect(function(state)
    if state == SharedTypes.GameState.Playing then
        generatePuzzleData()
        -- Сбросить состояние
        for name, puzzle in pairs(Puzzles) do
            if name ~= "FinalDoor" then
                puzzle.Status = SharedTypes.PuzzleStatus.Available
            else
                puzzle.Status = SharedTypes.PuzzleStatus.Locked
            end
        end
    end
end)

-- Также генерируем данные при загрузке скрипта (для тестирования)
generatePuzzleData()

print("[PuzzleSystem] Система головоломок инициализирована.")
