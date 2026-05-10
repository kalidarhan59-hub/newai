# Инструкция по установке "Паркур-Башня" в Roblox Studio

## Шаг 1: Открыть Roblox Studio

1. Открой **Roblox Studio** (не Roblox Player!)
2. Нажми **"New"** → выбери **"Baseplate"**
3. Подожди загрузку

## Шаг 2: Удалить Baseplate

1. В панели **Explorer** (справа) найди **Baseplate** внутри **Workspace**
2. Нажми на неё правой кнопкой → **Delete**

## Шаг 3: Создать папку Modules

1. В **Explorer** нажми правой кнопкой на **ReplicatedStorage**
2. **Insert Object** → **Folder**
3. Переименуй папку в **Modules**

## Шаг 4: Вставить скрипты

Вставляй скрипты **в указанном порядке** (сначала модули, потом серверные, потом клиентские):

### 4.1 — Модуль конфигурации
1. Нажми правой кнопкой на **ReplicatedStorage → Modules**
2. **Insert Object** → **ModuleScript**
3. Переименуй в **GameConfig**
4. Открой файл `src/ReplicatedStorage/Modules/GameConfig.lua`
5. Скопируй **ВЕСЬ** код, вставь в скрипт (заменив то что там было)

### 4.2 — Серверные скрипты
Для каждого файла ниже:
1. Нажми правой кнопкой на **ServerScriptService**
2. **Insert Object** → **Script**
3. Переименуй и вставь код

| # | Имя скрипта | Файл |
|---|---|---|
| 1 | **SetupEvents** | `src/ServerScriptService/SetupEvents.server.lua` |
| 2 | **MapBuilder** | `src/ServerScriptService/MapBuilder.server.lua` |
| 3 | **TowerManager** | `src/ServerScriptService/TowerManager.server.lua` |
| 4 | **TrapAnimator** | `src/ServerScriptService/TrapAnimator.server.lua` |

**ВАЖНО:** Вставляй именно в этом порядке! SetupEvents должен быть первым.

### 4.3 — Клиентские скрипты

**ParkourEffects:**
1. В Explorer: **StarterPlayer** → **StarterPlayerScripts**
2. Нажми правой кнопкой → **Insert Object** → **LocalScript**
3. Переименуй в **ParkourEffects**
4. Вставь код из `src/StarterPlayer/StarterPlayerScripts/ParkourEffects.client.lua`

**ParkourUI:**
1. В Explorer: нажми правой кнопкой на **StarterGui**
2. **Insert Object** → **LocalScript**
3. Переименуй в **ParkourUI**
4. Вставь код из `src/StarterGui/ParkourUI.client.lua`

## Шаг 5: Запустить!

1. Нажми кнопку **▶ Play** (зелёный треугольник вверху)
2. Подожди 5-10 секунд — башня построится автоматически!
3. Внизу в **Output** должно появиться: `[MapBuilder] ПАРКУР-БАШНЯ ПОСТРОЕНА!`

## Таблица-шпаргалка

| Файл | Куда в Roblox Studio | Тип |
|---|---|---|
| `GameConfig.lua` | ReplicatedStorage → Modules | ModuleScript |
| `SetupEvents.server.lua` | ServerScriptService | Script |
| `MapBuilder.server.lua` | ServerScriptService | Script |
| `TowerManager.server.lua` | ServerScriptService | Script |
| `TrapAnimator.server.lua` | ServerScriptService | Script |
| `ParkourEffects.client.lua` | StarterPlayer → StarterPlayerScripts | LocalScript |
| `ParkourUI.client.lua` | StarterGui | LocalScript |

**Всего: 7 скриптов**

## Управление

| Клавиша | Действие |
|---|---|
| WASD | Движение |
| Пробел | Прыжок |
| R | Быстрый респавн |

## Как это работает

- **20 этажей** — от лёгких (зелёные) до хардкорных (фиолетовые)
- **Чекпоинты** каждые 3 этажа — при смерти возвращаешься к последнему
- **Ловушки:** лазеры (вращаются), шипы (поднимаются/опускаются), молоты (качаются), огонь
- **Исчезающие платформы** — начинают мигать когда наступаешь, потом исчезают
- **Двигающиеся платформы** — двигаются влево-вправо, вверх-вниз или вперёд-назад
- Каждые **5 минут** этажи полностью меняются (новая генерация)
- На верхушке — **трофей ПОБЕДА!**

## Что делать если...

### Нет панели Output
Нажми **View** (верхнее меню) → поставь галочку на **Output**

### Башня не строится
- Проверь что **MapBuilder** лежит в **ServerScriptService** и его тип **Script**
- Проверь что **GameConfig** лежит в **ReplicatedStorage → Modules** и его тип **ModuleScript**
- Посмотри Output на наличие красных ошибок

### Нет интерфейса (таймер, этаж)
- Проверь что **ParkourUI** лежит в **StarterGui** и его тип **LocalScript**

### Игрок не появляется
- Убедись что ты удалил старую Baseplate (шаг 2)
- MapBuilder создаёт свой SpawnLocation автоматически
