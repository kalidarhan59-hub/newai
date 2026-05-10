extends Node2D
## Визуальный эффект AOE атаки

var radius: float = 60.0
var lifetime: float = 0.5
var elapsed: float = 0.0
var color: Color = Color(1, 0.3, 0.1, 0.4)

func _ready() -> void:
	z_index = -1

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var alpha = 1.0 - (elapsed / lifetime)
	var c = Color(color.r, color.g, color.b, color.a * alpha)
	draw_circle(Vector2.ZERO, radius * (0.5 + elapsed / lifetime * 0.5), c)
