extends Control
## Главное меню

@onready var play_button: Button = $VBoxContainer/PlayButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel

func _ready() -> void:
	play_button.pressed.connect(_on_play)
	quit_button.pressed.connect(_on_quit)
	
	# Анимация заголовка
	var tween = create_tween().set_loops()
	tween.tween_property(title_label, "modulate", Color(1.0, 0.85, 0.5), 1.5)
	tween.tween_property(title_label, "modulate", Color.WHITE, 1.5)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/Village.tscn")

func _on_quit() -> void:
	get_tree().quit()
