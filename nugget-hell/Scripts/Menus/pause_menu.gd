extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_menu() -> void:
	visible = true
	get_tree().paused = true

func hide_menu() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_pressed() -> void:
	hide_menu()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
