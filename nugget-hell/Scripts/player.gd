extends CharacterBody3D

const SFX_TAKE_DAMAGE := preload("res://Audio/take_damage.wav")

@export var move_speed: float = 6.0
@export var move_accel: float = 28.0
@export var move_decel: float = 36.0
@export var face_turn_speed: float = 18.0
@export var bullet_scene: PackedScene

# SFX configurables desde el inspector (AudioStream/WAV).
@export var sfx_shooting: AudioStream = preload("res://Audio/shooting.wav")
@export var sfx_reloading: AudioStream = preload("res://Audio/reloading.wav")

@export var dash_speed: float = 18.0
@export var dash_duration: float = 0.2
var dash_time_left: float = 0.0
var _dash_dir: Vector3 = Vector3.ZERO

@export var max_health: int = 10
var current_health: int

@export var max_ammo: int = 3
var current_ammo: int
@export var reload_time: float = 1.5
var _is_reloading: bool = false
var _reload_time_left: float = 0.0

@onready var cam: Camera3D = $Camera3D
@onready var muzzle: Node3D = $Muzzle

@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@export var footstep_interval: float = 0.3
var _footstep_timer: float = 0.0

# Cámara: fija (sin rotar con el player), encima y mirando al jugador.
@export var camera_offset: Vector3 = Vector3(0.0, 9.0, 6.0)
@export var camera_look_height: float = 0.9
@export var camera_follow_speed: float = 18.0

# Suavizado del clamp dentro de la sala (0 = duro, valores altos = más suave).
@export var room_clamp_strength: float = 25.0

func _ready() -> void:
	current_health = max_health
	current_ammo = max_ammo
	await get_tree().process_frame
	_update_hud()

	# La cámara está como hija del Player en la escena: si el Player rota,
	# la cámara también. Para un top-down shooter, suele ser mejor que la cámara
	# NO rote y solo rote el personaje (aim).
	if cam:
		# Si el offset en la escena es “bueno”, úsalo como default (pero evita el caso degenerado).
		var scene_offset := cam.global_position - global_position
		if scene_offset.length() > 0.5 and scene_offset.y > 1.0:
			camera_offset = scene_offset
		cam.set_as_top_level(true)
		_update_camera_follow(0.0)

func _physics_process(delta: float) -> void:
	_handle_dash_input()
	_move_player(delta)
	_update_camera_follow(delta)
	
	_play_footsteps(delta)

	# Mantener al player dentro de la sala (clamp suave a suelo).
	var room3d := get_tree().get_root().find_child("Room3D", true, false)
	if room3d and room3d.has_method("get_nearest_floor_position"):
		var target: Vector3 = room3d.get_nearest_floor_position(global_position)
		var t := clampf(room_clamp_strength * delta, 0.0, 1.0)
		global_position.x = lerpf(global_position.x, target.x, t)
		global_position.z = lerpf(global_position.z, target.z, t)



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
		var mv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if mv.length() > 0.1:
			_dash_dir = Vector3(mv.x, 0.0, mv.y).normalized()
		else:
			# Si no hay input, dash hacia donde está mirando el personaje (Hades-like).
			_dash_dir = -transform.basis.z
			_dash_dir.y = 0.0
			_dash_dir = _dash_dir.normalized()


func _move_player(delta: float) -> void:
	# Dash: si está activo, ignorar aceleración/freno.
	if dash_time_left > 0.0:
		dash_time_left -= delta
		var d := _dash_dir
		if d == Vector3.ZERO:
			d = -transform.basis.z
		d.y = 0.0
		d = d.normalized()
		velocity.x = d.x * dash_speed
		velocity.z = d.z * dash_speed
		velocity.y = 0.0
		move_and_slide()
		return

	# Movimiento libre estilo top-down: WASD en ejes del mundo (sin “tanque”).
	var mv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := Vector3(mv.x, 0.0, mv.y)
	if dir.length() > 1.0:
		dir = dir.normalized()

	# Rotación estilo Hades: mirar hacia la dirección de movimiento (si se mueve).
	_update_facing_from_movement(dir, delta)

	var target_v := dir * move_speed
	var accel := move_accel if dir != Vector3.ZERO else move_decel
	velocity.x = move_toward(velocity.x, target_v.x, accel * delta)
	velocity.z = move_toward(velocity.z, target_v.z, accel * delta)
	velocity.y = 0.0

	move_and_slide()


func _update_camera_follow(delta: float) -> void:
	if cam == null:
		return
	var desired_pos := global_position + camera_offset
	if delta <= 0.0:
		cam.global_position = desired_pos
	else:
		var t := clampf(camera_follow_speed * delta, 0.0, 1.0)
		cam.global_position = cam.global_position.lerp(desired_pos, t)

	# Mirar al jugador sin heredar rotación del CharacterBody.
	cam.look_at(global_position + Vector3(0.0, camera_look_height, 0.0), Vector3.UP)


func _update_facing_from_movement(move_dir: Vector3, delta: float) -> void:
	if move_dir == Vector3.ZERO:
		return
	var d := move_dir
	d.y = 0.0
	d = d.normalized()
	# Yaw para que el -Z del personaje apunte hacia `d`
	var desired_yaw := atan2(-d.x, -d.z)
	var t := clampf(face_turn_speed * delta, 0.0, 1.0)
	rotation.y = lerp_angle(rotation.y, desired_yaw, t)


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
		_play_sfx(sfx_shooting)

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
	_update_hud()
	_play_sfx(SFX_TAKE_DAMAGE)

	if current_health == 0:
		_die()


func _die() -> void:
	get_tree().change_scene_to_file("res://Escenas/DeathScreen.tscn")


func _start_reload() -> void:
	if _is_reloading:
		return
	_is_reloading = true
	_reload_time_left = reload_time
	_play_sfx(sfx_reloading)

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
	_update_hud()

	# Ocultar el círculo en el HUD
	var hud := get_tree().get_root().find_child("HUD", true, false)
	if hud and hud.has_method("hide_reload_progress"):
		hud.hide_reload_progress()


func _update_hud() -> void:
	var hud := get_tree().get_root().find_child("HUD", true, false)
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


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	get_tree().current_scene.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
