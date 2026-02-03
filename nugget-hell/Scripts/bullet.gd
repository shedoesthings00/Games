extends Area3D

@export var speed: float = 40.0
var move_dir: Vector3 = Vector3.ZERO

func init_direction(dir: Vector3) -> void:
	move_dir = dir.normalized()
	print("BALA init_direction dir =", move_dir)

func _ready() -> void:
	print("BALA ready dir =", move_dir)

func _physics_process(delta: float) -> void:
	global_position += move_dir * speed * delta

func _on_body_entered(body: Node3D) -> void:
	print("BALA body_entered:", body, " name =", body.name)

	# No hacer nada si chocamos con el Player
	if body.name == "Player":
		return

	# Hacer daño solo a enemigos con take_damage
	if body and body.has_method("take_damage"):
		print("BALA hace daño a", body.name)
		body.take_damage(1)

	queue_free()
