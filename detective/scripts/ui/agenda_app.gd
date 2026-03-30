extends PanelContainer

signal closed

var _gs: Node
var _vbox: VBoxContainer


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_build()
	_gs.cases_updated.connect(_refresh)
	_gs.day_changed.connect(func(_a, _b): _refresh())
	_refresh()


func _build() -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	add_child(m)
	_vbox = VBoxContainer.new()
	m.add_child(_vbox)
	var hdr := HBoxContainer.new()
	_vbox.add_child(hdr)
	var t := Label.new()
	t.text = "Agenda del detective (placeholder)"
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)
	hdr.add_spacer(false)
	var x := Button.new()
	x.text = "Cerrar"
	x.pressed.connect(func(): closed.emit())
	hdr.add_child(x)


func _refresh() -> void:
	while _vbox.get_child_count() > 1:
		_vbox.get_child(1).queue_free()
	var day_id: String = _gs.current_day_id()
	var n := Label.new()
	n.text = "Día: %s — citas fijas + casos aceptados" % day_id
	_vbox.add_child(n)
	var appts: Array = _gs.appointments_for_today()
	for i in range(appts.size()):
		var a: Dictionary = appts[i] as Dictionary
		var la := Label.new()
		la.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		la.text = "· %s %s — %s (%s)" % [
			str(a.get("date_relative", "hoy")),
			str(a.get("time_slot", "")),
			str(a.get("client_name", "")),
			str(a.get("appointment_type", "")),
		]
		_vbox.add_child(la)
	var slot: int = 10
	var cases_d: Array = _gs.cases_for_today()
	for k in range(cases_d.size()):
		var c: Dictionary = cases_d[k] as Dictionary
		if str(c.get("status", "")) != "accepted":
			continue
		var lb := Label.new()
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.text = "· [Cita simulada %02d:00] %s — %s" % [slot, str(c.get("case_id", "")), str(c.get("client_name", ""))]
		_vbox.add_child(lb)
		slot += 1
