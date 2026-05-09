# 📖 ПОШАГОВАЯ ИНСТРУКЦИЯ — Как установить игру в Roblox Studio

## Для тех, кто никогда не работал с Roblox Studio!

---

## Шаг 0: Скачать Roblox Studio

1. Зайдите на https://create.roblox.com/
2. Нажмите **"Start Creating"**
3. Скачайте и установите **Roblox Studio**
4. Войдите в свой аккаунт Roblox

---

## Шаг 1: Создать новый проект

1. Откройте Roblox Studio
2. На главном экране нажмите **"New"** (Новый)
3. Выберите шаблон **"Baseplate"** (просто плоскость)
4. Нажмите на него — откроется пустой проект

---

## Шаг 2: Открыть панель Explorer и Properties

Если справа нет панелей **Explorer** и **Properties**:

1. В верхнем меню нажмите **"View"** (Вид)
2. Поставьте галочки на:
   - ✅ **Explorer** — это дерево всех объектов в игре (справа)
   - ✅ **Properties** — свойства выбранного объекта (справа снизу)
   - ✅ **Output** — консоль с сообщениями (внизу)

---

## Шаг 3: Создать папки

В панели **Explorer** (справа) вы видите структуру игры. Нужно создать папки:

### 3.1 Создать папку "Modules" в ReplicatedStorage
1. Найдите **ReplicatedStorage** в Explorer
2. Нажмите правой кнопкой мыши → **Insert Object** → **Folder**
3. Назовите папку: `Modules`

### 3.2 Создать папку "Events" в ReplicatedStorage
1. Найдите **ReplicatedStorage** в Explorer
2. Правая кнопка → **Insert Object** → **Folder**
3. Назовите папку: `Events`

---

## Шаг 4: Вставить скрипты (ГЛАВНАЯ ЧАСТЬ)

Теперь нужно вставить все коды. Я напишу точно куда и как для каждого файла.

### ⚠️ ВАЖНО: Три типа скриптов в Roblox:
- **Script** (серверный) — работает на сервере, управляет игрой
- **LocalScript** (клиентский) — работает на компьютере игрока, управляет UI и эффектами
- **ModuleScript** (модуль) — общий код, который используют другие скрипты

---

### 📄 СКРИПТ 1: SetupEvents (создаёт все события)

**Куда:** `ServerScriptService`  
**Тип:** Script (серверный)

1. В Explorer найдите **ServerScriptService**
2. Правая кнопка мыши → **Insert Object** → **Script**
3. Назовите его: `SetupEvents`
4. Двойной клик по нему — откроется редактор кода
5. **Удалите** всё что там написано (обычно `print("Hello world!")`)
6. **Скопируйте** весь код из файла `src/ReplicatedStorage/Events/SetupEvents.server.lua`
7. **Вставьте** в редактор (Ctrl+V)

---

### 📄 СКРИПТ 2: MapBuilder (строит больницу автоматически!)

**Куда:** `ServerScriptService`  
**Тип:** Script (серверный)

1. В Explorer найдите **ServerScriptService**
2. Правая кнопка мыши → **Insert Object** → **Script**
3. Назовите его: `MapBuilder`
4. Двойной клик → откроется редактор
5. **Удалите** всё и **вставьте** код из файла `src/ServerScriptService/MapBuilder.server.lua`

> 🏥 Этот скрипт автоматически построит всю больницу при запуске!

---

### 📄 СКРИПТ 3: GameManager (управляет игрой)

**Куда:** `ServerScriptService`  
**Тип:** Script (серверный)

1. В Explorer → **ServerScriptService**
2. Правая кнопка → **Insert Object** → **Script**
3. Назовите: `GameManager`
4. Двойной клик → удалите всё → вставьте код из `src/ServerScriptService/GameManager.server.lua`

---

### 📄 СКРИПТ 4: MonsterAI (мозг монстра)

**Куда:** `ServerScriptService`  
**Тип:** Script (серверный)

1. В Explorer → **ServerScriptService**
2. Правая кнопка → **Insert Object** → **Script**
3. Назовите: `MonsterAI`
4. Двойной клик → удалите всё → вставьте код из `src/ServerScriptService/MonsterAI.server.lua`

---

### 📄 СКРИПТ 5: PuzzleSystem (головоломки)

**Куда:** `ServerScriptService`  
**Тип:** Script (серверный)

1. В Explorer → **ServerScriptService**
2. Правая кнопка → **Insert Object** → **Script**
3. Назовите: `PuzzleSystem`
4. Двойной клик → удалите всё → вставьте код из `src/ServerScriptService/PuzzleSystem.server.lua`

---

### 📄 СКРИПТ 6: LobbySystem (лобби)

**Куда:** `ServerScriptService`  
**Тип:** Script (серверный)

1. В Explorer → **ServerScriptService**
2. Правая кнопка → **Insert Object** → **Script**
3. Назовите: `LobbySystem`
4. Двойной клик → удалите всё → вставьте код из `src/ServerScriptService/LobbySystem.server.lua`

