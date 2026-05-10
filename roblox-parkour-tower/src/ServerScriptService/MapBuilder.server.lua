-- MapBuilder: автоматически строит паркур-башню при запуске
-- Вставь в ServerScriptService (тип Script)

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Ждём загрузку модулей
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("GameConfig"))

local FLOOR_H = Config.FLOOR_HEIGHT
local FLOOR_W = Config.FLOOR_WIDTH
local FLOOR_D = Config.FLOOR_DEPTH
local TOTAL_FLOORS = Config.TOWER_HEIGHT

print("[MapBuilder] Начинаю строить паркур-башню...")

-----------------------------------------------
-- УТИЛИТЫ
-----------------------------------------------
local function createPart(parent, name, size, position, color, anchored, canCollide, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide ~= false
	part.BrickColor = BrickColor.new(color or "Medium stone grey")
	if transparency then part.Transparency = transparency end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createColorPart(parent, name, size, position, color3, anchored, canCollide, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = anchored ~= false
	part.CanCollide = canCollide ~= false
	part.Color = color3 or Color3.fromRGB(128, 128, 128)
	if transparency then part.Transparency = transparency end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createNeon(parent, name, size, position, color3)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Anchored = true
	part.CanCollide = false
	part.Color = color3
	part.Material = Enum.Material.Neon
	part.Transparency = 0.3
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-----------------------------------------------
-- ОСНОВНАЯ ПАПКА
-----------------------------------------------
local towerFolder = Instance.new("Folder")
towerFolder.Name = "ParkourTower"
towerFolder.Parent = workspace

-- Папка для этажей (будет пересоздаваться при shuffle)
local floorsFolder = Instance.new("Folder")
floorsFolder.Name = "Floors"
floorsFolder.Parent = towerFolder

-----------------------------------------------
-- ОСНОВАНИЕ БАШНИ
-----------------------------------------------
local function buildBase()
	-- Платформа-основание
	local base = createPart(towerFolder, "Base", Vector3.new(80, 4, 80), Vector3.new(0, -2, 0), "Dark stone grey")
	
	-- Стартовая зона
	local spawn = createPart(towerFolder, "SpawnPlatform", Vector3.new(20, 1, 20), Vector3.new(0, 1, 0), "Bright green")
	spawn.Material = Enum.Material.Neon
	spawn.Color = Color3.fromRGB(80, 255, 80)
	
	-- SpawnLocation
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "MainSpawn"
	spawnLoc.Size = Vector3.new(8, 1, 8)
	spawnLoc.Position = Vector3.new(0, 2.5, 0)
	spawnLoc.Anchored = true
	spawnLoc.CanCollide = true
	spawnLoc.Transparency = 1
	spawnLoc.Parent = towerFolder
	
	-- Стены башни (прозрачные/невидимые)
	local wallThickness = 2
	local totalHeight = TOTAL_FLOORS * FLOOR_H + 20
	
	-- 4 стены
	createPart(towerFolder, "WallNorth", Vector3.new(FLOOR_W + 10, totalHeight, wallThickness), 
		Vector3.new(0, totalHeight/2, FLOOR_D/2 + 5), "Dark stone grey", true, true, 0.8)
	createPart(towerFolder, "WallSouth", Vector3.new(FLOOR_W + 10, totalHeight, wallThickness), 
		Vector3.new(0, totalHeight/2, -FLOOR_D/2 - 5), "Dark stone grey", true, true, 0.8)
	createPart(towerFolder, "WallEast", Vector3.new(wallThickness, totalHeight, FLOOR_D + 10), 
		Vector3.new(FLOOR_W/2 + 5, totalHeight/2, 0), "Dark stone grey", true, true, 0.8)
	createPart(towerFolder, "WallWest", Vector3.new(wallThickness, totalHeight, FLOOR_D + 10), 
		Vector3.new(-FLOOR_W/2 - 5, totalHeight/2, 0), "Dark stone grey", true, true, 0.8)
	
	-- Табличка "ПАРКУР БАШНЯ"
	local sign = createPart(towerFolder, "Sign", Vector3.new(16, 6, 1), Vector3.new(0, 8, -FLOOR_D/2 - 4))
	sign.Color = Color3.fromRGB(40, 40, 60)
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Back
	signGui.Parent = sign
	local signLabel = Instance.new("TextLabel")
	signLabel.Size = UDim2.new(1, 0, 1, 0)
	signLabel.BackgroundTransparency = 1
	signLabel.Text = "ПАРКУР БАШНЯ"
	signLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	signLabel.TextScaled = true
	signLabel.Font = Enum.Font.GothamBold
	signLabel.Parent = signGui
	
	print("[MapBuilder] Основание построено")
end

-----------------------------------------------
-- ГЕНЕРАЦИЯ ЭТАЖА
-----------------------------------------------
local function buildFloorFrame(floorNum, floorFolder)
	local baseY = floorNum * FLOOR_H
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty] or Color3.fromRGB(128, 128, 128)
	
	-- Номер этажа (текст на стене)
	local numSign = createColorPart(floorFolder, "FloorSign_" .. floorNum, Vector3.new(6, 3, 0.5), 
		Vector3.new(-FLOOR_W/2 + 1, baseY + FLOOR_H/2, 0), color)
	numSign.Material = Enum.Material.Neon
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Right
	gui.Parent = numSign
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = "Этаж " .. floorNum
	lbl.TextColor3 = Color3.new(1, 1, 1)
	lbl.TextScaled = true
	lbl.Font = Enum.Font.GothamBold
	lbl.Parent = gui
	
	-- Рамка этажа (тонкие полоски по краям для ориентации)
	local edgeColor = color
	createColorPart(floorFolder, "EdgeN_" .. floorNum, Vector3.new(FLOOR_W, 0.5, 0.5), 
		Vector3.new(0, baseY + 0.25, FLOOR_D/2 - 1), edgeColor)
	createColorPart(floorFolder, "EdgeS_" .. floorNum, Vector3.new(FLOOR_W, 0.5, 0.5), 
		Vector3.new(0, baseY + 0.25, -FLOOR_D/2 + 1), edgeColor)
	
	return baseY
end

-----------------------------------------------
-- ПЛАТФОРМЫ
-----------------------------------------------
local function createPlatform(parent, name, size, position, color3)
	return createColorPart(parent, name, size, position, color3)
end

local function createDisappearingPlatform(parent, name, size, position, color3)
	local plat = createColorPart(parent, name, size, position, color3, true, true, 0)
	plat:SetAttribute("Disappearing", true)
	plat:SetAttribute("Delay", Config.DISAPPEARING_DELAY)
	plat:SetAttribute("Respawn", Config.DISAPPEARING_RESPAWN)
	plat.Material = Enum.Material.Glass
	return plat
end

local function createMovingPlatform(parent, name, size, position, color3, moveDir, moveRange)
	local plat = createColorPart(parent, name, size, position, color3)
	plat:SetAttribute("Moving", true)
	plat:SetAttribute("MoveX", moveDir.X)
	plat:SetAttribute("MoveY", moveDir.Y)
	plat:SetAttribute("MoveZ", moveDir.Z)
	plat:SetAttribute("MoveRange", moveRange or 15)
	plat:SetAttribute("Speed", Config.MOVING_PLATFORM_SPEED)
	plat.Material = Enum.Material.DiamondPlate
	return plat
end

-----------------------------------------------
-- ЛОВУШКИ
-----------------------------------------------
local function createLaser(parent, floorNum, baseY, posX, posZ, length, rotAxis)
	local laserFolder = Instance.new("Folder")
	laserFolder.Name = "Laser_" .. floorNum .. "_" .. math.random(1000, 9999)
	laserFolder.Parent = parent
	
	-- Ось вращения
	local pivot = createColorPart(laserFolder, "LaserPivot", Vector3.new(2, 2, 2), 
		Vector3.new(posX, baseY + 3, posZ), Color3.fromRGB(80, 80, 80))
	pivot.Shape = Enum.PartType.Cylinder
	
	-- Луч лазера
	local beam = createNeon(laserFolder, "LaserBeam", Vector3.new(length or 20, 1.5, 1.5), 
		Vector3.new(posX, baseY + 3, posZ), Color3.fromRGB(255, 0, 0))
	beam:SetAttribute("Laser", true)
	beam:SetAttribute("Damage", Config.LASER_DAMAGE)
	beam:SetAttribute("PivotX", posX)
	beam:SetAttribute("PivotY", baseY + 3)
	beam:SetAttribute("PivotZ", posZ)
	beam:SetAttribute("Speed", Config.LASER_SPEED)
	beam:SetAttribute("RotAxis", rotAxis or "Y")
	
	return laserFolder
end

local function createSpikes(parent, floorNum, baseY, posX, posZ, sizeX, sizeZ)
	local spikePart = createColorPart(parent, "Spikes_" .. floorNum .. "_" .. math.random(1000, 9999), 
		Vector3.new(sizeX or 8, 3, sizeZ or 8), 
		Vector3.new(posX, baseY - 1, posZ), 
		Color3.fromRGB(120, 120, 120))
	spikePart:SetAttribute("Spikes", true)
	spikePart:SetAttribute("Damage", Config.SPIKE_DAMAGE)
	spikePart:SetAttribute("Interval", Config.SPIKE_INTERVAL)
	spikePart:SetAttribute("Active", false)
	spikePart.Material = Enum.Material.Slate
	
	-- Визуальные шипы сверху
	for i = 1, 4 do
		local spike = Instance.new("Part")
		spike.Name = "SpikeVisual"
		spike.Size = Vector3.new(1, 2, 1)
		spike.Position = spikePart.Position + Vector3.new(
			math.random(-3, 3), 2.5, math.random(-3, 3)
		)
		spike.Anchored = true
		spike.CanCollide = false
		spike.Color = Color3.fromRGB(80, 80, 80)
		spike.Material = Enum.Material.Metal
		spike.Parent = parent
	end
	
	return spikePart
end

local function createHammer(parent, floorNum, baseY, posX, posZ)
	local hammerFolder = Instance.new("Folder")
	hammerFolder.Name = "Hammer_" .. floorNum .. "_" .. math.random(1000, 9999)
	hammerFolder.Parent = parent
	
	-- Основание
	local hammerBase = createColorPart(hammerFolder, "HammerBase", Vector3.new(2, FLOOR_H - 2, 2), 
		Vector3.new(posX, baseY + FLOOR_H/2, posZ), Color3.fromRGB(80, 80, 80))
	
	-- Молот
	local head = createColorPart(hammerFolder, "HammerHead", Vector3.new(6, 6, 6), 
		Vector3.new(posX, baseY + 5, posZ), Color3.fromRGB(200, 50, 50))
	head:SetAttribute("Hammer", true)
	head:SetAttribute("Damage", Config.HAMMER_DAMAGE)
	head:SetAttribute("PivotX", posX)
	head:SetAttribute("PivotY", baseY + FLOOR_H - 2)
	head:SetAttribute("PivotZ", posZ)
	head:SetAttribute("Speed", Config.HAMMER_SPEED)
	head.Material = Enum.Material.Metal
	
	return hammerFolder
end

local function createFireZone(parent, floorNum, baseY, posX, posZ, sizeX, sizeZ)
	local fire = createNeon(parent, "FireZone_" .. floorNum .. "_" .. math.random(1000, 9999), 
		Vector3.new(sizeX or 10, 0.5, sizeZ or 10), 
		Vector3.new(posX, baseY + 0.5, posZ), 
		Color3.fromRGB(255, 100, 0))
	fire:SetAttribute("Fire", true)
	fire:SetAttribute("Damage", Config.FIRE_DAMAGE)
	fire:SetAttribute("Interval", Config.FIRE_INTERVAL)
	fire:SetAttribute("Active", true)
	
	-- Частицы огня
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 0, 0))
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Lifetime = NumberRange.new(0.3, 0.8)
	particles.Rate = 40
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(20, 20)
	particles.Parent = fire
	
	return fire
