extends Control

func _ready() -> void:
	# Opcional: tras X segundos, recargar nivel 1 automáticamente
	var t := get_tree().create_timer(2.0)
	t.timeout.connect(_on_restart)

func _input(event: InputEvent) -> void:
	# Si quieres permitir reiniciar con tecla o clic
	if event.is_action_pressed("ui_accept"):
		_on_restart()

func _on_restart() -> void:
	get_tree().change_scene_to_file("res://Escenas/Level_1.tscn")
