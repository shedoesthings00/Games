extends PanelContainer

signal closed

var _gs: Node
var _root_split: HSplitContainer
var _list: ItemList
## Misma orden que ítems en ItemList
var _list_rows: Array = []
var _right_column: VBoxContainer
var _reading_scroll: ScrollContainer
var _reading_inner: VBoxContainer
var _detail_title: Label
var _detail_meta: Label
var _detail_body: RichTextLabel
var _reply_area: VBoxContainer
var _selected: Dictionary = {}
var _inside_show_email: bool = false

const COLOR_UNREAD := Color(0.14, 0.18, 0.24)
const COLOR_READ := Color(0.38, 0.42, 0.46)


func _ready() -> void:
	_gs = get_node("/root/GameState")
	_build_ui()
	_gs.emails_updated.connect(_refresh_all)
	_gs.sim_time_changed.connect(_on_time)
	_refresh_all()


func _on_time(_m: int) -> void:
	_refresh_all()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	_root_split = HSplitContainer.new()
	_root_split.split_offset = 300
	margin.add_child(_root_split)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(288, 0)
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.allow_reselect = true
	_list.select_mode = ItemList.SELECT_SINGLE
	_list.item_selected.connect(_on_item_selected)
	_root_split.add_child(_list)

	_right_column = VBoxContainer.new()
	_right_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_split.add_child(_right_column)

	var hdr := HBoxContainer.new()
	_right_column.add_child(hdr)
	var t := Label.new()
	t.text = "Bandeja de entrada"
	t.add_theme_font_size_override("font_size", 18)
	hdr.add_child(t)
	hdr.add_spacer(false)
	var close_btn := Button.new()
	close_btn.text = "Cerrar"
	close_btn.pressed.connect(func(): closed.emit())
	hdr.add_child(close_btn)

	_reading_scroll = ScrollContainer.new()
	_reading_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reading_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_right_column.add_child(_reading_scroll)

	_reading_inner = VBoxContainer.new()
	_reading_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reading_scroll.add_child(_reading_inner)

	_detail_title = Label.new()
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_title.add_theme_font_size_override("font_size", 20)
	_reading_inner.add_child(_detail_title)
	_detail_meta = Label.new()
	_detail_meta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_meta.add_theme_font_size_override("font_size", 13)
	_reading_inner.add_child(_detail_meta)
	_detail_body = RichTextLabel.new()
	_detail_body.bbcode_enabled = false
	_detail_body.fit_content = true
	_detail_body.scroll_active = false
	_detail_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reading_inner.add_child(_detail_body)

	var sep := HSeparator.new()
	_right_column.add_child(sep)

	var reply_hdr := Label.new()
	reply_hdr.text = "Responder"
	reply_hdr.add_theme_font_size_override("font_size", 15)
	_right_column.add_child(reply_hdr)

	var reply_panel := PanelContainer.new()
	reply_panel.custom_minimum_size = Vector2(0, 200)
	reply_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_right_column.add_child(reply_panel)
	_reply_area = VBoxContainer.new()
	reply_panel.add_child(_reply_area)


func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _list_rows.size():
		return
	var e: Dictionary = _list_rows[index] as Dictionary
	_show_email(e)


func _format_row_text(e: Dictionary) -> String:
	var subj: String = str(e.get("subject", ""))
	var from_n: String = str(e.get("from_name", ""))
	var tb: String = str(e.get("time_block", ""))
	return "%s\n%s · %s" % [subj, from_n, tb]


func _rebuild_list() -> void:
	var keep_id: String = ""
	if not _selected.is_empty():
		keep_id = str(_selected.get("email_id", ""))

	_list.clear()
	_list_rows.clear()

	var em_list: Array = _gs.emails_arrived_today()
	for i in range(em_list.size()):
		var e: Dictionary = em_list[i] as Dictionary
		_list_rows.append(e)
		var eid: String = str(e.get("email_id", ""))
		var st: Dictionary = _gs.email_states.get(eid, {}) as Dictionary
		var read: bool = bool(st.get("read", false))
		var idx: int = _list.add_item(_format_row_text(e))
		_list.set_item_custom_fg_color(idx, COLOR_UNREAD if not read else COLOR_READ)

	var restore_idx: int = -1
	if not keep_id.is_empty():
		for j in range(_list_rows.size()):
			var e2: Dictionary = _list_rows[j] as Dictionary
			if str(e2.get("email_id", "")) == keep_id:
				restore_idx = j
				break

	if restore_idx >= 0:
		_list.select(restore_idx)
	else:
		_clear_reading_pane()


func _clear_reading_pane() -> void:
	_selected.clear()
	_detail_title.text = "Seleccione un correo"
	_detail_meta.text = ""
	_detail_body.text = ""
	_clear_reply_area()


