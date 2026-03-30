extends Control
## Pantalla de opciones: volumen, pantalla completa, Atrás.

@onready var volume_slider: HSlider = $Center/VBox/VolumeSlider
@onready var fullscreen_check: CheckButton = $Center/VBox/FullscreenCheck
@onready var back_button: Button = $Center/VBox/BackButton

func _ready() -> void:
	back_button.pressed.connect(_on_back)
	volume_slider.value_changed.connect(_on_volume_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	# Cargar valores guardados si existen (opcional para demo)
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		volume_slider.value = cfg.get_value("audio", "volume", 1.0)
		fullscreen_check.button_pressed = cfg.get_value("display", "fullscreen", false)
	else:
		volume_slider.value = 1.0
		fullscreen_check.button_pressed = false
	_apply_options()

func _on_back() -> void:
	_save_options()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _linear_to_db(linear: float) -> float:
	if linear <= 0.0001:
		return -80.0
	return 20.0 * log(linear) / log(10.0)

func _on_volume_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _linear_to_db(value))

func _on_fullscreen_toggled(_on: bool) -> void:
	if _on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_options() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), _linear_to_db(volume_slider.value))
	if fullscreen_check.button_pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _save_options() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume_slider.value)
	cfg.set_value("display", "fullscreen", fullscreen_check.button_pressed)
	cfg.save("user://settings.cfg")
