extends CharacterBody3D

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
	print("ENEMY READY en escena:", get_tree().current_scene.name)
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
	print("ENEMY: daño =", amount, " vida =", current_health)
	_update_health_bar()
	if current_health <= 0:
		die()


func die() -> void:
	# FX de muerte
	if death_fx_scene != null:
		var fx_root: Node3D = death_fx_scene.instantiate() as Node3D
		fx_root.global_transform.origin = global_transform.origin
		get_parent().add_child(fx_root)
		_enable_particles_recursive(fx_root)

	# Avisar al nivel
	var level := get_parent()
	if level and level.has_method("on_enemy_killed"):
		level.on_enemy_killed()

	queue_free()


func _enable_particles_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is GPUParticles3D:
			print("ENEMY: activando GPUParticles3D en", child.name)
			child.emitting = true
		_enable_particles_recursive(child)


func _update_health_bar() -> void:
	print("UPDATE BAR health =", current_health, " / ", max_health)
	if health_bar_ui and health_bar_ui.has_method("set_health"):
		health_bar_ui.set_health(current_health, max_health)
