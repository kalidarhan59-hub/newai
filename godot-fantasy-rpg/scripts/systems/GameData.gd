extends Node
## Глобальное хранилище данных: оружие, броня, враги, НПС, боссы, предметы, квесты

# =====================================================================
# ОРУЖИЕ (20 видов)
# =====================================================================
var WEAPONS: Dictionary = {
	# --- МЕЧИ ---
	"wooden_sword": {
		"name": "Деревянный меч", "type": "sword", "damage": 5, "speed": 1.0,
		"range": 40, "price": 0, "level_req": 1, "rarity": "common",
		"description": "Простой тренировочный меч из дерева.",
		"knockback": 80, "crit_chance": 0.05
	},
	"iron_sword": {
		"name": "Железный меч", "type": "sword", "damage": 12, "speed": 1.0,
		"range": 45, "price": 100, "level_req": 3, "rarity": "common",
		"description": "Прочный меч из железа.",
		"knockback": 100, "crit_chance": 0.08
	},
	"steel_sword": {
		"name": "Стальной меч", "type": "sword", "damage": 22, "speed": 1.0,
		"range": 45, "price": 350, "level_req": 7, "rarity": "uncommon",
		"description": "Отличный меч из закалённой стали.",
		"knockback": 120, "crit_chance": 0.10
	},
	"flame_sword": {
		"name": "Огненный клинок", "type": "sword", "damage": 35, "speed": 0.9,
		"range": 50, "price": 800, "level_req": 12, "rarity": "rare",
		"description": "Меч, пылающий магическим огнём. Наносит дополнительный урон.",
		"knockback": 140, "crit_chance": 0.12, "element": "fire", "bonus_damage": 10
	},
	"shadow_blade": {
		"name": "Клинок Тени", "type": "sword", "damage": 50, "speed": 1.1,
		"range": 50, "price": 2000, "level_req": 18, "rarity": "epic",
		"description": "Тёмный клинок, выкованный в Бездне. Высокий шанс крита.",
		"knockback": 130, "crit_chance": 0.25, "element": "dark"
	},
	"holy_excalibur": {
		"name": "Святой Экскалибур", "type": "sword", "damage": 75, "speed": 0.8,
		"range": 55, "price": 5000, "level_req": 25, "rarity": "legendary",
		"description": "Легендарный меч света. Исцеляет при ударе.",
		"knockback": 200, "crit_chance": 0.15, "element": "holy", "lifesteal": 0.1
	},
	# --- ТОПОРЫ ---
	"rusty_axe": {
		"name": "Ржавый топор", "type": "axe", "damage": 8, "speed": 0.7,
		"range": 35, "price": 50, "level_req": 2, "rarity": "common",
		"description": "Тяжёлый ржавый топор. Медленный, но мощный.",
		"knockback": 150, "crit_chance": 0.10
	},
	"war_axe": {
		"name": "Боевой топор", "type": "axe", "damage": 28, "speed": 0.7,
		"range": 40, "price": 500, "level_req": 8, "rarity": "uncommon",
		"description": "Мощный двуручный топор.",
		"knockback": 200, "crit_chance": 0.12
	},
	"thunder_axe": {
		"name": "Громовой топор", "type": "axe", "damage": 55, "speed": 0.65,
		"range": 45, "price": 2500, "level_req": 20, "rarity": "epic",
		"description": "При ударе вызывает молнию, поражая ближайших врагов.",
		"knockback": 250, "crit_chance": 0.15, "element": "lightning", "aoe": true
	},
	# --- КИНЖАЛЫ ---
	"rusty_dagger": {
		"name": "Ржавый кинжал", "type": "dagger", "damage": 4, "speed": 1.5,
		"range": 25, "price": 30, "level_req": 1, "rarity": "common",
		"description": "Маленький быстрый кинжал.",
		"knockback": 40, "crit_chance": 0.15
	},
	"assassin_blade": {
		"name": "Клинок убийцы", "type": "dagger", "damage": 18, "speed": 1.6,
		"range": 30, "price": 600, "level_req": 10, "rarity": "rare",
		"description": "Невероятно быстрый кинжал. Огромный шанс крита.",
		"knockback": 50, "crit_chance": 0.30
	},
	"venom_fang": {
		"name": "Ядовитый клык", "type": "dagger", "damage": 30, "speed": 1.7,
		"range": 30, "price": 1500, "level_req": 15, "rarity": "epic",
		"description": "Отравляет врагов при ударе.",
		"knockback": 60, "crit_chance": 0.25, "element": "poison", "dot_damage": 5
	},
	# --- ЛУКИ ---
	"short_bow": {
		"name": "Короткий лук", "type": "bow", "damage": 7, "speed": 0.8,
		"range": 200, "price": 80, "level_req": 2, "rarity": "common",
		"description": "Простой лук. Стреляет стрелами на расстоянии.",
		"knockback": 60, "crit_chance": 0.08, "projectile": true
	},
	"hunter_bow": {
		"name": "Лук охотника", "type": "bow", "damage": 20, "speed": 0.9,
		"range": 250, "price": 400, "level_req": 8, "rarity": "uncommon",
		"description": "Дальнобойный лук опытного охотника.",
		"knockback": 80, "crit_chance": 0.12, "projectile": true
	},
	"elven_bow": {
		"name": "Эльфийский лук", "type": "bow", "damage": 40, "speed": 1.1,
		"range": 300, "price": 1800, "level_req": 16, "rarity": "rare",
		"description": "Изящный лук эльфов. Быстрый и точный.",
		"knockback": 100, "crit_chance": 0.18, "projectile": true, "multi_shot": 2
	},
	# --- ПОСОХИ ---
	"apprentice_staff": {
		"name": "Посох ученика", "type": "staff", "damage": 10, "speed": 0.6,
		"range": 180, "price": 120, "level_req": 3, "rarity": "common",
		"description": "Простой магический посох. Стреляет магическими снарядами.",
		"knockback": 70, "crit_chance": 0.05, "projectile": true, "mana_cost": 5
	},
	"fire_staff": {
		"name": "Посох огня", "type": "staff", "damage": 30, "speed": 0.5,
		"range": 200, "price": 900, "level_req": 11, "rarity": "rare",
		"description": "Стреляет огненными шарами. Поджигает врагов.",
		"knockback": 90, "crit_chance": 0.10, "projectile": true, "mana_cost": 12,
		"element": "fire"
	},
	"ice_staff": {
		"name": "Посох льда", "type": "staff", "damage": 25, "speed": 0.55,
		"range": 200, "price": 900, "level_req": 11, "rarity": "rare",
		"description": "Замораживает врагов, замедляя их.",
		"knockback": 80, "crit_chance": 0.08, "projectile": true, "mana_cost": 10,
		"element": "ice", "slow_effect": 0.5
	},
	"archmage_staff": {
		"name": "Посох Архимага", "type": "staff", "damage": 60, "speed": 0.7,
		"range": 250, "price": 4000, "level_req": 22, "rarity": "legendary",
		"description": "Древний посох невероятной силы. Пронзает нескольких врагов.",
		"knockback": 120, "crit_chance": 0.15, "projectile": true, "mana_cost": 20,
		"element": "arcane", "pierce": true
	},
	# --- МОЛОТЫ ---
	"stone_hammer": {
		"name": "Каменный молот", "type": "hammer", "damage": 15, "speed": 0.5,
		"range": 35, "price": 200, "level_req": 5, "rarity": "common",
		"description": "Огромный молот. Очень медленный, но оглушает врагов.",
		"knockback": 300, "crit_chance": 0.08, "stun_chance": 0.3
	},
	"dragon_hammer": {
		"name": "Молот Дракона", "type": "hammer", "damage": 65, "speed": 0.45,
		"range": 45, "price": 3500, "level_req": 22, "rarity": "epic",
		"description": "Молот из кости дракона. Удар по земле наносит AOE урон.",
		"knockback": 350, "crit_chance": 0.12, "stun_chance": 0.5, "aoe": true,
		"element": "fire"
	},
}

