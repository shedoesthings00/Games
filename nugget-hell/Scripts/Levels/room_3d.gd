extends Node3D

@export var grid_size: Vector2i = Vector2i(40, 40)
@export var cell_size: float = 2.0

@export var floor_tile_scene: PackedScene  # tile de suelo (cubo/plane)

@export var red_scene_3d: PackedScene
@export var blue_scene_3d: PackedScene
@export var green_scene_3d: PackedScene

const MIN_PER_TYPE := 5

var floor_grid: Array = []   # bool: hay suelo
var grid: Array = []         # "R","B","G",null
var blocked: Array = []      # para reglas de verdes

@onready var room_root_3d: Node3D = $RoomRoot3D

@export var wall_tile_scene: PackedScene


func _ready() -> void:
	randomize()
	_init_grids()
	_generate_single_complex_room()
	_generate_color_grid()
	_spawn_floor_tiles()
	_spawn_walls()
	_spawn_color_objects()


# --------- INICIALIZACIÓN ---------

func _init_grids() -> void:
	floor_grid.clear()
	grid.clear()
	blocked.clear()

	for y in grid_size.y:
		var row_floor: Array = []
		var row_grid: Array = []
		var row_block: Array = []
		for x in grid_size.x:
			row_floor.append(false)
			row_grid.append(null)
			row_block.append(false)
		floor_grid.append(row_floor)
		grid.append(row_grid)
		blocked.append(row_block)


# --------- 1) UNA SOLA HABITACIÓN COMPLEJA ---------

func _generate_single_complex_room() -> void:
	# Rectángulo base grande centrado
	var base_w = int(grid_size.x * 0.7)
	var base_h = int(grid_size.y * 0.7)
	var x0 = (grid_size.x - base_w) / 2
	var y0 = (grid_size.y - base_h) / 2

	print("Habitación base en (", x0, ",", y0, ") tamaño (", base_w, "x", base_h, ")")
	_fill_rect_floor(x0, y0, base_w, base_h)

	# Crear esquinas recortando sub-rectángulos aleatorios en los bordes
	var cuts = randi_range(3, 6)  # número de recortes/esquinas
	for i in cuts:
		var side = randi() % 4  # 0=izq,1=dcha,2=arriba,3=abajo
		var cut_w = randi_range(int(base_w * 0.15), int(base_w * 0.3))
		var cut_h = randi_range(int(base_h * 0.15), int(base_h * 0.3))

		var cx0 = x0
		var cy0 = y0

		match side:
			0: # izquierda
				cx0 = x0
				cy0 = randi_range(y0, y0 + base_h - cut_h)
			1: # derecha
				cx0 = x0 + base_w - cut_w
				cy0 = randi_range(y0, y0 + base_h - cut_h)
			2: # arriba
				cx0 = randi_range(x0, x0 + base_w - cut_w)
				cy0 = y0
			3: # abajo
				cx0 = randi_range(x0, x0 + base_w - cut_w)
				cy0 = y0 + base_h - cut_h

		print("Recortando esquina ", i, " lado ", side, " en (", cx0, ",", cy0, ") tamaño (", cut_w, "x", cut_h, ")")
		_clear_rect_floor(cx0, cy0, cut_w, cut_h)

		var count := 0
		for y in grid_size.y:
			for x in grid_size.x:
				if floor_grid[y][x]:
					count += 1
		print("Celdas de suelo:", count, "de", grid_size.x * grid_size.y)


func _fill_rect_floor(x0: int, y0: int, w: int, h: int) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x >= 0 and y >= 0 and x < grid_size.x and y < grid_size.y:
				floor_grid[y][x] = true


func _clear_rect_floor(x0: int, y0: int, w: int, h: int) -> void:
	for y in range(y0, y0 + h):
		for x in range(x0, x0 + w):
			if x >= 0 and y >= 0 and x < grid_size.x and y < grid_size.y:
				floor_grid[y][x] = false


# --------- 2) GRID RGB SOBRE SUELO ---------

