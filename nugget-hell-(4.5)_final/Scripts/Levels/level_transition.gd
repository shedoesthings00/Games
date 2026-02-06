extends CanvasLayer

signal transition_finished

@onready var fade_rect: ColorRect = $FadeRect
@onready var level_label: Label = $LevelLabel

@export var hold_time: float = 1.0
@export var fade_out_time: float = 0.5

var _tween: Tween


func _ready() -> void:
	# Empezar invisible
	fade_rect.modulate.a = 0.0
	level_label.modulate.a = 0.0
	visible = false


func show_level(level_name: String) -> void:
	_show_transition(level_name)


func show_no_text() -> void:
	_show_transition("")


func _show_transition(text: String) -> void:
	if _tween and _tween.is_running():
		_tween.kill()

	visible = true
	fade_rect.modulate.a = 1.0

	if text != "":
		level_label.text = text
		level_label.modulate.a = 1.0
	else:
		level_label.text = ""
		level_label.modulate.a = 0.0

	_tween = create_tween()
	_tween.tween_interval(hold_time)
	_tween.tween_property(fade_rect, "modulate:a", 0.0, fade_out_time)
	_tween.tween_property(level_label, "modulate:a", 0.0, fade_out_time)
	_tween.finished.connect(_on_tween_finished)


func _on_tween_finished() -> void:
	visible = false
	transition_finished.emit()
