extends PanelContainer

signal closed

var _gs: Node
var _list: ItemList
var _rows: Array = []
var _trans_box: RichTextLabel
var _meta: Label
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
	var outer := VBoxContainer.new()
	m.add_child(outer)
	var hdr := HBoxContainer.new()
	outer.add_child(hdr)
	var t := Label.new()
	t.text = "Teléfono — transcripción de llamadas"
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)
	hdr.add_spacer(false)
	var x := Button.new()
	x.text = "Cerrar"
	x.pressed.connect(func(): closed.emit())
	hdr.add_child(x)
	var split := HSplitContainer.new()
	split.split_offset = 260
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(split)
	_list = ItemList.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_pick)
	split.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	_meta = Label.new()
	_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_meta)
	var tlab := Label.new()
	tlab.text = "Transcripción"
	tlab.add_theme_font_size_override("font_size", 13)
	right.add_child(tlab)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(sc)
	_trans_box = RichTextLabel.new()
	_trans_box.bbcode_enabled = false
	_trans_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_trans_box.fit_content = true
	_trans_box.scroll_active = false
	_trans_box.add_theme_color_override("default_color", Color(0.15, 0.18, 0.16))
	sc.add_child(_trans_box)
	_row = HBoxContainer.new()
	right.add_child(_row)


func _status_tag(call_id: String) -> String:
	var cdict: Dictionary = _gs.call_states.get(call_id, {}) as Dictionary
	var st: String = str(cdict.get("status", "pending"))
	match st:
		"pending":
			return "[PENDIENTE]"
		"answered":
			return "[ATENDIDA]"
		"missed":
			return "[PERDIDA]"
		_:
			return "[%s]" % st.to_upper()


func _refresh() -> void:
	_list.clear()
	_rows.clear()
	for c in _row.get_children():
		c.queue_free()
	_meta.text = ""
	_trans_box.text = "Seleccione una llamada de la lista."
	var cls: Array = _gs.calls_arrived_today()
	for i in range(cls.size()):
		var cl: Dictionary = cls[i] as Dictionary
		if str(cl.get("direction", "")) != "inbound":
			continue
		var cid: String = str(cl.get("call_id", ""))
		_rows.append(cl)
		var line: String = "%s  %s\n%s · %s" % [
			cid,
			_status_tag(cid),
			str(cl.get("caller_name", "")),
			str(cl.get("time_block", "")),
		]
		var idx: int = _list.add_item(line)
		_list.set_item_tooltip(idx, str(cl.get("purpose", "")))
	if _rows.size() > 0:
		_list.select(0)
		_show_call(0)
	else:
		_trans_box.text = "Ninguna llamada entrante ha llegado aún según la hora. Avance el tiempo desde el escritorio."


func _on_pick(index: int) -> void:
	_show_call(index)


func _transcript_text(cl: Dictionary) -> String:
	var tr: String = str(cl.get("transcript", "")).strip_edges()
	if tr.is_empty():
		return "[Sin transcripción en archivo]\n\nMotivo registrado: %s\n%s" % [
			str(cl.get("purpose", "")),
			str(cl.get("notes", "")),
		]
	return tr


func _show_call(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	var cl: Dictionary = _rows[index] as Dictionary
	for c in _row.get_children():
		c.queue_free()
	var cid: String = str(cl.get("call_id", ""))
	var cdict: Dictionary = _gs.call_states.get(cid, {}) as Dictionary
	var st: String = str(cdict.get("status", "pending"))
	_meta.text = "%s · %s\n%s | %s | %s" % [
		str(cl.get("caller_name", "")),
		str(cl.get("time_block", "")),
		str(cl.get("channel", "")),
		str(cl.get("purpose", "")),
		"Debe contestar" if bool(cl.get("answer_required", false)) else "Opcional",
	]
	_trans_box.text = _transcript_text(cl)
	if st != "pending":
		var done := Label.new()
		done.text = "Esta llamada ya está cerrada (%s)." % st
		_row.add_child(done)
		return
	if not _gs.call_has_arrived(cid):
		var w := Label.new()
		w.text = "La llamada aún no puede atenderse (hora simulada)."
		_row.add_child(w)
		return
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
