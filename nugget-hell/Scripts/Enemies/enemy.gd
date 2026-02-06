extends CharacterBody3D

const SFX_DO_DAMAGE := preload("res://Audio/do_damage.wav")

@export var enemy_name: String = "Enemy"
@export var model_scene: PackedScene
@export var level_id: int = 1
@export var max_health: int = 10
@export var attack_damage: int = 1
@export var move_speed: float = 3.0
@export var loot_value: int = 0
@export var attack_cooldown: float = 1.0  # segundos entre golpes

@export var death_fx_scene: PackedScene   # FX al morir (Node3D con GPUParticles3D hijas)

var current_health: int
var _time_since_last_attack: float = 0.0

@onready var target: Node3D = null  # el jugador

@onready var health_viewport: SubViewport = $HealthViewport
@onready var health_bar_ui: Control = $HealthViewport/EnemyHealthBar
@onready var health_bar_sprite: Sprite3D = $HealthBarSprite


func _ready() -> void:
	current_health = max_health
	target = get_tree().get_root().find_child("Player", true, false)
	_update_health_bar()


func _physics_process(delta: float) -> void:
	_time_since_last_attack += delta
	_move_towards_target(delta)
	_check_player_hit()
	_face_camera()


func _face_camera() -> void:
	if health_bar_sprite == null:
		return

	var vp := get_viewport()
	if vp == null:
		return

	var cam := vp.get_camera_3d()
	if cam == null:
		return

	health_bar_sprite.look_at(cam.global_transform.origin, Vector3.UP)


func _move_towards_target(delta: float) -> void:
	if target == null:
		return

	var dir: Vector3 = target.global_transform.origin - global_transform.origin
	dir.y = 0.0

	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity = dir * move_speed
		move_and_slide()


func _check_player_hit() -> void:
	if target == null:
		return

	var diff: Vector3 = target.global_transform.origin - global_transform.origin
	diff.y = 0.0

	if diff.length() < 1.2 and _time_since_last_attack >= attack_cooldown:
		if target.has_method("take_damage"):
			target.take_damage(attack_damage)
			_time_since_last_attack = 0.0


func take_damage(amount: int) -> void:
	current_health -= amount
	_update_health_bar()
	_play_sfx(SFX_DO_DAMAGE)
	if current_health <= 0:
		die()


func die() -> void:
	# FX de muerte
	if death_fx_scene != null:
		var fx_root: Node3D = death_fx_scene.instantiate() as Node3D
		fx_root.global_transform.origin = global_transform.origin
		get_parent().add_child(fx_root)
		_enable_particles_recursive(fx_root)

	# Powerup: se lo pedimos al nivel
	var level := get_parent()
	if level != null and level.has_method("get_powerup_drop"):
		var pu_scene: PackedScene = level.get_powerup_drop()
		if pu_scene != null:
			var pu: Node3D = pu_scene.instantiate() as Node3D
			# Levantar un poco para que no quede enterrado en el suelo
			pu.global_transform.origin = global_transform.origin + Vector3(0.0, 0.5, 0.0)
			level.add_child(pu)

	# Avisar al nivel de que ha muerto
	if level and level.has_method("on_enemy_killed"):
		level.on_enemy_killed()

	queue_free()



func _enable_particles_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is GPUParticles3D:
			child.emitting = true
		_enable_particles_recursive(child)


func _update_health_bar() -> void:
	if health_bar_ui and health_bar_ui.has_method("set_health"):
		health_bar_ui.set_health(current_health, max_health)


func _play_sfx(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.global_transform.origin = global_transform.origin
	get_tree().current_scene.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
