extends CharacterBody3D

@export var speed: float = 6.5
@export var turn_speed: float = 14.0
@export var stop_strength: float = 22.0

@onready var visual: Node3D = $Visual
@onready var joystick: Node = get_tree().current_scene.find_child("VirtualJoystick", true, false)

@onready var catalog: ProductCatalog = get_tree().current_scene.find_child("ProductCatalog", true, false) as ProductCatalog
@onready var missions_manager: MissionsManager = get_tree().current_scene.find_child("MissionsManager", true, false) as MissionsManager
@onready var shelf_panel: Control = get_tree().current_scene.find_child("ShelfPanel", true, false) as Control
@onready var pickup_feedback: PickupFeedback = get_tree().current_scene.find_child("PickupFeedback", true, false) as PickupFeedback

var inventory: Inventory
var _current_shelf: Shelf
var _is_picking: bool = false

func _ready() -> void:
	add_to_group("player")
	inventory = Inventory.new()
	add_child(inventory)

	# Conectamos el panel (si existe).
	if shelf_panel != null and shelf_panel.has_method("set_catalog") and catalog != null:
		shelf_panel.call("set_catalog", catalog)
	if shelf_panel != null and shelf_panel.has_signal("pickup_pressed"):
		shelf_panel.connect("pickup_pressed", Callable(self, "_on_pickup_pressed"))

	# Conectamos señales de estanterías.
	var shelves: Array[Node] = get_tree().current_scene.find_children("*", "Shelf", true, false)
	for n in shelves:
		var s := n as Shelf
		if s == null:
			continue
		s.player_entered_shelf.connect(_on_player_entered_shelf)
		s.player_exited_shelf.connect(_on_player_exited_shelf)

func _physics_process(delta: float) -> void:
	# Godot devuelve un Vector2 donde:
	# - x: izquierda(-1) / derecha(+1)
	# - y: arriba(-1) / abajo(+1)
	var input_vec := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if joystick != null and joystick.has_method("get_vector"):
		var j: Vector2 = joystick.call("get_vector") as Vector2
		if j.length_squared() > 0.0001:
			input_vec = j
	var input_len: float = minf(1.0, input_vec.length())
	var dir2 := input_vec
	if input_len > 0.0001:
		dir2 = input_vec / input_len
	var dir := Vector3(dir2.x, 0.0, dir2.y)

	if dir.length_squared() > 0.0001:
		velocity.x = dir.x * speed * input_len
		velocity.z = dir.z * speed * input_len

		# Rotamos SOLO el visual para que la cámara no gire.
		var target_yaw := atan2(dir.x, dir.z)
		visual.rotation.y = lerp_angle(visual.rotation.y, target_yaw, turn_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, stop_strength * delta)
		velocity.z = move_toward(velocity.z, 0.0, stop_strength * delta)

	velocity.y = 0.0
	move_and_slide()

func _on_player_entered_shelf(shelf: Shelf) -> void:
	_current_shelf = shelf
	if shelf_panel != null and shelf_panel.has_method("open_for_shelf"):
		shelf_panel.call("open_for_shelf", shelf)

func _on_player_exited_shelf(shelf: Shelf) -> void:
	if _current_shelf == shelf:
		_current_shelf = null
		if shelf_panel != null and shelf_panel.has_method("close"):
			shelf_panel.call("close")

func _on_pickup_pressed(product_id: String) -> void:
	if _is_picking:
		return
	if _current_shelf == null:
		return

	# Solo si el pedido lo necesita.
	if missions_manager == null or not missions_manager.can_collect(product_id):
		if pickup_feedback != null:
			var p_not: ProductData = null
			if catalog != null:
				p_not = catalog.get_product(product_id)
			var n_not: String = product_id
			if p_not != null:
				n_not = p_not.display_name
			pickup_feedback.play_not_needed(n_not)
		return

	var p: ProductData = null
	if catalog != null:
		p = catalog.get_product(product_id)
	var pickup_time: float = 0.2
	if p != null:
		pickup_time = p.pickup_time

	_is_picking = true
	if shelf_panel != null and shelf_panel.has_method("set_pickup_enabled"):
		shelf_panel.call("set_pickup_enabled", false)

	# Barra simple en el panel (si existe).
	var t: float = 0.0
	while t < pickup_time:
		if shelf_panel != null and shelf_panel.has_method("show_progress") and pickup_time > 0.0:
			shelf_panel.call("show_progress", t / pickup_time)
		await get_tree().process_frame
		t += get_process_delta_time()
	if shelf_panel != null and shelf_panel.has_method("hide_progress"):
		shelf_panel.call("hide_progress")

	# Aplica cambios.
	if missions_manager != null and missions_manager.try_collect(product_id):
		inventory.add(product_id, 1)
	else:
		# Por si cambió la misión en medio (raro en single player).
		if pickup_feedback != null:
			pickup_feedback.show_message("Ese producto ya no hace falta")
		if shelf_panel != null and shelf_panel.has_method("set_pickup_enabled"):
			shelf_panel.call("set_pickup_enabled", true)
		_is_picking = false
		return

	# Feedback.
	if pickup_feedback != null:
		var n_ok: String = product_id
		if p != null:
			n_ok = p.display_name
		pickup_feedback.play_pickup(n_ok)

	if shelf_panel != null and shelf_panel.has_method("set_pickup_enabled"):
		shelf_panel.call("set_pickup_enabled", true)
	_is_picking = false
