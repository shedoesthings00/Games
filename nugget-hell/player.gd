extends CharacterBody3D

@export var move_speed: float = 6.0
@export var bullet_scene: PackedScene

@onready var cam: Camera3D = get_viewport().get_camera_3d()
@onready var muzzle: Node3D = $Muzzle


func _physics_process(delta: float) -> void:
	_move_player(delta)


func _process(delta: float) -> void:
	_shoot()


func _move_player(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_back"
	)

	var direction: Vector3 = Vector3.ZERO

	if input_dir.x != 0.0:
		direction += transform.basis.x * input_dir.x
	if input_dir.y != 0.0:
		direction += transform.basis.z * input_dir.y

	if direction != Vector3.ZERO:
		direction = direction.normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	velocity.y = 0.0

	move_and_slide()


func _shoot() -> void:
	if Input.is_action_just_pressed("shoot") and bullet_scene and muzzle:
		var dir: Vector3 = _get_shoot_direction_to_mouse()
		if dir == Vector3.ZERO:
			return

		var bullet: RigidBody3D = bullet_scene.instantiate() as RigidBody3D
		get_parent().add_child(bullet)

		bullet.global_transform.origin = muzzle.global_transform.origin
		(bullet as Node).call("init_direction", dir)

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

	var dir: Vector3 = (hit as Vector3) - muzzle.global_transform.origin
	dir.y = 0.0
	return dir.normalized()
