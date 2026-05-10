extends Node
## Глобальная шина событий — связывает все системы без прямых зависимостей

# Игрок
signal player_health_changed(current_hp: int, max_hp: int)
signal player_mana_changed(current_mp: int, max_mp: int)
signal player_xp_gained(amount: int)
signal player_level_up(new_level: int)
signal player_died()
signal player_respawned()

# Предметы
signal item_picked_up(item_data: Dictionary)
signal item_used(item_data: Dictionary)
signal item_equipped(item_data: Dictionary, slot: String)
signal item_unequipped(item_data: Dictionary, slot: String)
signal gold_changed(amount: int)

# Враги
signal enemy_killed(enemy_data: Dictionary)
signal boss_defeated(boss_id: String)

# Квесты
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)
signal quest_objective_updated(quest_id: String, objective: String)

# UI
signal show_dialogue(npc_name: String, lines: Array)
signal dialogue_ended()
signal show_notification(text: String, color: Color)
signal open_shop(shop_data: Array)
signal shop_closed()

# Уровни
signal level_transition(target_level: String, spawn_point: String)
signal level_loaded(level_name: String)
