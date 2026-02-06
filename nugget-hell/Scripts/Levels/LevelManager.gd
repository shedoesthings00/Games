extends Node

var levels: Array[String] = [
	"res://Escenas/Levels/Level_1.tscn",
	"res://Escenas/Levels/Level_2.tscn",
]

var current_index: int = 0

const WIN_SCREEN_PATH := "res://Escenas/Menus/WinScreen.tscn"
const DEATH_SCREEN_PATH := "res://Escenas/Menus/DeathScreen.tscn"

# --- HABITACIONES HECHAS A MANO ---

var room_scenes: Array[String] = [
	"res://Escenas/Levels/Level1/Room1.tscn",
	"res://Escenas/Levels/Level1/Room2.tscn",
	"res://Escenas/Levels/Level1/Room3.tscn",
	"res://Escenas/Levels/Level1/Room4.tscn",
	"res://Escenas/Levels/Level1/Room5.tscn",
	"res://Escenas/Levels/Level1/Room6.tscn",
	"res://Escenas/Levels/Level1/Room7.tscn",
]

var available_rooms: Array[String] = []


func _ready() -> void:
	_reset_rooms_pool()


func _reset_rooms_pool() -> void:
	available_rooms = room_scenes.duplicate()
	available_rooms.shuffle()


func get_next_room_scene_path() -> String:
	if available_rooms.is_empty():
		# Si quieres que nunca se repitan en toda la partida, NO llames a _reset_rooms_pool()
		_reset_rooms_pool()
	return available_rooms.pop_back()


# --- NIVELES ---

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
