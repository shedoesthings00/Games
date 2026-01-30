extends Control

@export var auto_restart_time: float = 3.0  # segundos antes de reiniciar (opcional)

func _ready() -> void:
	# Opcional: reiniciar solo tras unos segundos
	if auto_restart_time > 0.0:
		var t := get_tree().create_timer(auto_restart_time)
		t.timeout.connect(_on_restart)

func _input(event: InputEvent) -> void:
	# Permitir reiniciar manualmente (tecla Enter / botón A)
	if event.is_action_pressed("ui_accept"):
		_on_restart()

func _on_restart() -> void:
	LevelManager.start_game()
