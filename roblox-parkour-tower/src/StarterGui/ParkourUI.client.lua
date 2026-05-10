-- ParkourUI: интерфейс игрока — таймер, этаж, смерти, уведомления
-- Вставь в StarterGui (тип LocalScript)

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

-- Ждём события
local UpdateTimer = ReplicatedStorage:WaitForChild("UpdateTimer")
local UpdateFloor = ReplicatedStorage:WaitForChild("UpdateFloor")
local UpdateDeaths = ReplicatedStorage:WaitForChild("UpdateDeaths")
local ShowNotification = ReplicatedStorage:WaitForChild("ShowNotification")
local PlayerCheckpoint = ReplicatedStorage:WaitForChild("PlayerCheckpoint")
local PlayerFinished = ReplicatedStorage:WaitForChild("PlayerFinished")
local TowerShuffled = ReplicatedStorage:WaitForChild("TowerShuffled")
local RequestRespawn = ReplicatedStorage:WaitForChild("RequestRespawn")

-----------------------------------------------
-- СОЗДАНИЕ GUI
-----------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ParkourHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- Фон верхней панели
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 50)
topBar.Position = UDim2.new(0, 0, 0, 0)
topBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
topBar.BackgroundTransparency = 0.3
topBar.BorderSizePixel = 0
topBar.Parent = screenGui

-- Таймер до смены
local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "TimerLabel"
timerLabel.Size = UDim2.new(0.3, 0, 1, 0)
timerLabel.Position = UDim2.new(0, 10, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Text = "Смена: 5:00"
timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
timerLabel.TextScaled = true
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextXAlignment = Enum.TextXAlignment.Left
timerLabel.Parent = topBar

-- Текущий этаж
local floorLabel = Instance.new("TextLabel")
floorLabel.Name = "FloorLabel"
floorLabel.Size = UDim2.new(0.3, 0, 1, 0)
floorLabel.Position = UDim2.new(0.35, 0, 0, 0)
floorLabel.BackgroundTransparency = 1
floorLabel.Text = "Этаж: 0 / 20"
floorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
floorLabel.TextScaled = true
floorLabel.Font = Enum.Font.GothamBold
floorLabel.TextXAlignment = Enum.TextXAlignment.Center
floorLabel.Parent = topBar

-- Счётчик смертей
local deathLabel = Instance.new("TextLabel")
deathLabel.Name = "DeathLabel"
deathLabel.Size = UDim2.new(0.3, 0, 1, 0)
deathLabel.Position = UDim2.new(0.68, 0, 0, 0)
deathLabel.BackgroundTransparency = 1
deathLabel.Text = "Смертей: 0"
deathLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
deathLabel.TextScaled = true
deathLabel.Font = Enum.Font.GothamBold
deathLabel.TextXAlignment = Enum.TextXAlignment.Right
deathLabel.Parent = topBar

-- Контейнер уведомлений
local notifContainer = Instance.new("Frame")
notifContainer.Name = "Notifications"
notifContainer.Size = UDim2.new(0.5, 0, 0, 200)
notifContainer.Position = UDim2.new(0.25, 0, 0.15, 0)
notifContainer.BackgroundTransparency = 1
notifContainer.Parent = screenGui

local notifLayout = Instance.new("UIListLayout")
notifLayout.SortOrder = Enum.SortOrder.LayoutOrder
notifLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
notifLayout.Padding = UDim.new(0, 5)
notifLayout.Parent = notifContainer

-- Кнопка респавна
local respawnButton = Instance.new("TextButton")
respawnButton.Name = "RespawnButton"
respawnButton.Size = UDim2.new(0, 200, 0, 50)
respawnButton.Position = UDim2.new(0.5, -100, 0.9, 0)
respawnButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
respawnButton.BackgroundTransparency = 0.3
respawnButton.Text = "Респавн [R]"
respawnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
respawnButton.TextScaled = true
respawnButton.Font = Enum.Font.GothamBold
respawnButton.BorderSizePixel = 0
respawnButton.Parent = screenGui

local respawnCorner = Instance.new("UICorner")
respawnCorner.CornerRadius = UDim.new(0, 10)
respawnCorner.Parent = respawnButton

-----------------------------------------------
-- ЭКРАН ПОБЕДЫ
-----------------------------------------------
local winFrame = Instance.new("Frame")
winFrame.Name = "WinScreen"
winFrame.Size = UDim2.new(0.6, 0, 0.5, 0)
winFrame.Position = UDim2.new(0.2, 0, 0.25, 0)
winFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 40)
winFrame.BackgroundTransparency = 0.2
winFrame.BorderSizePixel = 0
winFrame.Visible = false
winFrame.Parent = screenGui

local winCorner = Instance.new("UICorner")
winCorner.CornerRadius = UDim.new(0, 15)
winCorner.Parent = winFrame

local winTitle = Instance.new("TextLabel")
winTitle.Size = UDim2.new(1, 0, 0.3, 0)
winTitle.BackgroundTransparency = 1
winTitle.Text = "ПОБЕДА!"
winTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
winTitle.TextScaled = true
winTitle.Font = Enum.Font.GothamBold
winTitle.Parent = winFrame

