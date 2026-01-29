extends CharacterBody3D

@export var move_speed: float = 6.0
@export var turn_speed: float = 3.0
@export var bullet_scene: PackedScene

@onready var cam: Camera3D = get_viewport().get_camera_3d()
@onready var muzzle: Node3D = $Muzzle
@onready var cam_pivot: Node3D = $CamPivot   # crea este nodo hijo del Player y mete la Camera3D dentro


func _physics_process(delta: float) -> void:
	_move_player(delta)
	_update_camera_follow(delta)


func _process(delta: float) -> void:
	_shoot()


func _move_player(delta: float) -> void:
	var input_left_right := Input.get_axis("move_left", "move_right")     # A/D
	var input_forward_back := Input.get_axis("move_back", "move_forward") # S/W

	# Girar el jugador en Y con A/D
	if input_left_right != 0.0:
		rotation.y -= input_left_right * turn_speed * delta


	# Mover adelante/atrás según su frente local (-Z)
	var dir: Vector3 = Vector3.ZERO
	if input_forward_back != 0.0:
		dir -= transform.basis.z * input_forward_back  # -Z es "delante"

	if dir != Vector3.ZERO:
		dir = dir.normalized()

	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	velocity.y = 0.0

	move_and_slide()


func _update_camera_follow(delta: float) -> void:
	if cam_pivot == null:
		return

	# Si quieres que siga EXACTAMENTE la rotación del player:
	# cam_pivot.rotation.y = rotation.y

	# Si quieres un giro suave:
	var target_rot_y := rotation.y
	cam_pivot.rotation.y = lerp_angle(cam_pivot.rotation.y, target_rot_y, 10.0 * delta)


func _shoot() -> void:
	if Input.is_action_just_pressed("shoot") and bullet_scene and muzzle:
		var dir: Vector3 = _get_shoot_direction_to_mouse()
		if dir == Vector3.ZERO:
			return

		var bullet: RigidBody3D = bullet_scene.instantiate() as RigidBody3D
		get_parent().add_child(bullet)

		bullet.global_transform.origin = muzzle.global_transform.origin
		# Si seguiste mi recomendación de antes, usando init_direction en la bala:
		if bullet.has_method("init_direction"):
			bullet.init_direction(dir)
		else:
			# fallback al sistema antiguo de asignar move_dir
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