# =====================================================================
# БРОНЯ (15 видов)
# =====================================================================
var ARMOR: Dictionary = {
	# --- ШЛЕМЫ ---
	"leather_cap": {
		"name": "Кожаная шапка", "type": "helmet", "defense": 2, "price": 40,
		"level_req": 1, "rarity": "common", "description": "Простая кожаная защита."
	},
	"iron_helm": {
		"name": "Железный шлем", "type": "helmet", "defense": 6, "price": 200,
		"level_req": 5, "rarity": "uncommon", "description": "Крепкий железный шлем."
	},
	"royal_crown": {
		"name": "Королевская корона", "type": "helmet", "defense": 12, "price": 1500,
		"level_req": 15, "rarity": "rare", "description": "Корона с магической защитой.",
		"bonus_mana": 30
	},
	"dragon_helm": {
		"name": "Шлем Дракона", "type": "helmet", "defense": 20, "price": 4000,
		"level_req": 22, "rarity": "epic", "description": "Шлем из чешуи дракона.",
		"fire_resist": 0.3
	},
	# --- НАГРУДНИКИ ---
	"cloth_tunic": {
		"name": "Тканевая туника", "type": "chest", "defense": 3, "price": 50,
		"level_req": 1, "rarity": "common", "description": "Обычная одежда."
	},
	"leather_armor": {
		"name": "Кожаная броня", "type": "chest", "defense": 8, "price": 250,
		"level_req": 4, "rarity": "common", "description": "Лёгкая кожаная броня."
	},
	"chainmail": {
		"name": "Кольчуга", "type": "chest", "defense": 15, "price": 600,
		"level_req": 8, "rarity": "uncommon", "description": "Прочная кольчужная рубаха."
	},
	"plate_armor": {
		"name": "Латные доспехи", "type": "chest", "defense": 25, "price": 1500,
		"level_req": 14, "rarity": "rare", "description": "Тяжёлые но очень прочные.",
		"speed_penalty": -15
	},
	"shadow_robe": {
		"name": "Мантия тени", "type": "chest", "defense": 18, "price": 2000,
		"level_req": 16, "rarity": "rare", "description": "Мантия из ткани тени. Бонус к крит. урону.",
		"bonus_crit": 0.1
	},
	"mythril_plate": {
		"name": "Мифриловый доспех", "type": "chest", "defense": 35, "price": 5000,
		"level_req": 22, "rarity": "epic", "description": "Лёгкий и невероятно прочный.",
		"bonus_hp": 50
	},
	# --- ЩИТЫ ---
	"wooden_shield": {
		"name": "Деревянный щит", "type": "shield", "defense": 4, "price": 60,
		"level_req": 2, "rarity": "common", "description": "Блокирует часть урона.",
		"block_chance": 0.15
	},
	"iron_shield": {
		"name": "Железный щит", "type": "shield", "defense": 10, "price": 400,
		"level_req": 6, "rarity": "uncommon", "description": "Крепкий щит.",
		"block_chance": 0.20
	},
	"tower_shield": {
		"name": "Башенный щит", "type": "shield", "defense": 20, "price": 1200,
		"level_req": 13, "rarity": "rare", "description": "Огромный щит. Отличная защита.",
		"block_chance": 0.30, "speed_penalty": -10
	},
	"aegis_shield": {
		"name": "Щит Эгида", "type": "shield", "defense": 30, "price": 4500,
		"level_req": 23, "rarity": "legendary", "description": "Легендарный щит. Отражает магию.",
		"block_chance": 0.35, "magic_reflect": 0.2
	},
	# --- БОТИНКИ ---
	"leather_boots": {
		"name": "Кожаные сапоги", "type": "boots", "defense": 1, "price": 30,
		"level_req": 1, "rarity": "common", "description": "Обычные сапоги.",
		"speed_bonus": 5
	},
	"swift_boots": {
		"name": "Быстрые сапоги", "type": "boots", "defense": 3, "price": 300,
		"level_req": 6, "rarity": "uncommon", "description": "Магические сапоги скорости.",
		"speed_bonus": 25
	},
	"winged_boots": {
		"name": "Крылатые сапоги", "type": "boots", "defense": 8, "price": 1800,
		"level_req": 17, "rarity": "epic", "description": "Позволяют двойной прыжок/рывок.",
		"speed_bonus": 35, "double_dash": true
	},
}

