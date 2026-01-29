extends Area3D

@export var speed: float = 40.0
var move_dir: Vector3 = Vector3.ZERO

func _ready() -> void:
	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized()
	print("BALA ready dir =", move_dir)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += move_dir * speed * delta

	if global_position.length() > 500.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	print("BALA body_entered:", body)
	if body and body.has_method("take_damage"):
		print("BALA hace daño")
		body.take_damage(1)
	queue_free()
