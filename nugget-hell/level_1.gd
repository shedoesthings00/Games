extends Node3D

@export var enemy_config: Array[Dictionary] = [
	# { "scene": preload("res://Escenas/Enemy.tscn"), "count": 3 },
]

@export var boss_scene: PackedScene
@export var boss_spawn_point_path: NodePath = "BossSpawnPoint"

var enemies_remaining: int
var boss_alive: bool = false

@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	print("LEVEL_1 _ready")

	var total := 0
	for cfg in enemy_config:
		if cfg.has("count"):
			total += int(cfg["count"])
	enemies_remaining = total
	print("LEVEL_1: total enemigos normales =", enemies_remaining)

	_update_hud_enemies()
	if hud and hud.has_method("hide_boss_health"):
		hud.hide_boss_health()

	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null and spawner.has_method("set_config"):
		spawner.set_config(enemy_config)

	if LevelTransition != null and LevelTransition.has_signal("transition_finished"):
		LevelTransition.transition_finished.connect(_on_transition_finished)
	else:
		_activate_spawner()


func _on_transition_finished() -> void:
	_activate_spawner()


func _activate_spawner() -> void:
	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null and spawner.has_method("enable_spawning"):
		spawner.enable_spawning()


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
		_spawn_boss_or_finish()


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
