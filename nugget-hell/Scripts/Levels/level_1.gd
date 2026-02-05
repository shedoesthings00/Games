extends Node3D

@export var enemy_config: Array[Dictionary] = [
	# { "scene": preload("res://Escenas/Enemy.tscn"), "count": 3 },
]

@onready var room3d: Node3D = $Room3d

@export var powerup_scenes: Array[PackedScene] = []
@export var powerup_chances: Array[float] = []
@export var powerup_drop_chance: float = 0.3

@export var boss_scene: PackedScene
@export var boss_spawn_point_path: NodePath = "BossSpawnPoint"

# Sistema de habitaciones por nivel
@export var rooms_per_level_min: int = 5
@export var rooms_per_level_max: int = 6
@export var door_scene: PackedScene

var enemies_remaining: int
var boss_alive: bool = false

var current_room_index: int = 0
var total_rooms: int = 0
var current_door: Area3D = null

# Si true, el cambio de sala ya se hizo durante la transición; no volver a _start_room al terminar.
var _room_changed_during_transition: bool = false

@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	print("LEVEL_1 _ready")
	randomize()

	total_rooms = randi_range(rooms_per_level_min, rooms_per_level_max)
	current_room_index = 0

	if hud and hud.has_method("hide_boss_health"):
		hud.hide_boss_health()

	if LevelTransition != null and LevelTransition.has_signal("transition_finished"):
		LevelTransition.transition_finished.connect(_on_transition_finished)
	else:
		_start_room()


func _on_transition_finished() -> void:
	if _room_changed_during_transition:
		_room_changed_during_transition = false
		return
	_start_room()


# --- HABITACIONES ---

func _start_room() -> void:
	print("LEVEL_1: empezando habitación ", current_room_index + 1, " de ", total_rooms)

	if room3d and room3d.has_method("regenerate_room"):
		room3d.regenerate_room()

	# Colocar al jugador siempre dentro de la sala (evitar quedar fuera o en paredes)
	_reposition_player_in_room()

	var config_for_room := _get_enemy_config_for_room(current_room_index)

	enemies_remaining = 0
	for cfg in config_for_room:
		if cfg.has("count"):
			enemies_remaining += int(cfg["count"])
	print("LEVEL_1: enemigos en esta habitación =", enemies_remaining)
	_update_hud_enemies()

	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null and spawner.has_method("set_config"):
		spawner.set_config(config_for_room)
	if spawner != null and spawner.has_method("enable_spawning"):
		spawner.enable_spawning()

	_spawn_exit_door()  # puerta ya colocada, pero desactivada


func _reposition_player_in_room() -> void:
	var player := get_node_or_null("Player") as Node3D
	if player == null or room3d == null:
		return
	if not room3d.has_method("get_random_floor_position"):
		return
	var floor_pos: Vector3 = room3d.get_random_floor_position()
	player.global_position = floor_pos


func _get_enemy_config_for_room(room_index: int) -> Array[Dictionary]:
	return enemy_config


# --- PUERTA DE SALIDA ---

func _spawn_exit_door() -> void:
	if door_scene == null:
		print("LEVEL_1: door_scene es null, no se puede crear puerta")
		return

	if current_door and current_door.is_inside_tree():
		current_door.queue_free()
		current_door = null

	var door := door_scene.instantiate() as Area3D

	if room3d and room3d.has_method("get_random_wall_position"):
		var pos: Vector3 = room3d.get_random_wall_position()
		door.global_transform.origin = pos
	else:
		door.global_transform.origin = global_transform.origin

	if door.has_method("activate"):
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
		_spawn_boss_or_finish()
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
	if boss_alive:
		_on_boss_killed()
		return

	enemies_remaining -= 1
	if enemies_remaining < 0:
		enemies_remaining = 0
	print("ENEMIGOS RESTANTES =", enemies_remaining)
	_update_hud_enemies()

	if enemies_remaining == 0:
		_on_room_cleared()


func _on_room_cleared() -> void:
	print("LEVEL_1: habitación limpia")

	if current_room_index >= total_rooms - 1:
		if current_door and current_door.is_inside_tree():
			current_door.queue_free()
			current_door = null
		_spawn_boss_or_finish()
		return

	if current_door and current_door.has_method("activate"):
		current_door.activate()


func _spawn_boss_or_finish() -> void:
	if boss_scene == null:
		print("LEVEL_1: sin boss, siguiente nivel")
		if LevelManager != null:
			LevelManager.load_next_level()
		return

	var spawn_point := get_node_or_null(boss_spawn_point_path)
	var boss: CharacterBody3D = boss_scene.instantiate() as CharacterBody3D

	if spawn_point != null:
		boss.global_transform = spawn_point.global_transform
	else:
		boss.global_transform.origin = global_transform.origin

	add_child(boss)
	boss_alive = true

	if hud and hud.has_method("set_boss_health"):
		hud.set_boss_health(boss.current_health, boss.max_health)

	print("LEVEL_1: boss spawneado")


func update_boss_health(current: int, max_value: int) -> void:
	if hud and hud.has_method("set_boss_health"):
		hud.set_boss_health(current, max_value)


func _on_boss_killed() -> void:
	boss_alive = false
	if hud and hud.has_method("hide_boss_health"):
		hud.hide_boss_health()

	print("LEVEL_1: boss muerto, siguiente nivel")
	if LevelManager != null:
		LevelManager.load_next_level()


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
