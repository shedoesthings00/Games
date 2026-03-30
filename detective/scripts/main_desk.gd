extends Control

const MailAppScene := preload("res://scenes/ui/mail_app.tscn")
const CaseAppScene := preload("res://scenes/ui/case_app.tscn")
const PhoneAppScene := preload("res://scenes/ui/phone_app.tscn")
const RulesAppScene := preload("res://scenes/ui/rules_app.tscn")
const AgendaAppScene := preload("res://scenes/ui/agenda_app.tscn")
const ContractPaperScene := preload("res://scenes/ui/contract_paper.tscn")
const ComputerShellScene := preload("res://scenes/ui/computer_shell.tscn")
const HistoryAppScene := preload("res://scenes/ui/history_app.tscn")

## Paleta alineada con figma_ui (Desk / madera / pared).
const COL_WALL_TOP := Color(0.165, 0.122, 0.102)
const COL_WALL_BOT := Color(0.239, 0.184, 0.157)
const COL_DESK := Color(0.353, 0.290, 0.227)
const COL_WINDOW := Color(0.102, 0.078, 0.063)

var _gs: Node
var _modal_host: CanvasLayer
var _modal_dimmer: ColorRect
var _modal_center: CenterContainer
var _lbl_day: Label
var _lbl_policy: Label
var _lbl_score: Label
var _lbl_pending: Label
var _lbl_clock: Label
var _end_day_btn: Button
var _summary: AcceptDialog


func _ready() -> void:
	_gs = get_node("/root/GameState")
	theme = load("res://resources/office_theme.tres") as Theme
	_build_chrome()
	_summary = AcceptDialog.new()
	_summary.title = "Fin de jornada"
	add_child(_summary)
	_gs.demo_finished.connect(_on_demo_finished)
	_gs.day_changed.connect(_on_day_refresh)
	_gs.cases_updated.connect(_update_badge)
	_gs.calls_updated.connect(_update_badge)
	_gs.emails_updated.connect(_update_badge)
	_gs.sim_time_changed.connect(_on_sim_time)
	_gs.start_week()


