extends Node
class_name Inventory

var _counts: Dictionary = {}

func add(product_id: String, amount: int = 1) -> void:
	var current: int = int(_counts.get(product_id, 0))
	_counts[product_id] = current + amount

func consume(product_id: String, amount: int = 1) -> bool:
	var current: int = get_count(product_id)
	if current < amount:
		return false
	var new_value: int = current - amount
	if new_value <= 0:
		_counts.erase(product_id)
	else:
		_counts[product_id] = new_value
	return true

func get_count(product_id: String) -> int:
	return int(_counts.get(product_id, 0))

func all_counts() -> Dictionary:
	return _counts.duplicate(true)

func clear() -> void:
	_counts.clear()

