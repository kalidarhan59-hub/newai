extends CanvasLayer
## Диалоговое окно

@onready var panel: Panel = $Panel
@onready var name_label: Label = $Panel/NameLabel
@onready var text_label: Label = $Panel/TextLabel
@onready var continue_label: Label = $Panel/ContinueLabel

var lines: Array = []
var current_line: int = 0
var is_active: bool = false

func _ready() -> void:
	panel.visible = false
	EventBus.show_dialogue.connect(_start_dialogue)

func _process(_delta: float) -> void:
	if is_active and (Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("attack")):
		_next_line()

func _start_dialogue(npc_name: String, dialogue_lines: Array) -> void:
	lines = dialogue_lines
	current_line = 0
	is_active = true
	panel.visible = true
	name_label.text = npc_name
	_show_current_line()

func _show_current_line() -> void:
	if current_line < lines.size():
		text_label.text = lines[current_line]
		if current_line < lines.size() - 1:
			continue_label.text = "[E] Далее..."
		else:
			continue_label.text = "[E] Закрыть"

func _next_line() -> void:
	current_line += 1
	if current_line >= lines.size():
		_close_dialogue()
	else:
		_show_current_line()

func _close_dialogue() -> void:
	is_active = false
	panel.visible = false
	EventBus.dialogue_ended.emit()
