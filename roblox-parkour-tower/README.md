# Паркур-Башня для Roblox

Одиночная паркур-игра с башней из 20 этажей. Ловушки, лазеры, исчезающие платформы, этажи меняются каждые 5 минут!

## Контент

- **20 этажей** с возрастающей сложностью
- **12 типов этажей** (платформы, исчезающие, лазеры, шипы, молоты, огонь, микс...)
- **5 уровней сложности** (зелёный → жёлтый → оранжевый → красный → фиолетовый)
- **Ловушки:** вращающиеся лазеры, поднимающиеся шипы, качающиеся молоты, огненные зоны
- **Исчезающие платформы** — мигают и пропадают
- **Двигающиеся платформы** — по 3 осям
- **Чекпоинты** каждые 3 этажа
- **Смена этажей** каждые 5 минут (полная перегенерация)
- **Экран победы** с таймером и счётчиком смертей

## Скрипты (7 файлов)

| # | Файл | Куда | Тип | Описание |
|---|---|---|---|---|
| 1 | GameConfig.lua | ReplicatedStorage/Modules | ModuleScript | Все настройки |
| 2 | SetupEvents.server.lua | ServerScriptService | Script | Создаёт события |
| 3 | MapBuilder.server.lua | ServerScriptService | Script | Строит башню |
| 4 | TowerManager.server.lua | ServerScriptService | Script | Управление игрой |
| 5 | TrapAnimator.server.lua | ServerScriptService | Script | Анимация ловушек |
| 6 | ParkourEffects.client.lua | StarterPlayerScripts | LocalScript | Визуальные эффекты |
| 7 | ParkourUI.client.lua | StarterGui | LocalScript | Интерфейс |

## Установка

Подробная инструкция: [docs/SETUP_GUIDE_RU.md](docs/SETUP_GUIDE_RU.md)

**Быстрый старт:**
1. Roblox Studio → New → Baseplate
2. Удалить Baseplate
3. Вставить 7 скриптов по таблице выше
4. Play!
