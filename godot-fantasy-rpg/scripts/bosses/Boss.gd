extends CharacterBody2D
## Скрипт босса — фазы, уникальные атаки, призыв мобов

@export var boss_id: String = "forest_guardian"

@onready var sprite: Sprite2D = $Sprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var label: Label = $Label

var boss_data: Dictionary = {}
var hp: int = 300
var max_hp: int = 300
var damage: int = 18
var defense: int = 10
var speed: float = 40.0
var current_phase: int = 0

var target: CharacterBody2D = null
var is_dead: bool = false
var attack_cooldown: float = 0.0
var special_cooldown: float = 0.0
var knockback_velocity: Vector2 = Vector2.ZERO
var phase_announced: Array = []

enum BossState { IDLE, CHASE, ATTACK, SPECIAL, SUMMON, DEATH }
var state: BossState = BossState.IDLE

func _ready() -> void:
	_load_boss_data()
	attack_area.monitoring = false
	attack_shape.disabled = true
	hurtbox.area_entered.connect(_on_hit)

func _load_boss_data() -> void:
	if GameData.BOSSES.has(boss_id):
		boss_data = GameData.BOSSES[boss_id]
		hp = boss_data.hp
		max_hp = boss_data.hp
		damage = boss_data.damage
		defense = boss_data.defense
		speed = boss_data.speed
		
		if sprite:
			sprite.modulate = boss_data.get("color", Color.RED)
			var s = boss_data.get("size", 2.0)
			sprite.scale = Vector2(s, s)
		if label:
			label.text = boss_data.name
		_update_health_bar()
		
		for _i in boss_data.get("phases", []).size():
			phase_announced.append(false)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	attack_cooldown -= delta
	special_cooldown -= delta
	
	# Нокбэк
	if knockback_velocity.length() > 3:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8 * delta)
		move_and_slide()
		return
	
	_find_target()
	_check_phase()
	
	match state:
		BossState.IDLE:
			velocity = Vector2.ZERO
		BossState.CHASE:
			_chase(delta)
		BossState.ATTACK:
			_attack(delta)
		BossState.SPECIAL:
			_special_attack(delta)
	
	move_and_slide()
	_update_sprite()

func _find_target() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.is_empty():
		target = null
		state = BossState.IDLE
		return
	
	target = players[0]
	var dist = global_position.distance_to(target.global_position)
	
	if state == BossState.IDLE or state == BossState.CHASE:
		if dist <= 50 and attack_cooldown <= 0:
			state = BossState.ATTACK
		elif special_cooldown <= 0 and current_phase > 0:
			state = BossState.SPECIAL
		else:
			state = BossState.CHASE

func _check_phase() -> void:
	var phases = boss_data.get("phases", [])
	for i in phases.size():
		var phase = phases[i]
		var hp_percent = float(hp) / float(max_hp)
		if hp_percent <= phase.hp_percent and not phase_announced[i] if i < phase_announced.size() else false:
			current_phase = i
			phase_announced[i] = true
			speed = phase.get("speed", speed)
			
			if i > 0:
				EventBus.show_notification.emit(boss_data.name + " в ярости!", Color.RED)
				_phase_transition_effect()
			
			# Призыв мобов
			if phase.has("summon"):
				_summon_minions(phase.summon, phase.get("count", 2))

func _chase(_delta: float) -> void:
	if target == null:
		return
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed

func _attack(_delta: float) -> void:
	if target == null:
		state = BossState.IDLE
		return
	
	velocity = Vector2.ZERO
	
	if attack_cooldown <= 0:
		_perform_melee_attack()
		attack_cooldown = 1.5
		state = BossState.CHASE

func _special_attack(_delta: float) -> void:
	if target == null:
		state = BossState.IDLE
		return
	
	velocity = Vector2.ZERO
	
	if special_cooldown <= 0:
		var phases = boss_data.get("phases", [])
		if current_phase < phases.size():
			var phase = phases[current_phase]
			var attack_type = phase.get("attack", "slam")
			
			match attack_type:
				"stomp", "ice_slam", "slam":
					_aoe_attack(60, damage)
				"vine_whip", "shadow_strike":
					_ranged_strike()
				"frost_breath", "fire_breath":
					_breath_attack()
				"dark_bolt":
					_shoot_boss_projectile()
				"summon_undead":
					_summon_minions(phase.get("summon", "skeleton"), phase.get("count", 3))
				"ice_storm", "death_wave", "meteor_rain", "inferno", "dark_vortex":
					_massive_aoe()
				"tail_sweep":
					_aoe_attack(80, int(damage * 1.3))
				"teleport_slash":
					_teleport_attack()
				_:
					_perform_melee_attack()
		
		special_cooldown = 4.0
		state = BossState.CHASE

func _perform_melee_attack() -> void:
	attack_area.monitoring = true
	attack_shape.disabled = false
	
	# Хитбокс на полсекунды
	await get_tree().create_timer(0.3).timeout
	
	# Проверить попадание
	for body in attack_area.get_overlapping_areas():
		if body.is_in_group("player_hurtbox"):
			var player = body.get_parent()
			if player.has_method("take_damage"):
				player.take_damage(damage, global_position)
	
	attack_area.monitoring = false
	attack_shape.disabled = true

