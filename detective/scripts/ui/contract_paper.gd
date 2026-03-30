extends PanelContainer

signal closed
signal manage_cases_requested

var _gs: Node
var _list: ItemList
var _list_rows: Array = []
var _scroll: ScrollContainer
var _inner: VBoxContainer


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_build()
	_gs.cases_updated.connect(_refresh)
	_refresh()


func _paper_color() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.925, 0.878, 0.753)
	sb.set_border_width_all(6)
	sb.border_color = Color(0.8, 0.753, 0.612)
	return sb


func _build() -> void:
	add_theme_stylebox_override("panel", _paper_color())
	var outer := MarginContainer.new()
	outer.set_anchors_preset(Control.PRESET_FULL_RECT)
	outer.add_theme_constant_override("margin_left", 10)
	outer.add_theme_constant_override("margin_right", 10)
	outer.add_theme_constant_override("margin_top", 10)
	outer.add_theme_constant_override("margin_bottom", 10)
	add_child(outer)
	var root := HSplitContainer.new()
	root.split_offset = 220
	outer.add_child(root)
	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(200, 0)
	var lp_sb := StyleBoxFlat.new()
	lp_sb.bg_color = Color(0.95, 0.9, 0.78)
	lp_sb.set_border_width_all(2)
	lp_sb.border_color = Color(0.6, 0.55, 0.45)
	list_panel.add_theme_stylebox_override("panel", lp_sb)
	root.add_child(list_panel)
	var lv := VBoxContainer.new()
	list_panel.add_child(lv)
	var lh := Label.new()
	lh.text = "Expedientes hoy"
	lh.add_theme_font_size_override("font_size", 12)
	lh.add_theme_color_override("font_color", Color(0.16, 0.1, 0.04))
	lv.add_child(lh)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_pick)
	lv.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	var hdr := HBoxContainer.new()
	right.add_child(hdr)
	var close := Button.new()
	close.text = "✕"
	close.custom_minimum_size = Vector2(44, 36)
	var cb := StyleBoxFlat.new()
	cb.bg_color = Color(0.769, 0.204, 0.176)
	cb.set_border_width_all(4)
	cb.border_color = Color(0.58, 0.14, 0.125)
	close.add_theme_stylebox_override("normal", cb)
	close.add_theme_color_override("font_color", Color.WHITE)
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(func(): closed.emit())
	hdr.add_child(close)
	hdr.add_spacer(false)
	var t := Label.new()
	t.text = "CONTRATO DE SERVICIOS — EL DESPACHO"
	t.add_theme_font_size_override("font_size", 16)
	t.add_theme_color_override("font_color", Color(0.16, 0.1, 0.04))
	hdr.add_child(t)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(_scroll)
	_inner = VBoxContainer.new()
	_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_inner)
	var manage := Button.new()
	manage.text = "Gestionar expediente en el sistema"
	manage.pressed.connect(func(): manage_cases_requested.emit())
	right.add_child(manage)


func _refresh() -> void:
	_list.clear()
	_list_rows.clear()
	_clear_inner()
	var cases: Array = _gs.cases_for_today()
	for i in range(cases.size()):
		var st: Dictionary = cases[i] as Dictionary
		_list_rows.append(st)
		var sub: String = str(st.get("summary", str(st.get("case_id", ""))))
		if sub.length() > 40:
			sub = sub.substr(0, 37) + "…"
		var idx: int = _list.add_item("%s\n%s" % [str(st.get("case_id", "")), sub])
		var pend: bool = str(st.get("status", "pending")) == "pending"
		_list.set_item_custom_fg_color(idx, Color(0.1, 0.08, 0.06) if pend else Color(0.35, 0.32, 0.28))
	if _list_rows.size() > 0:
		_list.select(0)
		_show_case(0)
	else:
		var empty := Label.new()
		empty.text = "No hay contratos en la bandeja de hoy."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_inner.add_child(empty)


func _clear_inner() -> void:
	for k in range(_inner.get_child_count() - 1, -1, -1):
		_inner.get_child(k).queue_free()


func _on_pick(index: int) -> void:
	_show_case(index)


func _show_case(index: int) -> void:
	if index < 0 or index >= _list_rows.size():
		return
	var st: Dictionary = _list_rows[index] as Dictionary
	_clear_inner()
	var title := Label.new()
	title.text = st.get("case_id", "")
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.16, 0.1, 0.04))
	_inner.add_child(title)
	var meta := Label.new()
	meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	meta.text = "Cliente: %s · %s\nTipo: %s · Presupuesto: %.0f €\nEstado: %s" % [
		str(st.get("client_name", "")),
		str(st.get("city", "")),
		str(st.get("case_type", "")),
		float(st.get("budget_eur", 0)),
		str(st.get("status", "pending")),
	]
	meta.add_theme_color_override("font_color", Color(0.25, 0.2, 0.14))
	_inner.add_child(meta)
	var sep := HSeparator.new()
	_inner.add_child(sep)
	var desc_l := Label.new()
	desc_l.text = "Descripción / encargo"
	desc_l.add_theme_font_size_override("font_size", 14)
	desc_l.add_theme_color_override("font_color", Color(0.16, 0.1, 0.04))
	_inner.add_child(desc_l)
	var body := RichTextLabel.new()
	body.bbcode_enabled = false
	body.fit_content = true
	body.scroll_active = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var nb: String = str(st.get("narrative_body", st.get("summary", "")))
	body.text = nb
	body.add_theme_color_override("default_color", Color(0.12, 0.1, 0.08))
	_inner.add_child(body)
	if bool(st.get("is_metacase", false)):
		var stamp := Label.new()
		stamp.text = "⚠ METACASO / ALERTA"
		stamp.add_theme_color_override("font_color", Color(0.77, 0.2, 0.15))
		_inner.add_child(stamp)
