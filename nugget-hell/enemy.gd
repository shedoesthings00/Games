extends CharacterBody3D

@export var enemy_name: String = "Enemy"
@export var model_scene: PackedScene
@export var level_id: int = 1
@export var max_health: int = 10
@export var attack_damage: int = 1
@export var move_speed: float = 3.0
@export var loot_value: int = 0

var current_health: int

@onready var target: Node3D = null

func _ready() -> void:
	current_health = max_health
	target = get_tree().get_root().find_child("Player", true, false)

func _physics_process(delta: float) -> void:
	_move_towards_target(delta)

func _move_towards_target(delta: float) -> void:
	if target == null:
		return

	var dir: Vector3 = (target.global_transform.origin - global_transform.origin)
	dir.y = 0.0

	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		velocity.y = 0.0
		move_and_slide()

func take_damage(amount: int) -> void:
	current_health -= amount
	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
