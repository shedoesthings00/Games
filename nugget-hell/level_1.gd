extends Node3D

@export var max_enemies: int = 5   # TOTAL que deben morir en este nivel
var enemies_remaining: int

@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	print("LEVEL_1 _ready")
	enemies_remaining = max_enemies
	_update_hud_enemies()

	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null:
		print("LEVEL_1: Spawner encontrado, total =", max_enemies)
		if spawner.has_method("set_total_enemies"):
			spawner.set_total_enemies(max_enemies)
	else:
		print("LEVEL_1: NO se ha encontrado nodo EnemySpawner")

	if LevelTransition != null and LevelTransition.has_signal("transition_finished"):
		print("LEVEL_1: conectando a transition_finished")
		LevelTransition.transition_finished.connect(_on_transition_finished)
	else:
		print("LEVEL_1: sin transición, activando spawner directo")
		_activate_spawner()


func _on_transition_finished() -> void:
	print("LEVEL_1: transición terminada, activando spawner")
	_activate_spawner()


func _activate_spawner() -> void:
	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null and spawner.has_method("enable_spawning"):
		print("LEVEL_1: enable_spawning en EnemySpawner")
		spawner.enable_spawning()
	else:
		print("LEVEL_1: NO se ha podido activar el spawner")


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