func _refresh_all() -> void:
	_rebuild_list()
	if _inside_show_email:
		return
	if _list.get_selected_items().size() > 0:
		var ix: int = _list.get_selected_items()[0]
		if ix >= 0 and ix < _list_rows.size():
			_show_email(_list_rows[ix] as Dictionary)


func _show_email(e: Dictionary) -> void:
	_inside_show_email = true
	_selected = e
	var eid: String = str(e.get("email_id", ""))
	_gs.mark_email_read(eid)

	_detail_title.text = str(e.get("subject", ""))
	_detail_meta.text = "De: %s  ·  Para: %s\n%s  ·  %s" % [
		str(e.get("from_name", "")),
		str(e.get("to_name", "")),
		str(e.get("time_block", "")),
		str(e.get("mailbox", "")),
	]
	_detail_body.text = str(e.get("body", ""))

	_clear_reply_area()
	var st: Dictionary = _gs.email_states.get(eid, {}) as Dictionary
	if bool(st.get("handled", false)):
		var done := Label.new()
		done.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		done.text = "Ya contestado o archivado. El hilo permanece en la lista."
		_reply_area.add_child(done)
		_rebuild_list()
		_inside_show_email = false
		return
	if not bool(e.get("requires_player_reply", false)):
		var ok := Button.new()
		ok.text = "Marcar como gestionado (sin respuesta)"
		ok.pressed.connect(func(): _gs.mark_email_handled(eid); _after_send())
		_reply_area.add_child(ok)
		_rebuild_list()
		_inside_show_email = false
		return
	var rel: String = str(e.get("related_case_id", ""))
	if not rel.is_empty():
		var hint := Label.new()
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.text = "Decida el caso en «Casos» si aún está pendiente. Aquí puede enviar la respuesta al cliente."
		_reply_area.add_child(hint)
	var le := LineEdit.new()
	le.placeholder_text = "Escribir respuesta…"
	le.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reply_area.add_child(le)
	var tpl := str(e.get("reply_template_type", ""))
	_add_template_row(tpl, eid, le)
	var send := Button.new()
	send.text = "Enviar"
	send.pressed.connect(func():
		var body: String = le.text.strip_edges()
		if body.is_empty():
			return
		_gs.send_email_reply(eid, body)
		_after_send()
	)
	_reply_area.add_child(send)
	_rebuild_list()
	_inside_show_email = false


func _after_send() -> void:
	_rebuild_list()
	if _list.get_selected_items().size() > 0:
		var ix: int = _list.get_selected_items()[0]
		if ix >= 0 and ix < _list_rows.size():
			_show_email(_list_rows[ix] as Dictionary)


func _clear_reply_area() -> void:
	for k in range(_reply_area.get_child_count() - 1, -1, -1):
		_reply_area.get_child(k).queue_free()


func _tpl_btn(row: HBoxContainer, label: String, eid: String, body: String) -> void:
	var bt := Button.new()
	bt.text = label
	var bcopy: String = body
	var idcopy: String = eid
	bt.pressed.connect(func(): _gs.send_email_reply(idcopy, bcopy); _after_send())
	row.add_child(bt)


func _add_template_row(tpl: String, eid: String, _le: LineEdit) -> void:
	var row := HBoxContainer.new()
	_reply_area.add_child(row)
	var lbl := Label.new()
	lbl.text = "Plantillas:"
	row.add_child(lbl)
	match tpl:
		"accept_or_reject":
			_tpl_btn(row, "Aceptamos", eid, "Estimado/a cliente: confirmamos que el despacho toma su caso y nos pondremos en contacto con los siguientes pasos.")
			_tpl_btn(row, "Rechazamos", eid, "Estimado/a cliente: agradecemos su confianza; en este momento no podemos asumir este encargo según la política del despacho.")
		"reject_type":
			_tpl_btn(row, "Rechazo política", eid, "Le informamos que este tipo de asunto queda fuera de los servicios que presta el despacho.")
		"reject_budget_or_archive":
			_tpl_btn(row, "Presupuesto", eid, "Le comunicamos que con el presupuesto indicado no podemos iniciar la investigación. Quedamos a disposición si desea replantear el encargo.")
			_tpl_btn(row, "Archivo interno", eid, "Recibido. Registraremos la información para referencia interna sin abrir expediente formal.")
		"accept":
			_tpl_btn(row, "Confirmar cita", eid, "Confirmamos la cita y los datos facilitados. Quedamos atentos a cualquier documentación adicional.")
		"personal_followup":
			_tpl_btn(row, "Seguimos en contacto", eid, "Gracias por su mensaje. Mantendremos la comunicación según lo acordado.")
		_:
			_tpl_btn(row, "Acuse recibido", eid, "Hemos recibido su mensaje y lo tendremos en cuenta. Saludos, Despacho Ortega.")
