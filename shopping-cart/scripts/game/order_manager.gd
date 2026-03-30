extends Node
class_name OrderManager

signal order_changed()

# Pedido: id -> cantidad requerida
var required_order: Dictionary = {}
# Pedido: id -> cantidad que falta (de 0..required)
var remaining_order: Dictionary = {}

func _ready() -> void:
	start_example_order()

func start_example_order() -> void:
	# Pedido de ejemplo (luego lo sustituiremos por un generador de pedidos).
	required_order.clear()
	required_order["milk"] = 2
	required_order["bread"] = 1
	required_order["apple"] = 1
	_reset_remaining_from_required()
	order_changed.emit()

func needs(product_id: String) -> bool:
	return remaining(product_id) > 0

func required(product_id: String) -> int:
	return int(required_order.get(product_id, 0))

func remaining(product_id: String) -> int:
	return int(remaining_order.get(product_id, 0))

func consume_needed(product_id: String, amount: int = 1) -> bool:
	var rem: int = remaining(product_id)
	if rem <= 0:
		return false
	var new_rem: int = rem - amount
	if new_rem < 0:
		new_rem = 0
	remaining_order[product_id] = new_rem
	order_changed.emit()
	return true

func is_complete() -> bool:
	for k in required_order.keys():
		var pid: String = str(k)
		if remaining(pid) > 0:
			return false
	return true

func all_product_ids() -> Array[String]:
	var keys: Array[String] = []
	for k in required_order.keys():
		keys.append(str(k))
	keys.sort()
	return keys

func _reset_remaining_from_required() -> void:
	remaining_order.clear()
	for k in required_order.keys():
		var pid: String = str(k)
		remaining_order[pid] = required(pid)

