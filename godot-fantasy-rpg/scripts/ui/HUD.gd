extends CanvasLayer
## HUD — полоски HP/MP/XP, золото, уровень, уведомления, квесты

@onready var hp_bar: ProgressBar = $HPBar
@onready var mp_bar: ProgressBar = $MPBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $LevelLabel
@onready var gold_label: Label = $GoldLabel
@onready var weapon_label: Label = $WeaponLabel
@onready var potion_label: Label = $PotionLabel
@onready var notification_container: VBoxContainer = $NotificationContainer
@onready var quest_container: VBoxContainer = $QuestContainer
@onready var boss_bar_container: Control = $BossBarContainer
@onready var boss_hp_bar: ProgressBar = $BossBarContainer/BossHPBar
@onready var boss_name_label: Label = $BossBarContainer/BossNameLabel

var boss_node: Node = null

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_mana_changed.connect(_on_mana_changed)
	EventBus.player_xp_gained.connect(_on_xp_changed)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.show_notification.connect(_show_notification)
	EventBus.item_equipped.connect(_on_item_equipped)
	EventBus.quest_started.connect(_on_quest_updated)
	EventBus.quest_completed.connect(_on_quest_updated)
	EventBus.boss_defeated.connect(_on_boss_defeated)
	
	boss_bar_container.visible = false
	_update_all()

func _process(_delta: float) -> void:
	# Обновить бар босса
	if boss_node and is_instance_valid(boss_node) and not boss_node.is_dead:
		boss_hp_bar.value = boss_node.hp
		boss_bar_container.visible = true
	else:
		boss_bar_container.visible = false
	
	# Обновить зелья
	var potion_count = 0
	for potion_id in GameData.player_data.potions:
		potion_count += GameData.player_data.potions[potion_id]
	if potion_label:
		potion_label.text = "Зелья [F]: " + str(potion_count)

func _update_all() -> void:
	_on_health_changed(GameData.player_data.hp, GameData.player_data.max_hp)
	_on_mana_changed(GameData.player_data.mp, GameData.player_data.max_mp)
	_on_xp_changed(0)
	_on_gold_changed(GameData.player_data.gold)
	_update_weapon_display()
	_update_quest_display()
	if level_label:
		level_label.text = "Ур. " + str(GameData.player_data.level)

func _on_health_changed(current: int, max_val: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_val
		hp_bar.value = current

func _on_mana_changed(current: int, max_val: int) -> void:
	if mp_bar:
		mp_bar.max_value = max_val
		mp_bar.value = current

func _on_xp_changed(_amount: int) -> void:
	if xp_bar:
		var level = GameData.player_data.level
		var current_xp = GameData.player_data.xp
		if level < GameData.LEVEL_TABLE.size():
			var xp_for_next = GameData.LEVEL_TABLE[level] if level < GameData.LEVEL_TABLE.size() else 99999
			var xp_for_current = GameData.LEVEL_TABLE[level - 1] if level > 1 else 0
			xp_bar.max_value = xp_for_next - xp_for_current
			xp_bar.value = current_xp - xp_for_current
		else:
			xp_bar.max_value = 1
			xp_bar.value = 1

func _on_level_up(new_level: int) -> void:
	if level_label:
		level_label.text = "Ур. " + str(new_level)
	_show_notification("УРОВЕНЬ %d!" % new_level, Color.GOLD)

func _on_gold_changed(amount: int) -> void:
	if gold_label:
		gold_label.text = str(amount) + " G"

func _on_item_equipped(_item_data: Dictionary, _slot: String) -> void:
	_update_weapon_display()

func _update_weapon_display() -> void:
	if weapon_label:
		var weapon_id = GameData.player_data.equipped_weapon
		if weapon_id != "" and GameData.WEAPONS.has(weapon_id):
			weapon_label.text = GameData.WEAPONS[weapon_id].name
		else:
			weapon_label.text = "Без оружия"

func _show_notification(text: String, color: Color) -> void:
	if notification_container == null:
		return
	
	var notif = Label.new()
	notif.text = text
	notif.add_theme_color_override("font_color", color)
	notif.add_theme_font_size_override("font_size", 14)
	notif.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_container.add_child(notif)
	
	var tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(notif, "modulate:a", 0.0, 0.5)
	tween.tween_callback(notif.queue_free)

func _update_quest_display() -> void:
	if quest_container == null:
		return
	
	for child in quest_container.get_children():
		child.queue_free()
	
	for quest_id in GameData.player_data.active_quests:
		var quest = GameData.QUESTS.get(quest_id, {})
		if quest.is_empty():
			continue
		
		var quest_label = Label.new()
		var progress_text = ""
		
		match quest.type:
			"kill":
				var kills = GameData.player_data.kill_counts.get(quest.target, 0)
				progress_text = " (%d/%d)" % [kills, quest.target_count]
			"boss":
				if quest.target in GameData.player_data.bosses_defeated:
					progress_text = " (Выполнено!)"
				else:
					progress_text = ""
		
		quest_label.text = "► " + quest.name + progress_text
		quest_label.add_theme_font_size_override("font_size", 11)
		quest_label.add_theme_color_override("font_color", Color.YELLOW)
		quest_container.add_child(quest_label)

func _on_quest_updated(_quest_id: String) -> void:
	_update_quest_display()

func _on_boss_defeated(_boss_id: String) -> void:
	boss_bar_container.visible = false

func set_boss(boss: Node) -> void:
	boss_node = boss
	if boss and GameData.BOSSES.has(boss.boss_id):
		var data = GameData.BOSSES[boss.boss_id]
		boss_name_label.text = data.name
		boss_hp_bar.max_value = data.hp
		boss_hp_bar.value = data.hp
		boss_bar_container.visible = true
