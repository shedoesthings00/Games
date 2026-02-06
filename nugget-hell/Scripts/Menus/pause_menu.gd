extends CanvasLayer

const MAIN_MENU_SCENE := "res://Escenas/Menus/MainMenu.tscn"
const SETTINGS_PATH := "user://settings.cfg"

@onready var dim: ColorRect = $Control/Dim
@onready var panel: PanelContainer = $Control/Center/Panel
@onready var resume_button: Button = $Control/Center/Panel/Margin/VBox/Buttons/ResumeButton
@onready var volume_slider: HSlider = $Control/Center/Panel/Margin/VBox/OptionsBox/VolumeRow/VolumeSlider
@onready var fullscreen_check: CheckBox = $Control/Center/Panel/Margin/VBox/OptionsBox/FullscreenRow/FullscreenCheck

var _open_tween: Tween = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()

	# Estado inicial de “animación”
	if dim:
		dim.modulate.a = 0.0
	if panel:
		panel.modulate.a = 0.0
		panel.scale = Vector2(0.96, 0.96)

func show_menu() -> void:
	visible = true
	get_tree().paused = true
	_load_settings()
	_animate_open()
	if resume_button:
		resume_button.grab_focus()

func hide_menu() -> void:
	get_tree().paused = false
	visible = false

func _on_resume_pressed() -> void:
	hide_menu()

func _on_main_menu_pressed() -> void:
	# Importante: despausar antes de cambiar de escena.
	get_tree().paused = false
	visible = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _on_volume_changed(value: float) -> void:
	_set_master_volume_linear(value)
	_save_settings()


func _on_fullscreen_toggled(on: bool) -> void:
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func _animate_open() -> void:
	# Evitar apilar tweens si se abre/cierra rápido
	if _open_tween != null:
		_open_tween.kill()
		_open_tween = null

	var tween := create_tween()
	_open_tween = tween
	tween.set_parallel(true)
	if dim:
		tween.tween_property(dim, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if panel:
		tween.tween_property(panel, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_master_volume_linear(v: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return
	var clamped := clampf(v, 0.0, 1.0)
	var db := lerpf(-80.0, 0.0, clamped)
	AudioServer.set_bus_volume_db(idx, db)


func _get_master_volume_linear() -> float:
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return 1.0
	var db := AudioServer.get_bus_volume_db(idx)
	return clampf(inverse_lerp(-80.0, 0.0, db), 0.0, 1.0)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err == OK:
		var vol := float(cfg.get_value("audio", "master_volume", 1.0))
		var fs := bool(cfg.get_value("display", "fullscreen", false))
		if volume_slider:
			volume_slider.value = clampf(vol, 0.0, 1.0)
		_set_master_volume_linear(vol)
		if fullscreen_check:
			fullscreen_check.button_pressed = fs
		# aplicar modo de ventana sin disparar más lógica
		if fs:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		var vol_default := _get_master_volume_linear()
		if volume_slider:
			volume_slider.value = vol_default
		if fullscreen_check:
			fullscreen_check.button_pressed = false


func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", float(volume_slider.value) if volume_slider else 1.0)
	cfg.set_value("display", "fullscreen", bool(fullscreen_check.button_pressed) if fullscreen_check else false)
	cfg.save(SETTINGS_PATH)
