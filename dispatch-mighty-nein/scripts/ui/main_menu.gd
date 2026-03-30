extends Control
## Menú principal: Jugar, Opciones, Salir.

@onready var play_button: Button = $Center/VBox/PlayButton
@onready var options_button: Button = $Center/VBox/OptionsButton
@onready var quit_button: Button = $Center/VBox/QuitButton

func _ready() -> void:
	play_button.pressed.connect(_on_play)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(_on_quit)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/hero_select.tscn")

func _on_options() -> void:
	get_tree().change_scene_to_file("res://scenes/options.tscn")

func _on_quit() -> void:
	get_tree().quit()
