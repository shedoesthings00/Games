extends Node3D

# Adaptador simple para rooms "hechas a mano" (sin `Room3D` procedural).
# Expone métodos que el resto del juego ya espera:
# - get_random_floor_position()
# - get_nearest_floor_position()
# - get_random_wall_position()
#
# Calcula bounds recorriendo `MeshInstance3D` de la room instanciada.

@export var padding: float = 1.0
@export var wall_height: float = 1.5
@export var floor_y: float = 0.0
@export var generate_collisions: bool = true

var bounds_min: Vector3 = Vector3.ZERO
var bounds_max: Vector3 = Vector3.ZERO
var _has_bounds: bool = false


func setup_from_room(room: Node) -> void:
	if generate_collisions:
		_ensure_room_collisions(room)
	_has_bounds = _compute_bounds_from_meshes(room)
	if not _has_bounds:
		# Fallback razonable si no hay meshes: caja 20x20 centrada en el root.
		var c := (room as Node3D).global_transform.origin if room is Node3D else global_transform.origin
		bounds_min = c + Vector3(-10.0, 0.0, -10.0)
		bounds_max = c + Vector3(10.0, 0.0, 10.0)
		_has_bounds = true


func get_center_position() -> Vector3:
	return (bounds_min + bounds_max) * 0.5


func get_random_floor_position() -> Vector3:
	var min_x := bounds_min.x + padding
	var max_x := bounds_max.x - padding
	var min_z := bounds_min.z + padding
	var max_z := bounds_max.z - padding

	# Evitar rangos invertidos si la sala es pequeña o el padding es grande.
	if min_x > max_x:
		var mid_x := (bounds_min.x + bounds_max.x) * 0.5
		min_x = mid_x
		max_x = mid_x
	if min_z > max_z:
		var mid_z := (bounds_min.z + bounds_max.z) * 0.5
		min_z = mid_z
		max_z = mid_z

	return Vector3(
		randf_range(min_x, max_x),
		floor_y,
		randf_range(min_z, max_z)
	)


func get_nearest_floor_position(world_pos: Vector3) -> Vector3:
	var min_x := bounds_min.x + padding
	var max_x := bounds_max.x - padding
	var min_z := bounds_min.z + padding
	var max_z := bounds_max.z - padding

	# Mantener Y como está (el player ya está en el plano del suelo).
	return Vector3(
		clamp(world_pos.x, min_x, max_x),
		world_pos.y,
		clamp(world_pos.z, min_z, max_z)
	)


func get_random_wall_position() -> Vector3:
	var min_x := bounds_min.x + padding
	var max_x := bounds_max.x - padding
	var min_z := bounds_min.z + padding
	var max_z := bounds_max.z - padding

	var x := randf_range(min_x, max_x)
	var z := randf_range(min_z, max_z)

	match randi() % 4:
		0:
			x = bounds_min.x
		1:
			x = bounds_max.x
		2:
			z = bounds_min.z
		3:
			z = bounds_max.z

	return Vector3(x, wall_height, z)


func _compute_bounds_from_meshes(room: Node) -> bool:
	if room == null:
		return false

	var meshes := room.find_children("*", "MeshInstance3D", true, false)
	if meshes.is_empty():
		return false

	var min_v := Vector3(1.0e20, 1.0e20, 1.0e20)
	var max_v := Vector3(-1.0e20, -1.0e20, -1.0e20)

	for m in meshes:
		var mi := m as MeshInstance3D
		if mi == null:
			continue

		var aabb := mi.get_aabb()
		var p := aabb.position
		var s := aabb.size

		var corners := [
			Vector3(p.x, p.y, p.z),
			Vector3(p.x + s.x, p.y, p.z),
			Vector3(p.x, p.y + s.y, p.z),
			Vector3(p.x, p.y, p.z + s.z),
			Vector3(p.x + s.x, p.y + s.y, p.z),
			Vector3(p.x + s.x, p.y, p.z + s.z),
			Vector3(p.x, p.y + s.y, p.z + s.z),
			Vector3(p.x + s.x, p.y + s.y, p.z + s.z),
		]

		for c in corners:
			var wc: Vector3 = mi.global_transform * c
			min_v = min_v.min(wc)
			max_v = max_v.max(wc)

	bounds_min = min_v
	bounds_max = max_v
	return true


func _ensure_room_collisions(room: Node) -> void:
	if room == null:
		return

	# Colisiones para paredes y objetos (y también suelo si existe).
	var walls := room.get_node_or_null("Walls")
	if walls != null:
		_add_collisions_in_subtree(walls)

	var objects := room.get_node_or_null("Objects")
	if objects != null:
		# En Objects solo colisiona lo marcado como collidable (la deco no bloquea).
		_add_collisions_in_subtree(objects, true)

	var floor := room.get_node_or_null("Floor")
	if floor is MeshInstance3D:
		_ensure_collision_for_mesh(floor as MeshInstance3D)


func _is_mesh_collidable(mi: MeshInstance3D) -> bool:
	if mi == null:
		return false
	# Metadata generada por tools/generate_layout_rooms.py
	if mi.has_meta("collidable"):
		return bool(mi.get_meta("collidable"))
	# Backwards-compatible: si no hay metadata, asumir que colisiona (comportamiento antiguo).
	return true


func _add_collisions_in_subtree(root: Node, require_collidable_meta: bool = false) -> void:
	if root == null:
		return
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi == null:
			continue
		if require_collidable_meta and not _is_mesh_collidable(mi):
			continue
		_ensure_collision_for_mesh(mi)


func _ensure_collision_for_mesh(mi: MeshInstance3D) -> void:
	if mi == null:
		return

	# Evitar duplicados si ya hay un body.
	if mi.get_node_or_null("CollisionBody") != null:
		return

	var aabb := mi.get_aabb()
	if aabb.size == Vector3.ZERO:
		return

	var body := StaticBody3D.new()
	body.name = "CollisionBody"
	# Defaults explícitos (por si el player usa layer 1).
	body.collision_layer = 1
	body.collision_mask = 1
	mi.add_child(body)

	var cs := CollisionShape3D.new()
	cs.name = "CollisionShape3D"
	body.add_child(cs)

	var shape := BoxShape3D.new()
	shape.size = aabb.size
	cs.shape = shape

	# Centrar la caja según el AABB local del mesh (por si no está centrado en 0,0,0).
	cs.position = aabb.position + (aabb.size * 0.5)

