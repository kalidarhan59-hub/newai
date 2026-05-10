extends CharacterBody2D
## Главный скрипт игрока — движение, атака, получение урона, рывок

@export var base_speed: float = 120.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var attack_timer: Timer = $AttackTimer
@onready var dash_timer: Timer = $DashTimer
@onready var dash_cooldown: Timer = $DashCooldown
@onready var health_bar: ProgressBar = $HealthBar

var is_attacking: bool = false
var is_dashing: bool = false
var can_dash: bool = true
var is_invincible: bool = false
var facing_direction: Vector2 = Vector2.RIGHT
var dash_speed: float = 350.0
var dash_direction: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO

# Буфы
var buffs: Array = []  # [{"type": "strength", "value": 10, "time_left": 30.0}]

func _ready() -> void:
	attack_area.monitoring = false
	attack_shape.disabled = true
	_update_health_bar()
	
	# Подключить сигналы
	invincibility_timer.timeout.connect(_on_invincibility_end)
	attack_timer.timeout.connect(_on_attack_end)
	dash_timer.timeout.connect(_on_dash_end)
	dash_cooldown.timeout.connect(_on_dash_cooldown_end)
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	attack_area.area_entered.connect(_on_attack_hit)
	
	EventBus.player_respawned.connect(_on_respawn)

func _physics_process(delta: float) -> void:
	_update_buffs(delta)
	
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return
	
	# Применить нокбэк
	if knockback_velocity.length() > 5:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 10 * delta)
		move_and_slide()
		return
	else:
		knockback_velocity = Vector2.ZERO
	
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	# Движение
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		facing_direction = input_vector
		_update_sprite_direction()
	
	var speed = GameData.get_player_total_speed()
	var speed_buff = _get_buff_value("speed")
	speed += speed_buff
	
	velocity = input_vector * speed
	move_and_slide()
	
	# Анимации
	if input_vector.length() > 0:
		_play_anim("walk")
	else:
		_play_anim("idle")
	
	# Атака
	if Input.is_action_just_pressed("attack") and not is_attacking:
		_attack()
	
	# Рывок
	if Input.is_action_just_pressed("dash") and can_dash and not is_attacking:
		_dash()
	
	# Взаимодействие
	if Input.is_action_just_pressed("interact"):
		_interact()
	
	# Зелье
	if Input.is_action_just_pressed("use_potion"):
		_use_potion()

func _attack() -> void:
	is_attacking = true
	var weapon_data = GameData.get_weapon_data(GameData.player_data.equipped_weapon)
	
	if weapon_data.is_empty():
		is_attacking = false
		return
	
	# Проверка маны для посохов
	if weapon_data.get("mana_cost", 0) > 0:
		if GameData.player_data.mp < weapon_data.mana_cost:
			EventBus.show_notification.emit("Недостаточно маны!", Color.DODGER_BLUE)
			is_attacking = false
			return
		GameData.player_data.mp -= weapon_data.mana_cost
		EventBus.player_mana_changed.emit(GameData.player_data.mp, GameData.player_data.max_mp)
	
	# Дальнобойное оружие — создать снаряд
	if weapon_data.get("projectile", false):
		_spawn_projectile(weapon_data)
	else:
		# Ближний бой — включить хитбокс
		_position_attack_area(weapon_data.get("range", 40))
		attack_area.monitoring = true
		attack_shape.disabled = false
	
	_play_anim("attack")
	
	var attack_speed = weapon_data.get("speed", 1.0)
	attack_timer.wait_time = 0.4 / attack_speed
	attack_timer.start()

func _spawn_projectile(weapon_data: Dictionary) -> void:
	var projectile = preload("res://scenes/weapons/Projectile.tscn").instantiate()
	projectile.global_position = global_position
	projectile.direction = facing_direction.normalized()
	projectile.damage = GameData.get_player_total_damage() + _get_buff_value("strength")
	projectile.speed_val = 300.0
	projectile.max_range = weapon_data.get("range", 200)
	projectile.element = weapon_data.get("element", "")
	projectile.pierce = weapon_data.get("pierce", false)
	get_parent().add_child(projectile)

func _position_attack_area(attack_range: float) -> void:
	attack_area.position = facing_direction.normalized() * (attack_range * 0.5)
	var shape = attack_shape.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(attack_range, attack_range * 0.6)

func _on_attack_hit(area: Area2D) -> void:
	if area.is_in_group("enemy_hurtbox"):
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			var total_damage = GameData.get_player_total_damage() + _get_buff_value("strength")
			var weapon_data = GameData.get_weapon_data(GameData.player_data.equipped_weapon)
			
			# Крит
			var crit = false
			var crit_chance = weapon_data.get("crit_chance", 0.05)
			if randf() < crit_chance:
				total_damage = int(total_damage * 1.8)
				crit = true
			
			var knockback_dir = (enemy.global_position - global_position).normalized()
			var kb_force = weapon_data.get("knockback", 100)
			
			enemy.take_damage(total_damage, knockback_dir * kb_force, crit)
			GameData.player_data.stats.total_damage_dealt += total_damage
			
			# Лайфстил
			if weapon_data.get("lifesteal", 0) > 0:
				var heal = int(total_damage * weapon_data.lifesteal)
				GameData.player_data.hp = min(GameData.player_data.hp + heal, GameData.player_data.max_hp)
				EventBus.player_health_changed.emit(GameData.player_data.hp, GameData.player_data.max_hp)