# =====================================================================
# ПРЕДМЕТЫ (зелья, свитки и т.д.)
# =====================================================================
var ITEMS: Dictionary = {
	"health_potion_small": {
		"name": "Малое зелье здоровья", "type": "consumable", "subtype": "heal",
		"value": 30, "price": 25, "description": "Восстанавливает 30 HP."
	},
	"health_potion_medium": {
		"name": "Среднее зелье здоровья", "type": "consumable", "subtype": "heal",
		"value": 75, "price": 75, "description": "Восстанавливает 75 HP."
	},
	"health_potion_large": {
		"name": "Большое зелье здоровья", "type": "consumable", "subtype": "heal",
		"value": 200, "price": 200, "description": "Восстанавливает 200 HP."
	},
	"mana_potion_small": {
		"name": "Малое зелье маны", "type": "consumable", "subtype": "mana",
		"value": 20, "price": 30, "description": "Восстанавливает 20 MP."
	},
	"mana_potion_medium": {
		"name": "Среднее зелье маны", "type": "consumable", "subtype": "mana",
		"value": 50, "price": 80, "description": "Восстанавливает 50 MP."
	},
	"strength_elixir": {
		"name": "Эликсир силы", "type": "consumable", "subtype": "buff",
		"value": 10, "duration": 30.0, "price": 150,
		"description": "Увеличивает урон на 10 на 30 секунд."
	},
	"defense_elixir": {
		"name": "Эликсир защиты", "type": "consumable", "subtype": "buff",
		"value": 10, "duration": 30.0, "price": 150,
		"description": "Увеличивает защиту на 10 на 30 секунд."
	},
	"speed_elixir": {
		"name": "Эликсир скорости", "type": "consumable", "subtype": "buff",
		"value": 30, "duration": 20.0, "price": 120,
		"description": "Увеличивает скорость на 30% на 20 секунд."
	},
	"scroll_fireball": {
		"name": "Свиток: Огненный шар", "type": "consumable", "subtype": "scroll",
		"value": 80, "price": 200, "description": "Наносит 80 огненного урона всем рядом."
	},
	"scroll_teleport": {
		"name": "Свиток: Телепорт", "type": "consumable", "subtype": "scroll",
		"value": 0, "price": 500, "description": "Телепортирует к началу уровня."
	},
	"key_forest": {
		"name": "Ключ от леса", "type": "key", "subtype": "key",
		"value": 0, "price": 0, "description": "Открывает ворота в Тёмный Лес."
	},
	"key_cave": {
		"name": "Ключ от пещеры", "type": "key", "subtype": "key",
		"value": 0, "price": 0, "description": "Открывает вход в Ледяную Пещеру."
	},
	"key_castle": {
		"name": "Ключ от замка", "type": "key", "subtype": "key",
		"value": 0, "price": 0, "description": "Открывает ворота Тёмного Замка."
	},
	"key_volcano": {
		"name": "Ключ от вулкана", "type": "key", "subtype": "key",
		"value": 0, "price": 0, "description": "Открывает проход к Вулкану."
	},
	"boss_trophy_1": {
		"name": "Трофей: Рог Лесного Стража", "type": "trophy", "subtype": "trophy",
		"value": 500, "price": 0, "description": "Рог побеждённого Лесного Стража."
	},
	"boss_trophy_2": {
		"name": "Трофей: Сердце Ледяного Голема", "type": "trophy", "subtype": "trophy",
		"value": 1000, "price": 0, "description": "Магическое сердце Ледяного Голема."
	},
	"boss_trophy_3": {
		"name": "Трофей: Корона Некроманта", "type": "trophy", "subtype": "trophy",
		"value": 2000, "price": 0, "description": "Тёмная корона побеждённого Некроманта."
	},
	"boss_trophy_4": {
		"name": "Трофей: Чешуя Дракона", "type": "trophy", "subtype": "trophy",
		"value": 5000, "price": 0, "description": "Чешуя Великого Дракона Игниса."
	},
}

