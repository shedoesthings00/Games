extends Node3D

@export var enemy_config: Array[Dictionary] = [
	# { "scene": preload("res://Escenas/Enemy.tscn"), "count": 3 },
]

const RoomBoundsAdapterScript := preload("res://Scripts/Levels/room_bounds_adapter.gd")

@export var powerup_scenes: Array[PackedScene] = []
@export var powerup_chances: Array[float] = []
@export var powerup_drop_chance: float = 0.3

@export var boss_scene: PackedScene
@export var boss_spawn_point_path: NodePath = "BossSpawnPoint"

# Sistema de habitaciones por nivel
@export var rooms_per_level: int = 5
@export var door_scene: PackedScene
@export var door_node_name_in_rooms: String = "Door"
@export var spawn_door_if_missing_in_room: bool = false

var enemies_remaining: int
var boss_alive: bool = false

var current_room_index: int = 0
var total_rooms: int = 0
var current_door: Area3D = null

var _room_waves: Array = []
var _current_wave_index: int = 0

# Si true, el cambio de sala ya se hizo durante la transición; no volver a _start_room al terminar.
var _room_changed_during_transition: bool = false

@onready var hud: CanvasLayer = $HUD

@onready var room_root: Node3D = $RoomRoot
var current_room_instance: Node3D = null

func _ready() -> void:
	current_room_index = 0
	total_rooms = max(1, rooms_per_level)
	
	var player := get_tree().get_root().find_child("Player", true, false)
	if player:
		player.global_transform.origin = Vector3(0.0, 0.0, 0.0)
	else:
		push_warning("Level_1: Player no encontrado en el árbol de escena.")

	if hud and hud.has_method("hide_boss_health"):
		hud.hide_boss_health()

	if LevelTransition != null and LevelTransition.has_signal("transition_finished"):
		if not LevelTransition.transition_finished.is_connected(_on_transition_finished):
			LevelTransition.transition_finished.connect(_on_transition_finished)

		# Importante: cargar la primera habitación YA (debajo del fade),
		# para que no se vea al player "en el vacío" al iniciar.
		_start_room()
		_room_changed_during_transition = true
	else:
		_start_room()



func _on_transition_finished() -> void:
	if _room_changed_during_transition:
		_room_changed_during_transition = false
		return
	_start_room()


# --- HABITACIONES ---

func _start_room() -> void:
	_clear_room_powerups()

	# borrar habitación anterior
	if current_room_instance and current_room_instance.is_inside_tree():
		current_room_instance.queue_free()
		current_room_instance = null
	current_door = null
	_room_waves = []
	_current_wave_index = 0

	# pedir una sala random que no se haya usado
	var room_path := LevelManager.get_next_room_scene_path()
	var room_scene := load(room_path) as PackedScene
	current_room_instance = room_scene.instantiate() as Node3D
	room_root.add_child(current_room_instance)

	# Crear un helper `Room3D` para spawns/door/limitar movimiento usando bounds del mesh
	var room_helper := Node3D.new()
	room_helper.name = "Room3D"
	room_helper.set_script(RoomBoundsAdapterScript)
	current_room_instance.add_child(room_helper)
	if room_helper.has_method("setup_from_room"):
		room_helper.setup_from_room(current_room_instance)

	# recolocar al player al centro de la sala
	var player := get_tree().get_root().find_child("Player", true, false)
	if player:
		if room_helper.has_method("get_center_position"):
			var c: Vector3 = room_helper.get_center_position()
			player.global_transform.origin = Vector3(c.x, player.global_transform.origin.y, c.z)
		else:
			player.global_transform.origin = Vector3(0.0, player.global_transform.origin.y, 0.0)

	# Puerta de salida (la que ya viene en la room)
	_setup_exit_door_from_room()

	# --- OLEADAS ---
	_room_waves = _get_waves_for_current_room()
	_start_current_wave()


func _clear_room_powerups() -> void:
	# Los powerups se instancian como hijos del nivel (no de la room),
	# así que hay que limpiarlos al cambiar de habitación.
	for n in get_tree().get_nodes_in_group("powerups"):
		if n and n.is_inside_tree():
			n.queue_free()


