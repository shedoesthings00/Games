extends StaticBody3D
class_name Shelf

signal player_entered_shelf(shelf: Shelf)
signal player_exited_shelf(shelf: Shelf)

@export var product_ids: PackedStringArray = PackedStringArray()

@onready var trigger: Area3D = $Trigger

func _ready() -> void:
	if trigger != null:
		trigger.body_entered.connect(_on_body_entered)
		trigger.body_exited.connect(_on_body_exited)
	else:
		push_warning("Shelf: falta el nodo hijo Trigger (Area3D) en %s" % name)

func _on_body_entered(body: Node3D) -> void:
	if body != null and body.is_in_group("player"):
		player_entered_shelf.emit(self)

func _on_body_exited(body: Node3D) -> void:
	if body != null and body.is_in_group("player"):
		player_exited_shelf.emit(self)

