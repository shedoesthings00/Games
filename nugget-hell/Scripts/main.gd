extends Control

func _ready() -> void:
	# Ir al menú inicial.
	get_tree().change_scene_to_file("res://Escenas/Menus/MainMenu.tscn")