func _aoe_attack(radius: float, dmg: int) -> void:
	# Визуальный эффект AOE
	var aoe_visual = _create_aoe_visual(radius)
	
	# Нанести урон всем игрокам в радиусе
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if global_position.distance_to(player.global_position) <= radius:
			if player.has_method("take_damage"):
				player.take_damage(dmg, global_position)
	
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(aoe_visual):
		aoe_visual.queue_free()

func _breath_attack() -> void:
	# Конус перед боссом
	if target == null:
		return
	var direction = (target.global_position - global_position).normalized()
	
	# Создать несколько снарядов
	for i in range(-2, 3):
		var angle = i * 0.2
		var proj = preload("res://scenes/weapons/EnemyProjectile.tscn").instantiate()
		proj.global_position = global_position
		proj.direction = direction.rotated(angle)
		proj.damage = int(damage * 0.7)
		proj.speed_val = 200.0
		get_parent().add_child(proj)

func _shoot_boss_projectile() -> void:
	if target == null:
		return
	for i in range(3):
		await get_tree().create_timer(0.2).timeout
		if is_dead or target == null:
			return
		var proj = preload("res://scenes/weapons/EnemyProjectile.tscn").instantiate()
		proj.global_position = global_position
		proj.direction = (target.global_position - global_position).normalized()
		proj.damage = damage
		proj.speed_val = 180.0
		get_parent().add_child(proj)

func _massive_aoe() -> void:
	# Экран мигает красным
	EventBus.show_notification.emit("⚠ МОЩНАЯ АТАКА!", Color.RED)
	
	await get_tree().create_timer(1.0).timeout
	if is_dead:
		return
	
	# Урон по всей арене
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if player.has_method("take_damage"):
			player.take_damage(int(damage * 1.5), global_position)
	
	_create_aoe_visual(120)

func _teleport_attack() -> void:
	if target == null:
		return
	
	# Исчезнуть
	modulate = Color(1, 1, 1, 0.2)
	await get_tree().create_timer(0.5).timeout
	if is_dead:
		return
	
	# Телепорт за спину игрока
	global_position = target.global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
	modulate = Color(1, 1, 1, 1)
	
	# Удар
	_aoe_attack(40, int(damage * 1.5))

func _summon_minions(enemy_type: String, count: int) -> void:
	EventBus.show_notification.emit(boss_data.name + " призывает подкрепление!", Color.ORANGE_RED)
	
	for i in range(count):
		var enemy_scene = preload("res://scenes/enemies/Enemy.tscn")
		var enemy = enemy_scene.instantiate()
		enemy.enemy_id = enemy_type
		var offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))
		enemy.global_position = global_position + offset
		get_parent().call_deferred("add_child", enemy)

func _phase_transition_effect() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	tween.tween_property(sprite, "modulate", boss_data.get("color", Color.RED), 0.2)

func _create_aoe_visual(radius: float) -> Node2D:
	var visual = Node2D.new()
	visual.global_position = global_position
	get_parent().add_child(visual)
	visual.set_script(preload("res://scripts/effects/AOEVisual.gd"))
	visual.set("radius", radius)
	return visual

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO, crit: bool = false) -> void:
	if is_dead:
		return
	
	var actual = max(1, amount - defense)
	hp -= actual
	knockback_velocity = knockback * 0.3  # Боссы слабо откидываются
	
	_update_health_bar()
	_show_damage_number(actual, crit)
	_flash_hurt()
	
	if hp <= 0:
		_die()

func _die() -> void:
	is_dead = true
	state = BossState.DEATH
	
	# Дроп
	var gold = boss_data.get("gold_drop", 200)
	GameData.add_gold(gold)
	GameData.add_xp(boss_data.get("xp", 200))
	
	for item_id in boss_data.get("loot", []):
		_drop_item(item_id)
	
	GameData.player_data.bosses_defeated.append(boss_id)
	EventBus.boss_defeated.emit(boss_id)
	EventBus.show_notification.emit("БОСС ПОБЕЖДЁН: " + boss_data.name + "!", Color.GOLD)
	
	# Анимация
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.1, 0.1), 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.0)
	tween.tween_callback(queue_free)

func _drop_item(item_id: String) -> void:
	var drop = preload("res://scenes/items/ItemDrop.tscn").instantiate()
	drop.item_id = item_id
	drop.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	get_parent().call_deferred("add_child", drop)

func get_damage() -> int:
	return damage

func _show_damage_number(amount: int, crit: bool) -> void:
	var dmg_label = Label.new()
	dmg_label.text = str(amount) + ("!!" if crit else "")
	dmg_label.add_theme_font_size_override("font_size", 18 if crit else 14)
	dmg_label.add_theme_color_override("font_color", Color.GOLD if crit else Color.YELLOW)
	dmg_label.position = Vector2(-15, -60)
	dmg_label.z_index = 100
	add_child(dmg_label)
	
	var tween = create_tween()
	tween.tween_property(dmg_label, "position:y", dmg_label.position.y - 40, 0.8)
	tween.parallel().tween_property(dmg_label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(dmg_label.queue_free)

func _flash_hurt() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.05)
	tween.tween_property(sprite, "modulate", boss_data.get("color", Color.RED), 0.15)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

func _update_sprite() -> void:
	if sprite and velocity.x != 0:
		sprite.flip_h = velocity.x < 0

func _on_hit(_area: Area2D) -> void:
	pass