# =====================================================================
# ВРАГИ / МОБЫ (18 видов)
# =====================================================================
var ENEMIES: Dictionary = {
	# --- ЛЕС (Уровень 1-5) ---
	"slime_green": {
		"name": "Зелёный слайм", "hp": 20, "damage": 3, "defense": 0,
		"speed": 40, "xp": 10, "gold_drop": [2, 8],
		"level": 1, "color": Color.GREEN_YELLOW,
		"loot": [["health_potion_small", 0.3]],
		"behavior": "wander", "aggro_range": 80
	},
	"slime_red": {
		"name": "Красный слайм", "hp": 35, "damage": 6, "defense": 1,
		"speed": 45, "xp": 18, "gold_drop": [5, 15],
		"level": 3, "color": Color.RED,
		"loot": [["health_potion_small", 0.4]],
		"behavior": "wander", "aggro_range": 100
	},
	"goblin": {
		"name": "Гоблин", "hp": 30, "damage": 7, "defense": 2,
		"speed": 60, "xp": 20, "gold_drop": [8, 20],
		"level": 2, "color": Color.DARK_GREEN,
		"loot": [["rusty_dagger", 0.1], ["health_potion_small", 0.2]],
		"behavior": "chase", "aggro_range": 120
	},
	"goblin_archer": {
		"name": "Гоблин-лучник", "hp": 25, "damage": 10, "defense": 1,
		"speed": 50, "xp": 25, "gold_drop": [10, 25],
		"level": 3, "color": Color.DARK_GREEN,
		"loot": [["short_bow", 0.08]],
		"behavior": "ranged", "aggro_range": 180, "attack_range": 150
	},
	"wolf": {
		"name": "Дикий волк", "hp": 40, "damage": 9, "defense": 2,
		"speed": 80, "xp": 25, "gold_drop": [5, 15],
		"level": 4, "color": Color.GRAY,
		"loot": [],
		"behavior": "chase", "aggro_range": 150
	},
	"treant": {
		"name": "Трент", "hp": 80, "damage": 12, "defense": 8,
		"speed": 25, "xp": 40, "gold_drop": [15, 30],
		"level": 5, "color": Color.DARK_OLIVE_GREEN,
		"loot": [["health_potion_medium", 0.3]],
		"behavior": "guard", "aggro_range": 60
	},
	# --- ПЕЩЕРА (Уровень 6-12) ---
	"bat": {
		"name": "Пещерная летучая мышь", "hp": 15, "damage": 5, "defense": 0,
		"speed": 90, "xp": 15, "gold_drop": [3, 10],
		"level": 6, "color": Color.DIM_GRAY,
		"loot": [],
		"behavior": "fly", "aggro_range": 130
	},
	"skeleton": {
		"name": "Скелет", "hp": 50, "damage": 14, "defense": 5,
		"speed": 55, "xp": 35, "gold_drop": [15, 35],
		"level": 7, "color": Color.ANTIQUE_WHITE,
		"loot": [["iron_sword", 0.05], ["iron_shield", 0.05]],
		"behavior": "chase", "aggro_range": 120
	},
	"skeleton_mage": {
		"name": "Скелет-маг", "hp": 40, "damage": 20, "defense": 3,
		"speed": 40, "xp": 45, "gold_drop": [20, 45],
		"level": 9, "color": Color.SLATE_BLUE,
		"loot": [["mana_potion_small", 0.3], ["apprentice_staff", 0.05]],
		"behavior": "ranged", "aggro_range": 160, "attack_range": 140
	},
	"spider": {
		"name": "Гигантский паук", "hp": 60, "damage": 16, "defense": 4,
		"speed": 70, "xp": 40, "gold_drop": [12, 30],
		"level": 8, "color": Color.DARK_RED,
		"loot": [["venom_fang", 0.03]],
		"behavior": "chase", "aggro_range": 100, "poison": true
	},
	"golem_stone": {
		"name": "Каменный голем", "hp": 120, "damage": 20, "defense": 15,
		"speed": 30, "xp": 60, "gold_drop": [25, 50],
		"level": 10, "color": Color.DARK_GRAY,
		"loot": [["stone_hammer", 0.08]],
		"behavior": "guard", "aggro_range": 80
	},
	# --- ЗАМОК (Уровень 13-19) ---
	"dark_knight": {
		"name": "Тёмный рыцарь", "hp": 100, "damage": 25, "defense": 15,
		"speed": 55, "xp": 70, "gold_drop": [30, 60],
		"level": 13, "color": Color.DARK_SLATE_GRAY,
		"loot": [["steel_sword", 0.1], ["chainmail", 0.05]],
		"behavior": "chase", "aggro_range": 130
	},
	"dark_mage": {
		"name": "Тёмный маг", "hp": 70, "damage": 35, "defense": 8,
		"speed": 45, "xp": 80, "gold_drop": [35, 70],
		"level": 15, "color": Color.DARK_VIOLET,
		"loot": [["fire_staff", 0.05], ["mana_potion_medium", 0.3]],
		"behavior": "ranged", "aggro_range": 180, "attack_range": 160
	},
	"gargoyle": {
		"name": "Горгулья", "hp": 90, "damage": 22, "defense": 18,
		"speed": 65, "xp": 75, "gold_drop": [25, 55],
		"level": 14, "color": Color.GRAY,
		"loot": [],
		"behavior": "fly", "aggro_range": 150
	},
	"vampire": {
		"name": "Вампир", "hp": 80, "damage": 30, "defense": 10,
		"speed": 70, "xp": 90, "gold_drop": [40, 80],
		"level": 16, "color": Color.DARK_RED,
		"loot": [["shadow_blade", 0.02], ["health_potion_large", 0.2]],
		"behavior": "chase", "aggro_range": 140, "lifesteal": 0.2
	},
	# --- ВУЛКАН (Уровень 20-25) ---
	"fire_elemental": {
		"name": "Огненный элементаль", "hp": 130, "damage": 35, "defense": 12,
		"speed": 60, "xp": 100, "gold_drop": [50, 100],
		"level": 20, "color": Color.ORANGE_RED,
		"loot": [["flame_sword", 0.05]],
		"behavior": "chase", "aggro_range": 130, "element": "fire"
	},
	"demon": {
		"name": "Демон", "hp": 160, "damage": 40, "defense": 18,
		"speed": 55, "xp": 120, "gold_drop": [60, 120],
		"level": 22, "color": Color.CRIMSON,
		"loot": [["strength_elixir", 0.2], ["dragon_hammer", 0.02]],
		"behavior": "chase", "aggro_range": 160
	},
	"orc_warlord": {
		"name": "Орк-военачальник", "hp": 200, "damage": 45, "defense": 20,
		"speed": 50, "xp": 150, "gold_drop": [70, 140],
		"level": 23, "color": Color.DARK_GREEN,
		"loot": [["war_axe", 0.1], ["plate_armor", 0.05]],
		"behavior": "chase", "aggro_range": 120
	},
}