end

-----------------------------------------------
-- ЧЕКПОИНТ
-----------------------------------------------
local function createCheckpoint(parent, floorNum, baseY)
	local cpFolder = Instance.new("Folder")
	cpFolder.Name = "Checkpoint_" .. floorNum
	cpFolder.Parent = parent
	
	-- Платформа чекпоинта
	local cpPlat = createColorPart(cpFolder, "CheckpointPlatform", Vector3.new(12, 2, 12), 
		Vector3.new(0, baseY + 1, 0), Color3.fromRGB(50, 255, 50))
	cpPlat.Material = Enum.Material.Neon
	cpPlat:SetAttribute("Checkpoint", true)
	cpPlat:SetAttribute("Floor", floorNum)
	
	-- Флаг
	local pole = createColorPart(cpFolder, "Pole", Vector3.new(0.5, 8, 0.5), 
		Vector3.new(0, baseY + 6, 0), Color3.fromRGB(200, 200, 200))
	
	local flag = createColorPart(cpFolder, "Flag", Vector3.new(4, 2.5, 0.3), 
		Vector3.new(2, baseY + 9, 0), Color3.fromRGB(255, 255, 50))
	flag.Material = Enum.Material.Neon
	
	-- Текст
	local cpGui = Instance.new("BillboardGui")
	cpGui.Size = UDim2.new(5, 0, 2, 0)
	cpGui.StudsOffset = Vector3.new(0, 6, 0)
	cpGui.AlwaysOnTop = true
	cpGui.Parent = cpPlat
	local cpLabel = Instance.new("TextLabel")
	cpLabel.Size = UDim2.new(1, 0, 1, 0)
	cpLabel.BackgroundTransparency = 1
	cpLabel.Text = "ЧЕКПОИНТ " .. floorNum
	cpLabel.TextColor3 = Color3.fromRGB(50, 255, 50)
	cpLabel.TextStrokeTransparency = 0.5
	cpLabel.TextScaled = true
	cpLabel.Font = Enum.Font.GothamBold
	cpLabel.Parent = cpGui
	
	return cpFolder
