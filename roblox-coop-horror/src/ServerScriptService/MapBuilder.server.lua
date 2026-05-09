--[[
    MapBuilder.server.lua
    Автоматическая генерация карты больницы "Тихая Гавань"
    Этот скрипт создаёт ВСЮ карту из кода: комнаты, коридоры, двери, мебель,
    освещение, точки спавна, объекты головоломок.
    
    Расположение: ServerScriptService/MapBuilder.server.lua
    
    ВАЖНО: Запустите игру один раз — скрипт построит карту.
    После этого можно удалить этот скрипт если хотите.
]]

local Lighting = game:GetService("Lighting")

---------------------------------------------------------------------
-- Вспомогательные функции
---------------------------------------------------------------------

-- Создать часть (стену, пол, потолок)
local function createPart(name, size, position, color, material, parent, transparency)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Position = position
    part.Anchored = true
    part.BrickColor = BrickColor.new(color or "Medium stone grey")
    part.Material = material or Enum.Material.Concrete
    part.Transparency = transparency or 0
    part.Parent = parent
    return part
end

-- Создать комнату (4 стены + пол + потолок)
local function createRoom(name, centerX, centerZ, floorY, width, depth, height, parent, wallColor, floorColor)
    local room = Instance.new("Folder")
    room.Name = name
    room.Parent = parent

    wallColor = wallColor or "Institutional white"
    floorColor = floorColor or "Dark stone grey"
    local wallThickness = 1
    local ceilingColor = "Institutional white"

    -- Пол
    createPart("Floor", Vector3.new(width, 1, depth),
        Vector3.new(centerX, floorY, centerZ), floorColor, Enum.Material.SmoothPlastic, room)

    -- Потолок
    createPart("Ceiling", Vector3.new(width, 0.5, depth),
        Vector3.new(centerX, floorY + height, centerZ), ceilingColor, Enum.Material.SmoothPlastic, room)

    -- Стена Север (+Z)
    createPart("WallNorth", Vector3.new(width, height, wallThickness),
        Vector3.new(centerX, floorY + height/2, centerZ + depth/2), wallColor, Enum.Material.Concrete, room)

    -- Стена Юг (-Z)
    createPart("WallSouth", Vector3.new(width, height, wallThickness),
        Vector3.new(centerX, floorY + height/2, centerZ - depth/2), wallColor, Enum.Material.Concrete, room)

    -- Стена Запад (-X)
    createPart("WallWest", Vector3.new(wallThickness, height, depth),
        Vector3.new(centerX - width/2, floorY + height/2, centerZ), wallColor, Enum.Material.Concrete, room)

    -- Стена Восток (+X)
    createPart("WallEast", Vector3.new(wallThickness, height, depth),
        Vector3.new(centerX + width/2, floorY + height/2, centerZ), wallColor, Enum.Material.Concrete, room)

    return room
end

-- Создать дверной проём (удалить часть стены и добавить дверь)
local function createDoor(name, position, size, parent, locked, requiredKey)
    local door = Instance.new("Part")
    door.Name = name
    door.Size = size or Vector3.new(5, 8, 1)
    door.Position = position
    door.Anchored = true
    door.BrickColor = BrickColor.new("Reddish brown")
    door.Material = Enum.Material.Wood
    door.Parent = parent

    door:SetAttribute("Interactable", true)
    door:SetAttribute("InteractionType", "OpenDoor")
    door:SetAttribute("DoorName", name)
    door:SetAttribute("Locked", locked or false)
    if requiredKey then
        door:SetAttribute("RequiredKey", requiredKey)
    end

    -- ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = locked and "Открыть (нужен ключ)" or "Открыть"
    prompt.ObjectText = "Дверь"
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.Parent = door

    return door
end

-- Создать свет
local function createLight(name, position, parent, brightness, color, range)
    local lightPart = Instance.new("Part")
    lightPart.Name = name
    lightPart.Size = Vector3.new(2, 0.5, 2)
    lightPart.Position = position
    lightPart.Anchored = true
    lightPart.CanCollide = false
    lightPart.BrickColor = BrickColor.new("Institutional white")
    lightPart.Material = Enum.Material.Neon
    lightPart.Transparency = 0.3
    lightPart.Parent = parent

    local pointLight = Instance.new("PointLight")
    pointLight.Name = "Light"
    pointLight.Brightness = brightness or 0.5
    pointLight.Color = color or Color3.fromRGB(255, 230, 200)
    pointLight.Range = range or 20
    pointLight.Parent = lightPart

    return lightPart
end

-- Создать мерцающий свет
local function createFlickeringLight(name, position, parent)
    local light = createLight(name, position, parent, 0.3, Color3.fromRGB(255, 200, 150), 15)
    local pointLight = light:FindFirstChildOfClass("PointLight")

    -- Скрипт мерцания
    task.spawn(function()
        while light.Parent do
            if pointLight then
                pointLight.Brightness = 0.1 + math.random() * 0.5
                if math.random() < 0.05 then
                    pointLight.Enabled = false
                    task.wait(0.05 + math.random() * 0.2)
                    pointLight.Enabled = true
                end
            end
            task.wait(0.1 + math.random() * 0.3)
        end
    end)

    return light
