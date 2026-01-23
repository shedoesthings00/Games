extends CharacterBody3D

@export var speed: float = 6.0
@export var max_turn_speed: float = 2.0
@export var dead_zone: float = 30.0

@onready var cam: Camera3D = get_viewport().get_camera_3d()


func _physics_process(delta: float) -> void:
	_move_player(delta)


func _process(delta: float) -> void:
	_rotate_with_mouse_gradual(delta)


func _move_player(delta: float) -> void:
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right",
		"move_forward", "move_back"
	)

	var direction := Vector3.ZERO
	
	if input_dir.x != 0.0:
		direction += transform.basis.x * input_dir.x
	if input_dir.y != 0.0:
		direction += transform.basis.z * input_dir.y

	if direction != Vector3.ZERO:
		direction = direction.normalized()

	velocity = direction * speed
	velocity.y = 0.0

	move_and_slide()



func _rotate_with_mouse_gradual(delta: float) -> void:
	if cam == null:
		return

	var mouse_pos: Vector2 = get_viewport().get_mouse_position()

	var player_screen_pos: Vector2 = cam.unproject_position(global_position)

	var diff_x: float = mouse_pos.x - player_screen_pos.x

	if abs(diff_x) < dead_zone:
		return

	var viewport_width: float = get_viewport().size.x
	var max_dist: float = viewport_width * 0.5
	var strength: float = clamp(diff_x / max_dist, -1.0, 1.0)

	var turn_amount: float = -strength * max_turn_speed * delta

	rotation.y += turn_amount