end

-----------------------------------------------
-- ФИНИШ (ВЕРХ БАШНИ)
-----------------------------------------------
local function buildFinish()
	local topY = (TOTAL_FLOORS + 1) * FLOOR_H
	
	local finishFolder = Instance.new("Folder")
	finishFolder.Name = "Finish"
	finishFolder.Parent = towerFolder
	
	-- Финишная платформа
	local finPlat = createColorPart(finishFolder, "FinishPlatform", Vector3.new(30, 3, 30), 
		Vector3.new(0, topY, 0), Color3.fromRGB(255, 215, 0))
	finPlat.Material = Enum.Material.Neon
	finPlat:SetAttribute("Finish", true)
	
	-- Трофей
	local trophy = Instance.new("Part")
	trophy.Name = "Trophy"
	trophy.Size = Vector3.new(4, 8, 4)
	trophy.Position = Vector3.new(0, topY + 7, 0)
	trophy.Anchored = true
	trophy.CanCollide = false
	trophy.Color = Color3.fromRGB(255, 215, 0)
	trophy.Material = Enum.Material.Neon
	trophy.Shape = Enum.PartType.Cylinder
	trophy.Orientation = Vector3.new(0, 0, 90)
	trophy.Parent = finishFolder
	
	-- Текст ПОБЕДА
	local winGui = Instance.new("BillboardGui")
	winGui.Size = UDim2.new(10, 0, 3, 0)
	winGui.StudsOffset = Vector3.new(0, 8, 0)
	winGui.AlwaysOnTop = true
	winGui.Parent = trophy
	local winLabel = Instance.new("TextLabel")
	winLabel.Size = UDim2.new(1, 0, 1, 0)
	winLabel.BackgroundTransparency = 1
	winLabel.Text = "ПОБЕДА!"
	winLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	winLabel.TextStrokeTransparency = 0
	winLabel.TextScaled = true
	winLabel.Font = Enum.Font.GothamBold
	winLabel.Parent = winGui
	
	print("[MapBuilder] Финиш построен на высоте " .. topY)