local winStats = Instance.new("TextLabel")
winStats.Name = "WinStats"
winStats.Size = UDim2.new(1, 0, 0.4, 0)
winStats.Position = UDim2.new(0, 0, 0.3, 0)
winStats.BackgroundTransparency = 1
winStats.Text = "Время: 0 сек\nСмертей: 0"
winStats.TextColor3 = Color3.fromRGB(200, 200, 255)
winStats.TextScaled = true
winStats.Font = Enum.Font.Gotham
winStats.Parent = winFrame

local playAgainBtn = Instance.new("TextButton")
playAgainBtn.Size = UDim2.new(0.4, 0, 0.2, 0)
playAgainBtn.Position = UDim2.new(0.3, 0, 0.75, 0)
playAgainBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
playAgainBtn.Text = "Играть снова"
playAgainBtn.TextColor3 = Color3.new(1, 1, 1)
playAgainBtn.TextScaled = true
playAgainBtn.Font = Enum.Font.GothamBold
playAgainBtn.BorderSizePixel = 0
playAgainBtn.Parent = winFrame

local playAgainCorner = Instance.new("UICorner")
playAgainCorner.CornerRadius = UDim.new(0, 10)
playAgainCorner.Parent = playAgainBtn

-----------------------------------------------
-- ФУНКЦИИ
-----------------------------------------------

local function formatTime(seconds)
	local mins = math.floor(seconds / 60)
	local secs = seconds % 60
	return string.format("%d:%02d", mins, secs)
end

local function showNotification(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 35)
	label.BackgroundColor3 = color or Color3.fromRGB(50, 50, 80)
	label.BackgroundTransparency = 0.4
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.BorderSizePixel = 0
	label.Parent = notifContainer
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
	
	-- Анимация появления
	label.TextTransparency = 1
	label.BackgroundTransparency = 1
	local tweenIn = TweenService:Create(label, TweenInfo.new(0.3), {
		TextTransparency = 0,
		BackgroundTransparency = 0.4,
	})
	tweenIn:Play()
	
	-- Автоудаление через 3 секунды
	task.delay(3, function()
		local tweenOut = TweenService:Create(label, TweenInfo.new(0.5), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Connect(function()
			label:Destroy()
		end)
	end)
end

-----------------------------------------------
-- ОБРАБОТКА СОБЫТИЙ
-----------------------------------------------

UpdateTimer.OnClientEvent:Connect(function(seconds)
	timerLabel.Text = "Смена: " .. formatTime(seconds)
	
	-- Красный при <30 сек
	if seconds <= 30 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	elseif seconds <= 60 then
		timerLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
	else
		timerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
end)

UpdateFloor.OnClientEvent:Connect(function(floorNum)
	floorLabel.Text = "Этаж: " .. floorNum .. " / 20"
	
	-- Цвет по сложности
	if floorNum <= 4 then
		floorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	elseif floorNum <= 8 then
		floorLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
	elseif floorNum <= 12 then
		floorLabel.TextColor3 = Color3.fromRGB(255, 180, 50)
	elseif floorNum <= 16 then
		floorLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		floorLabel.TextColor3 = Color3.fromRGB(200, 80, 255)
	end
end)

UpdateDeaths.OnClientEvent:Connect(function(deaths)
	deathLabel.Text = "Смертей: " .. deaths
end)

ShowNotification.OnClientEvent:Connect(function(text, color)
	showNotification(text, color)
end)

PlayerCheckpoint.OnClientEvent:Connect(function(floor)
	showNotification("ЧЕКПОИНТ! Этаж " .. floor, Color3.fromRGB(50, 255, 50))
end)

PlayerFinished.OnClientEvent:Connect(function(elapsed, deaths)
	winFrame.Visible = true
	winStats.Text = "Время: " .. formatTime(elapsed) .. "\nСмертей: " .. deaths
end)

TowerShuffled.OnClientEvent:Connect(function()
	showNotification("ЭТАЖИ ОБНОВЛЕНЫ!", Color3.fromRGB(255, 100, 50))
end)

-----------------------------------------------
-- КНОПКИ
-----------------------------------------------

respawnButton.MouseButton1Click:Connect(function()
	RequestRespawn:FireServer()
end)

-- Клавиша R для респавна
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.R then
		RequestRespawn:FireServer()
	end
end)

playAgainBtn.MouseButton1Click:Connect(function()
	winFrame.Visible = false
	RequestRespawn:FireServer()
end)

-----------------------------------------------
-- НАЧАЛЬНОЕ УВЕДОМЛЕНИЕ
-----------------------------------------------
task.wait(3)
showNotification("Добро пожаловать в ПАРКУР-БАШНЮ!", Color3.fromRGB(100, 200, 255))
task.wait(2)
showNotification("Доберись до вершины! Этажи меняются каждые 5 минут.", Color3.fromRGB(200, 200, 200))
task.wait(2)
showNotification("Нажми R для быстрого респавна.", Color3.fromRGB(200, 200, 200))

print("[ParkourUI] Интерфейс загружен!")
