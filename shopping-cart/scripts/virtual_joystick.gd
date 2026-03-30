extends Control

@export var radius: float = 90.0
@export var knob_radius: float = 32.0
@export_range(0.0, 0.9, 0.01) var deadzone: float = 0.12

var _touch_id: int = -1
var _value: Vector2 = Vector2.ZERO

@onready var base: Control = $Base
@onready var knob: Control = $Knob

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = false
	set_process_input(true)
	_update_layout()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_layout()

func get_vector() -> Vector2:
	return _value

func is_active() -> bool:
	return _touch_id != -1

func _global_to_local_pos(global_pos: Vector2) -> Vector2:
	# Para Control/CanvasItem en Godot 4.x (no existe to_local()).
	# InputEvent.position viene en coordenadas de viewport/canvas.
	var t: Transform2D = get_global_transform_with_canvas()
	return t.affine_inverse() * global_pos

func _input(event: InputEvent) -> void:
	# Usamos coordenadas globales (viewport) y las pasamos a local.
	# Esto funciona tanto en móvil (touch) como en PC (ratón).
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		var global_pos: Vector2 = t.position
		if t.pressed:
			if _touch_id == -1:
				var local_pos: Vector2 = _global_to_local_pos(global_pos)
				if Rect2(Vector2.ZERO, size).has_point(local_pos) and _is_inside_radius(local_pos):
					_touch_id = t.index
					_set_from_pos(local_pos)
					get_viewport().set_input_as_handled()
		else:
			if t.index == _touch_id:
				_touch_id = -1
				_value = Vector2.ZERO
				_update_knob(Vector2.ZERO)
				get_viewport().set_input_as_handled()

	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _touch_id:
			_set_from_pos(_global_to_local_pos(d.position))
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var global_pos: Vector2 = mb.position
			if mb.pressed:
				if _touch_id == -1:
					var local_pos: Vector2 = _global_to_local_pos(global_pos)
					if Rect2(Vector2.ZERO, size).has_point(local_pos) and _is_inside_radius(local_pos):
						_touch_id = 999999 # id ficticio para ratón
						_set_from_pos(local_pos)
						get_viewport().set_input_as_handled()
			else:
				if _touch_id == 999999:
					_touch_id = -1
					_value = Vector2.ZERO
					_update_knob(Vector2.ZERO)
					get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _touch_id == 999999:
			_set_from_pos(_global_to_local_pos(mm.position))
			get_viewport().set_input_as_handled()

func _is_inside_radius(pos: Vector2) -> bool:
	var center := size * 0.5
	return (pos - center).length() <= radius

func _set_from_pos(pos: Vector2) -> void:
	var center := size * 0.5
	var delta := pos - center
	var len := delta.length()
	if len > radius and len > 0.0:
		delta = delta / len * radius

	var v := Vector2.ZERO
	if radius > 0.0:
		v = delta / radius

	if v.length() < deadzone:
		v = Vector2.ZERO
		delta = Vector2.ZERO

	_value = v.clamp(Vector2(-1, -1), Vector2(1, 1))
	_update_knob(delta)

func _update_layout() -> void:
	# Forzamos tamaño cuadrado para el área del joystick.
	custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	if size.x <= 0.0 or size.y <= 0.0:
		size = custom_minimum_size

	# Base ocupa todo el Control.
	base.position = Vector2.ZERO
	base.size = size

	# Knob al centro.
	knob.size = Vector2(knob_radius * 2.0, knob_radius * 2.0)
	_update_knob(Vector2.ZERO)

func _update_knob(delta_from_center: Vector2) -> void:
	var center := size * 0.5
	knob.position = (center + delta_from_center) - (knob.size * 0.5)
