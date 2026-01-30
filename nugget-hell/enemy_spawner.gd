extends Node3D

@export var spawn_area_radius: float = 20.0
@export var spawn_interval: float = 2.0
@export var max_alive: int = 5

var _timer: float = 0.0
var _spawning_enabled: bool = false

# Lista de diccionarios: { "scene": PackedScene, "remaining": int }
var _pool: Array[Dictionary] = []


func _ready() -> void:
	print("ENEMY_SPAWNER _ready")
	if LevelTransition != null and LevelTransition.has_signal("transition_finished"):
		LevelTransition.transition_finished.connect(_on_transition_finished)
	else:
		_spawning_enabled = true


func set_config(config: Array[Dictionary]) -> void:
	_pool.clear()
	for cfg in config:
		if cfg.has("scene") and cfg.has("count"):
			var scene := cfg["scene"] as PackedScene
			var count := int(cfg["count"])
			if scene != null and count > 0:
				_pool.append({ "scene": scene, "remaining": count })
	print("ENEMY_SPAWNER: config =", _pool)


func enable_spawning() -> void:
	_spawning_enabled = true
	print("ENEMY_SPAWNER: spawning habilitado")


func _on_transition_finished() -> void:
	_spawning_enabled = true
	print("ENEMY_SPAWNER: transición terminada, spawning habilitado")


func _physics_process(delta: float) -> void:
	if not _spawning_enabled:
		return

	# Si ya no queda ningún tipo con remaining > 0, paramos
	var any_remaining := false
	for cfg in _pool:
		if int(cfg["remaining"]) > 0:
			any_remaining = true
			break
	if not any_remaining:
		return

	_timer -= delta
	if _timer <= 0.0:
		_timer = spawn_interval
		_try_spawn_enemy()


func _try_spawn_enemy() -> void:
	# Limitar vivos simultáneamente
	var current_alive := 0
	for child in get_parent().get_children():
		if child is CharacterBody3D and child.has_method("die"):
			current_alive += 1
	if current_alive >= max_alive:
		return

	# Construir lista de índices con remaining > 0
	var available_indices: Array[int] = []
	for i in _pool.size():
		if int(_pool[i]["remaining"]) > 0:
			available_indices.append(i)
	if available_indices.is_empty():
		return

	# Elegir tipo de enemigo aleatorio entre los que quedan
	var idx := available_indices[randi() % available_indices.size()]
	var cfg := _pool[idx]
	var scene: PackedScene = cfg["scene"]
	var remaining: int = cfg["remaining"]

	if scene == null or remaining <= 0:
		return

	var enemy: CharacterBody3D = scene.instantiate() as CharacterBody3D

	var angle := randf() * TAU
	var radius := randf() * spawn_area_radius
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)

	enemy.global_transform.origin = global_transform.origin + offset
	get_parent().add_child(enemy)

	# Reducir remaining para ese tipo
	_pool[idx]["remaining"] = remaining - 1
