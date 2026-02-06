extends Node3D

@export var spawn_area_radius: float = 20.0
@export var spawn_interval: float = 2.0
@export var max_alive: int = 5
@export var spawn_marker_scene: PackedScene
@export var spawn_fx_scene: PackedScene

var _timer: float = 0.0
var _spawning_enabled: bool = false
var _pool: Array[Dictionary] = []

func _ready() -> void:
	if LevelTransition != null and LevelTransition.has_signal("transition_finished"):
		if not LevelTransition.transition_finished.is_connected(_on_transition_finished):
			LevelTransition.transition_finished.connect(_on_transition_finished)
	else:
		_spawning_enabled = true


func set_config(config: Array[Dictionary]) -> void:
	_pool.clear()
	_timer = 0.0
	for cfg in config:
		if cfg.has("scene") and cfg.has("count"):
			var scene := cfg["scene"] as PackedScene
			var count := int(cfg["count"])
			if scene != null and count > 0:
				_pool.append({ "scene": scene, "remaining": count })


func enable_spawning() -> void:
	_spawning_enabled = true


func _on_transition_finished() -> void:
	_spawning_enabled = true


func _physics_process(delta: float) -> void:
	if not _spawning_enabled:
		return

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
	# 1) limitar vivos simultáneamente
	var current_alive := 0
	for child in get_parent().get_children():
		if child is CharacterBody3D and child.has_method("die"):
			current_alive += 1
	if current_alive >= max_alive:
		return

	# 2) elegir tipo de enemigo con remaining > 0
	var available_indices: Array[int] = []
	for i in _pool.size():
		if int(_pool[i]["remaining"]) > 0:
			available_indices.append(i)
	if available_indices.is_empty():
		return

	var idx := available_indices[randi() % available_indices.size()]
	var cfg := _pool[idx]
	var scene: PackedScene = cfg["scene"]
	var remaining: int = cfg["remaining"]

	if scene == null or remaining <= 0:
		push_warning("EnemySpawner: escena inválida o remaining <= 0.")
		return

	# 3) Spawn siempre dentro de la sala: usar una posición de suelo válida del Room3D
	var room3d := get_tree().get_root().find_child("Room3D", true, false)
	if room3d == null:
		# Compatibilidad con el nombre antiguo
		room3d = get_tree().get_root().find_child("Room3d", true, false)

	var spawn_position: Vector3
	if room3d and room3d.has_method("get_random_floor_position"):
		spawn_position = room3d.get_random_floor_position()
	else:
		var angle := randf() * TAU
		var radius := randf() * spawn_area_radius
		var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		spawn_position = global_transform.origin + offset

	# 4) Instanciar marcador / sombra si existe
	var marker: Node3D = null
	if spawn_marker_scene != null:
		marker = spawn_marker_scene.instantiate() as Node3D
		marker.global_transform.origin = spawn_position
		get_parent().add_child(marker)

	# 5) Tras 2 segundos, spawnear enemigo y FX
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(func():
		# Enemigo
		var enemy: CharacterBody3D = scene.instantiate() as CharacterBody3D
		enemy.global_transform.origin = spawn_position
		get_parent().add_child(enemy)

		# Reducir remaining de ese tipo
		_pool[idx]["remaining"] = remaining - 1

		# Borrar marcador
		if marker != null and marker.is_inside_tree():
			marker.queue_free()

		# FX de partículas
		if spawn_fx_scene != null:
			var fx_root: Node3D = spawn_fx_scene.instantiate() as Node3D
			fx_root.global_transform.origin = spawn_position
			get_parent().add_child(fx_root)
			_enable_particles_recursive(fx_root)
	)


func _enable_particles_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is GPUParticles3D:
			child.emitting = true
		_enable_particles_recursive(child)
