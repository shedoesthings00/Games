extends Area3D

@export var rotation_speed: float = 2.0
@export var powerup_name: String = "PowerUp"

func _ready() -> void:
	# Si conectas desde el editor, no hace falta.
	add_to_group("powerups")
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	rotation.y += rotation_speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		queue_free()
