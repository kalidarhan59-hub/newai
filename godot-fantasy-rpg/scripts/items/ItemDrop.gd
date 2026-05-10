extends Area2D
## Выпавший предмет — подбирается игроком

@export var item_id: String = ""

var bob_time: float = 0.0
var start_y: float = 0.0

func _ready() -> void:
	start_y = position.y
	
	# Визуал
	var visual = ColorRect.new()
	visual.name = "Visual"
	visual.size = Vector2(12, 12)
	visual.position = Vector2(-6, -6)
	
	# Цвет по типу
	if GameData.WEAPONS.has(item_id):
		visual.color = GameData.get_rarity_color(GameData.WEAPONS[item_id].get("rarity", "common"))
	elif GameData.ARMOR.has(item_id):
		visual.color = GameData.get_rarity_color(GameData.ARMOR[item_id].get("rarity", "common"))
	elif GameData.ITEMS.has(item_id):
		match GameData.ITEMS[item_id].get("subtype", ""):
			"heal": visual.color = Color.GREEN
			"mana": visual.color = Color.DODGER_BLUE
			"key": visual.color = Color.GOLD
			"trophy": visual.color = Color.DARK_ORCHID
			_: visual.color = Color.YELLOW
	else:
		visual.color = Color.YELLOW
	
	add_child(visual)
	
	# Подпись
	var label = Label.new()
	label.name = "ItemLabel"
	var item_name = _get_item_name()
	label.text = item_name
	label.add_theme_font_size_override("font_size", 10)
	label.position = Vector2(-30, -22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size = Vector2(60, 15)
	add_child(label)
	
	# Коллизия
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 15
	shape.shape = circle
	add_child(shape)
	
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	bob_time += delta * 3
	position.y = start_y + sin(bob_time) * 3

func _get_item_name() -> String:
	if GameData.WEAPONS.has(item_id):
		return GameData.WEAPONS[item_id].name
	elif GameData.ARMOR.has(item_id):
		return GameData.ARMOR[item_id].name
	elif GameData.ITEMS.has(item_id):
		return GameData.ITEMS[item_id].name
	return item_id

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_pickup()

func _pickup() -> void:
	if GameData.WEAPONS.has(item_id):
		GameData.equip_weapon(item_id)
		EventBus.show_notification.emit("Экипировано: " + GameData.WEAPONS[item_id].name, GameData.get_rarity_color(GameData.WEAPONS[item_id].rarity))
	elif GameData.ARMOR.has(item_id):
		GameData.equip_armor(item_id)
		EventBus.show_notification.emit("Экипировано: " + GameData.ARMOR[item_id].name, GameData.get_rarity_color(GameData.ARMOR[item_id].rarity))
	elif GameData.ITEMS.has(item_id):
		var item = GameData.ITEMS[item_id]
		if item.subtype == "key":
			GameData.player_data.keys.append(item_id)
			EventBus.show_notification.emit("Получен: " + item.name, Color.GOLD)
		elif item.type == "trophy":
			EventBus.show_notification.emit("Трофей: " + item.name, Color.DARK_ORCHID)
		else:
			GameData.add_potion(item_id, 1)
			EventBus.show_notification.emit("Получено: " + item.name, Color.GREEN)
	
	EventBus.item_picked_up.emit({"id": item_id})
	queue_free()
