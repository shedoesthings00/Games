extends PanelContainer

signal closed

var _gs: Node
var _list: ItemList
var _rows: Array = []
var _detail: RichTextLabel


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_build()
	_gs.cases_updated.connect(_refresh)
	_refresh()


func _build() -> void:
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 12)
	m.add_theme_constant_override("margin_top", 10)
	m.add_theme_constant_override("margin_bottom", 10)
	add_child(m)
	var split := HSplitContainer.new()
	split.split_offset = 280
	m.add_child(split)
	_list = ItemList.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.item_selected.connect(_on_pick)
	split.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	var hdr := HBoxContainer.new()
	right.add_child(hdr)
	var t := Label.new()
	t.text = "Historial del día"
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)
	hdr.add_spacer(false)
	var x := Button.new()
	x.text = "Cerrar"
	x.pressed.connect(func(): closed.emit())
	hdr.add_child(x)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(sc)
	_detail = RichTextLabel.new()
	_detail.bbcode_enabled = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail.fit_content = true
	_detail.scroll_active = false
	sc.add_child(_detail)


func _refresh() -> void:
	_list.clear()
	_rows.clear()
	var decided: Array = _gs.cases_decided_today()
	if decided.is_empty():
		_detail.text = "[i]Aún no hay expedientes cerrados hoy.[/i]"
		return
	for i in range(decided.size()):
		var st: Dictionary = decided[i] as Dictionary
		_rows.append(st)
		var status: String = str(st.get("status", ""))
		var line: String = "%s · %s" % [str(st.get("case_id", "")), _status_label(status)]
		var idx: int = _list.add_item(line)
		_list.set_item_tooltip(idx, str(st.get("summary", "")))
	if _rows.size() > 0:
		_list.select(0)
		_show_row(0)


func _status_label(s: String) -> String:
	match s:
		"accepted":
			return "Aceptado"
		"rejected":
			return "Rechazado"
		"archived":
			return "Archivado"
		_:
			return s


func _on_pick(index: int) -> void:
	_show_row(index)


func _show_row(index: int) -> void:
	if index < 0 or index >= _rows.size():
		return
	var st: Dictionary = _rows[index] as Dictionary
	_detail.text = (
		"[b]%s[/b]\nCliente: %s · %s\nTipo: %s · Presupuesto: %.0f €\n\n"
		% [
			str(st.get("case_id", "")),
			str(st.get("client_name", "")),
			str(st.get("city", "")),
			str(st.get("case_type", "")),
			float(st.get("budget_eur", 0)),
		]
	)
	_detail.text += "[b]Resolución:[/b] %s\n" % _status_label(str(st.get("status", "")))
	var nb: String = str(st.get("narrative_body", ""))
	if not nb.is_empty():
		_detail.text += "\n[i]%s[/i]" % nb.replace("[", "«").replace("]", "»")

