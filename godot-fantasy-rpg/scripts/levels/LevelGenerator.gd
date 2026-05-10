extends Node2D
## Генератор уровня — создаёт карту, расставляет врагов, НПС, боссов, порталы

@export var level_id: String = "village"

@onready var player_node: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D

var level_data: Dictionary = {}

func _ready() -> void:
	level_data = GameData.LEVELS.get(level_id, {})
	GameData.player_data.current_level = level_id
	
	# Восстановить HP/MP игрока
	player_node.get_node("HealthBar").max_value = GameData.player_data.max_hp
	player_node.get_node("HealthBar").value = GameData.player_data.hp
	
	_generate_terrain()
	_spawn_enemies()
	_spawn_npcs()
	_spawn_boss()
	_spawn_portals()
	
	EventBus.level_loaded.emit(level_data.get("name", level_id))
	EventBus.show_notification.emit(level_data.get("name", ""), Color.WHITE)

func _generate_terrain() -> void:
	var bg_color = level_data.get("bg_color", Color(0.2, 0.3, 0.2))
	
	# Фоновый прямоугольник
	var bg = ColorRect.new()
	bg.color = bg_color
	bg.size = Vector2(3000, 3000)
	bg.position = Vector2(-1500, -1500)
	bg.z_index = -10
	add_child(bg)
	
	# Генерировать случайные препятствия
	match level_id:
		"village":
			_generate_village()
		"forest":
			_generate_forest()
		"cave":
			_generate_cave()
		"castle":
			_generate_castle()
		"volcano":
			_generate_volcano()

func _generate_village() -> void:
	# Дома
	var house_positions = [
		Vector2(-200, -100), Vector2(200, -100),
		Vector2(-200, 150), Vector2(200, 150),
		Vector2(0, -250),
	]
	
	for i in house_positions.size():
		_create_building("Дом " + str(i + 1), house_positions[i], Vector2(80, 60), Color(0.5, 0.35, 0.2))
	
	# Центральная площадь
	var plaza = ColorRect.new()
	plaza.color = Color(0.6, 0.55, 0.4)
	plaza.size = Vector2(150, 150)
	plaza.position = Vector2(-75, -75)
	plaza.z_index = -5
	add_child(plaza)
	
	# Кузница
	_create_building("Кузница", Vector2(-300, 0), Vector2(90, 70), Color(0.4, 0.3, 0.25))
	# Алхимик
	_create_building("Зельеварка", Vector2(300, 0), Vector2(70, 60), Color(0.35, 0.2, 0.45))
	# Башня мага
	_create_building("Башня Мага", Vector2(0, 300), Vector2(50, 80), Color(0.25, 0.3, 0.5))
	
	# Деревья-декор
	for i in range(20):
		_create_tree(Vector2(randf_range(-500, 500), randf_range(-400, 400)))
	
	# Дорожки
	_create_path(Vector2(0, 0), Vector2(0, 500), 20)
	_create_path(Vector2(0, 0), Vector2(-400, 0), 20)
	_create_path(Vector2(0, 0), Vector2(400, 0), 20)

func _generate_forest() -> void:
	# Много деревьев
	for i in range(60):
		var pos = Vector2(randf_range(-800, 800), randf_range(-800, 800))
		_create_tree(pos)
	
	# Поляны
	for i in range(5):
		var clearing = ColorRect.new()
		clearing.color = Color(0.2, 0.4, 0.15)
		clearing.size = Vector2(100, 100)
		clearing.position = Vector2(randf_range(-600, 600), randf_range(-600, 600))
		clearing.z_index = -5
		add_child(clearing)
	
	# Тропинки
	_create_path(Vector2(-800, 0), Vector2(800, 0), 15)
	_create_path(Vector2(0, -800), Vector2(0, 800), 15)

func _generate_cave() -> void:
	# Тёмный пол
	# Стены-скалы
	for i in range(40):
		var rock = StaticBody2D.new()
		rock.position = Vector2(randf_range(-700, 700), randf_range(-700, 700))
		
		var visual = ColorRect.new()
		visual.color = Color(0.2, 0.2, 0.25)
		var size = Vector2(randf_range(30, 80), randf_range(30, 80))
		visual.size = size
		visual.position = -size / 2
		rock.add_child(visual)
		
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = size
		shape.shape = rect
		rock.add_child(shape)
		
		rock.collision_layer = 0b01000000  # Layer 7 = Walls
		add_child(rock)
	
	# Кристаллы (декор + свет)
	for i in range(10):
		var crystal_pos = Vector2(randf_range(-600, 600), randf_range(-600, 600))
		var crystal = ColorRect.new()
		crystal.color = Color(0.3, 0.5, 0.8, 0.7)
		crystal.size = Vector2(10, 20)
		crystal.position = crystal_pos
		add_child(crystal)
		
		var light = PointLight2D.new()
		light.position = crystal_pos
		light.color = Color(0.3, 0.4, 0.8)
		light.energy = 0.5
		light.texture = _create_light_texture()
		add_child(light)

