extends Node

# Lista de niveles en orden
var levels: Array[String] = [
	"res://Escenas/Level_1.tscn",
	"res://Escenas/Level_2.tscn",
]

var current_index: int = 0

func start_game() -> void:
	current_index = 0
	_load_current_level()

func load_next_level() -> void:
	current_index += 1
	if current_index >= levels.size():
		_on_game_completed()
	else:
		_load_current_level()

func _load_current_level() -> void:
	get_tree().change_scene_to_file(levels[current_index])

func _on_game_completed() -> void:
	print("GAME COMPLETED")
	# Aquí puedes volver al menú, reiniciar, etc.
