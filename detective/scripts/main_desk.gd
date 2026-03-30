extends Control

const MailAppScene := preload("res://scenes/ui/mail_app.tscn")
const CaseAppScene := preload("res://scenes/ui/case_app.tscn")
const PhoneAppScene := preload("res://scenes/ui/phone_app.tscn")
const RulesAppScene := preload("res://scenes/ui/rules_app.tscn")
const AgendaAppScene := preload("res://scenes/ui/agenda_app.tscn")

var _gs: Node
var _modal_host: CanvasLayer
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
	bg.color = Color(0.72, 0.74, 0.78)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)
	var top := PanelContainer.new()
	root.add_child(top)
	var th := HBoxContainer.new()
	top.add_child(th)
	var brand := Label.new()
	brand.text = "Despacho Ortega — [PLACEHOLDER LOGO]"
	brand.add_theme_font_size_override("font_size", 20)
	th.add_child(brand)
	th.add_spacer(false)
	_lbl_day = Label.new()
	th.add_child(_lbl_day)
	_lbl_policy = Label.new()
	_lbl_policy.add_theme_font_size_override("font_size", 14)
	th.add_child(_lbl_policy)
	var time_row := HBoxContainer.new()
	root.add_child(time_row)
	_lbl_clock = Label.new()
	time_row.add_child(_lbl_clock)
	var adv := Button.new()
	adv.text = "Avanzar tiempo (+30 min)"
	adv.pressed.connect(func(): _gs.advance_sim_minutes(30))
	time_row.add_child(adv)
	var ph := PanelContainer.new()
	root.add_child(ph)
	var desk := HSplitContainer.new()
	desk.split_offset = 420
	ph.add_child(desk)
	var left := VBoxContainer.new()
	desk.add_child(left)
	var mon := PanelContainer.new()
	left.add_child(mon)
	var mv := VBoxContainer.new()
	mon.add_child(mv)
	var ml := Label.new()
	ml.text = "[Monitor — placeholder]"
	ml.add_theme_font_size_override("font_size", 12)
	mv.add_child(ml)
	var mrect := ColorRect.new()
	mrect.custom_minimum_size = Vector2(360, 200)
	mrect.color = Color(0.35, 0.38, 0.42)
	mv.add_child(mrect)
	var tray := PanelContainer.new()
	left.add_child(tray)
	var tv := VBoxContainer.new()
	tray.add_child(tv)
	var tl := Label.new()
	tl.text = "[Bandeja documentos — placeholder]"
	tv.add_child(tl)
	var trect := ColorRect.new()
	trect.custom_minimum_size = Vector2(360, 72)
	trect.color = Color(0.55, 0.52, 0.48)
	tv.add_child(trect)
	var right := VBoxContainer.new()
	desk.add_child(right)
	var phonep := PanelContainer.new()
	right.add_child(phonep)
	var pv := VBoxContainer.new()
	phonep.add_child(pv)
	var pl := Label.new()
	pl.text = "[Teléfono fijo — placeholder]"
	pv.add_child(pl)
	var prect := ColorRect.new()
	prect.custom_minimum_size = Vector2(280, 140)
	prect.color = Color(0.28, 0.3, 0.32)
	pv.add_child(prect)
	var dock := HBoxContainer.new()
	dock.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(dock)
	_lbl_score = Label.new()
	root.add_child(_lbl_score)
	_lbl_pending = Label.new()
	root.add_child(_lbl_pending)
	_add_app_btn(dock, "Correo", _open_mail)
	_add_app_btn(dock, "Casos", _open_cases)
	_add_app_btn(dock, "Teléfono", _open_phone)
	_add_app_btn(dock, "Normas", _open_rules)
	_add_app_btn(dock, "Agenda", _open_agenda)
	_end_day_btn = Button.new()
	_end_day_btn.text = "Fin de jornada"
	_end_day_btn.pressed.connect(_on_end_day)
	root.add_child(_end_day_btn)
	_modal_host = CanvasLayer.new()
	_modal_host.layer = 10
	add_child(_modal_host)
	_modal_center = CenterContainer.new()
	_modal_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Sin esto el CenterContainer a pantalla completa captura el ratón aun vacío y bloquea el escritorio.
	_modal_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_host.add_child(_modal_center)
	# Capa oculta sin ventanas: evita interceptar el ratón respecto al escritorio.
	_modal_host.visible = false


func _add_app_btn(parent: HBoxContainer, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(140, 40)
	b.pressed.connect(cb)
	parent.add_child(b)


func _close_modal() -> void:
	for c in _modal_center.get_children():
		c.queue_free()
	_modal_host.visible = false


func _open_mail() -> void:
	_close_modal()
	var p: PanelContainer = MailAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(760, 520)
	_modal_center.add_child(p)
	_modal_host.visible = true


func _open_cases() -> void:
	_close_modal()
	var p: PanelContainer = CaseAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(760, 520)
	_modal_center.add_child(p)
	_modal_host.visible = true


func _open_phone() -> void:
	_close_modal()
	var p: PanelContainer = PhoneAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(640, 420)
	_modal_center.add_child(p)
	_modal_host.visible = true


func _open_rules() -> void:
	_close_modal()
	var p: PanelContainer = RulesAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(640, 440)
	_modal_center.add_child(p)
	_modal_host.visible = true


func _open_agenda() -> void:
	_close_modal()
	var p: PanelContainer = AgendaAppScene.instantiate() as PanelContainer
	p.closed.connect(_close_modal)
	p.custom_minimum_size = Vector2(560, 400)
	_modal_center.add_child(p)
	_modal_host.visible = true


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
	_lbl_clock.text = "Hora en el despacho: %s (use el botón para que entren correos y llamadas)" % _gs.format_sim_time()


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
	# Summary ya mostrado por _on_end_day
	pass