func _generate_castle() -> void:
	# Стены замка
	_create_wall(Vector2(-500, -500), Vector2(1000, 20))  # Верхняя
	_create_wall(Vector2(-500, 500), Vector2(1000, 20))   # Нижняя
	_create_wall(Vector2(-500, -500), Vector2(20, 1000))   # Левая
	_create_wall(Vector2(500, -500), Vector2(20, 1000))    # Правая
	
	# Комнаты
	for i in range(6):
		var x = randf_range(-400, 400)
		var y = randf_range(-400, 400)
		_create_wall(Vector2(x, y), Vector2(randf_range(50, 150), 15))
	
	# Ковры (декор)
	for i in range(3):
		var carpet = ColorRect.new()
		carpet.color = Color(0.4, 0.1, 0.1)
		carpet.size = Vector2(80, 200)
		carpet.position = Vector2(randf_range(-300, 300), randf_range(-300, 300))
		carpet.z_index = -5
		add_child(carpet)
	
	# Факелы
	for i in range(8):
		var torch_pos = Vector2(randf_range(-450, 450), randf_range(-450, 450))
		var light = PointLight2D.new()
		light.position = torch_pos
		light.color = Color(1.0, 0.6, 0.2)
		light.energy = 0.6
		light.texture = _create_light_texture()
		add_child(light)

func _generate_volcano() -> void:
	# Лавовые реки
	for i in range(8):
		var lava = ColorRect.new()
		lava.color = Color(0.8, 0.2, 0.0, 0.8)
		lava.size = Vector2(randf_range(20, 40), randf_range(100, 400))
		lava.position = Vector2(randf_range(-600, 600), randf_range(-600, 600))
		lava.z_index = -5
		add_child(lava)
	
	# Скалы
	for i in range(25):
		var rock = StaticBody2D.new()
		var pos = Vector2(randf_range(-700, 700), randf_range(-700, 700))
		rock.position = pos
		
		var visual = ColorRect.new()
		visual.color = Color(0.3, 0.15, 0.1)
		var size = Vector2(randf_range(40, 100), randf_range(40, 100))
		visual.size = size
		visual.position = -size / 2
		rock.add_child(visual)
		
		var shape = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = size
		shape.shape = rect
		rock.add_child(shape)
		rock.collision_layer = 0b01000000
		add_child(rock)
	
	# Огненные частицы (свет)
	for i in range(12):
		var fire_pos = Vector2(randf_range(-500, 500), randf_range(-500, 500))
		var light = PointLight2D.new()
		light.position = fire_pos
		light.color = Color(1.0, 0.3, 0.0)
		light.energy = 0.8
		light.texture = _create_light_texture()
		add_child(light)

func _spawn_enemies() -> void:
	var enemy_types = level_data.get("enemy_types", [])
	if enemy_types.is_empty():
		return
	
	var enemy_count = 12 + GameData.player_data.level * 2
	
	for i in range(enemy_count):
		var enemy_scene = preload("res://scenes/enemies/Enemy.tscn")
		var enemy = enemy_scene.instantiate()
		enemy.enemy_id = enemy_types[randi() % enemy_types.size()]
		
		var pos = Vector2(randf_range(-600, 600), randf_range(-600, 600))
		# Не спавнить слишком близко к игроку
		while pos.length() < 150:
			pos = Vector2(randf_range(-600, 600), randf_range(-600, 600))
		
		enemy.position = pos
		add_child(enemy)

func _spawn_npcs() -> void:
	var npc_positions = {
		"village": {
			"elder": Vector2(0, -30),
			"blacksmith": Vector2(-300, 0),
			"alchemist": Vector2(300, 0),
			"wizard": Vector2(0, 300),
			"warrior_trainer": Vector2(-150, 200),
		},
		"cave": {
			"mysterious_stranger": Vector2(0, -200),
		},
	}
	
	if not npc_positions.has(level_id):
		return
	
	for npc_id in npc_positions[level_id]:
		var npc_scene = preload("res://scenes/npcs/NPC.tscn")
		var npc = npc_scene.instantiate()
		npc.npc_id = npc_id
		npc.position = npc_positions[level_id][npc_id]
		add_child(npc)

func _spawn_boss() -> void:
	var boss_id = level_data.get("boss", "")
	if boss_id == "" or boss_id in GameData.player_data.bosses_defeated:
		return
	
	var boss_scene = preload("res://scenes/bosses/Boss.tscn")
	var boss = boss_scene.instantiate()
	boss.boss_id = boss_id
	boss.position = Vector2(0, -500)  # В конце уровня
	add_child(boss)
	
	# Подключить бар HP босса
	var hud = get_node_or_null("HUD")
	if hud and hud.has_method("set_boss"):
		hud.set_boss(boss)