---

### 📄 СКРИПТ 7: GameConfig (настройки игры)

**Куда:** `ReplicatedStorage → Modules`  
**Тип:** ModuleScript ⚠️ (не Script!)

1. В Explorer найдите **ReplicatedStorage** → **Modules** (папка которую вы создали)
2. Правая кнопка → **Insert Object** → **ModuleScript** ⚠️
3. Назовите: `GameConfig`
4. Двойной клик → удалите всё → вставьте код из `src/ReplicatedStorage/Modules/GameConfig.lua`

---

### 📄 СКРИПТ 8: SharedTypes (типы данных)

**Куда:** `ReplicatedStorage → Modules`  
**Тип:** ModuleScript ⚠️

1. В Explorer → **ReplicatedStorage** → **Modules**
2. Правая кнопка → **Insert Object** → **ModuleScript**
3. Назовите: `SharedTypes`
4. Двойной клик → удалите всё → вставьте код из `src/ReplicatedStorage/Modules/SharedTypes.lua`

---

### 📄 СКРИПТ 9: InventoryModule (инвентарь)

**Куда:** `ReplicatedStorage → Modules`  
**Тип:** ModuleScript ⚠️

1. В Explorer → **ReplicatedStorage** → **Modules**
2. Правая кнопка → **Insert Object** → **ModuleScript**
3. Назовите: `InventoryModule`
4. Двойной клик → удалите всё → вставьте код из `src/ReplicatedStorage/Modules/InventoryModule.lua`

---

### 📄 СКРИПТ 10: DataManager (сохранение данных)

**Куда:** `ServerStorage`  
**Тип:** ModuleScript ⚠️

1. В Explorer найдите **ServerStorage**
2. Правая кнопка → **Insert Object** → **ModuleScript**
3. Назовите: `DataManager`
4. Двойной клик → удалите всё → вставьте код из `src/ServerStorage/DataManager.lua`

---

### 📄 СКРИПТ 11: HorrorEffects (визуальные эффекты)

**Куда:** `StarterPlayer → StarterPlayerScripts`  
**Тип:** LocalScript ⚠️ (не Script!)

1. В Explorer найдите **StarterPlayer** → **StarterPlayerScripts**
2. Правая кнопка → **Insert Object** → **LocalScript** ⚠️
3. Назовите: `HorrorEffects`
4. Двойной клик → удалите всё → вставьте код из `src/StarterPlayerScripts/HorrorEffects.client.lua`

---

### 📄 СКРИПТ 12: FlashlightController (фонарик)

**Куда:** `StarterPlayer → StarterPlayerScripts`  
**Тип:** LocalScript ⚠️

1. В Explorer → **StarterPlayer** → **StarterPlayerScripts**
2. Правая кнопка → **Insert Object** → **LocalScript**
3. Назовите: `FlashlightController`
4. Двойной клик → удалите всё → вставьте код из `src/StarterPlayerScripts/FlashlightController.client.lua`

---

### 📄 СКРИПТ 13: SoundManager (звуки)

**Куда:** `StarterPlayer → StarterPlayerScripts`  
**Тип:** LocalScript ⚠️

1. В Explorer → **StarterPlayer** → **StarterPlayerScripts**
2. Правая кнопка → **Insert Object** → **LocalScript**
3. Назовите: `SoundManager`
4. Двойной клик → удалите всё → вставьте код из `src/StarterPlayerScripts/SoundManager.client.lua`

---

### 📄 СКРИПТ 14: FearSystem (система страха)

**Куда:** `StarterPlayer → StarterPlayerScripts`  
**Тип:** LocalScript ⚠️

1. В Explorer → **StarterPlayer** → **StarterPlayerScripts**
2. Правая кнопка → **Insert Object** → **LocalScript**
3. Назовите: `FearSystem`
4. Двойной клик → удалите всё → вставьте код из `src/StarterPlayerScripts/FearSystem.client.lua`

---

### 📄 СКРИПТ 15: HorrorUI (интерфейс)

**Куда:** `StarterGui`  
**Тип:** LocalScript ⚠️

1. В Explorer найдите **StarterGui**
2. Правая кнопка → **Insert Object** → **LocalScript**
3. Назовите: `HorrorUI`
4. Двойной клик → удалите всё → вставьте код из `src/StarterGui/HorrorUI.client.lua`

---

## Шаг 5: Проверить структуру

После всех шагов ваш Explorer должен выглядеть так:

```
game
├── Workspace
│   (здесь MapBuilder автоматически создаст карту)
│
├── ServerScriptService
│   ├── SetupEvents          (Script)
│   ├── MapBuilder           (Script)
│   ├── GameManager          (Script)
│   ├── MonsterAI            (Script)
│   ├── PuzzleSystem         (Script)
│   └── LobbySystem          (Script)
│
├── StarterPlayer
│   └── StarterPlayerScripts
│       ├── HorrorEffects        (LocalScript)
│       ├── FlashlightController (LocalScript)
│       ├── SoundManager         (LocalScript)
│       └── FearSystem           (LocalScript)
│
├── ReplicatedStorage
│   ├── Modules
│   │   ├── GameConfig      (ModuleScript)
│   │   ├── SharedTypes     (ModuleScript)
│   │   └── InventoryModule (ModuleScript)
│   └── Events
│       (SetupEvents создаст события автоматически)
│
├── ServerStorage
│   └── DataManager         (ModuleScript)
│
└── StarterGui
    └── HorrorUI            (LocalScript)
```

