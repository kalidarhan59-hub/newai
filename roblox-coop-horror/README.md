# 🏥 Dead Silence — Кооперативный Хоррор для Roblox

Кооперативная хоррор-игра на 2-4 игрока. Группа исследователей оказывается заперта в заброшенной больнице и должна решить головоломки, собрать ключевые предметы и сбежать, избегая Существо.

## 📂 Структура проекта

```
roblox-coop-horror/
├── docs/
│   └── GDD.md                          # Game Design Document (полное описание игры)
├── src/
│   ├── ServerScriptService/             # Серверные скрипты
│   │   ├── GameManager.server.lua       # Главный менеджер игры
│   │   ├── MonsterAI.server.lua         # AI монстра (патруль/преследование)
│   │   ├── PuzzleSystem.server.lua      # Система головоломок
│   │   └── LobbySystem.server.lua       # Лобби и matchmaking
│   ├── StarterPlayerScripts/            # Клиентские скрипты
│   │   ├── HorrorEffects.client.lua     # Визуальные эффекты (тряска, виньетка, туман)
│   │   ├── FlashlightController.client.lua # Управление фонариком
│   │   ├── SoundManager.client.lua      # Звуки и музыка
│   │   └── FearSystem.client.lua        # Система страха и управление
│   ├── ReplicatedStorage/
│   │   ├── Modules/
│   │   │   ├── GameConfig.lua           # Конфигурация (все числа и настройки)
│   │   │   ├── SharedTypes.lua          # Enum'ы и типы данных
│   │   │   └── InventoryModule.lua      # Система инвентаря
│   │   └── Events/
│   │       └── SetupEvents.server.lua   # Создание RemoteEvents (⚠️ в ServerScriptService!)
│   ├── ServerStorage/
│   │   └── DataManager.lua             # Сохранение данных игроков
│   └── StarterGui/
│       └── HorrorUI.client.lua         # Интерфейс (HUD, лобби, инвентарь)
└── README.md
```

## 🚀 Установка в Roblox Studio (пошаговая инструкция)

### Шаг 1: Создать структуру в Roblox Studio

1. Откройте Roblox Studio → создайте новый Baseplate проект
2. В **Explorer** создайте следующую структуру папок:

```
game
├── ServerScriptService
├── StarterPlayer
│   └── StarterPlayerScripts
├── ReplicatedStorage
│   ├── Modules (Folder)
│   └── Events (Folder)
├── ServerStorage
├── StarterGui
└── Workspace
    ├── PatrolWaypoints (Folder)
    ├── GameSpawnPoints (Folder)
    ├── DroppedItems (Folder)
    ├── Floor2Lights (Folder)
    ├── LobbySpawn (Part)
    └── MonsterSpawn (Part)
```

### Шаг 2: Добавить скрипты

**⚠️ ВАЖНО: Типы скриптов!**
- Файлы `.server.lua` → создавайте как **Script** (серверный скрипт)
- Файлы `.client.lua` → создавайте как **LocalScript** (клиентский скрипт)
- Файлы `.lua` (без суффикса) → создавайте как **ModuleScript**

| Файл | Тип | Куда поместить |
|------|-----|----------------|
| `GameManager.server.lua` | Script | ServerScriptService |
| `MonsterAI.server.lua` | Script | ServerScriptService |
| `PuzzleSystem.server.lua` | Script | ServerScriptService |
| `LobbySystem.server.lua` | Script | ServerScriptService |
| `SetupEvents.server.lua` | Script | ServerScriptService (**НЕ** в ReplicatedStorage!) |
| `HorrorEffects.client.lua` | LocalScript | StarterPlayer → StarterPlayerScripts |
| `FlashlightController.client.lua` | LocalScript | StarterPlayer → StarterPlayerScripts |
| `SoundManager.client.lua` | LocalScript | StarterPlayer → StarterPlayerScripts |
| `FearSystem.client.lua` | LocalScript | StarterPlayer → StarterPlayerScripts |
| `HorrorUI.client.lua` | LocalScript | StarterGui |
| `GameConfig.lua` | ModuleScript | ReplicatedStorage → Modules |
| `SharedTypes.lua` | ModuleScript | ReplicatedStorage → Modules |
| `InventoryModule.lua` | ModuleScript | ReplicatedStorage → Modules |
| `DataManager.lua` | ModuleScript | ServerStorage |

