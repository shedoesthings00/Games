extends PanelContainer
## Card de un héroe en la lista inferior. Arrastrable a la misión.
## Asignar hero_id con set_meta("hero_id", id) antes de add_child.

var _hero_id: String = ""
var _state_label: Label
var _name_label: Label
var _stats_label: Label

func _ready() -> void:
	_hero_id = get_meta("hero_id", "")
	custom_minimum_size = Vector2(160, 72)
	var v := VBoxContainer.new()
	_name_label = Label.new()
	_name_label.add_theme_font_size_override("font_size", 14)
	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 11)
	_state_label = Label.new()
	_state_label.add_theme_font_size_override("font_size", 10)
	v.add_child(_name_label)
	v.add_child(_stats_label)
	v.add_child(_state_label)
	add_child(v)
	_update_display()

func _process(_delta: float) -> void:
	_update_state_label()

func _update_display() -> void:
	var h: HeroData = HeroManager.get_hero_by_id(_hero_id)
	if not h:
		return
	_name_label.text = h.display_name
	_stats_label.text = "C:%d I:%d M:%d Ch:%d V:%d" % [h.combat, h.intellect, h.mobility, h.charisma, h.vigor]
	_update_state_label()

func _update_state_label() -> void:
	var h: HeroData = HeroManager.get_hero_by_id(_hero_id)
	if not h:
		return
	if h.is_out:
		_state_label.text = "Fuera"
		_state_label.modulate = Color.RED
	elif h.get_rest_seconds_left() > 0.0:
		_state_label.text = "Descansando %.0fs" % h.get_rest_seconds_left()
		_state_label.modulate = Color.YELLOW
	elif h.is_damaged:
		_state_label.text = "Dañado"
		_state_label.modulate = Color.ORANGE
	else:
		_state_label.text = "OK"
		_state_label.modulate = Color.WHITE

func _get_drag_data(_position: Vector2) -> Variant:
	var h: HeroData = HeroManager.get_hero_by_id(_hero_id)
	if not h or not h.can_be_dispatched():
		return null
	# Preview mientras arrastras
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(120, 40)
	var l := Label.new()
	l.text = h.display_name
	preview.add_child(l)
	set_drag_preview(preview)
	return {"type": "hero", "id": _hero_id}