# =====================================================================
# БОССЫ (5 штук)
# =====================================================================
var BOSSES: Dictionary = {
	"forest_guardian": {
		"name": "Лесной Страж", "hp": 300, "damage": 18, "defense": 10,
		"speed": 40, "xp": 200, "gold_drop": 200,
		"level": 5, "color": Color.FOREST_GREEN, "size": 2.5,
		"loot": ["key_cave", "boss_trophy_1"],
		"reward_weapon": "iron_sword",
		"phases": [
			{"hp_percent": 1.0, "attack": "stomp", "speed": 40},
			{"hp_percent": 0.5, "attack": "vine_whip", "speed": 55, "summon": "treant"},
		],
		"description": "Древний страж леса. Защищает путь к пещере."
	},
	"ice_golem": {
		"name": "Ледяной Голем", "hp": 600, "damage": 30, "defense": 25,
		"speed": 30, "xp": 500, "gold_drop": 500,
		"level": 12, "color": Color.LIGHT_BLUE, "size": 3.0,
		"loot": ["key_castle", "boss_trophy_2"],
		"reward_weapon": "ice_staff",
		"phases": [
			{"hp_percent": 1.0, "attack": "ice_slam", "speed": 30},
			{"hp_percent": 0.6, "attack": "frost_breath", "speed": 35, "freeze": true},
			{"hp_percent": 0.3, "attack": "ice_storm", "speed": 25, "aoe": true},
		],
		"description": "Ледяной гигант. Замораживает всё вокруг."
	},
	"necromancer": {
		"name": "Некромант", "hp": 500, "damage": 40, "defense": 15,
		"speed": 50, "xp": 800, "gold_drop": 1000,
		"level": 19, "color": Color.DARK_ORCHID, "size": 2.0,
		"loot": ["key_volcano", "boss_trophy_3"],
		"reward_weapon": "shadow_blade",
		"phases": [
			{"hp_percent": 1.0, "attack": "dark_bolt", "speed": 50, "ranged": true},
			{"hp_percent": 0.7, "attack": "summon_undead", "summon": "skeleton", "count": 3},
			{"hp_percent": 0.3, "attack": "death_wave", "aoe": true, "speed": 60},
		],
		"description": "Тёмный маг, повелитель нежити."
	},
	"dragon_ignis": {
		"name": "Великий Дракон Игнис", "hp": 1000, "damage": 55, "defense": 30,
		"speed": 45, "xp": 1500, "gold_drop": 2000,
		"level": 25, "color": Color.RED, "size": 4.0,
		"loot": ["boss_trophy_4", "holy_excalibur"],
		"phases": [
			{"hp_percent": 1.0, "attack": "fire_breath", "speed": 45},
			{"hp_percent": 0.7, "attack": "tail_sweep", "speed": 50, "aoe": true},
			{"hp_percent": 0.4, "attack": "meteor_rain", "speed": 40, "aoe": true},
			{"hp_percent": 0.15, "attack": "inferno", "speed": 55, "enrage": true},
		],
		"description": "Финальный босс. Древний дракон огня."
	},
	"dark_lord": {
		"name": "Тёмный Властелин", "hp": 800, "damage": 50, "defense": 25,
		"speed": 55, "xp": 2000, "gold_drop": 3000,
		"level": 25, "color": Color.BLACK, "size": 2.5,
		"loot": ["archmage_staff"],
		"phases": [
			{"hp_percent": 1.0, "attack": "shadow_strike", "speed": 55},
			{"hp_percent": 0.6, "attack": "teleport_slash", "speed": 70},
			{"hp_percent": 0.3, "attack": "dark_vortex", "aoe": true, "summon": "demon"},
		],
		"description": "Секретный босс. Появляется после победы над Драконом."
	},
}

