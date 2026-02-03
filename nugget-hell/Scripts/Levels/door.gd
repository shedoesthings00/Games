extends Area3D

signal door_touched

@export var is_active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual()

func _on_body_entered(body: Node) -> void:
	if not is_active:
		return
	if body.name == "Player":
		door_touched.emit()

func activate() -> void:
	is_active = true
	_update_visual()

func _update_visual() -> void:
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh == null:
		return

	var base_mat: Material = mesh.get_active_material(0)
	var mat: StandardMaterial3D
	if base_mat is StandardMaterial3D:
		mat = base_mat as StandardMaterial3D
	else:
		mat = StandardMaterial3D.new()
		mesh.set_surface_override_material(0, mat)

	if is_active:
		mat.albedo_color = Color(0, 0, 0, 1)
	else:
		mat.albedo_color = Color(0.1, 0.1, 0.1, 0.5)
