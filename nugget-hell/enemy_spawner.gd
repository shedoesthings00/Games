extends Node3D

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_area_radius: float = 20.0
@export var spawn_interval: float = 2.0
@export var max_alive: int = 5   # máximo enemigos vivos simultáneamente

var _timer: float = 0.0
var level: Node3D


func _ready() -> void:
	# asumimos que el padre es el nodo con level_1.gd
	level = get_parent() as Node3D


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		_try_spawn_enemy()


func _try_spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return

	# 1) limitar enemigos vivos simultáneamente
	var current_alive := 0
	for child in get_parent().get_children():
		if child is CharacterBody3D and child.has_method("die"):
			current_alive += 1
	if current_alive >= max_alive:
		return

	# 2) limitar total del nivel usando max_enemies y enemies_remaining del nivel
	if level != null:
		var total_max: int = level.max_enemies          # definido en level_1.gd
		var remaining: int = level.enemies_remaining    # definido en level_1.gd
		var killed: int = total_max - remaining
		var already_spawned: int = killed + current_alive
		if already_spawned >= total_max:
			return

	# Elegir escena aleatoria
	var chosen_scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	if chosen_scene == null:
		return

	var enemy: CharacterBody3D = chosen_scene.instantiate() as CharacterBody3D

	var angle := randf() * TAU
	var radius := randf() * spawn_area_radius
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

	enemy.global_transform.origin = global_transform.origin + offset
	get_parent().add_child(enemy)