func _build_chrome() -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = COL_WALL_BOT
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)

	var top := PanelContainer.new()
	root.add_child(top)
	var th := HBoxContainer.new()
	top.add_child(th)
	var brand := Label.new()
	brand.text = "Despacho Ortega"
	brand.add_theme_font_size_override("font_size", 18)
	brand.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	th.add_child(brand)
	th.add_spacer(false)
	_lbl_day = Label.new()
	_lbl_day.add_theme_color_override("font_color", Color(0.88, 0.84, 0.76))
	th.add_child(_lbl_day)
	_lbl_policy = Label.new()
	_lbl_policy.add_theme_font_size_override("font_size", 12)
	_lbl_policy.add_theme_color_override("font_color", Color(0.75, 0.7, 0.62))
	th.add_child(_lbl_policy)

	var time_row := HBoxContainer.new()
	root.add_child(time_row)
	_lbl_clock = Label.new()
	_lbl_clock.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75))
	time_row.add_child(_lbl_clock)
	var adv := Button.new()
	adv.text = "Avanzar tiempo (+30 min)"
	adv.pressed.connect(func(): _gs.advance_sim_minutes(30))
	time_row.add_child(adv)

	var wall := PanelContainer.new()
	wall.custom_minimum_size = Vector2(0, 120)
	wall.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var wall_sb := StyleBoxFlat.new()
	wall_sb.bg_color = COL_WALL_TOP.lerp(COL_WALL_BOT, 0.45)
	wall.add_theme_stylebox_override("panel", wall_sb)
	root.add_child(wall)
	var wall_m := MarginContainer.new()
	wall_m.add_theme_constant_override("margin_top", 10)
	wall_m.add_theme_constant_override("margin_bottom", 8)
	wall.add_child(wall_m)
	var wall_row := HBoxContainer.new()
	wall_row.alignment = BoxContainer.ALIGNMENT_CENTER
	wall_m.add_child(wall_row)
	var win := ColorRect.new()
	win.custom_minimum_size = Vector2(160, 72)
	win.color = COL_WINDOW.lerp(Color(0.35, 0.45, 0.55), 0.35)
	wall_row.add_child(win)

	var desk_area := PanelContainer.new()
	desk_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var desk_sb := StyleBoxFlat.new()
	desk_sb.bg_color = COL_DESK
	desk_sb.set_border_width_all(2)
	desk_sb.border_color = Color(0.25, 0.2, 0.16)
	desk_area.add_theme_stylebox_override("panel", desk_sb)
	root.add_child(desk_area)
	var dm := MarginContainer.new()
	dm.set_anchors_preset(Control.PRESET_FULL_RECT)
	dm.add_theme_constant_override("margin_left", 16)
	dm.add_theme_constant_override("margin_right", 16)
	dm.add_theme_constant_override("margin_top", 14)
	dm.add_theme_constant_override("margin_bottom", 14)
	desk_area.add_child(dm)
	var desk_row := HBoxContainer.new()
	desk_row.add_theme_constant_override("separation", 24)
	desk_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dm.add_child(desk_row)
	_add_desk_hotspot(desk_row, "Contratos\n(papel físico)", _open_contract_paper)
	_add_desk_hotspot(desk_row, "Ordenador\n(DETECTIVE OS)", _open_computer)
	_add_desk_hotspot(desk_row, "Teléfono\n(transcripción)", _open_phone)

	var info := VBoxContainer.new()
	root.add_child(info)
	_lbl_score = Label.new()
	_lbl_score.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
	info.add_child(_lbl_score)
	_lbl_pending = Label.new()
	_lbl_pending.add_theme_color_override("font_color", Color(0.85, 0.78, 0.65))
	info.add_child(_lbl_pending)

	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 16)
	root.add_child(foot)
	var hint := Label.new()
	hint.text = "Pulse los objetos del escritorio para trabajar. — Acceso rápido:"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.65, 0.6, 0.52))
	foot.add_child(hint)
	_add_app_btn(foot, "Correo", _open_mail)
	_add_app_btn(foot, "Casos", _open_cases)
	_add_app_btn(foot, "Teléfono", _open_phone)
	_add_app_btn(foot, "Normas", _open_rules)
	_add_app_btn(foot, "Agenda", _open_agenda)
	foot.add_spacer(false)
	_end_day_btn = Button.new()
	_end_day_btn.text = "Fin de jornada"
	_end_day_btn.pressed.connect(_on_end_day)
	foot.add_child(_end_day_btn)

	_modal_host = CanvasLayer.new()
	_modal_host.layer = 10
	add_child(_modal_host)
	_modal_dimmer = ColorRect.new()
	_modal_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_dimmer.color = Color(0, 0, 0, 0.82)
	_modal_dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_dimmer.gui_input.connect(_on_modal_dimmer_input)
	_modal_host.add_child(_modal_dimmer)
	_modal_center = CenterContainer.new()
	_modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_host.add_child(_modal_center)
	_modal_host.visible = false


func _add_desk_hotspot(row: HBoxContainer, subtitle: String, cb: Callable) -> void:
	var wrap := CenterContainer.new()
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(wrap)
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 220)
	b.text = subtitle
	b.add_theme_font_size_override("font_size", 13)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.42, 0.36, 0.3)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.22, 0.18, 0.14)
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	b.add_theme_stylebox_override("normal", sb)
	var sb_h := sb.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.5, 0.43, 0.35)
	b.add_theme_stylebox_override("hover", sb_h)
	b.add_theme_color_override("font_color", Color(0.95, 0.9, 0.82))
	var c := cb
	b.pressed.connect(func():
		if c.is_valid():
			c.call()
	)
	wrap.add_child(b)


func _on_modal_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_close_modal()


