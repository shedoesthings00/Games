extends Node

# Solo niveles jugables
var levels: Array[String] = [
	"res://Escenas/Level_1.tscn",
	"res://Escenas/Level_2.tscn",
]

var current_index: int = 0
const WIN_SCREEN_PATH := "res://Escenas/WinScreen.tscn"


func start_game() -> void:
	current_index = 0
	_load_current_level()


func load_next_level() -> void:
	current_index += 1
	if current_index >= levels.size():
		# No hay más niveles, mostrar pantalla de victoria
		_load_win_screen()
	else:
		_load_current_level()


func _load_current_level() -> void:
	get_tree().change_scene_to_file(levels[current_index])


func _load_win_screen() -> void:
	get_tree().change_scene_to_file(WIN_SCREEN_PATH)