# =====================================================================
# НПС
# =====================================================================
var NPCS: Dictionary = {
	"elder": {
		"name": "Старейшина Ирвин",
		"role": "quest_giver",
		"location": "village",
		"color": Color.WHEAT,
		"dialogues": {
			"intro": [
				"Приветствую, путник! Наша деревня в опасности.",
				"Монстры из Тёмного Леса нападают каждую ночь.",
				"Прошу тебя, герой — победи Лесного Стража и спаси нас!",
			],
			"quest_active": ["Будь осторожен в лесу, герой. Лесной Страж очень силён."],
			"quest_complete": [
				"Ты победил Стража! Деревня спасена!",
				"Возьми этот ключ — он откроет путь к Ледяной Пещере.",
				"Говорят, там скрыто древнее зло...",
			],
		},
		"quests": ["quest_forest_guardian"],
	},
	"blacksmith": {
		"name": "Кузнец Торин",
		"role": "shop",
		"location": "village",
		"color": Color.SADDLE_BROWN,
		"dialogues": {
			"intro": ["Добро пожаловать в мою кузницу! Лучшее оружие и броня в округе."],
			"no_gold": ["У тебя не хватает золота, приходи позже."],
		},
		"shop_items": [
			"iron_sword", "steel_sword", "war_axe", "stone_hammer",
			"iron_helm", "leather_armor", "chainmail", "iron_shield",
			"leather_boots", "swift_boots",
		],
	},
	"alchemist": {
		"name": "Алхимик Мира",
		"role": "shop",
		"location": "village",
		"color": Color.MEDIUM_PURPLE,
		"dialogues": {
			"intro": ["Зелья, эликсиры, свитки! Всё для отважных героев!"],
			"no_gold": ["Я не раздаю бесплатно... Принеси золото!"],
		},
		"shop_items": [
			"health_potion_small", "health_potion_medium", "health_potion_large",
			"mana_potion_small", "mana_potion_medium",
			"strength_elixir", "defense_elixir", "speed_elixir",
			"scroll_fireball", "scroll_teleport",
		],
	},
	"wizard": {
		"name": "Маг Зефирон",
		"role": "shop",
		"location": "village",
		"color": Color.DODGER_BLUE,
		"dialogues": {
			"intro": ["Магические посохи и артефакты... Только для достойных!"],
		},
		"shop_items": [
			"apprentice_staff", "fire_staff", "ice_staff",
			"flame_sword", "elven_bow",
			"royal_crown", "shadow_robe",
		],
	},
	"warrior_trainer": {
		"name": "Воин Гарет",
		"role": "quest_giver",
		"location": "village",
		"color": Color.DARK_RED,
		"dialogues": {
			"intro": [
				"Хочешь стать сильнее? Я могу дать тебе задание.",
				"Убей 10 гоблинов в лесу и я дам тебе награду.",
			],
			"quest_active": ["Сколько гоблинов ты убил? Продолжай, воин!"],
			"quest_complete": [
				"Отличная работа! Ты настоящий воин.",
				"Держи эту броню, она тебе пригодится.",
			],
		},
		"quests": ["quest_goblin_hunt"],
	},
	"mysterious_stranger": {
		"name": "Таинственный незнакомец",
		"role": "quest_giver",
		"location": "cave",
		"color": Color.DARK_SLATE_GRAY,
		"dialogues": {
			"intro": [
				"Тсс... Я знаю тайну этих подземелий.",
				"В самом конце пещеры живёт Ледяной Голем.",
				"Победи его — и получишь доступ к Тёмному Замку.",
			],
		},
		"quests": ["quest_ice_golem"],
	},
}

