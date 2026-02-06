extends Control

const MAIN_MENU_SCENE := "res://Escenas/Menus/MainMenu.tscn"
const SETTINGS_PATH := "user://settings.cfg"

@onready var volume_slider: HSlider = $Margin/VBox/AudioBox/VolumeSlider
@onready var fullscreen_check: CheckBox = $Margin/VBox/FullscreenBox/FullscreenCheck


func _ready() -> void:
	_load_settings()
	if volume_slider:
		volume_slider.grab_focus()


func _on_volume_changed(value: float) -> void:
	_set_master_volume_linear(value)
	_save_settings()


func _on_fullscreen_toggled(on: bool) -> void:
	if on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_save_settings()


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _set_master_volume_linear(v: float) -> void:
	var idx := AudioServer.get_bus_index("Master")
	if idx < 0:
		return
	var clamped := clampf(v, 0.0, 1.0)
	# 0 -> -80 dB (silencio), 1 -> 0 dB.
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
		# Aplicar estado de fullscreen
		_on_fullscreen_toggled(fs)
	else:
		# Defaults
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

