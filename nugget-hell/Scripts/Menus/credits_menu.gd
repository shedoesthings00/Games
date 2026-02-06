extends Control

const MAIN_MENU_SCENE := "res://Escenas/Menus/MainMenu.tscn"


func _ready() -> void:
	var b := $Margin/VBox/BackButton as Button
	if b:
		b.grab_focus()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

