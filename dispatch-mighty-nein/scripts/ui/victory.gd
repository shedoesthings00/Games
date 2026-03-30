extends Control
## Pantalla de victoria. Botones Jugar de nuevo y Menú principal.

@onready var retry_button: Button = $Center/VBox/Buttons/RetryButton
@onready var menu_button: Button = $Center/VBox/Buttons/MenuButton

func _ready() -> void:
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)

func _on_retry() -> void:
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