func _add_app_btn(parent: HBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(110, 34)
	b.pressed.connect(cb)
	parent.add_child(b)


func _close_modal() -> void:
	for c in _modal_center.get_children():
		c.queue_free()
	_modal_host.visible = false


func _show_modal_panel(p: Control) -> void:
	_close_modal()
	_modal_center.add_child(p)
	_modal_host.visible = true


func _open_mail() -> void:
	var p: PanelContainer = MailAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(760, 520)
	_show_modal_panel(p)


func _open_cases() -> void:
	var p: PanelContainer = CaseAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(760, 520)
	_show_modal_panel(p)


func _open_phone() -> void:
	var p: PanelContainer = PhoneAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(720, 480)
	_show_modal_panel(p)


func _open_rules() -> void:
	var p: PanelContainer = RulesAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(640, 440)
	_show_modal_panel(p)


func _open_agenda() -> void:
	var p: PanelContainer = AgendaAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(560, 400)
	_show_modal_panel(p)


func _open_history() -> void:
	var p: PanelContainer = HistoryAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(640, 420)
	_show_modal_panel(p)


func _open_contract_paper() -> void:
	var p: PanelContainer = ContractPaperScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.manage_cases_requested.connect(_on_contract_manage)
	_show_modal_panel(p)


func _on_contract_manage() -> void:
	_close_modal()
	call_deferred("_open_cases")


func _open_computer() -> void:
	var sh: PanelContainer = ComputerShellScene.instantiate() as PanelContainer
	sh.closed.connect(_close_modal)
	sh.configure(
		Callable(self, "_open_cases"),
		Callable(self, "_open_mail"),
		Callable(self, "_open_agenda"),
		Callable(self, "_open_rules"),
		Callable(self, "_open_history")
	)
	sh.custom_minimum_size = Vector2(560, 460)
	_show_modal_panel(sh)


func _on_day_refresh(_day_id: String, _num: int) -> void:
	var dnum: int = _gs.current_day_number()
	var did: String = _gs.current_day_id()
	var phase: String = ""
	for si in range(_gs.story_days.size()):
		var sd: Dictionary = _gs.story_days[si] as Dictionary
		if str(sd.get("day_id", "")) == did:
			phase = str(sd.get("phase", ""))
			_lbl_policy.text = "Enfoque: %s" % str(sd.get("story_focus", ""))
			break
	_lbl_day.text = "Día %d (%s) · Fase: %s" % [dnum, did, phase]
	_update_clock_label()
	_update_badge()


func _on_sim_time(_m: int) -> void:
	_update_clock_label()
	_update_badge()


func _update_clock_label() -> void:
	_lbl_clock.text = "Hora en el despacho: %s (avance el tiempo para correos y llamadas)" % _gs.format_sim_time()


func _update_badge() -> void:
	_lbl_score.text = "Puntuación trabajo: %d · Errores graves: %d · Pistas metacaso: %d" % [
		_gs.score_trabajo, _gs.errores_graves, _gs.metacase_clues.size()
	]
	var pend_calls: int = _gs.pending_calls().size()
	var pend_cases: int = 0
	var cases_today: Array = _gs.cases_for_today()
	for i in range(cases_today.size()):
		var c: Dictionary = cases_today[i] as Dictionary
		if str(c.get("status", "")) == "pending":
			pend_cases += 1
	_lbl_pending.text = "Pendiente hoy: %d casos sin cerrar · %d llamadas sin atender" % [pend_cases, pend_calls]
	if _gs.demo_ended:
		_end_day_btn.disabled = true
		_end_day_btn.tooltip_text = "Demo de la primera semana completada."
	else:
		_end_day_btn.disabled = not _gs.can_finish_day()
		_end_day_btn.tooltip_text = (
			"Cierra todos los casos, gestiona correos que requieren respuesta y atiende llamadas obligatorias."
			if _end_day_btn.disabled else "Avanza al siguiente día."
		)


func _on_end_day() -> void:
	if not _gs.can_finish_day():
		return
	_summary.title = "Fin de jornada"
	_gs.finish_day()
	var lines: PackedStringArray = _gs.last_summary_lines
	var txt: String = ""
	for i in lines.size():
		if i > 0:
			txt += "\n"
		txt += lines[i]
	_summary.dialog_text = txt
	if _gs.demo_ended:
		_summary.title = "Fin de la demo — primera semana"
	_summary.popup_centered(Vector2i(520, 360))
	_update_badge()


func _on_demo_finished() -> void:
	pass
