extends Node
class_name MissionsManager

signal missions_changed()

@export var max_missions: int = 5
@export var spawn_interval_min: float = 3.0
@export var spawn_interval_max: float = 4.0

var missions: Array[Mission] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_mission_id: int = 1

var _catalog: ProductCatalog
var _timer: Timer

func _ready() -> void:
	_rng.randomize()
	_catalog = get_tree().current_scene.find_child("ProductCatalog", true, false) as ProductCatalog

	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)

	_schedule_next()

func can_collect(product_id: String) -> bool:
	for m: Mission in missions:
		if m.needs(product_id):
			return true
	return false

func try_collect(product_id: String) -> bool:
	for m: Mission in missions:
		if m.consume(product_id, 1):
			missions_changed.emit()
			return true
	return false

func remove_mission(mission: Mission) -> void:
	var idx: int = missions.find(mission)
	if idx != -1:
		missions.remove_at(idx)
		missions_changed.emit()

func completed_missions() -> Array[Mission]:
	var out: Array[Mission] = []
	for m: Mission in missions:
		if m.is_complete():
			out.append(m)
	return out

func _on_timeout() -> void:
	if missions.size() < max_missions:
		_spawn_mission()
	_schedule_next()

func _schedule_next() -> void:
	var minv: float = spawn_interval_min
	var maxv: float = spawn_interval_max
	if maxv < minv:
		maxv = minv
	var wait_time: float = _rng.randf_range(minv, maxv)
	_timer.start(wait_time)

func _spawn_mission() -> void:
	var ids: Array[String] = _available_product_ids()
	if ids.is_empty():
		return

	var m := Mission.new()
	m.mission_id = _next_mission_id
	_next_mission_id += 1

	var count_products: int = _rng.randi_range(1, min(3, ids.size()))
	var chosen: Array[String] = []

	while chosen.size() < count_products:
		var pick: String = ids[_rng.randi_range(0, ids.size() - 1)]
		if chosen.has(pick):
			continue
		chosen.append(pick)

	for pid: String in chosen:
		var qty: int = _rng.randi_range(1, 3)
		m.required[pid] = qty
		m.remaining[pid] = qty

	missions.append(m)
	missions_changed.emit()

func _available_product_ids() -> Array[String]:
	var out: Array[String] = []
	if _catalog == null:
		return out
	var products: Array[ProductData] = _catalog.all_products()
	for p: ProductData in products:
		if p != null and p.id.strip_edges() != "":
			out.append(p.id)
	return out