---

## Шаг 6: Включить нужные настройки

1. В верхнем меню: **Game Settings** (иконка шестерёнки)
2. Вкладка **Security**:
   - ✅ Включите **"Allow HTTP Requests"**
   - ✅ Включите **"Enable Studio Access to API Services"**
3. Нажмите **Save**

---

## Шаг 7: ЗАПУСК! 🎮

### Тест на одном компьютере (1 игрок):
1. Нажмите кнопку **▶ Play** (вверху, зелёная кнопка)
2. Подождите 5-10 секунд — MapBuilder построит больницу
3. Вы появитесь в лобби

### Тест мультиплеера (2+ игрока):
1. В верхнем меню: **Test** → **Start** (не Play!)
2. Или используйте **Local Server**: Test → выберите количество игроков → Start
3. Откроются отдельные окна для каждого "игрока"
4. В каждом окне нажмите **"Готов"**
5. Когда все готовы — начнётся обратный отсчёт

---

## Шаг 8: Публикация (когда всё работает)

1. В верхнем меню: **File** → **Publish to Roblox**
2. Заполните название: "Dead Silence"
3. Добавьте описание и иконку
4. Выберите **"Public"** чтобы все могли играть
5. Нажмите **"Create"**

---

## ❓ Частые проблемы

### "Attempt to index nil" ошибки
- Убедитесь что **все скрипты** на своих местах
- Проверьте что **SetupEvents** находится в **ServerScriptService** (не в ReplicatedStorage!)
- Проверьте что папка **Modules** называется именно `Modules` (с большой буквы)

### Карта не появляется
- Откройте панель **Output** (View → Output)
- Найдите сообщение `[MapBuilder] ✅ БОЛЬНИЦА ПОСТРОЕНА!`
- Если его нет — проверьте что `MapBuilder` это **Script** (не ModuleScript)

### Монстр не появляется
- Монстр появляется через 5 минут после начала игры (специально для баланса)
- В `GameConfig.lua` можно изменить `MONSTER_SPAWN_DELAY = 30` для теста (30 секунд)

### Нет звуков
- В `SoundManager.client.lua` все звуки — заглушки (`rbxassetid://0`)
- Нужно заменить на реальные ID звуков из Roblox
- Как найти звуки: в Roblox Studio → **Toolbox** → вкладка **Audio** → поиск "horror ambient"

---

## 🎵 Как добавить звуки

1. В Roblox Studio откройте **Toolbox** (View → Toolbox)
2. Перейдите на вкладку **Marketplace**
3. Выберите **Audio** в фильтре
4. Ищите звуки по ключевым словам:
   - `horror ambient` — для фоновых звуков
   - `heartbeat` — для сердцебиения
   - `footsteps` — для шагов
   - `door creak` — для дверей
   - `monster growl` — для монстра
5. Нажмите на понравившийся звук → скопируйте его **ID** (число в URL)
6. Вставьте ID в `SoundManager.client.lua` вместо `rbxassetid://0`

Например: `HospitalHum = "rbxassetid://1234567890"`

---

## 📊 Сводная таблица: Куда какой код

| # | Имя скрипта | Тип | Куда вставить |
|---|-------------|-----|---------------|
| 1 | SetupEvents | **Script** | ServerScriptService |
| 2 | MapBuilder | **Script** | ServerScriptService |
| 3 | GameManager | **Script** | ServerScriptService |
| 4 | MonsterAI | **Script** | ServerScriptService |
| 5 | PuzzleSystem | **Script** | ServerScriptService |
| 6 | LobbySystem | **Script** | ServerScriptService |
| 7 | GameConfig | **ModuleScript** | ReplicatedStorage → Modules |
| 8 | SharedTypes | **ModuleScript** | ReplicatedStorage → Modules |
| 9 | InventoryModule | **ModuleScript** | ReplicatedStorage → Modules |
| 10 | DataManager | **ModuleScript** | ServerStorage |
| 11 | HorrorEffects | **LocalScript** | StarterPlayer → StarterPlayerScripts |
| 12 | FlashlightController | **LocalScript** | StarterPlayer → StarterPlayerScripts |
| 13 | SoundManager | **LocalScript** | StarterPlayer → StarterPlayerScripts |
| 14 | FearSystem | **LocalScript** | StarterPlayer → StarterPlayerScripts |
| 15 | HorrorUI | **LocalScript** | StarterGui |

---

Удачи! Если что-то не работает — пиши, помогу разобраться! 🎮
