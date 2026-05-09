--[[
    MonsterAI.server.lua
    AI монстра — патруль, расследование, преследование
    Расположение: ServerScriptService/MonsterAI.server.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local MonsterStateChanged = Events:WaitForChild("MonsterStateChanged")
local MonsterAlert = Events:WaitForChild("MonsterAlert")
local FearUpdated = Events:WaitForChild("FearUpdated")

-- API для общения с GameManager
local GameManagerFunctions = ServerStorage:WaitForChild("GameManagerFunctions")

---------------------------------------------------------------------
-- Состояние монстра
---------------------------------------------------------------------
local Monster = SharedTypes.CreateMonsterData()
local monsterModel = nil -- Ссылка на модель монстра в workspace
local monsterHumanoid = nil
local monsterRootPart = nil
local isActive = false

-- Waypoints для патруля (настраиваются в Roblox Studio)
local patrolFolder = workspace:FindFirstChild("PatrolWaypoints")

---------------------------------------------------------------------
-- Инициализация монстра
---------------------------------------------------------------------
local function spawnMonster()
    -- Найти точку спавна
    local spawnPoint = workspace:FindFirstChild("MonsterSpawn")
    if not spawnPoint then
        warn("[MonsterAI] Не найдена точка спавна монстра (MonsterSpawn)")
        return
    end

    -- Найти модель монстра
    monsterModel = ServerStorage:FindFirstChild("MonsterModel")
    if not monsterModel then
        -- Создать простую модель-заглушку если нет модели
        monsterModel = Instance.new("Model")
        monsterModel.Name = "Monster"

        local rootPart = Instance.new("Part")
        rootPart.Name = "HumanoidRootPart"
        rootPart.Size = Vector3.new(3, 6, 3)
        rootPart.Position = spawnPoint.Position
        rootPart.Anchored = false
        rootPart.CanCollide = true
        rootPart.BrickColor = BrickColor.new("Really black")
        rootPart.Material = Enum.Material.SmoothPlastic
        rootPart.Parent = monsterModel

        local humanoid = Instance.new("Humanoid")
        humanoid.MaxHealth = math.huge
        humanoid.Health = math.huge
        humanoid.WalkSpeed = GameConfig.Monster.PatrolSpeed
        humanoid.Parent = monsterModel

        monsterModel.PrimaryPart = rootPart
    else
        monsterModel = monsterModel:Clone()
        monsterModel:SetPrimaryPartCFrame(spawnPoint.CFrame)
    end

    monsterModel.Parent = workspace
    monsterHumanoid = monsterModel:FindFirstChildOfClass("Humanoid")
    monsterRootPart = monsterModel:FindFirstChild("HumanoidRootPart")

    -- Загрузить waypoints
    if patrolFolder then
        Monster.PatrolWaypoints = {}
        for _, waypoint in ipairs(patrolFolder:GetChildren()) do
            if waypoint:IsA("BasePart") then
                table.insert(Monster.PatrolWaypoints, waypoint.Position)
            end
        end
        -- Сортировать по имени (Waypoint1, Waypoint2, ...)
        table.sort(Monster.PatrolWaypoints, function(a, b)
            return tostring(a) < tostring(b)
        end)
    end

    -- Если нет waypoints, создать случайные
    if #Monster.PatrolWaypoints == 0 then
        for i = 1, 8 do
            table.insert(Monster.PatrolWaypoints, Vector3.new(
                math.random(-100, 100),
                spawnPoint.Position.Y,
                math.random(-100, 100)
            ))
        end
    end

    -- Детекция касания (урон игроку)
    monsterRootPart.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if player then
            local playerData = GameManagerFunctions:Invoke("GetPlayerData", player)
            if playerData and playerData.State == SharedTypes.PlayerState.Alive then
                GameManagerFunctions:Invoke("DamagePlayer", player, 1)
                -- Отбросить монстра назад после атаки
                task.delay(2, function()
                    if Monster.State == SharedTypes.MonsterState.Chase then
                        Monster.State = SharedTypes.MonsterState.LostTarget
                        Monster.LoseTargetTimer = 3
                    end
                end)
            end
        end
    end)

    Monster.State = SharedTypes.MonsterState.Patrol
    Monster.CurrentWaypointIndex = 1
    isActive = true

    MonsterStateChanged:FireAllClients(Monster.State, monsterRootPart.Position)
    print("[MonsterAI] Монстр заспавнен!")
end

---------------------------------------------------------------------
-- Система зрения
---------------------------------------------------------------------
local function canSeePlayer(player)
    if not monsterRootPart then return false end

    local character = player.Character
    if not character then return false end

    local targetPart = character:FindFirstChild("HumanoidRootPart")
    if not targetPart then return false end

    local direction = (targetPart.Position - monsterRootPart.Position)
    local distance = direction.Magnitude

    -- Проверка расстояния
    if distance > GameConfig.Monster.VisionRadius then
        return false
    end

    -- Проверка угла (конус зрения)
    local forward = monsterRootPart.CFrame.LookVector
    local toTarget = direction.Unit
    local angle = math.deg(math.acos(math.clamp(forward:Dot(toTarget), -1, 1)))

    if angle > GameConfig.Monster.VisionAngle / 2 then
        return false
    end

    -- Raycast для проверки препятствий
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {monsterModel}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(monsterRootPart.Position, direction, rayParams)
    if result then
        -- Проверить что луч попал в игрока, а не в стену
        local hitCharacter = result.Instance:FindFirstAncestorOfClass("Model")
        if hitCharacter == character then
            return true
        end
    end

    return false
end

---------------------------------------------------------------------
-- Система слуха
---------------------------------------------------------------------
local function canHearNoise(position, noiseLevel)
    if not monsterRootPart then return false end

    local distance = (position - monsterRootPart.Position).Magnitude
    local effectiveRadius = GameConfig.Monster.HearingRadius * (noiseLevel / GameConfig.NoiseLevel.Loud)

    return distance <= effectiveRadius
end

-- Обработка звуков от MonsterAlert
MonsterAlert.Event:Connect(function(position, noiseLevel, sourcePlayer)
    if not isActive then
        -- Сигнал спавна
        if not position and noiseLevel == 0 then
            spawnMonster()
        end
        return
    end

    if not position or noiseLevel == 0 then return end

    if canHearNoise(position, noiseLevel) then
        if Monster.State == SharedTypes.MonsterState.Patrol or
           Monster.State == SharedTypes.MonsterState.Idle then
            -- Переключиться в режим расследования
            Monster.State = SharedTypes.MonsterState.Investigate
            Monster.InvestigatePosition = position
            MonsterStateChanged:FireAllClients(Monster.State, monsterRootPart.Position)
        elseif Monster.State == SharedTypes.MonsterState.LostTarget then
            -- Снова услышал звук — расследовать
            Monster.State = SharedTypes.MonsterState.Investigate
            Monster.InvestigatePosition = position
        end
    end
end)

---------------------------------------------------------------------
-- Движение (Pathfinding)
---------------------------------------------------------------------
local currentPath = nil
local currentWaypointIdx = 1

local function moveToPosition(targetPosition)
    if not monsterHumanoid or not monsterRootPart then return end

    local path = PathfindingService:CreatePath({
        AgentRadius = 2,
        AgentHeight = 6,
        AgentCanJump = false,
        WaypointSpacing = 4,
    })

    local success, err = pcall(function()
        path:ComputeAsync(monsterRootPart.Position, targetPosition)
    end)

    if success and path.Status == Enum.PathStatus.Success then
        local waypoints = path:GetWaypoints()
        for _, waypoint in ipairs(waypoints) do
            monsterHumanoid:MoveTo(waypoint.Position)
            local reached = monsterHumanoid.MoveToFinished:Wait()
            if not reached then break end

            -- Прервать если состояние изменилось (например, увидел игрока)
            if Monster.State == SharedTypes.MonsterState.Chase then
                break
            end
        end
    else
        -- Если Pathfinding не удался, двигаться напрямую
        monsterHumanoid:MoveTo(targetPosition)
    end
end

---------------------------------------------------------------------
-- Поведение AI: Патруль
---------------------------------------------------------------------
local function doPatrol()
    if #Monster.PatrolWaypoints == 0 then return end

    local targetWaypoint = Monster.PatrolWaypoints[Monster.CurrentWaypointIndex]
    monsterHumanoid.WalkSpeed = GameConfig.Monster.PatrolSpeed

    moveToPosition(targetWaypoint)

    -- Следующий waypoint
    Monster.CurrentWaypointIndex = Monster.CurrentWaypointIndex + 1
    if Monster.CurrentWaypointIndex > #Monster.PatrolWaypoints then
        Monster.CurrentWaypointIndex = 1
    end

    -- Пауза на waypoint
    task.wait(math.random(2, 5))
end

---------------------------------------------------------------------
-- Поведение AI: Расследование
---------------------------------------------------------------------
local function doInvestigate()
    if not Monster.InvestigatePosition then
        Monster.State = SharedTypes.MonsterState.Patrol
        return
    end

    monsterHumanoid.WalkSpeed = GameConfig.Monster.InvestigateSpeed
    moveToPosition(Monster.InvestigatePosition)

    -- Осмотреться на месте
    task.wait(3)

    -- Не нашёл никого — вернуться к патрулю
    Monster.State = SharedTypes.MonsterState.Patrol
    Monster.InvestigatePosition = nil
    MonsterStateChanged:FireAllClients(Monster.State, monsterRootPart.Position)
end

---------------------------------------------------------------------
-- Поведение AI: Преследование
---------------------------------------------------------------------
local function doChase()
    if not Monster.CurrentTarget then
        Monster.State = SharedTypes.MonsterState.LostTarget
        Monster.LoseTargetTimer = GameConfig.Monster.LoseTargetTime
        return
    end

    local target = Monster.CurrentTarget
    local character = target.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then
        Monster.State = SharedTypes.MonsterState.LostTarget
        Monster.LoseTargetTimer = GameConfig.Monster.LoseTargetTime
        return
    end

    -- Получить множитель агрессии
    local aggression = GameManagerFunctions:Invoke("GetMonsterAggression") or 1.0
    monsterHumanoid.WalkSpeed = GameConfig.Monster.ChaseSpeed * aggression

    -- Двигаться к цели
    monsterHumanoid:MoveTo(character.HumanoidRootPart.Position)
    Monster.LastKnownPosition = character.HumanoidRootPart.Position
end

---------------------------------------------------------------------
-- Поведение AI: Потеря цели
---------------------------------------------------------------------
local function doLostTarget(deltaTime)
    Monster.LoseTargetTimer = Monster.LoseTargetTimer - deltaTime

    if Monster.LoseTargetTimer <= 0 then
        Monster.State = SharedTypes.MonsterState.Patrol
        Monster.CurrentTarget = nil
        Monster.LastKnownPosition = nil
        MonsterStateChanged:FireAllClients(Monster.State, monsterRootPart.Position)
        return
    end

    -- Двигаться к последнему известному положению
    if Monster.LastKnownPosition then
        monsterHumanoid.WalkSpeed = GameConfig.Monster.InvestigateSpeed
        monsterHumanoid:MoveTo(Monster.LastKnownPosition)
    end
end

---------------------------------------------------------------------
-- Проверка телепортации
---------------------------------------------------------------------
local function checkTeleport()
    if not monsterRootPart then return end

    local alivePlayers = GameManagerFunctions:Invoke("GetAlivePlayers")
    if not alivePlayers or #alivePlayers == 0 then return end

    local allTooFar = true
    local closestPlayer = nil
    local closestDistance = math.huge

    for _, player in ipairs(alivePlayers) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local dist = (monsterRootPart.Position - character.HumanoidRootPart.Position).Magnitude
            if dist < GameConfig.Monster.TeleportDistance then
                allTooFar = false
            end
            if dist < closestDistance then
                closestDistance = dist
                closestPlayer = player
            end
        end
    end

    -- Если все игроки слишком далеко, телепортировать монстра ближе
    if allTooFar and closestPlayer then
        local character = closestPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local targetPos = character.HumanoidRootPart.Position
            local offset = Vector3.new(math.random(-40, 40), 0, math.random(-40, 40))
            local newPos = targetPos + offset
            monsterRootPart.CFrame = CFrame.new(newPos.X, monsterRootPart.Position.Y, newPos.Z)
            print("[MonsterAI] Телепортация ближе к игрокам")
        end
    end
end

---------------------------------------------------------------------
-- Обновление страха от монстра
---------------------------------------------------------------------
local function updateMonsterFear()
    if not monsterRootPart then return end

    local alivePlayers = GameManagerFunctions:Invoke("GetAlivePlayers")
    if not alivePlayers then return end

    for _, player in ipairs(alivePlayers) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local dist = (monsterRootPart.Position - character.HumanoidRootPart.Position).Magnitude

            if dist < 30 then
                -- Увеличить страх игрока (через FearUpdated)
                local playerData = GameManagerFunctions:Invoke("GetPlayerData", player)
                if playerData then
                    local fearAdd = GameConfig.Fear.MonsterNearbyRate * (1 - dist / 30)
                    -- Страх обрабатывается в GameManager, но мы можем отправить сигнал
                    MonsterAlert:Fire(monsterRootPart.Position, fearAdd, nil)
                end
            end
        end
    end
end

---------------------------------------------------------------------
-- Главный AI цикл
---------------------------------------------------------------------
local lastUpdate = os.clock()
local teleportTimer = 0

RunService.Heartbeat:Connect(function()
    if not isActive or not monsterRootPart then return end

    local gameState = GameManagerFunctions:Invoke("GetGameState")
    if gameState ~= SharedTypes.GameState.Playing then return end

    local now = os.clock()
    local deltaTime = now - lastUpdate
    lastUpdate = now

    -- Проверка зрения на всех игроков
    local alivePlayers = GameManagerFunctions:Invoke("GetAlivePlayers")
    if alivePlayers then
        for _, player in ipairs(alivePlayers) do
            if canSeePlayer(player) then
                if Monster.State ~= SharedTypes.MonsterState.Chase or Monster.CurrentTarget ~= player then
                    Monster.State = SharedTypes.MonsterState.Chase
                    Monster.CurrentTarget = player
                    MonsterStateChanged:FireAllClients(Monster.State, monsterRootPart.Position)
                end
                break
            end
        end
    end

    -- Выполнить поведение в зависимости от состояния
    if Monster.State == SharedTypes.MonsterState.Chase then
        doChase()
    elseif Monster.State == SharedTypes.MonsterState.LostTarget then
        doLostTarget(deltaTime)
    end
    -- Patrol и Investigate обрабатываются в отдельных потоках (ниже)

    -- Обновить страх от монстра
    updateMonsterFear()

    -- Периодическая проверка телепортации
    teleportTimer = teleportTimer + deltaTime
    if teleportTimer >= 30 then
        checkTeleport()
        teleportTimer = 0
    end
end)

-- Отдельный поток для Patrol/Investigate (они блокирующие из-за MoveTo)
task.spawn(function()
    while true do
        task.wait(0.5)
        if not isActive or not monsterRootPart then continue end

        local gameState = GameManagerFunctions:Invoke("GetGameState")
        if gameState ~= SharedTypes.GameState.Playing then continue end

        if Monster.State == SharedTypes.MonsterState.Patrol then
            doPatrol()
        elseif Monster.State == SharedTypes.MonsterState.Investigate then
            doInvestigate()
        end
    end
end)

print("[MonsterAI] Модуль загружен. Ожидание сигнала спавна...")
