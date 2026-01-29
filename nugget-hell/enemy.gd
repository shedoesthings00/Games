extends CharacterBody3D

@export var enemy_name: String = "Enemy"
@export var model_scene: PackedScene
@export var level_id: int = 1
@export var max_health: int = 10
@export var attack_damage: int = 1
@export var move_speed: float = 3.0
@export var loot_value: int = 0

@export var attack_cooldown: float = 1.0  # segundos entre golpes

var current_health: int
var _time_since_last_attack: float = 0.0

@onready var target: Node3D = null  # el jugador


func _ready() -> void:
	current_health = max_health
	target = get_tree().get_root().find_child("Player", true, false)


func _physics_process(delta: float) -> void:
	_time_since_last_attack += delta
	_move_towards_target(delta)
	_check_player_hit()


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
	if current_health <= 0:
		die()


func die() -> void:
	queue_free()
