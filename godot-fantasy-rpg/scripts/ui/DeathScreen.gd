extends CanvasLayer
## Экран смерти

@onready var panel: Panel = $Panel
@onready var respawn_button: Button = $Panel/RespawnButton
@onready var village_button: Button = $Panel/VillageButton

func _ready() -> void:
	panel.visible = false
	EventBus.player_died.connect(_show)
	respawn_button.pressed.connect(_respawn_here)
	village_button.pressed.connect(_respawn_village)

func _show() -> void:
	panel.visible = true
	# Потерять 10% золота
	var lost = int(GameData.player_data.gold * 0.1)
	GameData.player_data.gold -= lost
	EventBus.gold_changed.emit(GameData.player_data.gold)

func _respawn_here() -> void:
	panel.visible = false
	GameData.player_data.hp = GameData.player_data.max_hp
	GameData.player_data.mp = GameData.player_data.max_mp
	EventBus.player_respawned.emit()
	EventBus.player_health_changed.emit(GameData.player_data.hp, GameData.player_data.max_hp)
	EventBus.player_mana_changed.emit(GameData.player_data.mp, GameData.player_data.max_mp)

func _respawn_village() -> void:
	panel.visible = false
	GameData.player_data.hp = GameData.player_data.max_hp
	GameData.player_data.mp = GameData.player_data.max_mp
	GameData.player_data.current_level = "village"
	get_tree().change_scene_to_file("res://scenes/levels/Village.tscn")