end

-- Создать предмет для подбора
local function createPickupItem(name, itemType, position, parent, itemColor)
    local item = Instance.new("Part")
    item.Name = "Item_" .. name
    item.Size = Vector3.new(1, 1, 1)
    item.Position = position
    item.Anchored = true
    item.CanCollide = false
    item.BrickColor = BrickColor.new(itemColor or "Bright yellow")
    item.Material = Enum.Material.Neon
    item.Shape = Enum.PartType.Ball
    item.Parent = parent

    item:SetAttribute("Interactable", true)
    item:SetAttribute("ItemType", itemType)
    item:SetAttribute("InteractionType", "PickupItem")

    -- Свечение
    local glow = Instance.new("PointLight")
    glow.Brightness = 1
    glow.Range = 6
    glow.Color = Color3.fromRGB(255, 255, 150)
    glow.Parent = item

    -- Надпись
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 100, 0, 25)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = item

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(255, 255, 100)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = billboard

    -- ProximityPrompt
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Подобрать"
    prompt.ObjectText = name
    prompt.HoldDuration = 0.3
    prompt.MaxActivationDistance = 8
    prompt.Parent = item

    -- Парящая анимация
    task.spawn(function()
        local startY = position.Y
        local t = math.random() * math.pi * 2
        while item.Parent do
            t = t + 0.05
            item.Position = Vector3.new(position.X, startY + math.sin(t) * 0.3, position.Z)
            task.wait(0.03)
        end
    end)

    return item
end

-- Создать мебель (стол, кровать, шкаф и т.д.)
local function createFurniture(name, size, position, color, material, parent)
    local furniture = createPart(name, size, position, color, material or Enum.Material.WoodPlanks, parent)
    return furniture
end

-- Создать объект головоломки
local function createPuzzleObject(name, puzzleType, position, parent)
    local obj = Instance.new("Part")
    obj.Name = name
    obj.Size = Vector3.new(3, 4, 2)
    obj.Position = position
    obj.Anchored = true
    obj.BrickColor = BrickColor.new("Medium stone grey")
    obj.Material = Enum.Material.Metal
    obj.Parent = parent

    obj:SetAttribute("Interactable", true)
    obj:SetAttribute("PuzzleType", puzzleType)
    obj:SetAttribute("InteractionType", "SolvePuzzle")

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Взаимодействовать"
    prompt.ObjectText = name
    prompt.HoldDuration = 0.5
    prompt.MaxActivationDistance = 8
    prompt.Parent = obj

    -- Подсветка
    local highlight = Instance.new("SurfaceGui")
    highlight.Face = Enum.NormalId.Front
    highlight.Parent = obj

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 0.5
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.Text = name
    label.TextColor3 = Color3.fromRGB(200, 200, 100)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = highlight

    return obj
end

-- Создать записку
local function createNote(noteText, noteIndex, position, parent)
    local note = Instance.new("Part")
    note.Name = "Note_" .. noteIndex
    note.Size = Vector3.new(1.5, 0.1, 1)
    note.Position = position
    note.Anchored = true
    note.BrickColor = BrickColor.new("Brick yellow")
    note.Material = Enum.Material.SmoothPlastic
    note.Parent = parent

    note:SetAttribute("Interactable", true)
    note:SetAttribute("ItemType", "Note")
    note:SetAttribute("NoteIndex", noteIndex)
    note:SetAttribute("NoteText", noteText)
    note:SetAttribute("InteractionType", "PickupItem")

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Прочитать"
    prompt.ObjectText = "Записка"
    prompt.HoldDuration = 0.3
    prompt.MaxActivationDistance = 6
    prompt.Parent = note

    -- Свечение
    local glow = Instance.new("PointLight")
    glow.Brightness = 0.5
    glow.Range = 4
    glow.Color = Color3.fromRGB(255, 240, 200)
    glow.Parent = note

    return note
end

-- Создать шкафчик (место для прятания)
local function createHidingSpot(name, position, parent)
    local locker = Instance.new("Part")
    locker.Name = name
    locker.Size = Vector3.new(3, 7, 3)
    locker.Position = position
    locker.Anchored = true
    locker.BrickColor = BrickColor.new("Dark stone grey")
    locker.Material = Enum.Material.Metal
    locker.Parent = parent

    locker:SetAttribute("Interactable", true)
    locker:SetAttribute("InteractionType", "HideInLocker")

    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText = "Спрятаться"
    prompt.ObjectText = "Шкафчик"
    prompt.HoldDuration = 0.8
    prompt.MaxActivationDistance = 6
    prompt.Parent = locker

    return locker
end