end

-----------------------------------------------
-- ГЕНЕРАЦИЯ КОНКРЕТНЫХ ТИПОВ ЭТАЖЕЙ
-----------------------------------------------

local FloorBuilders = {}

function FloorBuilders.platforms_only(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local platCount = 6 + difficulty * 2
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Стартовая платформа (у входа)
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	
	-- Финишная (у выхода наверх)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
	
	-- Промежуточные платформы
	for i = 1, platCount do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(3, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		local size = Vector3.new(math.random(4, 10), 2, math.random(4, 10))
		createPlatform(parent, "Plat_" .. floorNum .. "_" .. i, size, Vector3.new(px, py, pz), color)
	end
end

function FloorBuilders.disappearing(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	local platCount = 8 + difficulty
	
	-- Стартовая (обычная)
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	
	-- Финишная (обычная)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
	
	-- Исчезающие платформы
	for i = 1, platCount do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(3, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createDisappearingPlatform(parent, "DisPlat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(5, 9), 2, math.random(5, 9)), 
			Vector3.new(px, py, pz), Color3.fromRGB(100, 200, 255))
	end
end

function FloorBuilders.lasers(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Платформы
	for i = 1, 8 do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(2, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createPlatform(parent, "Plat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(5, 10), 2, math.random(5, 10)), 
			Vector3.new(px, py, pz), color)
	end
	
	-- Лазеры
	local laserCount = 1 + difficulty
	for i = 1, laserCount do
		local lx = math.random(-15, 15)
		local lz = math.random(-15, 15)
		createLaser(parent, floorNum, baseY, lx, lz, math.random(15, 25), "Y")
	end
	
	-- Стартовая и финишная
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.spikes(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Платформы между шипами
	for i = 1, 10 do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(2, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createPlatform(parent, "Plat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(4, 8), 2, math.random(4, 8)), 
			Vector3.new(px, py, pz), color)
	end
	
	-- Шипы
	for i = 1, 2 + difficulty do
		local sx = math.random(-20, 20)
		local sz = math.random(-20, 20)
		createSpikes(parent, floorNum, baseY + math.random(0, 5), sx, sz, math.random(6, 12), math.random(6, 12))
	end
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.hammers(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Мост/платформы
	for i = 1, 6 do
		local px = -FLOOR_W/2 + 8 + (i - 1) * 10
		createPlatform(parent, "BridgePlat_" .. floorNum .. "_" .. i, 
			Vector3.new(8, 2, 12), 
			Vector3.new(px, baseY + i * 3, 0), color)
	end
	
	-- Молоты между платформами
	for i = 1, 2 + math.floor(difficulty / 2) do
		local hx = -FLOOR_W/2 + 13 + (i - 1) * 18
		createHammer(parent, floorNum, baseY, hx, 0)
	end
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.fire_floor(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Огненные зоны на полу
	for i = 1, 3 + difficulty do
		local fx = math.random(-20, 20)
		local fz = math.random(-20, 20)
		createFireZone(parent, floorNum, baseY, fx, fz, math.random(8, 14), math.random(8, 14))
	end
	
	-- Безопасные платформы выше огня
	for i = 1, 8 do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(4, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createPlatform(parent, "SafePlat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(5, 9), 2, math.random(5, 9)), 
			Vector3.new(px, py, pz), color)
	end
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.moving_platforms(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	
	-- Двигающиеся платформы
	for i = 1, 6 do
		local px = -FLOOR_W/2 + 8 + i * 8
		local py = baseY + i * 3
		local moveAxis
		if i % 3 == 0 then
			moveAxis = Vector3.new(0, 1, 0) -- вверх-вниз
		elseif i % 3 == 1 then
			moveAxis = Vector3.new(1, 0, 0) -- влево-вправо
		else
			moveAxis = Vector3.new(0, 0, 1) -- вперёд-назад
		end
		createMovingPlatform(parent, "MovPlat_" .. floorNum .. "_" .. i, 
			Vector3.new(7, 2, 7), 
			Vector3.new(px, py, 0), 
			Color3.fromRGB(100, 150, 255), moveAxis, 10 + difficulty * 2)
	end
	
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.mixed_easy(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Обычные + исчезающие платформы
	for i = 1, 5 do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(3, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createPlatform(parent, "Plat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(5, 9), 2, math.random(5, 9)), 
			Vector3.new(px, py, pz), color)
	end
	for i = 1, 4 do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(3, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createDisappearingPlatform(parent, "DisPlat_" .. floorNum .. "_" .. i, 
			Vector3.new(6, 2, 6), Vector3.new(px, py, pz), Color3.fromRGB(100, 200, 255))
	end
	
	createLaser(parent, floorNum, baseY, 0, 0, 18, "Y")
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.mixed_medium(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	for i = 1, 6 do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(3, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createPlatform(parent, "Plat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(4, 8), 2, math.random(4, 8)), 
			Vector3.new(px, py, pz), color)
	end
	
	-- Лазер + шипы
	createLaser(parent, floorNum, baseY, -10, 0, 20, "Y")
	createLaser(parent, floorNum, baseY, 10, 0, 15, "Y")
	createSpikes(parent, floorNum, baseY, 0, 10, 8, 8)
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.mixed_hard(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Мало платформ + много ловушек
	for i = 1, 4 do
		local px = math.random(-15, 15)
		local py = baseY + math.random(4, FLOOR_H - 5)
		local pz = math.random(-15, 15)
		createPlatform(parent, "Plat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(4, 6), 2, math.random(4, 6)), 
			Vector3.new(px, py, pz), color)
	end
	
	createLaser(parent, floorNum, baseY, -8, -8, 22, "Y")
	createLaser(parent, floorNum, baseY, 8, 8, 18, "Y")
	createHammer(parent, floorNum, baseY, 0, 0)
	createFireZone(parent, floorNum, baseY, 0, -15, 15, 10)
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.laser_maze(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Большой пол с дырками
	for i = 1, 8 do
		local px = math.random(-FLOOR_W/2 + 5, FLOOR_W/2 - 5)
		local py = baseY + math.random(2, FLOOR_H - 5)
		local pz = math.random(-FLOOR_D/2 + 5, FLOOR_D/2 - 5)
		createPlatform(parent, "Plat_" .. floorNum .. "_" .. i, 
			Vector3.new(math.random(4, 7), 2, math.random(4, 7)), 
			Vector3.new(px, py, pz), color)
	end
	
	-- Много лазеров
	for i = 1, 3 + difficulty do
		local lx = math.random(-20, 20)
		local lz = math.random(-20, 20)
		createLaser(parent, floorNum, baseY, lx, lz, math.random(12, 20), "Y")
	end
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

function FloorBuilders.vanishing_path(parent, floorNum, baseY)
	local difficulty = Config.GetDifficulty(floorNum)
	local color = Config.FLOOR_COLORS[difficulty]
	
	-- Длинный путь из исчезающих платформ
	local steps = 10 + difficulty * 2
	for i = 1, steps do
		local px = -FLOOR_W/2 + 5 + (i - 1) * (FLOOR_W / steps)
		local py = baseY + 2 + (i - 1) * ((FLOOR_H - 6) / steps)
		local pz = math.sin(i * 0.8) * 12
		createDisappearingPlatform(parent, "VanishPlat_" .. floorNum .. "_" .. i, 
			Vector3.new(5, 2, 5), 
			Vector3.new(px, py, pz), 
			Color3.fromRGB(255, 100 + i * 10, 100))
	end
	
	createPlatform(parent, "StartPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(-FLOOR_W/2 + 8, baseY + 1, 0), color)
	createPlatform(parent, "EndPlat_" .. floorNum, Vector3.new(8, 2, 8), 
		Vector3.new(FLOOR_W/2 - 8, baseY + FLOOR_H - 4, 0), color)
end

-----------------------------------------------
-- ГЕНЕРАЦИЯ ВСЕХ ЭТАЖЕЙ
-----------------------------------------------
local currentSeed = os.time()

local function generateAllFloors()
	-- Удалить старые этажи
	floorsFolder:ClearAllChildren()
	
	math.randomseed(currentSeed)
	
	for floorNum = 1, TOTAL_FLOORS do
		local floorFolder = Instance.new("Folder")
		floorFolder.Name = "Floor_" .. floorNum
		floorFolder.Parent = floorsFolder
		
		local baseY = buildFloorFrame(floorNum, floorFolder)
		
		-- Чекпоинт каждые N этажей
		if floorNum % Config.CHECKPOINT_EVERY == 0 then
			createCheckpoint(floorFolder, floorNum, baseY)
		else
			-- Определить тип этажа
			local difficulty = Config.GetDifficulty(floorNum)
			local possibleTypes = Config.DIFFICULTY_FLOORS[difficulty]
			local floorType = possibleTypes[math.random(1, #possibleTypes)]
			
			-- Построить этаж
			if FloorBuilders[floorType] then
				FloorBuilders[floorType](floorFolder, floorNum, baseY)
			else
				FloorBuilders.platforms_only(floorFolder, floorNum, baseY)
			end
		end
		
		print("[MapBuilder] Этаж " .. floorNum .. " построен")
	end
	
	print("[MapBuilder] Все " .. TOTAL_FLOORS .. " этажей построены!")
end

-----------------------------------------------
-- ЗАПУСК
-----------------------------------------------
buildBase()
generateAllFloors()
buildFinish()

-- Смена этажей каждые 5 минут
task.spawn(function()
	while true do
		task.wait(Config.SHUFFLE_INTERVAL)
		print("[MapBuilder] Смена этажей! Новый seed...")
		currentSeed = os.time()
		generateAllFloors()
		
		-- Уведомление
		local shuffleEvent = ReplicatedStorage:FindFirstChild("TowerShuffled")
		if shuffleEvent then
			shuffleEvent:FireAllClients()
		end
	end
end)

print("[MapBuilder] ПАРКУР-БАШНЯ ПОСТРОЕНА!")
