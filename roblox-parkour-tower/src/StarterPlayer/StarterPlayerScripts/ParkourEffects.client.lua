-- ParkourEffects: визуальные эффекты для игрока
-- Вставь в StarterPlayer → StarterPlayerScripts (тип LocalScript)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-----------------------------------------------
-- ТРЯСКА КАМЕРЫ ПРИ ПРИЗЕМЛЕНИИ
-----------------------------------------------
local lastY = 0
local wasInAir = false

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return end
	
	local currentY = rootPart.Position.Y
	local falling = currentY < lastY - 0.5
	local onGround = humanoid.FloorMaterial ~= Enum.Material.Air
	
	if wasInAir and onGround then
		-- Приземление — лёгкая тряска
		local fallDist = lastY - currentY
		if fallDist > 5 then
			local intensity = math.clamp(fallDist / 50, 0.05, 0.3)
			task.spawn(function()
				for i = 1, 5 do
					local offset = CFrame.new(
						math.random() * intensity - intensity/2,
						math.random() * intensity - intensity/2,
						0
					)
					camera.CFrame = camera.CFrame * offset
					task.wait(0.02)
				end
			end)
		end
	end
	
	wasInAir = not onGround
	if onGround then
		lastY = currentY
	end
end)

-----------------------------------------------
-- ЭФФЕКТ СКОРОСТИ
-----------------------------------------------
local speedLines = {}

local function createSpeedLine()
	local line = Instance.new("Part")
	line.Size = Vector3.new(0.1, 0.1, 3)
	line.Anchored = true
	line.CanCollide = false
	line.Color = Color3.fromRGB(200, 200, 255)
	line.Material = Enum.Material.Neon
	line.Transparency = 0.6
	line.CastShadow = false
	line.Parent = workspace
	return line
end

RunService.RenderStepped:Connect(function()
	local character = player.Character
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	local humanoid = character:FindFirstChild("Humanoid")
	if not rootPart or not humanoid then return end
	
	local speed = rootPart.AssemblyLinearVelocity.Magnitude
	
	-- Показать линии скорости при быстром падении
	if speed > 60 then
		if #speedLines < 10 then
			local line = createSpeedLine()
			local offset = Vector3.new(
				math.random(-5, 5),
				math.random(2, 8),
				math.random(-5, 5)
			)
			line.Position = rootPart.Position + offset
			line.CFrame = CFrame.lookAt(line.Position, line.Position + rootPart.AssemblyLinearVelocity)
			table.insert(speedLines, {part = line, life = 0.3})
		end
	end
	
	-- Обновить линии
	for i = #speedLines, 1, -1 do
		local data = speedLines[i]
		data.life = data.life - 0.016
		if data.life <= 0 then
			data.part:Destroy()
			table.remove(speedLines, i)
		else
			data.part.Transparency = 1 - data.life
		end
	end
end)

print("[ParkourEffects] Эффекты загружены!")
