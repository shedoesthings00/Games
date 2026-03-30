extends MeshInstance3D
## Genera la malla de un D20 (icosaedro) para la escena del dado.

func _ready() -> void:
	mesh = _create_icosahedron_mesh(1.0)


static func _create_icosahedron_mesh(radius: float) -> ArrayMesh:
	var phi: float = (1.0 + sqrt(5.0)) * 0.5  # razón áurea
	var inv: float = 1.0 / sqrt(1.0 + phi * phi)
	# 12 vértices del icosaedro normalizados
	var verts := PackedVector3Array([
		Vector3(0, inv, inv * phi) * radius,
		Vector3(0, inv, -inv * phi) * radius,
		Vector3(0, -inv, inv * phi) * radius,
		Vector3(0, -inv, -inv * phi) * radius,
		Vector3(inv, inv * phi, 0) * radius,
		Vector3(-inv, inv * phi, 0) * radius,
		Vector3(inv, -inv * phi, 0) * radius,
		Vector3(-inv, -inv * phi, 0) * radius,
		Vector3(inv * phi, 0, inv) * radius,
		Vector3(-inv * phi, 0, inv) * radius,
		Vector3(inv * phi, 0, -inv) * radius,
		Vector3(-inv * phi, 0, -inv) * radius
	])
	# 20 caras triangulares (vértices en orden CCW visto desde fuera)
	var indices := PackedInt32Array([
		0, 8, 4,  0, 4, 1,  0, 1, 6,  0, 6, 2,  0, 2, 8,
		8, 2, 7,  8, 7, 11, 8, 11, 4,  4, 11, 5,  4, 5, 1,
		1, 5, 10, 1, 10, 6,  6, 10, 3,  6, 3, 2,  2, 3, 7,
		7, 3, 10, 7, 10, 11, 7, 11, 5,  5, 11, 10, 3, 5, 10
	])
	var normals := PackedVector3Array()
	for i in verts.size():
		normals.append(verts[i].normalized())
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am
