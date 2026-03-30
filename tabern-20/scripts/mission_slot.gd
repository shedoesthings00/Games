extends Control
## Casilla de la misión donde se suelta un trabajador para asignarlo.
## Emite worker_assigned(worker_id) al soltar.

signal worker_assigned(worker_id: String)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and data.get("worker_id", "") is String:
		return len(data["worker_id"]) > 0
	return false


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data is Dictionary:
		var wid: String = data.get("worker_id", "")
		if len(wid) > 0:
			worker_assigned.emit(wid)
