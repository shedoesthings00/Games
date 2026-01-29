extends CharacterBody3D

@export var move_speed: float = 6.0
@export var turn_speed: float = 3.0
@export var bullet_scene: PackedScene

@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.2
var dash_time_left: float = 0.0

@onready var cam: Camera3D = get_viewport().get_camera_3d()
@onready var muzzle: Node3D = $Muzzle


func _physics_process(delta: float) -> void:
	_handle_dash_input()
	_move_player(delta)
	_update_camera_follow(delta)


func _process(delta: float) -> void:
	_shoot()


func _handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and dash_time_left <= 0.0:
		dash_time_left = dash_duration


func _move_player(delta: float) -> void:
	var input_left_right := Input.get_axis("move_left", "move_right")     # A/D
	var input_forward_back := Input.get_axis("move_back", "move_forward") # S/W

	# Girar el jugador en Y con A/D (A = izquierda, D = derecha)
	if input_left_right != 0.0:
		rotation.y -= input_left_right * turn_speed * delta

	# Dirección de movimiento
	var dir: Vector3 = Vector3.ZERO
	if input_forward_back != 0.0:
		dir -= transform.basis.z * input_forward_back  # -Z es "delante"

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	var final_speed := move_speed

	# Dash hacia delante
	if dash_time_left > 0.0:
		dash_time_left -= delta
		dir = -transform.basis.z            # siempre hacia delante
		dir = dir.normalized()
		final_speed = dash_speed

	velocity.x = dir.x * final_speed
	velocity.z = dir.z * final_speed
	velocity.y = 0.0

	move_and_slide()


func _update_camera_follow(delta: float) -> void:
	# Si la cámara es hija del Player y la has orientado en la escena,
	# realmente no hace falta nada aquí; la dejo por si quieres suavizar algo.
	pass


func _shoot() -> void:
	if Input.is_action_just_pressed("shoot") and bullet_scene and muzzle:
		var dir: Vector3 = _get_shoot_direction_to_mouse()
		if dir == Vector3.ZERO:
			return

		var bullet: RigidBody3D = bullet_scene.instantiate() as RigidBody3D
		get_parent().add_child(bullet)

		bullet.global_transform.origin = muzzle.global_transform.origin
		if bullet.has_method("init_direction"):
			bullet.init_direction(dir)
		else:
			bullet.move_dir = dir

		print("PLAYER: Disparo, dir =", dir)


func _get_shoot_direction_to_mouse() -> Vector3:
	if cam == null:
		return Vector3.ZERO

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var from: Vector3 = cam.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = cam.project_ray_normal(mouse_pos)

	var plane: Plane = Plane(Vector3.UP, global_position.y)
	var hit: Variant = plane.intersects_ray(from, ray_dir)
	if hit == null:
		return Vector3.ZERO

	var hit_pos: Vector3 = hit as Vector3
	var dir: Vector3 = hit_pos - muzzle.global_transform.origin
	dir.y = 0.0
	return dir.normalized()
