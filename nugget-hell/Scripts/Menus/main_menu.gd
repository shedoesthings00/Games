extends Control


const OPTIONS_SCENE := "res://Escenas/Menus/OptionsMenu.tscn"
const CREDITS_SCENE := "res://Escenas/Menus/CreditsMenu.tscn"


func _ready() -> void:
	# Enfocar el primer botón para mando/teclado.
	var b := $Center/VBox/PlayButton as Button
	if b:
		b.grab_focus()


func _on_play_pressed() -> void:
	if LevelManager != null:
		LevelManager.start_game()


func _on_options_pressed() -> void:
	get_tree().change_scene_to_file(OPTIONS_SCENE)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file(CREDITS_SCENE)


func _on_quit_pressed() -> void:
	get_tree().quit()

