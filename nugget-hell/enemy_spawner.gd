extends Node3D

@export var enemy_scenes: Array[PackedScene] = []
@export var spawn_area_radius: float = 20.0
@export var spawn_interval: float = 2.0
@export var max_alive: int = 5

var _timer: float = 0.0
var _total_spawned: int = 0
var _total_allowed: int = 0
var _spawning_enabled: bool = false


func _ready() -> void:
	print("ENEMY_SPAWNER _ready")
	if LevelTransition != null and LevelTransition.has_signal("transition_finished"):
		print("ENEMY_SPAWNER: esperando a transition_finished")
		LevelTransition.transition_finished.connect(_on_transition_finished)
	else:
		print("ENEMY_SPAWNER: sin transición, activando directamente")
		_spawning_enabled = true


func set_total_enemies(count: int) -> void:
	_total_allowed = count
	print("ENEMY_SPAWNER: total_allowed =", _total_allowed)


func enable_spawning() -> void:
	_spawning_enabled = true
	print("ENEMY_SPAWNER: spawning habilitado")


func _on_transition_finished() -> void:
	_spawning_enabled = true
	print("ENEMY_SPAWNER: transición terminada, spawning habilitado")


func _physics_process(delta: float) -> void:
	if not _spawning_enabled:
		return

	if _total_allowed > 0 and _total_spawned >= _total_allowed:
		return

	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		_try_spawn_enemy()


func _try_spawn_enemy() -> void:
	if enemy_scenes.is_empty():
		print("ENEMY_SPAWNER: enemy_scenes vacío")
		return

	var current_alive := 0
	for child in get_parent().get_children():
		if child is CharacterBody3D and child.has_method("die"):
			current_alive += 1

	if current_alive >= max_alive:
		print("ENEMY_SPAWNER: max_alive alcanzado:", current_alive)
		return

	if _total_allowed > 0 and _total_spawned >= _total_allowed:
		print("ENEMY_SPAWNER: total permitido alcanzado:", _total_spawned, "/", _total_allowed)
		return

	var chosen_scene: PackedScene = enemy_scenes[randi() % enemy_scenes.size()]
	if chosen_scene == null:
		print("ENEMY_SPAWNER: chosen_scene null")
		return

	var enemy: CharacterBody3D = chosen_scene.instantiate() as CharacterBody3D

	var angle := randf() * TAU
	var radius := randf() * spawn_area_radius
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

	enemy.global_transform.origin = global_transform.origin + offset
	get_parent().add_child(enemy)

	_total_spawned += 1
	print("ENEMY_SPAWNER: enemigo spawneado, total_spawned =", _total_spawned)
