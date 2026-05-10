-- TowerManager: управляет таймером, чекпоинтами, смертями и респавном
-- Вставь в ServerScriptService (тип Script)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("GameConfig"))

-- Ждём события
local PlayerDied = ReplicatedStorage:WaitForChild("PlayerDied")
local PlayerCheckpoint = ReplicatedStorage:WaitForChild("PlayerCheckpoint")
local PlayerFinished = ReplicatedStorage:WaitForChild("PlayerFinished")
local TowerShuffled = ReplicatedStorage:WaitForChild("TowerShuffled")
local UpdateTimer = ReplicatedStorage:WaitForChild("UpdateTimer")
local UpdateFloor = ReplicatedStorage:WaitForChild("UpdateFloor")
local UpdateDeaths = ReplicatedStorage:WaitForChild("UpdateDeaths")
local ShowNotification = ReplicatedStorage:WaitForChild("ShowNotification")
local RequestRespawn = ReplicatedStorage:WaitForChild("RequestRespawn")

-----------------------------------------------
-- ДАННЫЕ ИГРОКОВ
-----------------------------------------------
local playerData = {} -- {[player] = {deaths, checkpoint, currentFloor, startTime, bestTime, finished}}

local function initPlayerData(player)
	playerData[player] = {
		deaths = 0,
		checkpoint = 0,         -- 0 = спавн, N = этаж чекпоинта
		currentFloor = 0,
		startTime = os.time(),
		bestTime = 0,
		finished = false,
	}
end

-----------------------------------------------
-- ПОДКЛЮЧЕНИЕ ИГРОКОВ
-----------------------------------------------
Players.PlayerAdded:Connect(function(player)
	initPlayerData(player)
	
	player.CharacterAdded:Connect(function(character)
		-- Ждём загрузку персонажа
		local humanoid = character:WaitForChild("Humanoid")
		local rootPart = character:WaitForChild("HumanoidRootPart")
		
		-- Обнуление при новом персонаже
		humanoid.Died:Connect(function()
			local data = playerData[player]
			if data then
				data.deaths = data.deaths + 1
				UpdateDeaths:FireClient(player, data.deaths)
				
				-- Респавн через 2 секунды
				task.wait(2)
				player:LoadCharacter()
			end
		end)
		
		-- Телепорт к чекпоинту после загрузки
		task.wait(0.5)
		local data = playerData[player]
		if data and data.checkpoint > 0 then
			local checkpointY = data.checkpoint * Config.FLOOR_HEIGHT + 3
			rootPart.CFrame = CFrame.new(0, checkpointY, 0)
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player] = nil
end)

-----------------------------------------------
-- ОПРЕДЕЛЕНИЕ ЭТАЖА ИГРОКА
-----------------------------------------------
local function getPlayerFloor(player)
	local character = player.Character
	if not character then return 0 end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return 0 end
	
	local y = rootPart.Position.Y
	return math.max(0, math.floor(y / Config.FLOOR_HEIGHT))
end

-----------------------------------------------
-- ОТСЛЕЖИВАНИЕ ПОЗИЦИИ
-----------------------------------------------
RunService.Heartbeat:Connect(function()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = playerData[player]
		if not data then continue end
		
		local floor = getPlayerFloor(player)
		if floor ~= data.currentFloor then
			data.currentFloor = floor
			UpdateFloor:FireClient(player, floor)
		end
	end
end)

-----------------------------------------------
-- ТАЙМЕР ДО СМЕНЫ ЭТАЖЕЙ
-----------------------------------------------
local shuffleTimer = Config.SHUFFLE_INTERVAL

task.spawn(function()
	while true do
		task.wait(1)
		shuffleTimer = shuffleTimer - 1
		
		if shuffleTimer <= 0 then
			shuffleTimer = Config.SHUFFLE_INTERVAL
		end
		
		-- Отправить таймер всем
		for _, player in ipairs(Players:GetPlayers()) do
			UpdateTimer:FireClient(player, shuffleTimer)
		end
		
		-- Предупреждение за 30 секунд
		if shuffleTimer == 30 then
			for _, player in ipairs(Players:GetPlayers()) do
				ShowNotification:FireClient(player, "Смена этажей через 30 сек!", Color3.fromRGB(255, 200, 50))
			end
		end
		
		-- Предупреждение за 10 секунд
		if shuffleTimer == 10 then
			for _, player in ipairs(Players:GetPlayers()) do
				ShowNotification:FireClient(player, "СМЕНА ЭТАЖЕЙ ЧЕРЕЗ 10 СЕК!", Color3.fromRGB(255, 80, 80))
			end
		end
	end
end)

-----------------------------------------------
-- ОБРАБОТКА ЧЕКПОИНТОВ И ЛОВУШЕК
-----------------------------------------------
local function onTouched(part, otherPart)
	local player = Players:GetPlayerFromCharacter(otherPart.Parent)
	if not player then return nil, nil end
	local data = playerData[player]
	if not data then return nil, nil end
	local humanoid = otherPart.Parent:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil, nil end
	return player, humanoid
end

-- Обработка касаний в башне
local towerFolder = workspace:WaitForChild("ParkourTower")
local floorsFolder = towerFolder:WaitForChild("Floors")

