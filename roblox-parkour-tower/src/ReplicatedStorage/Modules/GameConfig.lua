-- GameConfig: все настройки паркур-башни
local GameConfig = {}

-- Основные настройки
GameConfig.TOWER_HEIGHT = 20           -- Количество этажей
GameConfig.FLOOR_HEIGHT = 25           -- Высота каждого этажа (studs)
GameConfig.FLOOR_WIDTH = 60            -- Ширина этажа
GameConfig.FLOOR_DEPTH = 60            -- Глубина этажа
GameConfig.SHUFFLE_INTERVAL = 300      -- Смена этажей каждые 5 минут (в секундах)

-- Платформы
GameConfig.PLATFORM_SIZE = Vector3.new(8, 2, 8)
GameConfig.MOVING_PLATFORM_SPEED = 15
GameConfig.DISAPPEARING_DELAY = 1.5    -- Секунд до исчезновения
GameConfig.DISAPPEARING_RESPAWN = 3.0  -- Секунд до появления

-- Ловушки
GameConfig.TRAP_DAMAGE = 25
GameConfig.LASER_DAMAGE = 20
GameConfig.LASER_SPEED = 30            -- Скорость вращения лазеров
GameConfig.FIRE_DAMAGE = 15
GameConfig.FIRE_INTERVAL = 2.0         -- Интервал огня
GameConfig.HAMMER_DAMAGE = 40
GameConfig.HAMMER_SPEED = 2.0          -- Скорость качания молота
GameConfig.SPIKE_DAMAGE = 30
GameConfig.SPIKE_INTERVAL = 3.0        -- Интервал шипов (вверх/вниз)

-- Чекпоинты
GameConfig.CHECKPOINT_EVERY = 3        -- Чекпоинт каждые N этажей

-- Цвета этажей (по сложности)
GameConfig.FLOOR_COLORS = {
	[1] = Color3.fromRGB(100, 200, 100),   -- Зелёный (легко)
	[2] = Color3.fromRGB(200, 200, 100),   -- Жёлтый
	[3] = Color3.fromRGB(200, 150, 50),    -- Оранжевый
	[4] = Color3.fromRGB(200, 80, 80),     -- Красный (сложно)
	[5] = Color3.fromRGB(150, 50, 200),    -- Фиолетовый (хардкор)
}

-- Типы этажей
GameConfig.FLOOR_TYPES = {
	"platforms_only",       -- Только прыжки по платформам
	"disappearing",         -- Исчезающие платформы
	"lasers",               -- Лазеры
	"spikes",               -- Шипы
	"hammers",              -- Молоты
	"fire_floor",           -- Огненный пол
	"moving_platforms",     -- Двигающиеся платформы
	"mixed_easy",           -- Микс лёгкий
	"mixed_medium",         -- Микс средний
	"mixed_hard",           -- Микс сложный
	"laser_maze",           -- Лазерный лабиринт
	"vanishing_path",       -- Исчезающая тропа
}

-- Сложность по этажу (1-5)
function GameConfig.GetDifficulty(floor_number)
	if floor_number <= 4 then return 1
	elseif floor_number <= 8 then return 2
	elseif floor_number <= 12 then return 3
	elseif floor_number <= 16 then return 4
	else return 5
	end
end

-- Доступные типы этажей по сложности
GameConfig.DIFFICULTY_FLOORS = {
	[1] = {"platforms_only", "disappearing", "moving_platforms"},
	[2] = {"disappearing", "lasers", "moving_platforms", "mixed_easy"},
	[3] = {"lasers", "spikes", "hammers", "mixed_medium", "fire_floor"},
	[4] = {"mixed_medium", "mixed_hard", "laser_maze", "fire_floor", "hammers"},
	[5] = {"mixed_hard", "laser_maze", "vanishing_path", "spikes"},
}

return GameConfig