func _spawn_portals() -> void:
	# Портал назад в деревню
	if level_id != "village":
		_create_portal(Vector2(0, 600), "village", "Деревня", Color.GREEN)
	
	# Порталы к другим уровням
	match level_id:
		"village":
			_create_portal(Vector2(0, -500), "forest", "Тёмный Лес", Color.DARK_GREEN)
			if GameData.has_key("key_cave"):
				_create_portal(Vector2(-500, 0), "cave", "Ледяная Пещера", Color.LIGHT_BLUE)
			if GameData.has_key("key_castle"):
				_create_portal(Vector2(500, 0), "castle", "Тёмный Замок", Color.DARK_VIOLET)
			if GameData.has_key("key_volcano"):
				_create_portal(Vector2(0, 500), "volcano", "Вулкан Игниса", Color.ORANGE_RED)
		"forest":
			if GameData.has_key("key_cave"):
				_create_portal(Vector2(600, 0), "cave", "Ледяная Пещера", Color.LIGHT_BLUE)

func _create_portal(pos: Vector2, target_level: String, label_text: String, color: Color) -> void:
	var portal = Area2D.new()
	portal.position = pos
	
	var visual = ColorRect.new()
	visual.color = color
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	portal.add_child(visual)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	shape.shape = rect
	portal.add_child(shape)
	
	var lbl = Label.new()
	lbl.text = "► " + label_text
	lbl.position = Vector2(-50, -35)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(100, 20)
	portal.add_child(lbl)
	
	portal.body_entered.connect(func(body):
		if body.is_in_group("player"):
			_transition_to(target_level)
	)
	
	add_child(portal)
	
	# Анимация пульсации
	var tween = create_tween().set_loops()
	tween.tween_property(visual, "modulate:a", 0.5, 0.8)
	tween.tween_property(visual, "modulate:a", 1.0, 0.8)

func _transition_to(target_level: String) -> void:
	# Проверить ключ
	var target_data = GameData.LEVELS.get(target_level, {})
	var required_key = target_data.get("required_key", null)
	if required_key and not GameData.has_key(required_key):
		EventBus.show_notification.emit("Нужен ключ: " + GameData.ITEMS.get(required_key, {}).get("name", required_key), Color.RED)
		return
	
	GameData.player_data.current_level = target_level
	
	var scene_path = "res://scenes/levels/" + target_level.capitalize() + ".tscn"
	get_tree().change_scene_to_file(scene_path)

# ==================== Хелпер-функции ====================

func _create_building(bld_name: String, pos: Vector2, size: Vector2, color: Color) -> void:
	var building = StaticBody2D.new()
	building.position = pos
	
	var visual = ColorRect.new()
	visual.color = color
	visual.size = size
	visual.position = -size / 2
	building.add_child(visual)
	
	# Крыша
	var roof = ColorRect.new()
	roof.color = color.darkened(0.3)
	roof.size = Vector2(size.x + 10, 15)
	roof.position = Vector2(-size.x / 2 - 5, -size.y / 2 - 15)
	building.add_child(roof)
	
	# Подпись
	var lbl = Label.new()
	lbl.text = bld_name
	lbl.position = Vector2(-size.x / 2, -size.y / 2 - 30)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(size.x, 15)
	building.add_child(lbl)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	building.add_child(shape)
	
	building.collision_layer = 0b01000000  # Walls
	add_child(building)

func _create_tree(pos: Vector2) -> void:
	var tree = StaticBody2D.new()
	tree.position = pos
	
	# Ствол
	var trunk = ColorRect.new()
	trunk.color = Color(0.35, 0.2, 0.1)
	trunk.size = Vector2(8, 20)
	trunk.position = Vector2(-4, -10)
	tree.add_child(trunk)
	
	# Крона
	var crown = ColorRect.new()
	crown.color = Color(0.1, 0.4 + randf() * 0.2, 0.1)
	crown.size = Vector2(25, 25)
	crown.position = Vector2(-12.5, -30)
	tree.add_child(crown)
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 8
	shape.shape = circle
	tree.add_child(shape)
	
	tree.collision_layer = 0b01000000
	add_child(tree)

func _create_wall(pos: Vector2, size: Vector2) -> void:
	var wall = StaticBody2D.new()
	wall.position = pos
	
	var visual = ColorRect.new()
	visual.color = Color(0.3, 0.3, 0.35)
	visual.size = size
	wall.add_child(visual)
	
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2
	wall.add_child(shape)
	
	wall.collision_layer = 0b01000000
	add_child(wall)

func _create_path(from: Vector2, to: Vector2, width: float) -> void:
	var path = ColorRect.new()
	path.color = Color(0.55, 0.5, 0.35)
	var diff = to - from
	if abs(diff.x) > abs(diff.y):
		path.size = Vector2(abs(diff.x), width)
	else:
		path.size = Vector2(width, abs(diff.y))
	path.position = Vector2(min(from.x, to.x), min(from.y, to.y))
	if abs(diff.x) > abs(diff.y):
		path.position.y -= width / 2
	else:
		path.position.x -= width / 2
	path.z_index = -5
	add_child(path)

func _create_light_texture() -> Texture2D:
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center = Vector2(32, 32)
	for x in 64:
		for y in 64:
			var dist = Vector2(x, y).distance_to(center) / 32.0
			var alpha = max(0, 1.0 - dist)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)
