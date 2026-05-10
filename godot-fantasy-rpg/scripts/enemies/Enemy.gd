extends CharacterBody2D
## Базовый скрипт врага — AI, движение, атака, дроп лута

@export var enemy_id: String = "slime_green"

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var label: Label = $Label
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var enemy_data: Dictionary = {}
var hp: int = 20
var max_hp: int = 20
var damage: int = 3
var defense: int = 0
var speed: float = 40.0
var aggro_range: float = 80.0
var attack_range: float = 30.0

var target: CharacterBody2D = null
var is_dead: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var wander_direction: Vector2 = Vector2.ZERO
var spawn_position: Vector2 = Vector2.ZERO

# Для показа урона
var damage_numbers: Array = []

enum State { IDLE, WANDER, CHASE, ATTACK, RANGED_ATTACK, HURT, DEAD }
var state: State = State.IDLE

func _ready() -> void:
	_load_enemy_data()
	spawn_position = global_position
	
	hurtbox.area_entered.connect(_on_hit_by_player)
	
	attack_area.monitoring = false
	attack_shape.disabled = true
	
	# Настроить навигацию
	nav_agent.path_desired_distance = 4.0
	nav_agent.target_desired_distance = 4.0

func _load_enemy_data() -> void:
	if GameData.ENEMIES.has(enemy_id):
		enemy_data = GameData.ENEMIES[enemy_id]
		hp = enemy_data.hp
		max_hp = enemy_data.hp
		damage = enemy_data.damage
		defense = enemy_data.defense
		speed = enemy_data.speed
		aggro_range = enemy_data.get("aggro_range", 80)
		attack_range = enemy_data.get("attack_range", 30)
		
		# Визуал
		if sprite:
			sprite.modulate = enemy_data.get("color", Color.WHITE)
		if label:
			label.text = enemy_data.name
		_update_health_bar()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	attack_cooldown -= delta
	
	# Нокбэк
	if knockback_velocity.length() > 5:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
		move_and_slide()
		return
	
	# Найти игрока
	_find_target()
	
	match state:
		State.IDLE:
			_state_idle(delta)
		State.WANDER:
			_state_wander(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.RANGED_ATTACK:
			_state_ranged_attack(delta)
	
	move_and_slide()
	_update_sprite()

func _find_target() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		target = null
		return
	
	var closest = players[0]
	var closest_dist = global_position.distance_to(closest.global_position)
	
	for p in players:
		var d = global_position.distance_to(p.global_position)
		if d < closest_dist:
			closest = p
			closest_dist = d
	
	if closest_dist <= aggro_range:
		target = closest
		if closest_dist <= attack_range and attack_cooldown <= 0:
			if enemy_data.get("behavior", "chase") == "ranged":
				state = State.RANGED_ATTACK
			else:
				state = State.ATTACK
		else:
			state = State.CHASE
	else:
		target = null
		if state == State.CHASE:
			state = State.IDLE

func _state_idle(delta: float) -> void:
	velocity = Vector2.ZERO
	wander_timer -= delta
	if wander_timer <= 0:
		state = State.WANDER
		wander_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		wander_timer = randf_range(2.0, 5.0)

func _state_wander(delta: float) -> void:
	velocity = wander_direction * speed * 0.3
	wander_timer -= delta
	
	# Не уходить далеко от спавна
	if global_position.distance_to(spawn_position) > 150:
		wander_direction = (spawn_position - global_position).normalized()
	
	if wander_timer <= 0:
		state = State.IDLE
		wander_timer = randf_range(1.0, 3.0)

func _state_chase(_delta: float) -> void:
	if target == null:
		state = State.IDLE
		return
	
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed

func _state_attack(_delta: float) -> void:
	if target == null:
		state = State.IDLE
		return
	
	velocity = Vector2.ZERO
	
	if attack_cooldown <= 0:
		_perform_attack()
		attack_cooldown = 1.2

func _state_ranged_attack(_delta: float) -> void:
	if target == null:
		state = State.IDLE
		return
	
	# Отступить если слишком близко
	var dist = global_position.distance_to(target.global_position)
	if dist < attack_range * 0.5:
		var away = (global_position - target.global_position).normalized()
		velocity = away * speed * 0.5
	else:
		velocity = Vector2.ZERO
	
	if attack_cooldown <= 0:
		_shoot_projectile()
		attack_cooldown = 1.5

func _perform_attack() -> void:
	is_attacking = true
	attack_area.monitoring = true
	attack_shape.disabled = false
	
	# Проверить попадание по игроку
	await get_tree().create_timer(0.2).timeout
	
	if not is_dead:
		attack_area.monitoring = false
		attack_shape.disabled = true
		is_attacking = false

func _shoot_projectile() -> void:
	if target == null:
		return
	var projectile = preload("res://scenes/weapons/EnemyProjectile.tscn").instantiate()
	projectile.global_position = global_position
	projectile.direction = (target.global_position - global_position).normalized()
	projectile.damage = damage
	get_parent().add_child(projectile)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, crit: bool = false) -> void:
	if is_dead:
		return
	
	var actual = max(1, amount - defense)
	hp -= actual
	knockback_velocity = knockback
	
	_update_health_bar()
	_show_damage_number(actual, crit)
	_flash_hurt()
	
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	state = State.DEAD
	
	# Дроп золота
	var gold_range = enemy_data.get("gold_drop", [1, 5])
	var gold = 0
	if gold_range is Array:
		gold = randi_range(gold_range[0], gold_range[1])
	else:
		gold = int(gold_range)
	GameData.add_gold(gold)
	
	# Дроп XP
	var xp = enemy_data.get("xp", 10)
	GameData.add_xp(xp)
	
	# Дроп лута
	for loot_entry in enemy_data.get("loot", []):
		if loot_entry is Array and loot_entry.size() >= 2:
			if randf() < loot_entry[1]:
				_drop_item(loot_entry[0])
	
	# Уведомления
	GameData.add_kill(enemy_id)
	EventBus.enemy_killed.emit(enemy_data)
	EventBus.show_notification.emit("+" + str(xp) + " XP  +" + str(gold) + " золота", Color.GOLD)
	
	# Анимация смерти
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _drop_item(item_id: String) -> void:
	var drop = preload("res://scenes/items/ItemDrop.tscn").instantiate()
	drop.item_id = item_id
	drop.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	get_parent().call_deferred("add_child", drop)

func get_damage() -> int:
	return damage

func _show_damage_number(amount: int, crit: bool) -> void:
	var dmg_label = Label.new()
	dmg_label.text = str(amount) + ("!" if crit else "")
	dmg_label.add_theme_font_size_override("font_size", 16 if crit else 12)
	dmg_label.add_theme_color_override("font_color", Color.GOLD if crit else Color.WHITE)
	dmg_label.position = Vector2(-10, -40)
	dmg_label.z_index = 100
	add_child(dmg_label)
	
	var tween = create_tween()
	tween.tween_property(dmg_label, "position:y", dmg_label.position.y - 30, 0.6)
	tween.parallel().tween_property(dmg_label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(dmg_label.queue_free)

func _flash_hurt() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(sprite, "modulate", enemy_data.get("color", Color.WHITE), 0.15)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
		health_bar.visible = hp < max_hp

func _update_sprite() -> void:
	if sprite and velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _on_hit_by_player(area: Area2D) -> void:
	pass  # Обрабатывается через attack_area игрока
