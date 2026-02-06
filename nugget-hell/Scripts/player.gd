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
var _reload_time_left: float = 0.0


@onready var cam: Camera3D = get_viewport().get_camera_3d()
@onready var muzzle: Node3D = $Muzzle

@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@export var footstep_interval: float = 0.3
var _footstep_timer: float = 0.0

func _ready() -> void:
	current_health = max_health
	current_ammo = max_ammo
	print("PLAYER VIDA =", current_health)
	await get_tree().process_frame
	_update_hud()

func _physics_process(delta: float) -> void:
	_handle_dash_input()
	_move_player(delta)
	_update_camera_follow(delta)
	
	_play_footsteps(delta)

	# <<< AÑADIR ESTO si quieres que el player nunca salga del suelo >>>
	var room3d := get_tree().get_root().find_child("Room3D", true, false)
	if room3d and room3d.has_method("get_nearest_floor_position"):
		var target: Vector3 = room3d.get_nearest_floor_position(global_position)
		# mezcla suave para que no pegue saltos bruscos
		global_position.x = target.x
		global_position.z = target.z



func _update_reload_feedback(delta: float) -> void:
	if not _is_reloading:
		return

	_reload_time_left -= delta
	if _reload_time_left < 0.0:
		_reload_time_left = 0.0

	var progress := 1.0 - (_reload_time_left / reload_time)

	var hud := get_tree().get_root().find_child("HUD", true, false)
	if hud and hud.has_method("set_reload_progress"):
		hud.set_reload_progress(progress)


func _handle_manual_reload() -> void:
	# Si ya está recargando, no hacer nada
	if _is_reloading:
		return

	# Si ya tenemos el cargador lleno, opcionalmente no recargar
	if current_ammo >= max_ammo:
		return

	# Pulsar R para recargar
	if Input.is_action_just_pressed("reload"):
		_start_reload()
		
		
func _process(delta: float) -> void:
	_shoot()
	_handle_manual_reload()

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

		print("PLAYER: bullet tiene init_direction:", bullet.has_method("init_direction"))
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
	get_tree().change_scene_to_file("res://Escenas/DeathScreen.tscn")


func _start_reload() -> void:
	if _is_reloading:
		return
	_is_reloading = true
	_reload_time_left = reload_time
	print("RELOAD...")

	# Avisar al HUD para que muestre el círculo
	var hud := get_tree().get_root().find_child("HUD", true, false)
	if hud and hud.has_method("show_reload_progress"):
		hud.show_reload_progress()

	var t := get_tree().create_timer(reload_time)
	t.timeout.connect(_finish_reload)


func _finish_reload() -> void:
	current_ammo = max_ammo
	_is_reloading = false
	_reload_time_left = 0.0
	print("RELOAD DONE, ammo =", current_ammo)
	_update_hud()

	# Ocultar el círculo en el HUD
	var hud := get_tree().get_root().find_child("HUD", true, false)
	if hud and hud.has_method("hide_reload_progress"):
		hud.hide_reload_progress()


func _update_hud() -> void:
	var hud := get_tree().get_root().find_child("HUD", true, false)
	print("HUD encontrado:", hud)
	if hud:
		if hud.has_method("set_health"):
			hud.set_health(current_health, max_health)
		if hud.has_method("set_ammo"):
			hud.set_ammo(current_ammo, max_ammo)

func _play_footsteps(delta: float) -> void:
	if footstep_player == null:
		return

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if horizontal_speed > 0.1:
		_footstep_timer -= delta
		if _footstep_timer <= 0.0:
			footstep_player.play()
			_footstep_timer = footstep_interval
	else:
		_footstep_timer = 0.0
		if footstep_player.playing:
			footstep_player.stop()