func _reposition_player_in_room() -> void:
	var player := get_node_or_null("Player") as Node3D
	if player == null:
		return
	var room3d := get_tree().get_root().find_child("Room3D", true, false)
	if room3d == null or not room3d.has_method("get_random_floor_position"):
		return
	player.global_position = room3d.get_random_floor_position()


func _get_enemy_config_for_room(room_index: int) -> Array[Dictionary]:
	return enemy_config


func _get_waves_for_current_room() -> Array:
	# Buscar el nodo `RoomWaves` dentro de la habitación instanciada.
	if current_room_instance == null:
		return []

	var rw := current_room_instance.find_child("RoomWaves", true, false)
	if rw == null:
		return []

	var waves: Variant = rw.get("waves")
	if waves is Array and not (waves as Array).is_empty():
		return waves as Array

	return []


func _start_current_wave() -> void:
	var spawner := get_node_or_null("EnemySpawner")

	var config_for_wave: Array[Dictionary] = []
	var wave_spawn_interval: float = 0.0
	var wave_max_alive: int = 0
	var using_room_waves := _room_waves.size() > 0

	# Si la room tiene oleadas configuradas, usar esa. Si no, fallback a `enemy_config` (1 oleada).
	if _current_wave_index < _room_waves.size():
		var wave: Variant = _room_waves[_current_wave_index]
		# WaveDefinition: entries(Array[SpawnEntry]), spawn_interval, max_alive
		if wave != null:
			if wave.has_method("get"):
				wave_spawn_interval = float(wave.get("spawn_interval"))
				wave_max_alive = int(wave.get("max_alive"))
				var entries: Variant = wave.get("entries")
				if entries is Array:
					for e in entries:
						if e == null:
							continue
						var scn: PackedScene = e.get("scene") as PackedScene
						var cnt: int = int(e.get("count"))
						if scn != null and cnt > 0:
							config_for_wave.append({ "scene": scn, "count": cnt })

	# Fallback: una única oleada con el config global
	if (not using_room_waves) and config_for_wave.is_empty():
		config_for_wave = _get_enemy_config_for_room(current_room_index)
		wave_spawn_interval = 0.0
		wave_max_alive = 0

	# Contador de enemigos restantes en esta oleada
	enemies_remaining = 0
	for cfg in config_for_wave:
		if cfg.has("count"):
			enemies_remaining += int(cfg["count"])
	_update_hud_enemies()

	# Oleada vacía (permitir pasar a la siguiente sin spawns)
	if enemies_remaining == 0:
		call_deferred("_on_wave_cleared")
		return

	# Aplicar parámetros de spawner por oleada (si se han seteado)
	if spawner:
		if wave_spawn_interval > 0.0:
			spawner.spawn_interval = wave_spawn_interval
		if wave_max_alive > 0:
			spawner.max_alive = wave_max_alive

		if spawner.has_method("set_config"):
			spawner.set_config(config_for_wave)

		# El spawner ya se habilita con `LevelTransition.transition_finished`.
		# Si no hay transición (por ejemplo, ejecutando esta escena directamente), habilitarlo aquí.
		if (LevelTransition == null) and spawner.has_method("enable_spawning"):
			spawner.enable_spawning()


# --- PUERTA DE SALIDA ---

func _setup_exit_door_from_room() -> void:
	if current_room_instance == null:
		return

	# 1) Preferencia: nodo con nombre "Door" dentro de la room
	var door_candidate := current_room_instance.find_child(door_node_name_in_rooms, true, false)
	if door_candidate is Area3D:
		current_door = door_candidate as Area3D
	else:
		# 2) Fallback: primer Area3D que emita "door_touched" o tenga método "activate"
		for n in current_room_instance.find_children("*", "Area3D", true, false):
			var a := n as Area3D
			if a == null:
				continue
			if a.has_signal("door_touched") or a.has_method("activate"):
				current_door = a
				break

	if current_door == null:
		if spawn_door_if_missing_in_room:
			_spawn_exit_door()
		else:
			push_warning("Level_1: no se encontró Door en la room y spawn_door_if_missing_in_room=false.")
		return

	# Asegurar desactivada al entrar
	if current_door.has_method("deactivate"):
		current_door.deactivate()
	else:
		current_door.is_active = false

	# Conectar señal una sola vez
	if current_door.has_signal("door_touched"):
		if not current_door.door_touched.is_connected(_on_door_touched):
			current_door.door_touched.connect(_on_door_touched)

