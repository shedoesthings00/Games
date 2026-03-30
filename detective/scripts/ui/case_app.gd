extends PanelContainer

signal closed

var _gs: Node
var _list: VBoxContainer
var _scroll: ScrollContainer
var _right: VBoxContainer
var _title: Label
var _body: RichTextLabel
var _policy: Label
var _decision_area: VBoxContainer
var _case_id: String = ""


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
	split.split_offset = 260
	m.add_child(split)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(240, 0)
	split.add_child(_scroll)
	_list = VBoxContainer.new()
	_scroll.add_child(_list)
	_right = VBoxContainer.new()
	split.add_child(_right)
	var hdr := HBoxContainer.new()
	_right.add_child(hdr)
	var t := Label.new()
	t.text = "Gestor de casos"
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)
	hdr.add_spacer(false)
	var x := Button.new()
	x.text = "Cerrar"
	x.pressed.connect(func(): closed.emit())
	hdr.add_child(x)
	_title = Label.new()
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(_title)
	_policy = Label.new()
	_policy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_right.add_child(_policy)
	_body = RichTextLabel.new()
	_body.bbcode_enabled = false
	_body.custom_minimum_size = Vector2(0, 260)
	_body.scroll_active = true
	_right.add_child(_body)
	_decision_area = VBoxContainer.new()
	_decision_area.name = "DecisionArea"
	_right.add_child(_decision_area)


func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	_case_id = ""
	_title.text = "Seleccione un caso"
	_policy.text = ""
	_body.text = ""
	_clear_buttons()
	var case_list: Array = _gs.cases_for_today()
	for i in range(case_list.size()):
		var c: Dictionary = case_list[i] as Dictionary
		var cid: String = str(c.get("case_id", ""))
		var status: String = str(c.get("status", "pending"))
		var client: String = str(c.get("client_name", ""))
		var b := Button.new()
		var mark: String = "● " if status == "pending" else "✓ "
		b.text = "%s%s — %s" % [mark, cid, client]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var copy: Dictionary = c
		b.pressed.connect(func(): _open_case(copy))
		_list.add_child(b)


func _clear_buttons() -> void:
	for i in range(_decision_area.get_child_count() - 1, -1, -1):
		_decision_area.get_child(i).queue_free()


func _open_case(c: Dictionary) -> void:
	_case_id = str(c.get("case_id", ""))
	_clear_buttons()
	var ev: Dictionary = _gs.policy_for_case(c)
	var ok: bool = bool(ev.get("policy_would_accept", false))
	var failed: Array = ev.get("failed_labels", []) as Array
	var fail_txt: String = "—"
	if failed.size() > 0:
		fail_txt = ""
		for fi in range(failed.size()):
			if fi > 0:
				fail_txt += ", "
			fail_txt += str(failed[fi])
	_title.text = "%s — %s" % [_case_id, str(c.get("client_name", ""))]
	_policy.text = (
		"Según normas del despacho (día %d): %s\nIncumplimientos: %s"
		% [_gs.current_day_number(), "encaja en política" if ok else "NO encaja en política", fail_txt]
	)
	var sum_v: Variant = c.get("summary", "")
	var doc: String = str(c.get("documents_expected", ""))
	var txt: String = str(c.get("narrative_body", sum_v))
	_body.text = "%s\n\n— Documentos (placeholder): %s\n— Ciudad: %s | Tipo: %s | Presupuesto: %.0f €\n— Tel: %s | Email: %s" % [
		txt,
		doc,
		str(c.get("city", "")),
		str(c.get("case_type", "")),
		float(c.get("budget_eur", 0.0)),
		str(c.get("client_phone", "—")),
		str(c.get("client_email", "—")),
	]
	var status: String = str(c.get("status", "pending"))
	if status != "pending":
		var done := Label.new()
		done.text = "Estado: %s" % status
		_decision_area.add_child(done)
		return
	var row: HBoxContainer = HBoxContainer.new()
	_decision_area.add_child(row)
	var b1 := Button.new()
	b1.text = "Aceptar"
	b1.pressed.connect(func(): _decide("accepted"))
	row.add_child(b1)
	var b2 := Button.new()
	b2.text = "Rechazar"
	var dang := StyleBoxFlat.new()
	dang.bg_color = Color(0.55, 0.28, 0.28)
	dang.corner_radius_top_left = 3
	dang.corner_radius_top_right = 3
	dang.corner_radius_bottom_right = 3
	dang.corner_radius_bottom_left = 3
	dang.content_margin_left = 12
	dang.content_margin_right = 12
	dang.content_margin_top = 6
	dang.content_margin_bottom = 6
	b2.add_theme_stylebox_override("normal", dang)
	b2.pressed.connect(func(): _decide("rejected"))
	row.add_child(b2)
	if bool(c.get("can_archive_personal", false)):
		var b3 := Button.new()
		b3.text = "Archivar (invest. propia)"
		b3.pressed.connect(func(): _decide("archived"))
		row.add_child(b3)


func _decide(d: String) -> void:
	if _case_id.is_empty():
		return
	_gs.decide_case(_case_id, d)
	_refresh()
	var case_list2: Array = _gs.cases_for_today()
	for j in range(case_list2.size()):
		var c2: Dictionary = case_list2[j] as Dictionary
		if str(c2.get("case_id", "")) == _case_id:
			_open_case(c2)
			break
