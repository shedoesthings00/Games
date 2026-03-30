extends Control
## Juego tipo Dispatch: mapa con misiones, arrastrar héroes a la misión, enviar.
## Éxito = descanso 3 s. Fallo = daño; si ya dañado, queda fuera.

@onready var mission_title: Label = $UILayer/MapArea/Margin/MissionCard/MissionTitle
@onready var mission_briefing: Label = $UILayer/MapArea/Margin/MissionCard/MissionBriefing
@onready var req_label: Label = $UILayer/MissionPanel/Margin/VBox/ReqLabel
@onready var drop_zone: Control = $UILayer/MissionPanel/Margin/VBox/DropZone
@onready var assigned_slots: HBoxContainer = $UILayer/MissionPanel/Margin/VBox/AssignedSlots
@onready var team_total_label: Label = $UILayer/MissionPanel/Margin/VBox/TeamTotalLabel
@onready var send_button: Button = $UILayer/MissionPanel/Margin/VBox/SendButton
@onready var hero_list_inner: HBoxContainer = $UILayer/HeroList/HeroListInner
@onready var failures_label: Label = $UILayer/BottomBar/Margin/FailuresLabel
@onready var result_panel: PanelContainer = $UILayer/ResultPanel
@onready var result_title: Label = $UILayer/ResultPanel/Margin/VBox/ResultTitle
@onready var result_detail: Label = $UILayer/ResultPanel/Margin/VBox/ResultDetail
@onready var result_quote: Label = $UILayer/ResultPanel/Margin/VBox/ResultQuote
@onready var continue_button: Button = $UILayer/ResultPanel/Margin/VBox/ContinueButton

var _assigned_hero_ids: Array = []
const MAX_ASSIGNED: int = 3
const HeroCardScript: GDScript = preload("res://scripts/ui/hero_card.gd")

func _ready() -> void:
	# Fondo visible para la zona de soltar
	var drop_bg: ColorRect = ColorRect.new()
	drop_bg.color = Color(0.25, 0.28, 0.35, 0.9)
	drop_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_zone.add_child(drop_bg)
	var drop_hint: Label = Label.new()
	drop_hint.text = "Suelta aquí los héroes (máx. 3)"
	drop_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	drop_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	drop_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	drop_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drop_zone.add_child(drop_hint)
	send_button.pressed.connect(_on_send_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.mission_resolved.connect(_on_mission_resolved)
	GameManager.game_over.connect(_on_game_over)
	GameManager.victory.connect(_on_victory)
	_build_hero_list()
	var wi: int = GameManager.get_current_wave_index()
	var wd: WaveData = WaveManager.get_wave(wi)
	if wd:
		_on_wave_started(wi, wd)
	_refresh_ui()

func can_accept_hero(data: Variant) -> bool:
	if _assigned_hero_ids.size() >= MAX_ASSIGNED:
		return false
	var id: String = str(data.get("id", ""))
	return not _assigned_hero_ids.has(id)

func add_assigned_hero(hero_id: String) -> void:
	if _assigned_hero_ids.size() >= MAX_ASSIGNED:
		return
	if _assigned_hero_ids.has(hero_id):
		return
	_assigned_hero_ids.append(hero_id)
	_refresh_mission_panel()

func remove_assigned_hero(hero_id: String) -> void:
	_assigned_hero_ids.erase(hero_id)
	_refresh_mission_panel()

func _build_hero_list() -> void:
	for c in hero_list_inner.get_children():
		c.queue_free()
	var heroes: Array = HeroManager.get_all_heroes()
	for h in heroes:
		var card: PanelContainer = PanelContainer.new()
		card.set_script(HeroCardScript)
		card.set_meta("hero_id", h.id)
		hero_list_inner.add_child(card)

func _refresh_ui() -> void:
	_refresh_mission_panel()
	_update_failures()
	send_button.disabled = _assigned_hero_ids.is_empty()

func _refresh_mission_panel() -> void:
	# Slots asignados: un mini panel por héroe con nombre y botón quitar
	for c in assigned_slots.get_children():
		c.queue_free()
	for id in _assigned_hero_ids:
		var h: HeroData = HeroManager.get_hero_by_id(str(id))
		var slot: HBoxContainer = HBoxContainer.new()
		var name_lbl: Label = Label.new()
		name_lbl.text = h.display_name if h else "?"
		name_lbl.custom_minimum_size.x = 70.0
		var btn: Button = Button.new()
		btn.text = "✕"
		btn.custom_minimum_size = Vector2(28, 28)
		btn.pressed.connect(_on_remove_assigned.bind(id))
		slot.add_child(name_lbl)
		slot.add_child(btn)
		assigned_slots.add_child(slot)
	# Total de stats del equipo
	if _assigned_hero_ids.is_empty():
		team_total_label.text = "Arrastra héroes aquí. Total: —"
	else:
		var c: int = 0
		var i: int = 0
		var m: int = 0
		var ch: int = 0
		var v: int = 0
		for id in _assigned_hero_ids:
			var hero: HeroData = HeroManager.get_hero_by_id(str(id))
			if hero:
				c += hero.combat
				i += hero.intellect
				m += hero.mobility
				ch += hero.charisma
				v += hero.vigor
		team_total_label.text = "Total equipo: Combate %d, Intelecto %d, Movilidad %d, Carisma %d, Vigor %d" % [c, i, m, ch, v]
	send_button.disabled = _assigned_hero_ids.is_empty()

func _on_remove_assigned(hero_id: String) -> void:
	remove_assigned_hero(hero_id)

func _update_failures() -> void:
	failures_label.text = "Fallos: %d / %d" % [GameManager.get_failure_count(), GameManager.MAX_FAILURES]

func _on_send_pressed() -> void:
	if _assigned_hero_ids.is_empty():
		return
	send_button.disabled = true
	var ids: Array = _assigned_hero_ids.duplicate()
	_assigned_hero_ids.clear()
	_refresh_mission_panel()
	GameManager.send_heroes(ids)

func _on_wave_started(wave_index: int, wave_data: WaveData) -> void:
	var total: int = WaveManager.get_wave_count()
	mission_title.text = "Misión %d / %d" % [wave_index + 1, total]
	mission_briefing.text = wave_data.briefing if wave_data else ""
	req_label.text = "Qué se necesita: " + (wave_data.requirements_description if wave_data and wave_data.requirements_description else "—")
	result_panel.visible = false
	_refresh_ui()

func _on_mission_resolved(success: bool, quote: String, _xp_gained: int, detail: String = "") -> void:
	result_panel.visible = true
	result_title.text = "¡Éxito!" if success else "Fallo"
	result_detail.text = detail
	result_detail.visible = detail != ""
	result_quote.text = quote if quote else ("Misión completada." if success else "La misión ha fallado.")
	_refresh_ui()

func _on_continue_pressed() -> void:
	result_panel.visible = false
	_refresh_ui()

func _on_game_over(_reason: String) -> void:
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _on_victory() -> void:
	get_tree().change_scene_to_file("res://scenes/victory.tscn")
