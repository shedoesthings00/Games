extends Control
## Carta de trabajador arrastrable. Devuelve worker_id al iniciar el drag.

@export var worker_id: String = ""


func _get_drag_data(_at_position: Vector2) -> Variant:
	if worker_id.is_empty():
		return null
	# Solo permitir arrastrar si hay misión revelada y evento activo
	if not GameState:
		return null
	if GameState.eventos_activos.is_empty() or GameState.partida_terminada:
		return null
	var data := {"worker_id": worker_id}
	set_drag_preview(_make_preview())
	return data


func _make_preview() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 48)
	var label := Label.new()
	label.text = "  %s  " % worker_id.capitalize()
	panel.add_child(label)
	return panel
