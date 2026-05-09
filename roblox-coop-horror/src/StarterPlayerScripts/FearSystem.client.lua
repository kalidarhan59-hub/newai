--[[
    FearSystem.client.lua
    Клиентская система страха — ввод, движение, приседание, бег
    Расположение: StarterPlayerScripts/FearSystem.client.lua
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local SharedTypes = require(ReplicatedStorage.Modules.SharedTypes)

local LocalPlayer = Players.LocalPlayer

-- RemoteEvents
local Events = ReplicatedStorage:WaitForChild("Events")
local FearUpdated = Events:WaitForChild("FearUpdated")
local InteractionRequest = Events:WaitForChild("InteractionRequest")
local NoiseGenerated = Events:WaitForChild("NoiseGenerated")

---------------------------------------------------------------------
-- Состояние клиента
---------------------------------------------------------------------
local ClientState = {
    IsSprinting = false,
    IsCrouching = false,
    IsBreathing = false, -- глубокое дыхание (снижает страх)
    Stamina = GameConfig.Player.MaxStamina,
    Fear = 0,
    InvertedControls = false,
    InvertTimer = 0,
}

---------------------------------------------------------------------
-- Управление движением
---------------------------------------------------------------------
local function setMovementSpeed(speed)
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    humanoid.WalkSpeed = speed
end

local function startSprinting()
    if ClientState.IsCrouching then return end
    if ClientState.Stamina <= 0 then return end

    ClientState.IsSprinting = true
    setMovementSpeed(GameConfig.Player.RunSpeed)
end

local function stopSprinting()
    ClientState.IsSprinting = false
    if ClientState.IsCrouching then
        setMovementSpeed(GameConfig.Player.CrouchSpeed)
    else
        setMovementSpeed(GameConfig.Player.WalkSpeed)
    end
end

local function toggleCrouch()
    ClientState.IsCrouching = not ClientState.IsCrouching

    if ClientState.IsCrouching then
        ClientState.IsSprinting = false
        setMovementSpeed(GameConfig.Player.CrouchSpeed)

        -- Визуальный эффект приседания (смещение камеры вниз)
        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.CameraOffset = Vector3.new(0, -1.5, 0)
            end
        end
    else
        setMovementSpeed(GameConfig.Player.WalkSpeed)

        local character = LocalPlayer.Character
        if character then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.CameraOffset = Vector3.new(0, 0, 0)
            end
        end
    end
end

---------------------------------------------------------------------
-- Глубокое дыхание (снижение страха)
---------------------------------------------------------------------
local function startBreathing()
    ClientState.IsBreathing = true
end

local function stopBreathing()
    ClientState.IsBreathing = false
end

---------------------------------------------------------------------
-- Обновление стамины
---------------------------------------------------------------------
local function updateStamina(deltaTime)
    if ClientState.IsSprinting then
        ClientState.Stamina = ClientState.Stamina - GameConfig.Player.StaminaDrainRate * deltaTime

        if ClientState.Stamina <= 0 then
            ClientState.Stamina = 0
            stopSprinting()
        end

        -- Генерация шума от бега
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.MoveDirection.Magnitude > 0.1 then
                -- Шум бега (только периодически, не каждый кадр)
                if math.random() < deltaTime * 2 then
                    InteractionRequest:FireServer("GenerateNoise", {
                        Level = GameConfig.NoiseLevel.Loud,
                    })
                end
            end
        end
    else
        ClientState.Stamina = math.min(
            GameConfig.Player.MaxStamina,
            ClientState.Stamina + GameConfig.Player.StaminaRegenRate * deltaTime
        )
    end
end

---------------------------------------------------------------------
-- Инвертирование управления (при панике)
---------------------------------------------------------------------
local function invertControls(duration)
    ClientState.InvertedControls = true
    ClientState.InvertTimer = duration

    -- Инвертировать через Humanoid
    -- В реальности это обрабатывается через модификацию MoveDirection
end

---------------------------------------------------------------------
-- Обработка ввода
---------------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    -- Бег (Shift)
    if input.KeyCode == Enum.KeyCode.LeftShift then
        startSprinting()
    end

    -- Приседание (C)
    if input.KeyCode == Enum.KeyCode.C then
        toggleCrouch()
    end

    -- Глубокое дыхание (B)
    if input.KeyCode == Enum.KeyCode.B then
        startBreathing()
    end

    -- Взаимодействие (E)
    if input.KeyCode == Enum.KeyCode.E then
        -- Найти ближайший интерактивный объект
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local rootPart = character.HumanoidRootPart
        local nearestDist = 10
        local nearestObject = nil

        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:GetAttribute("Interactable") and obj:IsA("BasePart") then
                local dist = (obj.Position - rootPart.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearestObject = obj
                end
            end
        end

        if nearestObject then
            local interactionType = nearestObject:GetAttribute("InteractionType")
            InteractionRequest:FireServer(interactionType or "Interact", {
                ObjectName = nearestObject.Name,
                ItemType = nearestObject:GetAttribute("ItemType"),
            })
        end
    end

    -- Инвентарь (Tab)
    if input.KeyCode == Enum.KeyCode.Tab then
        -- Toggle inventory UI (обрабатывается в HorrorUI)
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            local inventoryGui = playerGui:FindFirstChild("InventoryGui")
            if inventoryGui then
                inventoryGui.Enabled = not inventoryGui.Enabled
            end
        end
    end

    -- Передать предмет (G)
    if input.KeyCode == Enum.KeyCode.G then
        -- Найти ближайшего игрока
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local nearestPlayer = nil
        local nearestDist = 10

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local pChar = player.Character
                if pChar and pChar:FindFirstChild("HumanoidRootPart") then
                    local dist = (pChar.HumanoidRootPart.Position - character.HumanoidRootPart.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearestPlayer = player
                    end
                end
            end
        end

        if nearestPlayer then
            -- Передать первый предмет из инвентаря
            InteractionRequest:FireServer(SharedTypes.InteractionType.GiveItem, {
                ReceiverName = nearestPlayer.Name,
                Slot = 1, -- TODO: выбор слота через UI
            })
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.LeftShift then
        stopSprinting()
    end

    if input.KeyCode == Enum.KeyCode.B then
        stopBreathing()
    end
end)

---------------------------------------------------------------------
-- Мобильные кнопки
---------------------------------------------------------------------
local function createMobileControls()
    if not UserInputService.TouchEnabled then return end

    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileControlsGui"
    gui.Parent = playerGui

    local function createButton(name, text, position, callback)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(0, 55, 0, 55)
        button.Position = position
        button.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        button.BackgroundTransparency = 0.3
        button.Text = text
        button.TextColor3 = Color3.fromRGB(200, 200, 200)
        button.TextScaled = true
        button.Font = Enum.Font.GothamBold
        button.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        button.Activated:Connect(callback)
        return button
    end

    -- Кнопка бега
    local sprintBtn = createButton("SprintBtn", "🏃", UDim2.new(0, 10, 0.7, 0), function()
        if ClientState.IsSprinting then
            stopSprinting()
        else
            startSprinting()
        end
    end)

    -- Кнопка приседания
    createButton("CrouchBtn", "🧎", UDim2.new(0, 10, 0.7, 60), toggleCrouch)

    -- Кнопка дыхания
    local breathBtn = createButton("BreathBtn", "💨", UDim2.new(0, 10, 0.7, 120), function()
        if ClientState.IsBreathing then
            stopBreathing()
        else
            startBreathing()
        end
    end)

    -- Кнопка взаимодействия
    createButton("InteractBtn", "E", UDim2.new(0, 75, 0.7, 0), function()
        -- Имитируем нажатие E
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end

        local rootPart = character.HumanoidRootPart
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:GetAttribute("Interactable") and obj:IsA("BasePart") then
                local dist = (obj.Position - rootPart.Position).Magnitude
                if dist < 10 then
                    InteractionRequest:FireServer("Interact", {
                        ObjectName = obj.Name,
                    })
                    break
                end
            end
        end
    end)
end

---------------------------------------------------------------------
-- Обработка событий от сервера
---------------------------------------------------------------------
FearUpdated.OnClientEvent:Connect(function(fearLevel)
    ClientState.Fear = fearLevel

    -- Паника: инвертирование управления
    if fearLevel >= GameConfig.Fear.MaxPanicThreshold and not ClientState.InvertedControls then
        invertControls(GameConfig.Fear.InvertControlsDuration)
    end

    -- Глубокое дыхание снижает страх (отправляем на сервер)
    if ClientState.IsBreathing and fearLevel > 0 then
        InteractionRequest:FireServer("Breathing", {})
    end
end)

---------------------------------------------------------------------
-- Главный цикл
---------------------------------------------------------------------
RunService.Heartbeat:Connect(function(deltaTime)
    updateStamina(deltaTime)

    -- Обновление инвертирования
    if ClientState.InvertedControls then
        ClientState.InvertTimer = ClientState.InvertTimer - deltaTime
        if ClientState.InvertTimer <= 0 then
            ClientState.InvertedControls = false
        end
    end
end)

---------------------------------------------------------------------
-- Инициализация
---------------------------------------------------------------------
createMobileControls()

-- Экспорт состояния
local ClientStateAPI = Instance.new("BindableFunction")
ClientStateAPI.Name = "ClientStateAPI"
ClientStateAPI.OnInvoke = function(action)
    if action == "GetStamina" then
        return ClientState.Stamina
    elseif action == "GetFear" then
        return ClientState.Fear
    elseif action == "IsSprinting" then
        return ClientState.IsSprinting
    elseif action == "IsCrouching" then
        return ClientState.IsCrouching
    end
end
ClientStateAPI.Parent = LocalPlayer

print("[FearSystem] Клиентская система страха активирована.")