func _generate_color_grid() -> void:
	_place_minimum_of_type("R", MIN_PER_TYPE)
	_place_minimum_of_type("B", MIN_PER_TYPE)
	_place_minimum_of_type("G", MIN_PER_TYPE)

	for y in grid_size.y:
		for x in grid_size.x:
			if not floor_grid[y][x]:
				continue
			if grid[y][x] == null and not blocked[y][x]:
				_place_pixel(x, y)


func _place_minimum_of_type(t: String, count: int) -> void:
	var placed := 0
	var safety := grid_size.x * grid_size.y * 5

	while placed < count and safety > 0:
		safety -= 1
		var x = randi_range(0, grid_size.x - 1)
		var y = randi_range(0, grid_size.y - 1)

		if not floor_grid[y][x]:
			continue
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
	if not floor_grid[y][x]:
		return false
	if blocked[y][x]:
		return false

	if t == "G":
		return (not _has_any_neighbor(x, y)) and (not _has_blocked_neighbor(x, y))

	if t == "R":
		return _has_neighbor_of_type(x, y, "B") and (not _has_blocked_neighbor(x, y))

	if t == "B":
		return not _has_blocked_neighbor(x, y)

	return false


func _has_any_neighbor(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or nx >= grid_size.x or ny >= grid_size.y:
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
			if nx < 0 or ny < 0 or nx >= grid_size.x or ny >= grid_size.y:
				continue
			if grid[ny][nx] == t:
				return true
	return false


func _block_neighbors(x: int, y: int) -> void:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or ny < 0 or nx >= grid_size.x or ny >= grid_size.y:
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
			if nx < 0 or ny < 0 or nx >= grid_size.x or ny >= grid_size.y:
				continue
			if blocked[ny][nx]:
				return true
	return false


# --------- 3) SPAWN SUELO + OBJETOS ---------

func _spawn_floor_tiles() -> void:
	if floor_tile_scene == null:
		print("AVISO: floor_tile_scene no asignado, no se genera suelo.")
		return

	var offset_x = - (grid_size.x * cell_size) / 2.0
	var offset_z = - (grid_size.y * cell_size) / 2.0

	for y in grid_size.y:
		for x in grid_size.x:
			if not floor_grid[y][x]:
				continue

			var tile := floor_tile_scene.instantiate() as Node3D
			var px = offset_x + float(x) * cell_size
			var pz = offset_z + float(y) * cell_size
			tile.position = Vector3(px, 0.0, pz)
			room_root_3d.add_child(tile)

func _spawn_color_objects() -> void:
	if red_scene_3d == null and blue_scene_3d == null and green_scene_3d == null:
		print("AVISO: no hay escenas 3D asignadas para objetos.")
		return

	var offset_x = - (grid_size.x * cell_size) / 2.0
	var offset_z = - (grid_size.y * cell_size) / 2.0

	for y in grid_size.y:
		for x in grid_size.x:
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
			inst.position = Vector3(px, 0.5, pz)
			room_root_3d.add_child(inst)

func cell_to_world(x: int, y: int) -> Vector3:
	var offset_x = - (grid_size.x * cell_size) / 2.0
	var offset_z = - (grid_size.y * cell_size) / 2.0
	var px = offset_x + float(x) * cell_size
	var pz = offset_z + float(y) * cell_size
	return Vector3(px, 0.0, pz)

func get_random_floor_cell() -> Vector2i:
	var candidates: Array[Vector2i] = []
	for y in grid_size.y:
		for x in grid_size.x:
			if floor_grid[y][x]:
				candidates.append(Vector2i(x, y))

	if candidates.is_empty():
		return Vector2i(0, 0)

	return candidates[randi() % candidates.size()]

func get_random_floor_position() -> Vector3:
	var cell := get_random_floor_cell()
	return cell_to_world(cell.x, cell.y)

func get_nearest_floor_position(world_pos: Vector3) -> Vector3:
	var offset_x = - (grid_size.x * cell_size) / 2.0
	var offset_z = - (grid_size.y * cell_size) / 2.0

	var fx = int(round((world_pos.x - offset_x) / cell_size))
	var fy = int(round((world_pos.z - offset_z) / cell_size))

	fx = clamp(fx, 0, grid_size.x - 1)
	fy = clamp(fy, 0, grid_size.y - 1)

	# Si la celda no es suelo, busca en vecinos
	if not floor_grid[fy][fx]:
		for radius in range(1, 4):
			for dy in range(-radius, radius + 1):
				for dx in range(-radius, radius + 1):
					var nx = fx + dx
					var ny = fy + dy
					if nx < 0 or ny < 0 or nx >= grid_size.x or ny >= grid_size.y:
						continue
					if floor_grid[ny][nx]:
						return cell_to_world(nx, ny)

	# fallback
	return cell_to_world(fx, fy)

func _spawn_walls() -> void:
	print("SPAWN_WALLS llamado, wall_tile_scene =", wall_tile_scene, " room_root_3d =", room_root_3d)

	if wall_tile_scene == null:
		print("AVISO: wall_tile_scene es null, no se generan paredes.")
		return
	if room_root_3d == null:
		print("AVISO: room_root_3d es null, revisa que exista el nodo RoomRoot3D.")
		return

	var offset_x: float = - (grid_size.x * cell_size) / 2.0
	var offset_z: float = - (grid_size.y * cell_size) / 2.0

	var wall_height: float = 3.0          # altura del muro
	var floor_y: float = wall_height * 0.5  # centro del muro en Y

	var wall_count := 0

	for y in grid_size.y:
		for x in grid_size.x:
			if not floor_grid[y][x]:
				continue

			var base_x: float = offset_x + float(x) * cell_size
			var base_z: float = offset_z + float(y) * cell_size

			# LADO +X (derecha): pared en el borde derecho de la celda de suelo.
			if x + 1 >= grid_size.x or not floor_grid[y][x + 1]:
				var wall_right: Node3D = wall_tile_scene.instantiate() as Node3D
				wall_right.position = Vector3(base_x + cell_size * 0.5, floor_y, base_z)
				# Normal mirando hacia +X → interior (suelo) está a -X
				wall_right.rotation_degrees = Vector3(0.0, 90.0, 0.0)
				room_root_3d.add_child(wall_right)
				wall_count += 1

			# LADO -X (izquierda)
			if x - 1 < 0 or not floor_grid[y][x - 1]:
				var wall_left: Node3D = wall_tile_scene.instantiate() as Node3D
				wall_left.position = Vector3(base_x - cell_size * 0.5, floor_y, base_z)
				# Normal mirando hacia -X → interior (suelo) está a +X
				wall_left.rotation_degrees = Vector3(0.0, -90.0, 0.0)
				room_root_3d.add_child(wall_left)
				wall_count += 1

			# LADO +Y (abajo en grid → +Z en mundo)
			if y + 1 >= grid_size.y or not floor_grid[y + 1][x]:
				var wall_down: Node3D = wall_tile_scene.instantiate() as Node3D
				wall_down.position = Vector3(base_x, floor_y, base_z + cell_size * 0.5)
				# Antes 180, ahora al revés:
				wall_down.rotation_degrees = Vector3(0.0, 0.0, 0.0)
				room_root_3d.add_child(wall_down)
				wall_count += 1

			# LADO -Y (arriba en grid → -Z en mundo)
			if y - 1 < 0 or not floor_grid[y - 1][x]:
				var wall_up: Node3D = wall_tile_scene.instantiate() as Node3D
				wall_up.position = Vector3(base_x, floor_y, base_z - cell_size * 0.5)
				# Antes 0, ahora 180:
				wall_up.rotation_degrees = Vector3(0.0, 180.0, 0.0)
				room_root_3d.add_child(wall_up)
				wall_count += 1



	print("PAREDES GENERADAS =", wall_count)