### Шаг 3: Настроить Workspace

1. **LobbySpawn** — создайте Part, назовите `LobbySpawn`. Это точка появления игроков в лобби.
2. **MonsterSpawn** — создайте Part, назовите `MonsterSpawn`. Место появления монстра.
3. **GameSpawnPoints** — создайте Folder. Внутри разместите 4 Part с именами `Spawn1`-`Spawn4` — точки появления на карте.
4. **PatrolWaypoints** — создайте Folder. Внутри разместите Part'ы (`Waypoint1`, `Waypoint2`, ...) по маршруту патруля монстра.

### Шаг 4: Построить карту больницы

Постройте карту с 3 зонами:
- **Этаж 1 (Приёмная):** лобби, коридоры, регистратура
- **Этаж 2 (Палаты):** комнаты, лаборатория, операционная
- **Этаж 3 (Подвал):** морг, котельная, выход

**Важные объекты на карте:**
- Двери (Part) с атрибутами: `Locked` (bool), `RequiredKey` (string), `Interactable` (bool)
- Предметы для подбора (Part) с атрибутами: `ItemType` (string), `Interactable` (bool)
- Головоломки (Part) с атрибутами: `PuzzleType` (string), `Interactable` (bool)

### Шаг 5: Добавить звуки

В файле `SoundManager.client.lua` замените все `rbxassetid://0` на реальные ID звуков:
1. Найдите звуки в Roblox Creator Marketplace (toolbox)
2. Загрузите свои звуки через Creator Hub → Audio
3. Вставьте ID в формате `rbxassetid://1234567890`

### Шаг 6: Настроить освещение

Скрипт `HorrorEffects.client.lua` автоматически настроит:
- Тёмное освещение (ClockTime = 0, полночь)
- Туман (Atmosphere)
- Цветокоррекцию

Вы можете дополнительно добавить:
- SpotLight / PointLight в комнатах
- Мерцающие лампы (через скрипт или анимацию)

### Шаг 7: Настроить игровые сервисы

1. **Game Settings → Security:** включите "Allow HTTP Requests" (для DataStore)
2. **Game Settings → Security:** включите "Enable Studio Access to API Services" (для тестов)

## 🎮 Управление

| Действие | PC | Мобильные |
|----------|-----|-----------|
| Движение | WASD | Джойстик |
| Бег | Left Shift | Кнопка 🏃 |
| Приседание | C | Кнопка 🧎 |
| Фонарик | F | Кнопка 🔦 |
| Вспышка | Правая кнопка мыши | Кнопка ⚡ |
| Взаимодействие | E | Кнопка E |
| Инвентарь | Tab | — |
| Глубокое дыхание | B | Кнопка 💨 |
| Передать предмет | G | — |

## 🧩 Головоломки

1. **Предохранители** — найти 3 предохранителя → вставить в электрощит
2. **Код сейфа** — найти записки с цифрами → ввести 4-значный код
3. **Ритуал в морге** — расставить 4 свечи (нужно 2 игрока рядом)
4. **Лаборатория** — смешать 3 реагента в правильном порядке
5. **Финальная дверь** — после решения всех головоломок, бежать к выходу

## ⚙️ Настройка

Все числовые параметры собраны в `GameConfig.lua`:
- Скорости игрока и монстра
- Параметры страха
- Батарея фонарика
- Уровни шума
- Сложность по времени

## 🔧 Тестирование

1. В Roblox Studio нажмите **Test → Start** (локальный сервер)
2. Для мультиплеера: **Test → Start** с 2+ клиентами
3. Нажмите "Готов" в лобби → дождитесь обратного отсчёта

## 📝 Заметки

- Монстр появляется через 5 минут после начала (настраивается в `GameConfig.MONSTER_SPAWN_DELAY`)
- Данные игроков сохраняются через DataStoreService
- Все скрипты написаны с поддержкой мобильных устройств
- Поддержка Roblox Studio с API Services для тестирования

## 🚧 Что нужно добавить вручную

1. **3D модели:** карта больницы, модель монстра, предметы
2. **Звуки:** загрузить и вставить ID звуков
3. **Текстуры:** виньетка, UI иконки
4. **Анимации:** ходьба монстра, атака, открытие дверей
5. **ProximityPrompt:** добавить к интерактивным объектам на карте
