extends Panel

signal character_dropped(character_slot)

func _can_drop_data(_at_position, data):
	return data is CharacterSlot

func _drop_data(_at_position, data):
	emit_signal("character_dropped", data)


func _on_character_dropped(character_slot: Variant) -> void:
	pass # Replace with function body.
