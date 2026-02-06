extends Node3D

@export var lifetime: float = 0.75
@export var float_speed: float = 1.3
@export var spread: Vector3 = Vector3(0.35, 0.0, 0.35)

@onready var label: Label3D = $Label3D

var _time: float = 0.0
var _base_color: Color = Color(1.0, 0.92, 0.35, 1.0)


func setup(amount: int, color: Color = Color(1.0, 0.92, 0.35, 1.0)) -> void:
	_base_color = color
	if label:
		label.text = str(amount)
		label.modulate = _base_color


func _ready() -> void:
	# Pequeño offset aleatorio para que varios números no se solapen.
	global_position.x += randf_range(-spread.x, spread.x)
	global_position.z += randf_range(-spread.z, spread.z)


func _process(delta: float) -> void:
	_time += delta

	# Subir
	global_position.y += float_speed * delta

	# Mirar a cámara
	var cam := get_viewport().get_camera_3d()
	if cam:
		look_at(cam.global_transform.origin, Vector3.UP)
		# (Si lo vieras espejado, lo corregimos con un offset de 180º, pero
		# primero priorizamos que siempre mire a la cámara.)

	# Fade out
	var t := clampf(_time / max(0.01, lifetime), 0.0, 1.0)
	var a := 1.0 - t
	if label:
		var c := _base_color
		c.a = a
		label.modulate = c

	if _time >= lifetime:
		queue_free()

