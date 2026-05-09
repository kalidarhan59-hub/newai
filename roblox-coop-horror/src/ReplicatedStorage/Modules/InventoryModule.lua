--[[
    InventoryModule.lua
    Система инвентаря (shared: используется на сервере и клиенте)
    Расположение: ReplicatedStorage/Modules/InventoryModule.lua
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local InventoryModule = {}
InventoryModule.__index = InventoryModule

function InventoryModule.new(maxSlots)
    local self = setmetatable({}, InventoryModule)
    self.MaxSlots = maxSlots or GameConfig.Player.InventorySlots
    self.Items = {} -- {[slotIndex] = {ItemType, ItemId, ...}}
    return self
end

-- Добавить предмет в инвентарь
function InventoryModule:AddItem(itemType, itemId)
    if self:GetItemCount() >= self.MaxSlots then
        return false, "Инвентарь полон"
    end

    local slot = self:FindEmptySlot()
    if not slot then
        return false, "Нет свободных слотов"
    end

    self.Items[slot] = {
        ItemType = itemType,
        ItemId = itemId or game:GetService("HttpService"):GenerateGUID(false),
        PickupTime = os.clock(),
    }

    return true, slot
end

-- Удалить предмет из слота
function InventoryModule:RemoveItem(slot)
    if not self.Items[slot] then
        return false, "Слот пустой"
    end

    local item = self.Items[slot]
    self.Items[slot] = nil
    return true, item
end

-- Удалить предмет по типу
function InventoryModule:RemoveItemByType(itemType)
    for slot, item in pairs(self.Items) do
        if item.ItemType == itemType then
            self.Items[slot] = nil
            return true, item
        end
    end
    return false, "Предмет не найден"
end

-- Проверить наличие предмета
function InventoryModule:HasItem(itemType)
    for _, item in pairs(self.Items) do
        if item.ItemType == itemType then
            return true
        end
    end
    return false
end

-- Подсчитать предметы определённого типа
function InventoryModule:CountItemType(itemType)
    local count = 0
    for _, item in pairs(self.Items) do
        if item.ItemType == itemType then
            count = count + 1
        end
    end
    return count
end

-- Количество предметов в инвентаре
function InventoryModule:GetItemCount()
    local count = 0
    for _ in pairs(self.Items) do
        count = count + 1
    end
    return count
end

-- Найти пустой слот
function InventoryModule:FindEmptySlot()
    for i = 1, self.MaxSlots do
        if not self.Items[i] then
            return i
        end
    end
    return nil
end

-- Получить предмет из слота
function InventoryModule:GetItem(slot)
    return self.Items[slot]
end

-- Получить все предметы
function InventoryModule:GetAllItems()
    local items = {}
    for slot, item in pairs(self.Items) do
        items[slot] = {
            ItemType = item.ItemType,
            ItemId = item.ItemId,
        }
    end
    return items
end

-- Очистить инвентарь
function InventoryModule:Clear()
    self.Items = {}
end

-- Сериализация для сети
function InventoryModule:Serialize()
    local data = {}
    for slot, item in pairs(self.Items) do
        data[slot] = {
            ItemType = item.ItemType,
            ItemId = item.ItemId,
        }
    end
    return data
end

-- Десериализация
function InventoryModule:Deserialize(data)
    self.Items = {}
    for slot, itemData in pairs(data) do
        self.Items[tonumber(slot)] = {
            ItemType = itemData.ItemType,
            ItemId = itemData.ItemId,
            PickupTime = os.clock(),
        }
    end
end

return InventoryModule
