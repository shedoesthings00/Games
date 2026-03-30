extends RefCounted
class_name Mission

var mission_id: int = 0
var required: Dictionary = {} # id -> int
var remaining: Dictionary = {} # id -> int

func all_product_ids() -> Array[String]:
	var keys: Array[String] = []
	for k in required.keys():
		keys.append(str(k))
	keys.sort()
	return keys

func required_qty(product_id: String) -> int:
	return int(required.get(product_id, 0))

func remaining_qty(product_id: String) -> int:
	return int(remaining.get(product_id, 0))

func needs(product_id: String) -> bool:
	return remaining_qty(product_id) > 0

func consume(product_id: String, amount: int = 1) -> bool:
	var rem: int = remaining_qty(product_id)
	if rem <= 0:
		return false
	var new_rem: int = rem - amount
	if new_rem < 0:
		new_rem = 0
	remaining[product_id] = new_rem
	return true

func is_complete() -> bool:
	for k in required.keys():
		var pid: String = str(k)
		if remaining_qty(pid) > 0:
			return false
	return true

