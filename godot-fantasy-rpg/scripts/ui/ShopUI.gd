extends CanvasLayer
## UI магазина

@onready var panel: Panel = $Panel
@onready var item_list: VBoxContainer = $Panel/ScrollContainer/ItemList
@onready var gold_label: Label = $Panel/GoldLabel
@onready var close_button: Button = $Panel/CloseButton

var shop_data: Array = []
var is_open: bool = false

func _ready() -> void:
	panel.visible = false
	EventBus.open_shop.connect(_open_shop)
	close_button.pressed.connect(_close_shop)

func _process(_delta: float) -> void:
	if is_open and Input.is_action_just_pressed("inventory"):
		_close_shop()

func _open_shop(data: Array) -> void:
	shop_data = data
	is_open = true
	panel.visible = true
	_refresh_list()

func _close_shop() -> void:
	is_open = false
	panel.visible = false
	EventBus.shop_closed.emit()

func _refresh_list() -> void:
	for child in item_list.get_children():
		child.queue_free()
	
	gold_label.text = "Золото: " + str(GameData.player_data.gold) + " G"
	
	for item in shop_data:
		var row = HBoxContainer.new()
		row.custom_minimum_size = Vector2(0, 35)
		
		# Название
		var name_label = Label.new()
		name_label.text = item.get("name", "???")
		name_label.custom_minimum_size = Vector2(200, 0)
		var rarity = item.get("rarity", "common")
		name_label.add_theme_color_override("font_color", GameData.get_rarity_color(rarity))
		name_label.add_theme_font_size_override("font_size", 13)
		row.add_child(name_label)
		
		# Характеристики
		var stats_label = Label.new()
		var category = item.get("category", "")
		match category:
			"weapon":
				stats_label.text = "Урон: %d  Скорость: %.1f" % [item.get("damage", 0), item.get("speed", 1.0)]
			"armor":
				stats_label.text = "Защита: %d" % item.get("defense", 0)
			"item":
				stats_label.text = item.get("description", "")
		stats_label.custom_minimum_size = Vector2(200, 0)
		stats_label.add_theme_font_size_override("font_size", 11)
		stats_label.add_theme_color_override("font_color", Color.LIGHT_GRAY)
		row.add_child(stats_label)
		
		# Цена
		var price = item.get("price", 0)
		var buy_button = Button.new()
		buy_button.text = str(price) + " G"
		buy_button.custom_minimum_size = Vector2(80, 30)
		
		var level_req = item.get("level_req", 1)
		if GameData.player_data.gold < price:
			buy_button.disabled = true
			buy_button.tooltip_text = "Недостаточно золота"
		elif GameData.player_data.level < level_req:
			buy_button.disabled = true
			buy_button.tooltip_text = "Нужен уровень " + str(level_req)
		
		var item_copy = item.duplicate()
		buy_button.pressed.connect(_buy_item.bind(item_copy))
		row.add_child(buy_button)
		
		# Требуемый уровень
		if level_req > 1:
			var req_label = Label.new()
			req_label.text = "Ур." + str(level_req)
			req_label.add_theme_font_size_override("font_size", 10)
			if GameData.player_data.level >= level_req:
				req_label.add_theme_color_override("font_color", Color.GREEN)
			else:
				req_label.add_theme_color_override("font_color", Color.RED)
			row.add_child(req_label)
		
		item_list.add_child(row)

func _buy_item(item: Dictionary) -> void:
	var price = item.get("price", 0)
	if GameData.player_data.gold < price:
		EventBus.show_notification.emit("Недостаточно золота!", Color.RED)
		return
	
	var level_req = item.get("level_req", 1)
	if GameData.player_data.level < level_req:
		EventBus.show_notification.emit("Нужен уровень " + str(level_req) + "!", Color.RED)
		return
	
	GameData.player_data.gold -= price
	EventBus.gold_changed.emit(GameData.player_data.gold)
	
	var item_id = item.get("id", "")
	var category = item.get("category", "")
	
	match category:
		"weapon":
			GameData.equip_weapon(item_id)
			EventBus.show_notification.emit("Куплено: " + item.name, Color.GREEN)
		"armor":
			GameData.equip_armor(item_id)
			EventBus.show_notification.emit("Куплено: " + item.name, Color.GREEN)
		"item":
			GameData.add_potion(item_id, 1)
			EventBus.show_notification.emit("Куплено: " + item.name, Color.GREEN)
	
	_refresh_list()
