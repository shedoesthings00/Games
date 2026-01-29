extends Node3D

@export var enemy_scenes: Array[PackedScene] = []  # escenas de enemigos que PUEDEN salir en este nivel
@export var spawn_area_radius: float = 20.0
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 20

var _timer: float = 0.0


func _physics_process(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		_try_spawn_enemy()


func _try_spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		return

	# Contar enemigos actuales (asumimos que todos usan enemy.gd y tienen die())
	var current_count := 0
	for child in get_parent().get_children():
		if child is CharacterBody3D and child.has_method("die"):
			current_count += 1

	if current_count >= max_enemies:
		return

	# Elegir una escena de enemigo aleatoria
	var chosen_scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	if chosen_scene == null:
		return

	var enemy: CharacterBody3D = chosen_scene.instantiate() as CharacterBody3D

	# Posición random dentro de un círculo alrededor del spawner
	var angle := randf() * TAU
	var radius := randf() * spawn_area_radius
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

	enemy.global_transform.origin = global_transform.origin + offset
	get_parent().add_child(enemy)