# =====================================================================
# КВЕСТЫ
# =====================================================================
var QUESTS: Dictionary = {
	"quest_forest_guardian": {
		"name": "Спаси деревню",
		"description": "Победи Лесного Стража в Тёмном Лесу.",
		"type": "boss",
		"target": "forest_guardian",
		"target_count": 1,
		"rewards": {"xp": 200, "gold": 100, "items": ["key_cave"]},
		"npc": "elder",
	},
	"quest_goblin_hunt": {
		"name": "Охота на гоблинов",
		"description": "Убей 10 гоблинов.",
		"type": "kill",
		"target": "goblin",
		"target_count": 10,
		"rewards": {"xp": 150, "gold": 80, "items": ["leather_armor"]},
		"npc": "warrior_trainer",
	},
	"quest_ice_golem": {
		"name": "Ледяная угроза",
		"description": "Победи Ледяного Голема в пещере.",
		"type": "boss",
		"target": "ice_golem",
		"target_count": 1,
		"rewards": {"xp": 500, "gold": 300, "items": ["key_castle"]},
		"npc": "mysterious_stranger",
	},
	"quest_necromancer": {
		"name": "Тьма в замке",
		"description": "Победи Некроманта в Тёмном Замке.",
		"type": "boss",
		"target": "necromancer",
		"target_count": 1,
		"rewards": {"xp": 800, "gold": 500, "items": ["key_volcano"]},
		"npc": "elder",
	},
	"quest_dragon": {
		"name": "Пламя Дракона",
		"description": "Сразись с Великим Драконом Игнисом.",
		"type": "boss",
		"target": "dragon_ignis",
		"target_count": 1,
		"rewards": {"xp": 2000, "gold": 2000, "items": ["holy_excalibur"]},
		"npc": "elder",
	},
	"quest_skeleton_clear": {
		"name": "Зачистка пещеры",
		"description": "Убей 15 скелетов в пещере.",
		"type": "kill",
		"target": "skeleton",
		"target_count": 15,
		"rewards": {"xp": 300, "gold": 200, "items": ["war_axe"]},
		"npc": "mysterious_stranger",
	},
	"quest_spider_venom": {
		"name": "Ядовитые пауки",
		"description": "Убей 8 гигантских пауков.",
		"type": "kill",
		"target": "spider",
		"target_count": 8,
		"rewards": {"xp": 250, "gold": 150, "items": ["venom_fang"]},
		"npc": "alchemist",
	},
}

# =====================================================================
# ЛОКАЦИИ
# =====================================================================
var LEVELS: Dictionary = {
	"village": {
		"name": "Деревня Надежды",
		"description": "Мирная стартовая деревня с НПС.",
		"enemy_types": [],
		"recommended_level": 1,
		"music": "village_theme",
		"bg_color": Color(0.3, 0.5, 0.2),
	},
	"forest": {
		"name": "Тёмный Лес",
		"description": "Опасный лес, полный гоблинов и волков.",
		"enemy_types": ["slime_green", "slime_red", "goblin", "goblin_archer", "wolf", "treant"],
		"boss": "forest_guardian",
		"recommended_level": 3,
		"required_key": null,
		"music": "forest_theme",
		"bg_color": Color(0.1, 0.3, 0.1),
	},
	"cave": {
		"name": "Ледяная Пещера",
		"description": "Мрачная пещера с нежитью и пауками.",
		"enemy_types": ["bat", "skeleton", "skeleton_mage", "spider", "golem_stone"],
		"boss": "ice_golem",
		"recommended_level": 8,
		"required_key": "key_cave",
		"music": "cave_theme",
		"bg_color": Color(0.15, 0.15, 0.25),
	},
	"castle": {
		"name": "Тёмный Замок",
		"description": "Замок, захваченный нежитью и тьмой.",
		"enemy_types": ["dark_knight", "dark_mage", "gargoyle", "vampire"],
		"boss": "necromancer",
		"recommended_level": 15,
		"required_key": "key_castle",
		"music": "castle_theme",
		"bg_color": Color(0.1, 0.05, 0.15),
	},
	"volcano": {
		"name": "Вулкан Игниса",
		"description": "Огненный вулкан. Логово Великого Дракона.",
		"enemy_types": ["fire_elemental", "demon", "orc_warlord"],
		"boss": "dragon_ignis",
		"recommended_level": 22,
		"required_key": "key_volcano",
		"music": "volcano_theme",
		"bg_color": Color(0.4, 0.1, 0.05),
	},
}

# =====================================================================
# ТАБЛИЦА УРОВНЕЙ ИГРОКА (XP для каждого уровня)
# =====================================================================
var LEVEL_TABLE: Array = [
	0, 50, 120, 220, 350, 520, 740, 1000, 1320, 1700,        # 1-10
	2150, 2680, 3300, 4020, 4860, 5830, 6950, 8240, 9720, 11400,  # 11-20
	13300, 15500, 18000, 21000, 25000,                              # 21-25
]

