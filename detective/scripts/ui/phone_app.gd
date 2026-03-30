extends PanelContainer

signal closed

var _gs: Node
var _list: VBoxContainer
var _detail: RichTextLabel
var _row: HBoxContainer


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_build()
	_gs.calls_updated.connect(_refresh)
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
	t.text = "Teléfono — línea del despacho"
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)
	hdr.add_spacer(false)
	var x := Button.new()
	x.text = "Cerrar"
	x.pressed.connect(func(): closed.emit())
	hdr.add_child(x)
	_list = VBoxContainer.new()
	v.add_child(_list)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.fit_content = true
	_detail.custom_minimum_size = Vector2(0, 80)
	v.add_child(_detail)
	_row = HBoxContainer.new()
	v.add_child(_row)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for c in _row.get_children():
		c.queue_free()
	_detail.text = "Solo se muestran llamadas que ya han «entrado» según la hora del despacho. Avance el tiempo en el escritorio si no aparece ninguna."
	var cls: Array = _gs.calls_arrived_today()
	for i in range(cls.size()):
		var cl: Dictionary = cls[i] as Dictionary
		if str(cl.get("direction", "")) != "inbound":
			continue
		var cid: String = str(cl.get("call_id", ""))
		var cdict: Dictionary = _gs.call_states.get(cid, {}) as Dictionary
		var st: String = str(cdict.get("status", ""))
		if st != "pending":
			continue
		var b := Button.new()
		b.text = "%s — %s (%s)" % [cid, str(cl.get("caller_name", "")), str(cl.get("time_block", ""))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var copy: Dictionary = cl
		b.pressed.connect(func(): _open_call(copy))
		_list.add_child(b)


func _open_call(cl: Dictionary) -> void:
	for c in _row.get_children():
		c.queue_free()
	var cid: String = str(cl.get("call_id", ""))
	_detail.text = "[b]%s[/b]\n%s\nCanal: %s | %s" % [
		str(cl.get("caller_name", "")),
		str(cl.get("purpose", "")),
		str(cl.get("channel", "")),
		"Requiere contestar" if bool(cl.get("answer_required", false)) else "Opcional",
	]
	var a := Button.new()
	a.text = "Contestar"
	a.pressed.connect(func(): _gs.answer_call(cid, true); _refresh())
	_row.add_child(a)
	var mbtn := Button.new()
	mbtn.text = "Perder llamada"
	var stl := StyleBoxFlat.new()
	stl.bg_color = Color(0.45, 0.45, 0.48)
	stl.corner_radius_top_left = 3
	stl.corner_radius_top_right = 3
	stl.corner_radius_bottom_right = 3
	stl.corner_radius_bottom_left = 3
	stl.content_margin_left = 12
	stl.content_margin_right = 12
	mbtn.add_theme_stylebox_override("normal", stl)
	mbtn.pressed.connect(func(): _gs.answer_call(cid, false); _refresh())
	_row.add_child(mbtn)
