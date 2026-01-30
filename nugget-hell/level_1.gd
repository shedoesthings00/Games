extends Node3D

# Cada entrada: una escena de enemigo y cuántos quieres de ese tipo
@export var enemy_config: Array[Dictionary] = [
	{ "scene": preload("res://Escenas/Enemy1.tscn"), "count": 3 },
	{ "scene": preload("res://Escenas/Enemy2.tscn"), "count": 2 },
]

var enemies_remaining: int

@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	print("LEVEL_1 _ready")

	# Calcular total = suma de todos los counts
	var total := 0
	for cfg in enemy_config:
		if cfg.has("count"):
			total += int(cfg["count"])
	enemies_remaining = total
	print("LEVEL_1: total enemigos =", enemies_remaining)

	_update_hud_enemies()

	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null:
		if spawner.has_method("set_config"):
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
	enemies_remaining -= 1
	if enemies_remaining < 0:
		enemies_remaining = 0
	print("ENEMIGOS RESTANTES =", enemies_remaining)
	_update_hud_enemies()

	if enemies_remaining == 0 and LevelManager != null:
		LevelManager.load_next_level()