func _on_attack_end() -> void:
	is_attacking = false
	attack_area.monitoring = false
	attack_shape.disabled = true

func _dash() -> void:
	if facing_direction.length() == 0:
		return
	is_dashing = true
	can_dash = false
	is_invincible = true
	dash_direction = facing_direction.normalized()
	dash_timer.start()
	# Визуальный эффект
	modulate = Color(1, 1, 1, 0.5)

func _on_dash_end() -> void:
	is_dashing = false
	is_invincible = false
	modulate = Color(1, 1, 1, 1)
	dash_cooldown.start()

func _on_dash_cooldown_end() -> void:
	can_dash = true

func _on_hurtbox_entered(area: Area2D) -> void:
	if is_invincible:
		return
	if area.is_in_group("enemy_attack"):
		var attacker = area.get_parent()
		var damage = 5
		if attacker.has_method("get_damage"):
			damage = attacker.get_damage()
		take_damage(damage, attacker.global_position)

func take_damage(amount: int, source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_invincible:
		return
	
	var defense = GameData.get_player_total_defense() + _get_buff_value("defense")
	var actual_damage = max(1, amount - defense)
	
	# Блок щитом
	var shield_id = GameData.player_data.equipped_shield
	if shield_id != "" and GameData.ARMOR.has(shield_id):
		var block_chance = GameData.ARMOR[shield_id].get("block_chance", 0)
		if randf() < block_chance:
			actual_damage = int(actual_damage * 0.3)
			EventBus.show_notification.emit("Заблокировано!", Color.CYAN)
	
	GameData.player_data.hp -= actual_damage
	_update_health_bar()
	EventBus.player_health_changed.emit(GameData.player_data.hp, GameData.player_data.max_hp)
	
	# Нокбэк
	if source_pos != Vector2.ZERO:
		knockback_velocity = (global_position - source_pos).normalized() * 200
	
	# Неуязвимость
	is_invincible = true
	invincibility_timer.start()
	_flash_damage()
	
	if GameData.player_data.hp <= 0:
		_die()

func _die() -> void:
	GameData.player_data.stats.total_deaths += 1
	EventBus.player_died.emit()

func _on_respawn() -> void:
	GameData.player_data.hp = GameData.player_data.max_hp
	GameData.player_data.mp = GameData.player_data.max_mp
	is_invincible = false
	modulate = Color.WHITE
	_update_health_bar()

func _on_invincibility_end() -> void:
	is_invincible = false
	modulate = Color.WHITE

func _flash_damage() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color(1, 1, 1, 0.5), 0.05)
	tween.tween_property(self, "modulate", Color.RED, 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func _interact() -> void:
	# Ищем интерактивные объекты рядом
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 0b00100000  # Layer 6 = NPCs
	query.collide_with_areas = true
	var results = space.intersect_point(query, 5)
	
	for result in results:
		var collider = result.collider
		if collider.has_method("interact"):
			collider.interact()
			return

func _use_potion() -> void:
	# Использовать первое доступное зелье здоровья
	for potion_id in ["health_potion_large", "health_potion_medium", "health_potion_small"]:
		if GameData.player_data.potions.get(potion_id, 0) > 0:
			if GameData.player_data.hp < GameData.player_data.max_hp:
				GameData.use_potion(potion_id)
				EventBus.show_notification.emit("Использовано: " + GameData.ITEMS[potion_id].name, Color.GREEN)
				_update_health_bar()
				return
	EventBus.show_notification.emit("Нет зелий!", Color.RED)

func _update_health_bar() -> void:
	if health_bar:
		health_bar.max_value = GameData.player_data.max_hp
		health_bar.value = GameData.player_data.hp

func _update_sprite_direction() -> void:
	if facing_direction.x < 0:
		sprite.flip_h = true
	elif facing_direction.x > 0:
		sprite.flip_h = false

func _play_anim(anim_name: String) -> void:
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)

func add_buff(buff_type: String, value: float, duration: float) -> void:
	buffs.append({"type": buff_type, "value": value, "time_left": duration})
	EventBus.show_notification.emit("Буф: +" + str(int(value)) + " " + buff_type, Color.YELLOW)

func _update_buffs(delta: float) -> void:
	var expired = []
	for i in buffs.size():
		buffs[i].time_left -= delta
		if buffs[i].time_left <= 0:
			expired.append(i)
	expired.reverse()
	for i in expired:
		EventBus.show_notification.emit("Буф закончился: " + buffs[i].type, Color.GRAY)
		buffs.remove_at(i)

func _get_buff_value(buff_type: String) -> float:
	var total = 0.0
	for buff in buffs:
		if buff.type == buff_type:
			total += buff.value
	return total
