extends PanelContainer

@onready var title: Label = %OrderTitle
@onready var hbox: HBoxContainer = %MissionsHBox

var _catalog: ProductCatalog
var _missions: MissionsManager

func _ready() -> void:
	_catalog = get_tree().current_scene.find_child("ProductCatalog", true, false) as ProductCatalog
	_missions = get_tree().current_scene.find_child("MissionsManager", true, false) as MissionsManager

	title.text = "Misiones"
	if _missions != null:
		_missions.missions_changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	if hbox != null:
		for c in hbox.get_children():
			c.queue_free()

	# Si aún no hay misiones, no mostramos nada (sin "Esperando...").
	if _missions == null or _missions.missions.is_empty():
		visible = false
		return

	visible = true

	for m: Mission in _missions.missions:
		hbox.add_child(_build_mission_card(m))

func _build_mission_card(m: Mission) -> Control:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(v)

	var header := Label.new()
	header.text = "Misión #%d" % m.mission_id
	v.add_child(header)

	for pid: String in m.all_product_ids():
		var req: int = m.required_qty(pid)
		if req <= 0:
			continue
		var rem: int = m.remaining_qty(pid)
		var got: int = req - rem
		if got < 0:
			got = 0
		if got > req:
			got = req

		var name: String = pid
		if _catalog != null:
			var p: ProductData = _catalog.get_product(pid)
			if p != null:
				name = p.display_name

		var prefix: String = "✓" if rem <= 0 else "•"
		var line := Label.new()
		line.text = "%s %s %d/%d" % [prefix, name, got, req]
		v.add_child(line)

	return card

