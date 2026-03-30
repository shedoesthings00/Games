extends PanelContainer

signal closed

var _gs: Node
var _labels: VBoxContainer


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_build()
	_gs.day_changed.connect(func(_d, _n): _refresh())
	_refresh()


func _build() -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	add_child(m)
	var v := VBoxContainer.new()
	m.add_child(v)
	var hdr := HBoxContainer.new()
	v.add_child(hdr)
	var t := Label.new()
	t.text = "Normas del despacho (vigentes hoy)"
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)
	hdr.add_spacer(false)
	var x := Button.new()
	x.text = "Cerrar"
	x.pressed.connect(func(): closed.emit())
	hdr.add_child(x)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(600, 360)
	v.add_child(sc)
	_labels = VBoxContainer.new()
	sc.add_child(_labels)


func _refresh() -> void:
	for c in _labels.get_children():
		c.queue_free()
	var day: int = _gs.current_day_number()
	var rules: Array = RulesService.rules_for_day(_gs.office_rules, day)
	for j in range(rules.size()):
		var r: Dictionary = rules[j] as Dictionary
		if not bool(r.get("player_visible", true)):
			continue
		var l := Label.new()
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var rt: String = str(r.get("rule_type", ""))
		l.text = "— %s (%s): campo «%s» — %s «%s» · Días %s–%s" % [
			str(r.get("label", "")),
			rt,
			str(r.get("field", "")),
			str(r.get("operator", "")),
			str(r.get("value", "")),
			str(r.get("day_start", "")),
			str(r.get("day_end", "")),
		]
		_labels.add_child(l)
	if _labels.get_child_count() == 0:
		var l2 := Label.new()
		l2.text = "(No hay normas visibles para el jugador en este día.)"
		_labels.add_child(l2)
