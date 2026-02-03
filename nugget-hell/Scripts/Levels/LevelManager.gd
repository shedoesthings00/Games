extends Node

var levels: Array[String] = [
	"res://Escenas/Levels/Level_1.tscn",
	"res://Escenas/Levels/Level_2.tscn",
]

var current_index: int = 0

const WIN_SCREEN_PATH := "res://Escenas/Menus/WinScreen.tscn"
const DEATH_SCREEN_PATH := "res://Escenas/Menus/DeathScreen.tscn"


func start_game() -> void:
	current_index = 0
	get_tree().change_scene_to_file(levels[current_index])
	if LevelTransition != null:
		LevelTransition.show_level("Level " + str(current_index + 1))



func load_next_level() -> void:
	current_index += 1
	if current_index >= levels.size():
		_load_win_screen()
	else:
		_load_current_level_with_transition()


func player_died() -> void:
	_load_death_screen()


func _load_current_level_with_transition() -> void:
	get_tree().change_scene_to_file(levels[current_index])

	if LevelTransition != null:
		var text := "Level " + str(current_index + 1)
		LevelTransition.show_level(text)


func _load_win_screen() -> void:
	get_tree().change_scene_to_file(WIN_SCREEN_PATH)

	if LevelTransition != null:
		LevelTransition.show_no_text()


func _load_death_screen() -> void:
	get_tree().change_scene_to_file(DEATH_SCREEN_PATH)

	if LevelTransition != null:
		LevelTransition.show_no_text()
