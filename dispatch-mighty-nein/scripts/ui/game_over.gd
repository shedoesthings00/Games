extends Control
## Pantalla de derrota. Botones Reintentar y Menú principal.

@onready var reason_label: Label = $Center/VBox/Reason
@onready var retry_button: Button = $Center/VBox/Buttons/RetryButton
@onready var menu_button: Button = $Center/VBox/Buttons/MenuButton

func _ready() -> void:
	reason_label.text = GameManager.last_game_over_reason if GameManager.last_game_over_reason else "La partida ha terminado."
	retry_button.pressed.connect(_on_retry)
	menu_button.pressed.connect(_on_menu)

func _on_retry() -> void:
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
