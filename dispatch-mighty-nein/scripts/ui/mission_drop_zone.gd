extends Control
## Zona donde soltar héroes arrastrados. El padre (Game) gestiona la lista.

func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return false
	if data.get("type", "") != "hero":
		return false
	var game: Node = get_tree().current_scene
	if game and game.has_method("can_accept_hero"):
		return game.can_accept_hero(data)
	return false

func _drop_data(_position: Vector2, data: Variant) -> void:
	if data == null or typeof(data) != TYPE_DICTIONARY:
		return
	var id: String = str(data.get("id", ""))
	var game: Node = get_tree().current_scene
	if game and game.has_method("add_assigned_hero"):
		game.add_assigned_hero(id)
