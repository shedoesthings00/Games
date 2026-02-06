extends CanvasLayer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_menu() -> void:
	print("PAUSE: show_menu()")
	visible = true
	get_tree().paused = true

func hide_menu() -> void:
	print("PAUSE: hide_menu()")
	get_tree().paused = false
	visible = false

func _on_resume_pressed() -> void:
	print("PAUSE: Resume button pressed")
	hide_menu()

func _on_exit_pressed() -> void:
	print("PAUSE: Exit button pressed")
	get_tree().paused = false
	get_tree().quit()