local function setupTouchHandlers(parent)
	for _, descendant in ipairs(parent:GetDescendants()) do
		if descendant:IsA("BasePart") then
			-- Чекпоинт
			if descendant:GetAttribute("Checkpoint") then
				descendant.Touched:Connect(function(hit)
					local player, humanoid = onTouched(descendant, hit)
					if not player then return end
					local data = playerData[player]
					local cpFloor = descendant:GetAttribute("Floor") or 0
					if cpFloor > data.checkpoint then
						data.checkpoint = cpFloor
						PlayerCheckpoint:FireClient(player, cpFloor)
						ShowNotification:FireClient(player, "Чекпоинт! Этаж " .. cpFloor, Color3.fromRGB(50, 255, 50))
					end
				end)
			end
			
			-- Финиш
			if descendant:GetAttribute("Finish") then
				descendant.Touched:Connect(function(hit)
					local player, humanoid = onTouched(descendant, hit)
					if not player then return end
					local data = playerData[player]
					if not data.finished then
						data.finished = true
						local elapsed = os.time() - data.startTime
						data.bestTime = elapsed
						PlayerFinished:FireClient(player, elapsed, data.deaths)
						ShowNotification:FireClient(player, "ПОБЕДА! Время: " .. elapsed .. " сек, Смертей: " .. data.deaths, Color3.fromRGB(255, 215, 0))
					end
				end)
			end
			
			-- Лазер
			if descendant:GetAttribute("Laser") then
				descendant.Touched:Connect(function(hit)
					local player, humanoid = onTouched(descendant, hit)
					if not player then return end
					local dmg = descendant:GetAttribute("Damage") or Config.LASER_DAMAGE
					humanoid:TakeDamage(dmg)
				end)
			end
			
			-- Шипы
			if descendant:GetAttribute("Spikes") then
				descendant.Touched:Connect(function(hit)
					local player, humanoid = onTouched(descendant, hit)
					if not player then return end
					local dmg = descendant:GetAttribute("Damage") or Config.SPIKE_DAMAGE
					humanoid:TakeDamage(dmg)
				end)
			end
			
			-- Огонь
			if descendant:GetAttribute("Fire") then
				descendant.Touched:Connect(function(hit)
					local player, humanoid = onTouched(descendant, hit)
					if not player then return end
					local dmg = descendant:GetAttribute("Damage") or Config.FIRE_DAMAGE
					humanoid:TakeDamage(dmg)
				end)
			end
			
			-- Молот
			if descendant:GetAttribute("Hammer") then
				descendant.Touched:Connect(function(hit)
					local player, humanoid = onTouched(descendant, hit)
					if not player then return end
					local dmg = descendant:GetAttribute("Damage") or Config.HAMMER_DAMAGE
					humanoid:TakeDamage(dmg)
				end)
			end
			
			-- Исчезающая платформа
			if descendant:GetAttribute("Disappearing") then
				local isActive = true
				descendant.Touched:Connect(function(hit)
					local player = Players:GetPlayerFromCharacter(hit.Parent)
					if not player then return end
					if not isActive then return end
					isActive = false
					
					local delayTime = descendant:GetAttribute("Delay") or Config.DISAPPEARING_DELAY
					local respawnTime = descendant:GetAttribute("Respawn") or Config.DISAPPEARING_RESPAWN
					
					-- Мигание перед исчезновением
					for i = 1, 3 do
						descendant.Transparency = 0.5
						task.wait(delayTime / 6)
						descendant.Transparency = 0
						task.wait(delayTime / 6)
					end
					
					-- Исчезнуть
					descendant.Transparency = 1
					descendant.CanCollide = false
					
					-- Вернуться
					task.wait(respawnTime)
					descendant.Transparency = 0
					descendant.CanCollide = true
					isActive = true
				end)
			end
		end
	end
end

-- Настройка обработчиков
task.wait(2)  -- Ждём пока MapBuilder построит
setupTouchHandlers(towerFolder)

-- При смене этажей — пересоздать обработчики
floorsFolder.ChildAdded:Connect(function()
	task.wait(1)
	setupTouchHandlers(floorsFolder)
end)

-- Респавн по запросу
RequestRespawn.OnServerEvent:Connect(function(player)
	player:LoadCharacter()
end)

-- При shuffle — сбросить чекпоинты
TowerShuffled.Event = nil  -- Серверный сигнал
local function onShuffle()
	for player, data in pairs(playerData) do
		data.checkpoint = 0
		data.startTime = os.time()
		data.finished = false
		ShowNotification:FireClient(player, "Этажи обновлены! Чекпоинты сброшены.", Color3.fromRGB(255, 100, 100))
		-- Телепорт в начало
		task.wait(0.5)
		player:LoadCharacter()
	end
end

-- Слушаем изменения в floorsFolder (когда MapBuilder очищает)
floorsFolder.ChildRemoved:Connect(function()
	task.wait(3)
	if #floorsFolder:GetChildren() > 0 then
		onShuffle()
		setupTouchHandlers(floorsFolder)
	end
end)

print("[TowerManager] Менеджер башни запущен!")
