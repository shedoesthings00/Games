extends Node2D

@export var min_size: Vector2i = Vector2i(8, 8)
@export var max_size: Vector2i = Vector2i(24, 24)
@export var tile_size: int = 16

# Escenas 3D para cada tipo de "pixel"
@export var red_scene_3d: PackedScene
@export var blue_scene_3d: PackedScene
@export var green_scene_3d: PackedScene

const MIN_PER_TYPE := 5

var room_size: Vector2i
var grid: Array = []      # grid[y][x] = "R","B","G",null
var blocked: Array = []   # blocked[y][x] = true si esa celda no se puede usar


func _ready() -> void:
	randomize()
	room_size = Vector2i(
		randi_range(min_size.x, max_size.x),
		randi_range(min_size.y, max_size.y)
	)
	_generate_grid()
	queue_redraw()


func _generate_grid() -> void:
	grid.clear()
	blocked.clear()

	for y in room_size.y:
		var row: Array = []
		var brow: Array = []
		for x in room_size.x:
			row.append(null)
			brow.append(false)
		grid.append(row)
		blocked.append(brow)

	# Mínimo de cada tipo
	_place_minimum_of_type("R", MIN_PER_TYPE)
	_place_minimum_of_type("B", MIN_PER_TYPE)
	_place_minimum_of_type("G", MIN_PER_TYPE)

	# Rellenar el resto respetando reglas/bloqueos
	for y in room_size.y:
		for x in room_size.x:
			if grid[y][x] == null and not blocked[y][x]:
				_place_pixel(x, y)


func _place_minimum_of_type(t: String, count: int) -> void:
	var placed := 0
	var safety := room_size.x * room_size.y * 5

	while placed < count and safety > 0:
		safety -= 1
		var x = randi_range(0, room_size.x - 1)
		var y = randi_range(0, room_size.y - 1)
		if grid[y][x] != null or blocked[y][x]:
			continue

		if _can_place_type_at(t, x, y):
			grid[y][x] = t
			if t == "G":
				_block_neighbors(x, y)
			placed += 1


func _place_pixel(x: int, y: int) -> void:
	var r = randf()
	var t := ""

	if r < 0.2:
		t = "G"
	elif r < 0.5:
		t = "R"
	else:
		t = "B"

	if _can_place_type_at(t, x, y):
		grid[y][x] = t
		if t == "G":
			_block_neighbors(x, y)


func _can_place_type_at(t: String, x: int, y: int) -> bool:
	if blocked[y][x]:
		return false

	if t == "G":
		# Verde: ni vecinos ocupados ni vecinos bloqueados
		return (not _has_any_neighbor(x, y)) and (not _has_blocked_neighbor(x, y))

	if t == "R":
		# Rojo: necesita azul vecino y no tocar zonas bloqueadas
		return _has_neighbor_of_type(x, y, "B") and (not _has_blocked_neighbor(x, y))

	if t == "B":
		# Azul: no puede tocar zonas bloqueadas
		return not _has_blocked_neighbor(x, y)

	return false


func _has_any_neighbor(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or nx >= room_size.x or ny >= room_size.y:
				continue
			if grid[ny][nx] != null:
				return true
	return false


func _has_neighbor_of_type(x: int, y: int, t: String) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or nx >= room_size.x or ny >= room_size.y:
				continue
			if grid[ny][nx] == t:
				return true
	return false


func _block_neighbors(x: int, y: int) -> void:
	# Marca como bloqueadas todas las celdas alrededor del verde
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or nx >= room_size.x or ny >= room_size.y:
				continue
			if nx == x and ny == y:
				continue
			blocked[ny][nx] = true


func _has_blocked_neighbor(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or nx >= room_size.x or ny >= room_size.y:
				continue
			if blocked[ny][nx]:
				return true
	return false


func _draw() -> void:
	pass
	#var width = room_size.x * tile_size
	#var height = room_size.y * tile_size
	#var center = get_viewport_rect().size / 2.0
	#var top_left = center - Vector2(width, height) / 2.0
#
	## Borde de la habitación
	#draw_rect(Rect2(top_left, Vector2(width, height)), Color.DIM_GRAY, false, 2.0)
#
	## Pixeles de colores
	#for y in room_size.y:
		#for x in room_size.x:
			#var t = grid[y][x]
			#if t == null:
				#continue
#
			#var color = Color.WHITE
			#if t == "R":
				#color = Color.RED
			#elif t == "B":
				#color = Color.BLUE
			#elif t == "G":
				#color = Color.GREEN
#
			#var cell_pos = top_left + Vector2(x * tile_size, y * tile_size)
			#var rect = Rect2(cell_pos, Vector2(tile_size, tile_size))
			#draw_rect(rect, color, true)
			
			# --------- GENERACIÓN 3D A PARTIR DE LA GRID ---------

func spawn_3d_room(parent_3d: Node3D, cell_size: float = 1.0) -> void:
	# Centrar la habitación 3D alrededor del origen
	var offset_x = - (room_size.x * cell_size) / 2.0
	var offset_z = - (room_size.y * cell_size) / 2.0

	for y in room_size.y:
		for x in room_size.x:
			var t = grid[y][x]
			if t == null:
				continue

			var scene: PackedScene = null
			if t == "R":
				scene = red_scene_3d
			elif t == "B":
				scene = blue_scene_3d
			elif t == "G":
				scene = green_scene_3d

			if scene == null:
				continue

			var inst: Node3D = scene.instantiate()
			var px = offset_x + float(x) * cell_size
			var pz = offset_z + float(y) * cell_size
			inst.position = Vector3(px, 0.0, pz)
			parent_3d.add_child(inst)
