extends CharacterBody2D
## НПС — торговец, квестодатель, тренер

@export var npc_id: String = "elder"

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var interact_area: Area2D = $InteractArea
@onready var exclamation: Label = $Exclamation

var npc_data: Dictionary = {}
var player_nearby: bool = false

func _ready() -> void:
	_load_npc_data()
	interact_area.body_entered.connect(_on_player_enter)
	interact_area.body_exited.connect(_on_player_exit)

func _load_npc_data() -> void:
	if GameData.NPCS.has(npc_id):
		npc_data = GameData.NPCS[npc_id]
		if label:
			label.text = npc_data.name
		if sprite:
			sprite.modulate = npc_data.get("color", Color.WHITE)
		_update_exclamation()

func _process(_delta: float) -> void:
	_update_exclamation()
	
	if player_nearby and Input.is_action_just_pressed("interact"):
		interact()

func interact() -> void:
	if npc_data.is_empty():
		return
	
	var role = npc_data.get("role", "")
	
	match role:
		"quest_giver":
			_handle_quest_giver()
		"shop":
			_handle_shop()
		_:
			_show_dialogue("intro")

func _handle_quest_giver() -> void:
	var quests = npc_data.get("quests", [])
	
	for quest_id in quests:
		# Проверить завершённые
		if quest_id in GameData.player_data.completed_quests:
			continue
		
		# Проверить активные — может, можно сдать?
		if quest_id in GameData.player_data.active_quests:
			if _check_quest_complete(quest_id):
				_complete_quest(quest_id)
				return
			else:
				_show_dialogue("quest_active")
				return
		
		# Выдать новый квест
		_start_quest(quest_id)
		return
	
	# Все квесты выполнены
	_show_dialogue("quest_complete")

func _start_quest(quest_id: String) -> void:
	var quest = GameData.QUESTS.get(quest_id, {})
	if quest.is_empty():
		return
	
	GameData.player_data.active_quests.append(quest_id)
	_show_dialogue("intro")
	EventBus.quest_started.emit(quest_id)
	EventBus.show_notification.emit("Новый квест: " + quest.name, Color.YELLOW)

func _check_quest_complete(quest_id: String) -> bool:
	var quest = GameData.QUESTS.get(quest_id, {})
	if quest.is_empty():
		return false
	
	match quest.type:
		"kill":
			var kills = GameData.player_data.kill_counts.get(quest.target, 0)
			return kills >= quest.target_count
		"boss":
			return quest.target in GameData.player_data.bosses_defeated
		_:
			return false

func _complete_quest(quest_id: String) -> void:
	var quest = GameData.QUESTS.get(quest_id, {})
	if quest.is_empty():
		return
	
	# Убрать из активных, добавить в завершённые
	GameData.player_data.active_quests.erase(quest_id)
	GameData.player_data.completed_quests.append(quest_id)
	
	# Выдать награды
	var rewards = quest.get("rewards", {})
	if rewards.has("xp"):
		GameData.add_xp(rewards.xp)
	if rewards.has("gold"):
		GameData.add_gold(rewards.gold)
	if rewards.has("items"):
		for item_id in rewards.items:
			if GameData.WEAPONS.has(item_id):
				GameData.equip_weapon(item_id)
			elif GameData.ARMOR.has(item_id):
				GameData.equip_armor(item_id)
			elif GameData.ITEMS.has(item_id):
				var item = GameData.ITEMS[item_id]
				if item.subtype == "key":
					GameData.player_data.keys.append(item_id)
				else:
					GameData.add_potion(item_id, 1)
	
	_show_dialogue("quest_complete")
	EventBus.quest_completed.emit(quest_id)
	EventBus.show_notification.emit("Квест выполнен: " + quest.name + "!", Color.GOLD)

func _handle_shop() -> void:
	var shop_items = npc_data.get("shop_items", [])
	var shop_data = []
	
	for item_id in shop_items:
		var data = {}
		if GameData.WEAPONS.has(item_id):
			data = GameData.WEAPONS[item_id].duplicate()
			data["id"] = item_id
			data["category"] = "weapon"
		elif GameData.ARMOR.has(item_id):
			data = GameData.ARMOR[item_id].duplicate()
			data["id"] = item_id
			data["category"] = "armor"
		elif GameData.ITEMS.has(item_id):
			data = GameData.ITEMS[item_id].duplicate()
			data["id"] = item_id
			data["category"] = "item"
		
		if not data.is_empty():
			shop_data.append(data)
	
	_show_dialogue("intro")
	
	# Задержка перед открытием магазина
	await get_tree().create_timer(0.5).timeout
	EventBus.open_shop.emit(shop_data)

func _show_dialogue(dialogue_key: String) -> void:
	var dialogues = npc_data.get("dialogues", {})
	var lines = dialogues.get(dialogue_key, ["..."])
	EventBus.show_dialogue.emit(npc_data.name, lines)

func _update_exclamation() -> void:
	if exclamation == null:
		return
	
	var has_available_quest = false
	var has_completable_quest = false
	
	for quest_id in npc_data.get("quests", []):
		if quest_id in GameData.player_data.completed_quests:
			continue
		if quest_id in GameData.player_data.active_quests:
			if _check_quest_complete(quest_id):
				has_completable_quest = true
			continue
		has_available_quest = true
	
	if has_completable_quest:
		exclamation.text = "?"
		exclamation.add_theme_color_override("font_color", Color.GOLD)
		exclamation.visible = true
	elif has_available_quest:
		exclamation.text = "!"
		exclamation.add_theme_color_override("font_color", Color.YELLOW)
		exclamation.visible = true
	elif npc_data.get("role", "") == "shop":
		exclamation.text = "$"
		exclamation.add_theme_color_override("font_color", Color.GREEN)
		exclamation.visible = true
	else:
		exclamation.visible = false

func _on_player_enter(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		EventBus.show_notification.emit("[E] Поговорить с " + npc_data.get("name", "НПС"), Color.WHITE)

func _on_player_exit(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