---------------------------------------------------------------------
-- ГЛАВНАЯ ФУНКЦИЯ: Построить всю больницу
---------------------------------------------------------------------
local function buildHospital()
    print("[MapBuilder] Начинаю строительство больницы...")

    -- Удалить старый Baseplate если есть
    local oldBaseplate = workspace:FindFirstChild("Baseplate")
    if oldBaseplate then oldBaseplate:Destroy() end

    -- Главная папка
    local hospital = Instance.new("Folder")
    hospital.Name = "Hospital"
    hospital.Parent = workspace

    -- Папки для организации
    local floor1 = Instance.new("Folder"); floor1.Name = "Floor1_Reception"; floor1.Parent = hospital
    local floor2 = Instance.new("Folder"); floor2.Name = "Floor2_Wards"; floor2.Parent = hospital
    local floor3 = Instance.new("Folder"); floor3.Name = "Floor3_Basement"; floor3.Parent = hospital
    local exteriorFolder = Instance.new("Folder"); exteriorFolder.Name = "Exterior"; exteriorFolder.Parent = hospital

    -- Специальные папки (нужны другим скриптам)
    local patrolWaypoints = Instance.new("Folder"); patrolWaypoints.Name = "PatrolWaypoints"; patrolWaypoints.Parent = workspace
    local gameSpawnPoints = Instance.new("Folder"); gameSpawnPoints.Name = "GameSpawnPoints"; gameSpawnPoints.Parent = workspace
    local droppedItems = Instance.new("Folder"); droppedItems.Name = "DroppedItems"; droppedItems.Parent = workspace
    local floor2Lights = Instance.new("Folder"); floor2Lights.Name = "Floor2Lights"; floor2Lights.Parent = workspace

    -- Параметры
    local FLOOR_HEIGHT = 12
    local FLOOR1_Y = 0
    local FLOOR2_Y = FLOOR_HEIGHT + 1
    local FLOOR3_Y = -FLOOR_HEIGHT - 1

    ---------------------------------------------------------------
    -- ЭТАЖ 1: ПРИЁМНАЯ (Y = 0)
    ---------------------------------------------------------------
    print("[MapBuilder] Строю Этаж 1 — Приёмная...")

    -- Главный холл (лобби)
    local lobby = createRoom("Lobby", 0, 0, FLOOR1_Y, 40, 30, FLOOR_HEIGHT, floor1,
        "Institutional white", "Dark stone grey")

    -- Стойка регистрации
    createFurniture("ReceptionDesk", Vector3.new(12, 4, 3), Vector3.new(0, FLOOR1_Y + 2.5, 8),
        "Reddish brown", Enum.Material.WoodPlanks, lobby)

    -- Стулья в зоне ожидания
    for i = 1, 4 do
        createFurniture("Chair" .. i, Vector3.new(2, 3, 2),
            Vector3.new(-12 + i * 5, FLOOR1_Y + 2, -8),
            "Medium stone grey", Enum.Material.Plastic, lobby)
    end

    -- Коридор 1 (ведёт направо)
    local corridor1 = createRoom("Corridor1", 35, 0, FLOOR1_Y, 30, 6, FLOOR_HEIGHT, floor1,
        "Institutional white", "Medium stone grey")

    -- Комната охраны
    local securityRoom = createRoom("SecurityRoom", 55, -15, FLOOR1_Y, 15, 15, FLOOR_HEIGHT, floor1,
        "Sand blue", "Dark stone grey")
    createDoor("SecurityDoor", Vector3.new(55, FLOOR1_Y + 4.5, -7.5), Vector3.new(5, 8, 1), floor1, false)
    createFurniture("SecurityDesk", Vector3.new(6, 3, 4), Vector3.new(55, FLOOR1_Y + 2, -15),
        "Dark stone grey", Enum.Material.Metal, securityRoom)

    -- Кабинет врача
    local doctorOffice = createRoom("DoctorOffice", 55, 15, FLOOR1_Y, 15, 15, FLOOR_HEIGHT, floor1,
        "Pastel blue", "Dark stone grey")
    createDoor("DoctorDoor", Vector3.new(55, FLOOR1_Y + 4.5, 7.5), Vector3.new(5, 8, 1), floor1, true, "Key")
    createFurniture("DoctorDesk", Vector3.new(6, 3, 4), Vector3.new(57, FLOOR1_Y + 2, 17),
        "Reddish brown", Enum.Material.WoodPlanks, doctorOffice)
    createFurniture("Bookshelf", Vector3.new(8, 8, 2), Vector3.new(62, FLOOR1_Y + 4.5, 15),
        "Reddish brown", Enum.Material.WoodPlanks, doctorOffice)

    -- Коридор 2 (ведёт налево)
    local corridor2 = createRoom("Corridor2", -35, 0, FLOOR1_Y, 30, 6, FLOOR_HEIGHT, floor1,
        "Institutional white", "Medium stone grey")

    -- Комната ожидания
    local waitingRoom = createRoom("WaitingRoom", -55, -15, FLOOR1_Y, 15, 15, FLOOR_HEIGHT, floor1,
        "Sand green", "Dark stone grey")
    createDoor("WaitingDoor", Vector3.new(-55, FLOOR1_Y + 4.5, -7.5), Vector3.new(5, 8, 1), floor1, false)

    -- Аптека
    local pharmacy = createRoom("Pharmacy", -55, 15, FLOOR1_Y, 15, 15, FLOOR_HEIGHT, floor1,
        "Pastel green", "Dark stone grey")
    createDoor("PharmacyDoor", Vector3.new(-55, FLOOR1_Y + 4.5, 7.5), Vector3.new(5, 8, 1), floor1, true, "Key")
    -- Полки
    for i = 1, 3 do
        createFurniture("PharmShelf" .. i, Vector3.new(2, 7, 10),
            Vector3.new(-60 + i * 3, FLOOR1_Y + 4, 15),
            "White", Enum.Material.SmoothPlastic, pharmacy)
    end

    -- Лестница наверх (на Этаж 2)
    local stairsUp = Instance.new("Folder"); stairsUp.Name = "StairsUp"; stairsUp.Parent = floor1
    for i = 0, 12 do
        createPart("Step" .. i, Vector3.new(6, 1, 3),
            Vector3.new(0, FLOOR1_Y + 1 + i, 18 + i * 2),
            "Medium stone grey", Enum.Material.Concrete, stairsUp)
    end

    -- Лестница вниз (в Подвал)
    local stairsDown = Instance.new("Folder"); stairsDown.Name = "StairsDown"; stairsDown.Parent = floor1
    for i = 0, 12 do
        createPart("Step" .. i, Vector3.new(6, 1, 3),
            Vector3.new(0, FLOOR1_Y - i, -18 - i * 2),
            "Medium stone grey", Enum.Material.Concrete, stairsDown)
    end

    -- Освещение Этаж 1
    createFlickeringLight("LobbyLight1", Vector3.new(-10, FLOOR1_Y + FLOOR_HEIGHT - 0.5, 0), floor1)
    createFlickeringLight("LobbyLight2", Vector3.new(10, FLOOR1_Y + FLOOR_HEIGHT - 0.5, 0), floor1)
    createLight("CorridorLight1", Vector3.new(30, FLOOR1_Y + FLOOR_HEIGHT - 0.5, 0), floor1, 0.3)
    createLight("CorridorLight2", Vector3.new(-30, FLOOR1_Y + FLOOR_HEIGHT - 0.5, 0), floor1, 0.3)

    -- Шкафчики для прятания
    createHidingSpot("Locker_F1_1", Vector3.new(18, FLOOR1_Y + 4, 2), floor1)
    createHidingSpot("Locker_F1_2", Vector3.new(-18, FLOOR1_Y + 4, -2), floor1)

    ---------------------------------------------------------------
    -- ЭТАЖ 2: ПАЛАТЫ (Y = 13)
    ---------------------------------------------------------------
    print("[MapBuilder] Строю Этаж 2 — Палаты...")

    -- Главный коридор Этаж 2
    local corridor2F = createRoom("MainCorridor", 0, 50, FLOOR2_Y, 80, 6, FLOOR_HEIGHT, floor2,
        "Light stone grey", "Medium stone grey")

    -- Палата 1
    local ward1 = createRoom("Ward1", -30, 62, FLOOR2_Y, 15, 12, FLOOR_HEIGHT, floor2,
        "Pastel blue", "Dark stone grey")
    createDoor("Ward1Door", Vector3.new(-30, FLOOR2_Y + 4.5, 56), Vector3.new(5, 8, 1), floor2, false)
    createFurniture("Bed_W1", Vector3.new(7, 3, 3), Vector3.new(-32, FLOOR2_Y + 2, 64),
        "White", Enum.Material.SmoothPlastic, ward1)

    -- Палата 2
    local ward2 = createRoom("Ward2", -10, 62, FLOOR2_Y, 15, 12, FLOOR_HEIGHT, floor2,
        "Pastel blue", "Dark stone grey")
    createDoor("Ward2Door", Vector3.new(-10, FLOOR2_Y + 4.5, 56), Vector3.new(5, 8, 1), floor2, false)
    createFurniture("Bed_W2", Vector3.new(7, 3, 3), Vector3.new(-12, FLOOR2_Y + 2, 64),
        "White", Enum.Material.SmoothPlastic, ward2)

    -- Палата 3
    local ward3 = createRoom("Ward3", 10, 62, FLOOR2_Y, 15, 12, FLOOR_HEIGHT, floor2,
        "Pastel blue", "Dark stone grey")
    createDoor("Ward3Door", Vector3.new(10, FLOOR2_Y + 4.5, 56), Vector3.new(5, 8, 1), floor2, false)
    createFurniture("Bed_W3", Vector3.new(7, 3, 3), Vector3.new(8, FLOOR2_Y + 2, 64),
        "White", Enum.Material.SmoothPlastic, ward3)

    -- Палата 4 (запертая)
    local ward4 = createRoom("Ward4", 30, 62, FLOOR2_Y, 15, 12, FLOOR_HEIGHT, floor2,
        "Pastel blue", "Dark stone grey")
    createDoor("Ward4Door", Vector3.new(30, FLOOR2_Y + 4.5, 56), Vector3.new(5, 8, 1), floor2, true, "Key")
    createFurniture("Bed_W4", Vector3.new(7, 3, 3), Vector3.new(28, FLOOR2_Y + 2, 64),
        "White", Enum.Material.SmoothPlastic, ward4)

    -- Операционная
    local operatingRoom = createRoom("OperatingRoom", -30, 38, FLOOR2_Y, 20, 15, FLOOR_HEIGHT, floor2,
        "White", "Flint")
    createDoor("OperatingDoor", Vector3.new(-30, FLOOR2_Y + 4.5, 45.5), Vector3.new(5, 8, 1), floor2, true, "Key")
    createFurniture("OperatingTable", Vector3.new(6, 3, 3), Vector3.new(-30, FLOOR2_Y + 2, 36),
        "Medium stone grey", Enum.Material.Metal, operatingRoom)
    createFurniture("EquipmentCart", Vector3.new(3, 4, 2), Vector3.new(-36, FLOOR2_Y + 2.5, 34),
        "Dark stone grey", Enum.Material.Metal, operatingRoom)

    -- Лаборатория (головоломка с реагентами)
    local lab = createRoom("Laboratory", 30, 38, FLOOR2_Y, 20, 15, FLOOR_HEIGHT, floor2,
        "Sand blue", "Dark stone grey")
    createDoor("LabDoor", Vector3.new(30, FLOOR2_Y + 4.5, 45.5), Vector3.new(5, 8, 1), floor2, false)
    createFurniture("LabTable", Vector3.new(10, 3.5, 4), Vector3.new(30, FLOOR2_Y + 2.2, 35),
        "White", Enum.Material.SmoothPlastic, lab)
    createPuzzleObject("Лаборатория — Смешивание", "LabReagents", Vector3.new(30, FLOOR2_Y + 5, 33), lab)

    -- Электрощит (головоломка с предохранителями)
    createPuzzleObject("Электрощит", "FuseBox", Vector3.new(0, FLOOR2_Y + 5, 47), floor2)

    -- Освещение Этаж 2 (изначально выключено — включится после головоломки)
    local light2_1 = createLight("F2Light1", Vector3.new(-20, FLOOR2_Y + FLOOR_HEIGHT - 0.5, 50), floor2Lights, 0.5)
    local light2_2 = createLight("F2Light2", Vector3.new(0, FLOOR2_Y + FLOOR_HEIGHT - 0.5, 50), floor2Lights, 0.5)
    local light2_3 = createLight("F2Light3", Vector3.new(20, FLOOR2_Y + FLOOR_HEIGHT - 0.5, 50), floor2Lights, 0.5)
    -- Выключить свет (включится после головоломки)
    for _, lightObj in ipairs(floor2Lights:GetChildren()) do
        for _, desc in ipairs(lightObj:GetDescendants()) do
            if desc:IsA("PointLight") or desc:IsA("SpotLight") then
                desc.Enabled = false
            end
        end
    end

    -- Шкафчики Этаж 2
    createHidingSpot("Locker_F2_1", Vector3.new(-35, FLOOR2_Y + 4, 50), floor2)
    createHidingSpot("Locker_F2_2", Vector3.new(35, FLOOR2_Y + 4, 50), floor2)

    ---------------------------------------------------------------
    -- ЭТАЖ 3: ПОДВАЛ (Y = -13)
    ---------------------------------------------------------------
    print("[MapBuilder] Строю Этаж 3 — Подвал...")

    -- Главный коридор подвала
    local basementCorridor = createRoom("BasementCorridor", 0, -50, FLOOR3_Y, 60, 6, FLOOR_HEIGHT, floor3,
        "Dark stone grey", "Really black")

    -- Морг (головоломка с ритуалом)
    local morgue = createRoom("Morgue", -25, -65, FLOOR3_Y, 20, 20, FLOOR_HEIGHT, floor3,
        "Medium stone grey", "Really black")
    createDoor("MorgueDoor", Vector3.new(-25, FLOOR3_Y + 4.5, -55), Vector3.new(5, 8, 1), floor3, false)

    -- Столы в морге
    for i = 1, 3 do
        createFurniture("MorgueTable" .. i, Vector3.new(6, 3, 2.5),
            Vector3.new(-30 + i * 5, FLOOR3_Y + 2, -70),
            "Medium stone grey", Enum.Material.Metal, morgue)
    end

    -- Алтарь для ритуала
    local altar = createPart("Altar", Vector3.new(5, 2, 5),
        Vector3.new(-25, FLOOR3_Y + 1.5, -73), "Really black", Enum.Material.Slate, morgue)
    createPuzzleObject("Алтарь Ритуала", "MorgueRitual", Vector3.new(-25, FLOOR3_Y + 4, -73), morgue)

    -- Позиции свечей на алтаре
    local candlePositions = {
        {name = "CandleNorth", pos = Vector3.new(-25, FLOOR3_Y + 3, -76)},
        {name = "CandleSouth", pos = Vector3.new(-25, FLOOR3_Y + 3, -70)},
        {name = "CandleWest", pos = Vector3.new(-28, FLOOR3_Y + 3, -73)},
        {name = "CandleEast", pos = Vector3.new(-22, FLOOR3_Y + 3, -73)},
    }
    for _, cp in ipairs(candlePositions) do
        local holder = createPart(cp.name, Vector3.new(1, 1.5, 1), cp.pos,
            "Dark stone grey", Enum.Material.Metal, morgue)
        holder:SetAttribute("CandlePosition", cp.name:gsub("Candle", ""))
    end

    -- Подсказка на стене морга
    createPart("RitualHintWall", Vector3.new(0.5, 5, 8),
        Vector3.new(-35, FLOOR3_Y + 5, -65), "Dark stone grey", Enum.Material.Concrete, morgue)
    local hintGui = Instance.new("SurfaceGui")
    hintGui.Face = Enum.NormalId.Right
    hintGui.Parent = morgue:FindFirstChild("RitualHintWall") or morgue
    local hintText = Instance.new("TextLabel")
    hintText.Size = UDim2.new(1, 0, 1, 0)
    hintText.BackgroundTransparency = 0.5
    hintText.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    hintText.Text = "Зажги огни там где тени падают:\nСначала на Севере,\nзатем на Востоке,\nпотом на Юге,\nи наконец на Западе"
    hintText.TextColor3 = Color3.fromRGB(150, 50, 50)
    hintText.TextScaled = true
    hintText.Font = Enum.Font.Antique
    hintText.Parent = hintGui

    -- Котельная
    local boilerRoom = createRoom("BoilerRoom", 25, -65, FLOOR3_Y, 20, 20, FLOOR_HEIGHT, floor3,
        "Dark stone grey", "Really black")
    createDoor("BoilerDoor", Vector3.new(25, FLOOR3_Y + 4.5, -55), Vector3.new(5, 8, 1), floor3, false)
    createFurniture("Boiler1", Vector3.new(6, 8, 6), Vector3.new(22, FLOOR3_Y + 4.5, -70),
        "Really black", Enum.Material.Metal, boilerRoom)
    createFurniture("Pipes", Vector3.new(15, 2, 2), Vector3.new(25, FLOOR3_Y + 10, -65),
        "Dark stone grey", Enum.Material.Metal, boilerRoom)

    -- Сейф (головоломка с кодом)
    local safeRoom = createRoom("SafeRoom", 0, -70, FLOOR3_Y, 10, 10, FLOOR_HEIGHT, floor3,
        "Dark stone grey", "Really black")
    createDoor("SafeDoor", Vector3.new(0, FLOOR3_Y + 4.5, -65), Vector3.new(5, 8, 1), floor3, false)
    createPuzzleObject("Сейф", "SafeCode", Vector3.new(0, FLOOR3_Y + 4, -73), safeRoom)

    -- Финальная дверь (выход)
    local exitRoom = createRoom("ExitRoom", 0, -85, FLOOR3_Y, 15, 10, FLOOR_HEIGHT, floor3,
        "Dark stone grey", "Really black")
    local finalDoor = createDoor("FinalDoor", Vector3.new(0, FLOOR3_Y + 4.5, -80),
        Vector3.new(8, 10, 2), floor3, true, "FinalKey")
    finalDoor.BrickColor = BrickColor.new("Really red")
    finalDoor.Material = Enum.Material.Metal
    finalDoor:SetAttribute("PuzzleType", "FinalDoor")

    local finalPrompt = finalDoor:FindFirstChildOfClass("ProximityPrompt")
    if finalPrompt then
        finalPrompt.ActionText = "Активировать финальную дверь"
        finalPrompt.ObjectText = "ВЫХОД"
    end

    createPuzzleObject("Финальная Дверь", "FinalDoor", Vector3.new(0, FLOOR3_Y + 7, -80), exitRoom)

    -- Освещение подвала (очень тусклое)
    createFlickeringLight("BasementLight1", Vector3.new(-15, FLOOR3_Y + FLOOR_HEIGHT - 0.5, -50), floor3)
    createFlickeringLight("BasementLight2", Vector3.new(15, FLOOR3_Y + FLOOR_HEIGHT - 0.5, -50), floor3)
    createFlickeringLight("MorgueLight", Vector3.new(-25, FLOOR3_Y + FLOOR_HEIGHT - 0.5, -65), floor3)

    -- Шкафчики подвал
    createHidingSpot("Locker_F3_1", Vector3.new(-10, FLOOR3_Y + 4, -50), floor3)
    createHidingSpot("Locker_F3_2", Vector3.new(10, FLOOR3_Y + 4, -50), floor3)

    ---------------------------------------------------------------
    -- ПРЕДМЕТЫ НА КАРТЕ
    ---------------------------------------------------------------
    print("[MapBuilder] Размещаю предметы...")

    -- Батарейки (6 штук по карте)
    createPickupItem("Батарейка", "Battery", Vector3.new(15, FLOOR1_Y + 2, 5), hospital, "Bright yellow")
    createPickupItem("Батарейка", "Battery", Vector3.new(-50, FLOOR1_Y + 2, -12), hospital, "Bright yellow")
    createPickupItem("Батарейка", "Battery", Vector3.new(25, FLOOR2_Y + 2, 60), hospital, "Bright yellow")
    createPickupItem("Батарейка", "Battery", Vector3.new(-15, FLOOR2_Y + 2, 40), hospital, "Bright yellow")
    createPickupItem("Батарейка", "Battery", Vector3.new(20, FLOOR3_Y + 2, -55), hospital, "Bright yellow")
    createPickupItem("Батарейка", "Battery", Vector3.new(-20, FLOOR3_Y + 2, -68), hospital, "Bright yellow")

    -- Бинты (4 штуки)
    createPickupItem("Бинт", "Bandage", Vector3.new(-55, FLOOR1_Y + 2, 18), hospital, "White")
    createPickupItem("Бинт", "Bandage", Vector3.new(30, FLOOR2_Y + 2, 65), hospital, "White")
    createPickupItem("Бинт", "Bandage", Vector3.new(-25, FLOOR3_Y + 2, -60), hospital, "White")
    createPickupItem("Бинт", "Bandage", Vector3.new(55, FLOOR1_Y + 2, 12), hospital, "White")

    -- Ключи
    createPickupItem("Ключ", "Key", Vector3.new(-50, FLOOR1_Y + 2, -18), hospital, "Bright orange")
    createPickupItem("Ключ", "Key", Vector3.new(55, FLOOR1_Y + 2, -18), hospital, "Bright orange")
    createPickupItem("Ключ", "Key", Vector3.new(15, FLOOR2_Y + 2, 65), hospital, "Bright orange")

    -- Предохранители (для головоломки)
    createPickupItem("Предохранитель", "Fuse", Vector3.new(50, FLOOR1_Y + 2, 10), hospital, "Bright blue")
    createPickupItem("Предохранитель", "Fuse", Vector3.new(-30, FLOOR2_Y + 2, 60), hospital, "Bright blue")
    createPickupItem("Предохранитель", "Fuse", Vector3.new(20, FLOOR3_Y + 2, -70), hospital, "Bright blue")

    -- Свечи (для ритуала)
    createPickupItem("Свеча", "Candle", Vector3.new(-10, FLOOR2_Y + 2, 55), hospital, "Bright red")
    createPickupItem("Свеча", "Candle", Vector3.new(10, FLOOR1_Y + 2, -10), hospital, "Bright red")
    createPickupItem("Свеча", "Candle", Vector3.new(-55, FLOOR1_Y + 2, 10), hospital, "Bright red")
    createPickupItem("Свеча", "Candle", Vector3.new(25, FLOOR3_Y + 2, -60), hospital, "Bright red")

    -- Реагенты (для лаборатории)
    createPickupItem("Красный реагент", "Reagent", Vector3.new(35, FLOOR2_Y + 2, 35), hospital, "Bright red")
    createPickupItem("Синий реагент", "Reagent", Vector3.new(-20, FLOOR1_Y + 2, 5), hospital, "Bright blue")
    createPickupItem("Зелёный реагент", "Reagent", Vector3.new(0, FLOOR3_Y + 2, -55), hospital, "Bright green")

    -- Записки (подсказки к коду сейфа)
    createNote("Запись пациента #347: Код начинается с 7", 1, Vector3.new(55, FLOOR1_Y + 3, 18), hospital)
    createNote("Запись пациента #128: Вторая цифра — 3", 2, Vector3.new(-10, FLOOR2_Y + 3, 62), hospital)
    createNote("Запись пациента #592: Третья цифра — 9", 3, Vector3.new(22, FLOOR3_Y + 3, -62), hospital)
    createNote("Запись пациента #801: Последняя цифра — 1", 4, Vector3.new(-30, FLOOR3_Y + 3, -70), hospital)

    -- Ключевые предметы (5 штук — по одному за каждую головоломку)
    -- Они появятся при решении головоломок, но один можно найти свободно
    createPickupItem("Жетон пациента", "KeyItem", Vector3.new(55, FLOOR1_Y + 2, -10), hospital, "Bright violet")

    ---------------------------------------------------------------
    -- ТОЧКИ СПАВНА
    ---------------------------------------------------------------
    print("[MapBuilder] Создаю точки спавна...")

    -- Спавн лобби
    local lobbySpawn = createPart("LobbySpawn", Vector3.new(4, 1, 4),
        Vector3.new(0, FLOOR1_Y + 1, -5), "Bright green", Enum.Material.Neon, workspace, 0.5)

    -- Спавн монстра (в подвале)
    local monsterSpawn = createPart("MonsterSpawn", Vector3.new(4, 1, 4),
        Vector3.new(0, FLOOR3_Y + 1, -85), "Really red", Enum.Material.Neon, workspace, 0.5)

    -- Точки спавна игроков (на Этаже 1)
    for i = 1, 4 do
        local spawn = createPart("Spawn" .. i, Vector3.new(3, 1, 3),
            Vector3.new(-6 + i * 3, FLOOR1_Y + 1, 0), "Bright green", Enum.Material.Neon, gameSpawnPoints, 0.7)
    end

    ---------------------------------------------------------------
    -- WAYPOINTS ПАТРУЛЯ МОНСТРА
    ---------------------------------------------------------------
    print("[MapBuilder] Создаю маршрут патруля монстра...")

    local waypointPositions = {
        Vector3.new(0, FLOOR3_Y + 2, -50),      -- Подвал коридор
        Vector3.new(-25, FLOOR3_Y + 2, -65),     -- Морг
        Vector3.new(25, FLOOR3_Y + 2, -65),      -- Котельная
        Vector3.new(0, FLOOR3_Y + 2, -70),       -- Сейф
        Vector3.new(0, FLOOR1_Y + 2, 0),         -- Лобби (через лестницу)
        Vector3.new(35, FLOOR1_Y + 2, 0),        -- Коридор 1
        Vector3.new(-35, FLOOR1_Y + 2, 0),       -- Коридор 2
        Vector3.new(0, FLOOR2_Y + 2, 50),        -- Этаж 2 коридор
        Vector3.new(-30, FLOOR2_Y + 2, 62),      -- Палата 1
        Vector3.new(30, FLOOR2_Y + 2, 38),       -- Лаборатория
    }

    for i, pos in ipairs(waypointPositions) do
        local wp = createPart("Waypoint" .. i, Vector3.new(2, 2, 2), pos,
            "Bright orange", Enum.Material.Neon, patrolWaypoints, 1) -- невидимый
    end

    ---------------------------------------------------------------
    -- ВНЕШНИЙ ВИД (окружение)
    ---------------------------------------------------------------
    print("[MapBuilder] Настраиваю атмосферу...")

    -- Земля вокруг больницы
    createPart("Ground", Vector3.new(300, 1, 300), Vector3.new(0, FLOOR1_Y - 1, 0),
        "Dark green", Enum.Material.Grass, exteriorFolder)

    -- Забор вокруг больницы
    createPart("FenceN", Vector3.new(140, 8, 1), Vector3.new(0, FLOOR1_Y + 4, 100),
        "Really black", Enum.Material.Metal, exteriorFolder)
    createPart("FenceS", Vector3.new(140, 8, 1), Vector3.new(0, FLOOR1_Y + 4, -100),
        "Really black", Enum.Material.Metal, exteriorFolder)
    createPart("FenceW", Vector3.new(1, 8, 200), Vector3.new(-70, FLOOR1_Y + 4, 0),
        "Really black", Enum.Material.Metal, exteriorFolder)
    createPart("FenceE", Vector3.new(1, 8, 200), Vector3.new(70, FLOOR1_Y + 4, 0),
        "Really black", Enum.Material.Metal, exteriorFolder)

    -- Деревья (простые)
    for i = 1, 12 do
        local tx = math.random(-65, 65)
        local tz = math.random(-95, 95)
        -- Ствол
        createPart("TreeTrunk" .. i, Vector3.new(2, 10, 2),
            Vector3.new(tx, FLOOR1_Y + 5, tz), "Reddish brown", Enum.Material.WoodPlanks, exteriorFolder)
        -- Крона
        createPart("TreeLeaves" .. i, Vector3.new(8, 8, 8),
            Vector3.new(tx, FLOOR1_Y + 12, tz), "Earth green", Enum.Material.Grass, exteriorFolder)
    end

    ---------------------------------------------------------------
    -- НАСТРОЙКИ ОСВЕЩЕНИЯ
    ---------------------------------------------------------------
    Lighting.Ambient = Color3.fromRGB(10, 10, 15)
    Lighting.OutdoorAmbient = Color3.fromRGB(15, 15, 20)
    Lighting.Brightness = 0.1
    Lighting.ClockTime = 0 -- полночь
    Lighting.FogEnd = 150
    Lighting.FogStart = 30
    Lighting.FogColor = Color3.fromRGB(5, 5, 10)
    Lighting.GlobalShadows = true

    -- Атмосфера
    local existingAtmo = Lighting:FindFirstChild("Atmosphere")
    if existingAtmo then existingAtmo:Destroy() end

    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Name = "Atmosphere"
    atmosphere.Density = 0.4
    atmosphere.Offset = 0
    atmosphere.Color = Color3.fromRGB(15, 15, 25)
    atmosphere.Decay = Color3.fromRGB(20, 20, 30)
    atmosphere.Glare = 0
    atmosphere.Haze = 10
    atmosphere.Parent = Lighting

    ---------------------------------------------------------------
    -- ГОТОВО!
    ---------------------------------------------------------------
    print("═══════════════════════════════════════════════════")
    print("[MapBuilder] ✅ БОЛЬНИЦА ПОСТРОЕНА!")
    print("  Этаж 1: Лобби, 2 коридора, 4 комнаты")
    print("  Этаж 2: 4 палаты, операционная, лаборатория")
    print("  Этаж 3: Морг, котельная, сейф, выход")
    print("  Предметов: батарейки, бинты, ключи, предохранители, свечи, реагенты")
    print("  Головоломок: 5")
    print("  Точек патруля: " .. #waypointPositions)
    print("═══════════════════════════════════════════════════")
end

---------------------------------------------------------------------
-- ЗАПУСК
---------------------------------------------------------------------
buildHospital()
