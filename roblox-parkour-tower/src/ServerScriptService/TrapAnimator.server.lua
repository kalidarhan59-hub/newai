-- TrapAnimator: анимация ловушек (лазеры, молоты, шипы, двигающиеся платформы)
-- Вставь в ServerScriptService (тип Script)

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Config = require(Modules:WaitForChild("GameConfig"))

local towerFolder = workspace:WaitForChild("ParkourTower")

-----------------------------------------------
-- АНИМАЦИЯ ЛАЗЕРОВ (вращение)
-----------------------------------------------
local function animateLasers(dt)
	for _, descendant in ipairs(towerFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("Laser") then
			local pivotX = descendant:GetAttribute("PivotX") or 0
			local pivotY = descendant:GetAttribute("PivotY") or 0
			local pivotZ = descendant:GetAttribute("PivotZ") or 0
			local speed = descendant:GetAttribute("Speed") or Config.LASER_SPEED
			
			local t = os.clock() * speed
			local halfLen = descendant.Size.X / 2
			
			-- Вращение вокруг оси Y
			local angle = math.rad(t)
			local offsetX = math.cos(angle) * halfLen
			local offsetZ = math.sin(angle) * halfLen
			
			descendant.CFrame = CFrame.new(pivotX, pivotY, pivotZ) 
				* CFrame.Angles(0, angle, 0)
		end
	end
end

-----------------------------------------------
-- АНИМАЦИЯ МОЛОТОВ (качание)
-----------------------------------------------
local function animateHammers(dt)
	for _, descendant in ipairs(towerFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("Hammer") then
			local pivotX = descendant:GetAttribute("PivotX") or 0
			local pivotY = descendant:GetAttribute("PivotY") or 0
			local pivotZ = descendant:GetAttribute("PivotZ") or 0
			local speed = descendant:GetAttribute("Speed") or Config.HAMMER_SPEED
			
			local t = os.clock() * speed
			local swingAngle = math.sin(t) * math.rad(70)  -- Качание ±70 градусов
			
			-- Длина маятника
			local armLength = 15
			local headX = pivotX + math.sin(swingAngle) * armLength
			local headY = pivotY - math.cos(swingAngle) * armLength
			
			descendant.Position = Vector3.new(headX, headY, pivotZ)
		end
	end
end

-----------------------------------------------
-- АНИМАЦИЯ ШИПОВ (вверх-вниз)
-----------------------------------------------
local function animateSpikes(dt)
	for _, descendant in ipairs(towerFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("Spikes") then
			local interval = descendant:GetAttribute("Interval") or Config.SPIKE_INTERVAL
			local t = os.clock()
			local phase = t % (interval * 2)
			
			if phase < interval * 0.3 then
				-- Шипы поднимаются
				descendant.Position = descendant.Position + Vector3.new(0, dt * 8, 0)
				descendant.CanCollide = true
				descendant:SetAttribute("Active", true)
				descendant.Color = Color3.fromRGB(200, 50, 50)
			elseif phase > interval then
				-- Шипы опускаются
				descendant.CanCollide = false
				descendant:SetAttribute("Active", false)
				descendant.Color = Color3.fromRGB(120, 120, 120)
			end
		end
	end
end

-----------------------------------------------
-- АНИМАЦИЯ ДВИГАЮЩИХСЯ ПЛАТФОРМ
-----------------------------------------------
local function animateMovingPlatforms(dt)
	for _, descendant in ipairs(towerFolder:GetDescendants()) do
		if descendant:IsA("BasePart") and descendant:GetAttribute("Moving") then
			local moveX = descendant:GetAttribute("MoveX") or 0
			local moveY = descendant:GetAttribute("MoveY") or 0
			local moveZ = descendant:GetAttribute("MoveZ") or 0
			local moveRange = descendant:GetAttribute("MoveRange") or 15
			local speed = descendant:GetAttribute("Speed") or Config.MOVING_PLATFORM_SPEED
			
			local t = os.clock() * (speed / moveRange)
			local offset = math.sin(t) * moveRange
			
			local basePos = descendant.Position
			descendant.CFrame = CFrame.new(
				basePos.X + moveX * offset * dt,
				basePos.Y + moveY * offset * dt,
				basePos.Z + moveZ * offset * dt
			)
		end
	end
end

-----------------------------------------------
-- ГЛАВНЫЙ ЦИКЛ АНИМАЦИИ
-----------------------------------------------
RunService.Heartbeat:Connect(function(dt)
	animateLasers(dt)
	animateHammers(dt)
	animateMovingPlatforms(dt)
	-- Шипы обновляются реже
end)

-- Шипы на отдельном таймере (медленнее)
task.spawn(function()
	while true do
		task.wait(0.2)
		animateSpikes(0.2)
	end
end)

print("[TrapAnimator] Анимация ловушек запущена!")
