extends PanelContainer

signal closed

var _cb_cases: Callable
var _cb_mail: Callable
var _cb_agenda: Callable
var _cb_rules: Callable
var _cb_history: Callable
var _built: bool = false


func configure(
	p_open_cases: Callable,
	p_open_mail: Callable,
	p_open_agenda: Callable,
	p_open_rules: Callable,
	p_open_history: Callable
) -> void:
	_cb_cases = p_open_cases
	_cb_mail = p_open_mail
	_cb_agenda = p_open_agenda
	_cb_rules = p_open_rules
	_cb_history = p_open_history
	if _built:
		return
	_built = true
	_build()


func _os_panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.063, 0.102, 0.063)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.153, 0.275, 0.153)
	return sb


func _header_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.165, 0.275, 0.165)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.2, 0.35, 0.2)
	return sb


func _btn_normal() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.165, 0.275, 0.165)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.2, 0.35, 0.2)
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	return sb


func _build() -> void:
	add_theme_stylebox_override("panel", _os_panel_style())
	var m := MarginContainer.new()
	m.set_anchors_preset(Control.PRESET_FULL_RECT)
	m.add_theme_constant_override("margin_left", 16)
	m.add_theme_constant_override("margin_right", 16)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 14)
	add_child(m)
	var v := VBoxContainer.new()
	m.add_child(v)
	var top := HBoxContainer.new()
	v.add_child(top)
	var hdr := PanelContainer.new()
	hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr.add_theme_stylebox_override("panel", _header_style())
	top.add_child(hdr)
	var ht := HBoxContainer.new()
	hdr.add_child(ht)
	var folder := Label.new()
	folder.text = "■"
	folder.add_theme_color_override("font_color", Color(0.42, 0.67, 0.42))
	ht.add_child(folder)
	var lbl := Label.new()
	lbl.text = "DESPACHO.EXE"
	lbl.add_theme_color_override("font_color", Color(0.42, 0.67, 0.42))
	lbl.add_theme_font_size_override("font_size", 11)
	ht.add_child(lbl)
	ht.add_spacer(false)
	var close := Button.new()
	close.text = "✕"
	close.add_theme_color_override("font_color", Color(0.7, 0.45, 0.45))
	close.add_theme_font_size_override("font_size", 14)
	close.custom_minimum_size = Vector2(36, 28)
	close.pressed.connect(func(): closed.emit())
	top.add_child(close)
	var screen := PanelContainer.new()
	screen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scr_sb := StyleBoxFlat.new()
	scr_sb.bg_color = Color(0.039, 0.078, 0.039)
	scr_sb.set_border_width_all(4)
	scr_sb.border_color = Color(0.153, 0.275, 0.153)
	screen.add_theme_stylebox_override("panel", scr_sb)
	v.add_child(screen)
	var sm := MarginContainer.new()
	sm.set_anchors_preset(Control.PRESET_FULL_RECT)
	sm.add_theme_constant_override("margin_left", 12)
	sm.add_theme_constant_override("margin_right", 12)
	sm.add_theme_constant_override("margin_top", 12)
	sm.add_theme_constant_override("margin_bottom", 12)
	screen.add_child(sm)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	sm.add_child(grid)
	_add_app(grid, "Contratos", "Expedientes", _cb_cases)
	_add_app(grid, "Historial", "Cerrados hoy", _cb_history)
	_add_app(grid, "Correos", "Bandeja", _cb_mail)
	_add_app(grid, "Calendario", "Agenda", _cb_agenda)
	_add_app(grid, "Normas", "Política", _cb_rules)
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", _header_style())
	v.add_child(bar)
	var bt := HBoxContainer.new()
	bar.add_child(bt)
	var led := ColorRect.new()
	led.custom_minimum_size = Vector2(8, 8)
	led.color = Color(0.29, 0.55, 0.29)
	bt.add_child(led)
	var st := Label.new()
	st.text = "SISTEMA: OK   ·   CONECTADO"
	st.add_theme_color_override("font_color", Color(0.42, 0.62, 0.42))
	st.add_theme_font_size_override("font_size", 9)
	bt.add_child(st)


func _add_app(parent: GridContainer, title: String, subtitle: String, cb: Callable) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 88)
	var n := _btn_normal()
	b.add_theme_stylebox_override("normal", n)
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.2, 0.33, 0.2)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_color_override("font_color", Color(0.55, 0.78, 0.55))
	b.add_theme_font_size_override("font_size", 11)
	b.text = "%s\n%s" % [title.to_upper(), subtitle]
	var col := cb
	b.pressed.connect(func():
		if col.is_valid():
			col.call()
	)
	parent.add_child(b)
