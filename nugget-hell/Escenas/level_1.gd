extends Node3D

@export var max_enemies: int = 2   # TOTAL que deben morir en este nivel
var enemies_remaining: int

@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	enemies_remaining = max_enemies
	_update_hud_enemies()

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
		LevelManager.load_next_level()
