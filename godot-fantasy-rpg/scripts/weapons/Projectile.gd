extends Area2D
## Снаряд игрока (стрела, магический шар и т.д.)

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var speed_val: float = 300.0
var max_range: float = 200.0
var element: String = ""
var pierce: bool = false

var distance_traveled: float = 0.0
var hit_enemies: Array = []

func _ready() -> void:
	# Визуал
	var visual = ColorRect.new()
	visual.size = Vector2(8, 4)
	visual.position = Vector2(-4, -2)
	
	match element:
		"fire": visual.color = Color.ORANGE_RED
		"ice": visual.color = Color.LIGHT_BLUE
		"arcane": visual.color = Color.MEDIUM_PURPLE
		"poison": visual.color = Color.GREEN
		"dark": visual.color = Color.DARK_VIOLET
		"holy": visual.color = Color.GOLD
		"lightning": visual.color = Color.YELLOW
		_: visual.color = Color.WHITE
	
	add_child(visual)
	rotation = direction.angle()
	
	# Коллизия
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 5
	shape.shape = circle
	add_child(shape)
	
	add_to_group("player_attack")
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	var move = direction * speed_val * delta
	position += move
	distance_traveled += move.length()
	
	if distance_traveled >= max_range:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox") or area.get_parent().is_in_group("enemies"):
		var enemy = area.get_parent()
		if enemy in hit_enemies:
			return
		hit_enemies.append(enemy)
		
		if enemy.has_method("take_damage"):
			var kb = direction * 100
			enemy.take_damage(damage, kb, false)
		
		if not pierce:
			queue_free()