func _spawn_exit_door() -> void:
	if door_scene == null:
		push_error("Level_1: door_scene es null; no se puede crear puerta.")
		return

	if current_door and current_door.is_inside_tree():
		current_door.queue_free()
		current_door = null

	var door := door_scene.instantiate() as Area3D

	var room3d := get_tree().get_root().find_child("Room3D", true, false)
	if room3d and room3d.has_method("get_random_wall_position"):
		var pos: Vector3 = room3d.get_random_wall_position()
		door.global_transform.origin = pos
	else:
		door.global_transform.origin = global_transform.origin

	# empieza desactivada
	door.is_active = false

	add_child(door)
	current_door = door

	if door.has_signal("door_touched"):
		door.door_touched.connect(_on_door_touched)


func _on_door_touched() -> void:
	current_room_index += 1

	if current_room_index >= total_rooms:
		if current_door and current_door.is_inside_tree():
			current_door.queue_free()
			current_door = null
		print("LEVEL_1: completadas ", total_rooms, " habitaciones. Cargando Level_2.")
		if LevelManager != null:
			LevelManager.load_next_level()
	else:
		# Cambiar la sala AHORA (mientras vamos a cubrir con la transición) y luego mostrar transición.
		# Así el cambio ocurre con pantalla tapada y al terminar la transición la nueva sala ya está.
		_start_room()
		_room_changed_during_transition = true
		if LevelTransition != null and LevelTransition.has_method("show_level"):
			LevelTransition.show_level("Habitación " + str(current_room_index + 1))


# --- ENEMIGOS / BOSS ---

func _update_hud_enemies() -> void:
	if hud and hud.has_method("set_enemies_remaining"):
		hud.set_enemies_remaining(enemies_remaining)


func on_enemy_killed() -> void:
	enemies_remaining -= 1
	if enemies_remaining < 0:
		enemies_remaining = 0
	_update_hud_enemies()

	if enemies_remaining == 0:
		_on_wave_cleared()

func _on_wave_cleared() -> void:
	# Si hay más oleadas en la room, lanzar la siguiente.
	if _room_waves.size() > 0 and _current_wave_index < _room_waves.size() - 1:
		_current_wave_index += 1
		_start_current_wave()
		return

	# Última oleada completada → se puede activar la puerta.
	_on_room_cleared()


func _on_room_cleared() -> void:
	if current_door == null or not current_door.is_inside_tree():
		_setup_exit_door_from_room()
	if current_door and current_door.has_method("activate"):
		current_door.activate()


# --- POWER UPS ---

func get_powerup_drop() -> PackedScene:
	if powerup_scenes.is_empty():
		return null
	if powerup_drop_chance <= 0.0:
		return null
	if randf() > powerup_drop_chance:
		return null

	var total := 0.0
	if powerup_chances.is_empty():
		# Si no hay chances configuradas, todos tienen el mismo peso
		total = float(powerup_scenes.size())
	else:
		for i in powerup_scenes.size():
			var c := 0.0
			if i < powerup_chances.size():
				c = powerup_chances[i]
			else:
				c = 1.0
			total += c
	if total <= 0.0:
		return null

	var r := randf() * total
	var accum := 0.0

	for i in powerup_scenes.size():
		var c := 0.0
		if powerup_chances.is_empty():
			c = 1.0
		elif i < powerup_chances.size():
			c = powerup_chances[i]
		else:
			c = 1.0

		accum += c
		if r <= accum:
			return powerup_scenes[i]

	return null
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		var pause_menu := get_tree().get_root().find_child("PauseMenu", true, false)
		if pause_menu:
			if get_tree().paused:
				pause_menu.hide_menu()
			else:
				pause_menu.show_menu()