# =====================================================================
# СОСТОЯНИЕ ИГРОКА (сохраняется при переходе между уровнями)
# =====================================================================
var player_data: Dictionary = {
	"name": "Герой",
	"level": 1,
	"xp": 0,
	"hp": 100,
	"max_hp": 100,
	"mp": 30,
	"max_mp": 30,
	"gold": 50,
	"base_damage": 2,
	"base_defense": 0,
	"base_speed": 120,
	"equipped_weapon": "wooden_sword",
	"equipped_helmet": "",
	"equipped_chest": "cloth_tunic",
	"equipped_shield": "",
	"equipped_boots": "leather_boots",
	"inventory": [],     # массив {"id": ..., "count": ...}
	"potions": {"health_potion_small": 3},
	"keys": [],
	"completed_quests": [],
	"active_quests": [],
	"kill_counts": {},   # {"goblin": 5, "skeleton": 3, ...}
	"bosses_defeated": [],
	"current_level": "village",
	"stats": {
		"total_kills": 0,
		"total_deaths": 0,
		"total_gold_earned": 0,
		"total_damage_dealt": 0,
		"playtime": 0.0,
	},
}

# =====================================================================
# ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =====================================================================

func get_player_total_damage() -> int:
	var base = player_data.base_damage
	var weapon_id = player_data.equipped_weapon
	if weapon_id != "" and WEAPONS.has(weapon_id):
		base += WEAPONS[weapon_id].damage
	return base

func get_player_total_defense() -> int:
	var base = player_data.base_defense
	for slot in ["equipped_helmet", "equipped_chest", "equipped_shield", "equipped_boots"]:
		var item_id = player_data[slot]
		if item_id != "" and ARMOR.has(item_id):
			base += ARMOR[item_id].defense
	return base

func get_player_total_speed() -> float:
	var base = float(player_data.base_speed)
	for slot in ["equipped_helmet", "equipped_chest", "equipped_shield", "equipped_boots"]:
		var item_id = player_data[slot]
		if item_id != "" and ARMOR.has(item_id):
			base += ARMOR[item_id].get("speed_bonus", 0)
			base += ARMOR[item_id].get("speed_penalty", 0)
	return base

func add_xp(amount: int) -> void:
	player_data.xp += amount
	EventBus.player_xp_gained.emit(amount)
	while player_data.level < LEVEL_TABLE.size() and player_data.xp >= LEVEL_TABLE[player_data.level]:
		_level_up()

func _level_up() -> void:
	player_data.level += 1
	player_data.max_hp += 15
	player_data.hp = player_data.max_hp
	player_data.max_mp += 5
	player_data.mp = player_data.max_mp
	player_data.base_damage += 2
	player_data.base_defense += 1
	EventBus.player_level_up.emit(player_data.level)
	EventBus.show_notification.emit("Уровень %d!" % player_data.level, Color.GOLD)

func add_gold(amount: int) -> void:
	player_data.gold += amount
	player_data.stats.total_gold_earned += amount
	EventBus.gold_changed.emit(player_data.gold)

func add_kill(enemy_id: String) -> void:
	if not player_data.kill_counts.has(enemy_id):
		player_data.kill_counts[enemy_id] = 0
	player_data.kill_counts[enemy_id] += 1
	player_data.stats.total_kills += 1

func has_key(key_id: String) -> bool:
	return key_id in player_data.keys

func add_potion(potion_id: String, count: int = 1) -> void:
	if not player_data.potions.has(potion_id):
		player_data.potions[potion_id] = 0
	player_data.potions[potion_id] += count

func use_potion(potion_id: String) -> bool:
	if not player_data.potions.has(potion_id) or player_data.potions[potion_id] <= 0:
		return false
	player_data.potions[potion_id] -= 1
	var item = ITEMS[potion_id]
	match item.subtype:
		"heal":
			player_data.hp = min(player_data.hp + item.value, player_data.max_hp)
			EventBus.player_health_changed.emit(player_data.hp, player_data.max_hp)
		"mana":
			player_data.mp = min(player_data.mp + item.value, player_data.max_mp)
			EventBus.player_mana_changed.emit(player_data.mp, player_data.max_mp)
	return true

func get_weapon_data(weapon_id: String) -> Dictionary:
	if WEAPONS.has(weapon_id):
		return WEAPONS[weapon_id]
	return {}

func get_armor_data(armor_id: String) -> Dictionary:
	if ARMOR.has(armor_id):
		return ARMOR[armor_id]
	return {}

func equip_weapon(weapon_id: String) -> void:
	player_data.equipped_weapon = weapon_id
	EventBus.item_equipped.emit(WEAPONS[weapon_id], "weapon")

func equip_armor(armor_id: String) -> void:
	var data = ARMOR[armor_id]
	match data.type:
		"helmet":
			player_data.equipped_helmet = armor_id
		"chest":
			player_data.equipped_chest = armor_id
		"shield":
			player_data.equipped_shield = armor_id
		"boots":
			player_data.equipped_boots = armor_id
	EventBus.item_equipped.emit(data, data.type)

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color.WHITE
		"uncommon": return Color.GREEN
		"rare": return Color.DODGER_BLUE
		"epic": return Color.DARK_ORCHID
		"legendary": return Color.GOLD
		_: return Color.WHITE
