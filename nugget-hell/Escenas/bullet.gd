# bullet.gd
extends RigidBody3D

@export var speed: float = 40.0
var move_dir: Vector3 = Vector3.ZERO

func init_direction(dir: Vector3) -> void:
	move_dir = dir.normalized()
	linear_velocity = move_dir * speed
	print("BALA INIT. move_dir =", move_dir, " vel =", linear_velocity)

func _physics_process(delta: float) -> void:
	if global_position.length() > 500.0:
		queue_free()
