extends CharacterBody3D

@export var move_speed: float = 6.0
@export var turn_speed: float = 3.0
@export var bullet_scene: PackedScene

@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.2
var dash_time_left: float = 0.0

@export var max_health: int = 10
var current_health: int

@export var max_ammo: int = 3
var current_ammo: int
@export var reload_time: float = 1.5
var _is_reloading: bool = false

@onready var cam: Camera3D = get_viewport().get_camera_3d()
@onready var muzzle: Node3D = $Muzzle


func _ready() -> void:
	current_health = max_health
	current_ammo = max_ammo
	print("PLAYER VIDA =", current_health)
	_update_hud()


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
	var input_left_right := Input.get_axis("move_left", "move_right")
	var input_forward_back := Input.get_axis("move_back", "move_forward")

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
		dir = -transform.basis.z
		dir = dir.normalized()
		final_speed = dash_speed

	velocity.x = dir.x * final_speed
	velocity.z = dir.z * final_speed
	velocity.y = 0.0

	move_and_slide()


func _update_camera_follow(delta: float) -> void:
	# La cámara es hija del Player, no hace falta nada
	pass


func _shoot() -> void:
	if _is_reloading:
		return

	if current_ammo <= 0:
		_start_reload()
		return

	if Input.is_action_just_pressed("shoot") and bullet_scene and muzzle:
		var dir: Vector3 = _get_shoot_direction_to_mouse()
		if dir == Vector3.ZERO:
			return

		var bullet = bullet_scene.instantiate()
		get_parent().add_child(bullet)

		var spawn_pos = muzzle.global_transform.origin
		spawn_pos.y = global_position.y
		bullet.global_transform.origin = spawn_pos

		if bullet.has_method("init_direction"):
			bullet.init_direction(dir)
		else:
			bullet.move_dir = dir

		current_ammo -= 1
		_update_hud()
		print("PLAYER: Disparo, dir =", dir, " ammo =", current_ammo)

		if current_ammo <= 0:
			_start_reload()


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


func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health < 0:
		current_health = 0
	print("PLAYER VIDA =", current_health)
	_update_hud()

	if current_health == 0:
		_die()


func _die() -> void:
	print("PLAYER MUERTO")
	# Aquí puedes recargar escena o mostrar menú


func _start_reload() -> void:
	if _is_reloading:
		return
	_is_reloading = true
	print("RELOAD...")
	var t := get_tree().create_timer(reload_time)
	t.timeout.connect(_finish_reload)


func _finish_reload() -> void:
	current_ammo = max_ammo
	_is_reloading = false
	print("RELOAD DONE, ammo =", current_ammo)
	_update_hud()


func _update_hud() -> void:
	var hud := get_tree().get_root().find_child("HUD", true, false)
	print("HUD encontrado:", hud)
	if hud:
		if hud.has_method("set_health"):
			hud.set_health(current_health, max_health)
		if hud.has_method("set_ammo"):
			hud.set_ammo(current_ammo, max_ammo)
