extends Area2D
## Снаряд врага

var direction: Vector2 = Vector2.RIGHT
var damage: int = 10
var speed_val: float = 150.0
var lifetime: float = 3.0

func _ready() -> void:
	var visual = ColorRect.new()
	visual.size = Vector2(6, 6)
	visual.position = Vector2(-3, -3)
	visual.color = Color.RED
	add_child(visual)
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 5
	shape.shape = circle
	add_child(shape)
	
	rotation = direction.angle()
	add_to_group("enemy_attack")
	
	body_entered.connect(_on_body_entered)
	
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += direction * speed_val * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		queue_free()
