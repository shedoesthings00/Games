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

# Si true, el cambio de sala ya se hizo durante la transición; no volver a _start_room al terminar.
var _room_changed_during_transition: bool = false

@onready var hud: CanvasLayer = $HUD

@onready var room_root: Node3D = $RoomRoot
var current_room_instance: Node3D = null

func _ready() -> void:
	print("LEVEL_1 _ready")
	current_room_index = 0
	total_rooms = max(1, rooms_per_level)
	
	var player := get_tree().get_root().find_child("Player", true, false)
	if player:
		print("LEVEL_1: player encontrado, moviendo al centro")
		player.global_transform.origin = Vector3(0.0, 0.0, 0.0)
	else:
		print("LEVEL_1: player NO encontrado")

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
	# borrar habitación anterior
	if current_room_instance and current_room_instance.is_inside_tree():
		current_room_instance.queue_free()
		current_room_instance = null
	current_door = null

	# pedir una sala random que no se haya usado
	var room_path := LevelManager.get_next_room_scene_path()
	var room_scene := load(room_path) as PackedScene
	current_room_instance = room_scene.instantiate() as Node3D
	room_root.add_child(current_room_instance)
	print("LEVEL_1: habitación cargada:", room_path)

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

	# --- CONFIGURAR ENEMIGOS PARA ESTA HABITACIÓN ---

	var config_for_room := _get_enemy_config_for_room(current_room_index)

	enemies_remaining = 0
	for cfg in config_for_room:
		if cfg.has("count"):
			enemies_remaining += int(cfg["count"])
	print("LEVEL_1: enemigos en esta habitación =", enemies_remaining)
	_update_hud_enemies()

	var spawner := get_node_or_null("EnemySpawner")
	if spawner and spawner.has_method("set_config"):
		spawner.set_config(config_for_room)
	# El spawner ya se habilita con `LevelTransition.transition_finished`.
	# Si no hay transición (por ejemplo, ejecutando esta escena directamente), habilitarlo aquí.
	if (LevelTransition == null) and spawner and spawner.has_method("enable_spawning"):
		spawner.enable_spawning()

	# Puerta de salida (la que ya viene en la room)
	_setup_exit_door_from_room()


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
			print("LEVEL_1: no se encontró Door en la room; no se spawnea otra (spawn_door_if_missing_in_room=false)")
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
		print("LEVEL_1: door_scene es null, no se puede crear puerta")
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
	print("LEVEL_1: puerta tocada, pasando a siguiente habitación")
	current_room_index += 1

	if current_room_index >= total_rooms:
		if current_door and current_door.is_inside_tree():
			current_door.queue_free()
			current_door = null
		print("LEVEL_1: completadas", total_rooms, "habitaciones, cargando Level_2")
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
	print("ENEMIGOS RESTANTES =", enemies_remaining)
	_update_hud_enemies()

	if enemies_remaining == 0:
		_on_room_cleared()


func _on_room_cleared() -> void:
	print("LEVEL_1: habitación limpia")
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
				
	if event.is_action_pressed("debug_change_room"):
		change_room_test()

func change_room_test() -> void:
	print("LEVEL_1: change_room_test llamado")

	if room_root == null:
		print("LEVEL_1: room_root es null, revisa que exista el nodo RoomRoot")
		return

	# borrar habitación anterior
	if current_room_instance and current_room_instance.is_inside_tree():
		print("LEVEL_1: borrando habitación anterior")
		current_room_instance.queue_free()
		current_room_instance = null

	# pedir una sala random al LevelManager
	if LevelManager == null:
		print("LEVEL_1: LevelManager es null")
		return

	var room_path := LevelManager.get_next_room_scene_path()
	print("LEVEL_1: instanciando habitación:", room_path)

	var room_scene := load(room_path) as PackedScene
	if room_scene == null:
		print("LEVEL_1: room_scene es null")
		return

	current_room_instance = room_scene.instantiate() as Node3D
	room_root.add_child(current_room_instance)

	print("LEVEL_1: habitación cambiada OK")
