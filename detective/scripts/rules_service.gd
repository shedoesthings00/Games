class_name RulesService
extends RefCounted


static func rules_for_day(office_rules: Array, day_number: int) -> Array:
	var out: Array = []
	for i in range(office_rules.size()):
		var raw: Variant = office_rules[i]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var r: Dictionary = raw as Dictionary
		var rs: int = int(r.get("day_start", 0))
		var re: int = int(r.get("day_end", 99))
		if day_number >= rs and day_number <= re:
			out.append(r)
	return out


static func case_field(case_data: Dictionary, field: String) -> Variant:
	match field:
		"ciudad":
			return str(case_data.get("city", ""))
		"presupuesto":
			return float(case_data.get("budget_eur", 0.0))
		"tipo_caso":
			return str(case_data.get("case_type", ""))
		"telefono":
			return str(case_data.get("client_phone", ""))
		"email":
			return str(case_data.get("client_email", ""))
		_:
			return null


static func _check_operator(op: String, field_val: Variant, rule_val: String) -> bool:
	match op:
		"in":
			var parts: PackedStringArray = rule_val.split("|")
			var fv: String = str(field_val)
			for p in parts:
				if p.strip_edges() == fv:
					return true
			return false
		">=":
			return float(field_val) >= float(rule_val)
		"not_empty":
			return str(field_val).strip_edges().length() > 0
		"prefer_repeat", "matches_city":
			return true
		_:
			return true


static func evaluate(case_data: Dictionary, day_number: int, office_rules: Array) -> Dictionary:
	var failed: Array = []
	var active: Array = rules_for_day(office_rules, day_number)
	for j in range(active.size()):
		var r: Dictionary = active[j] as Dictionary
		var rt: String = str(r.get("rule_type", ""))
		var op: String = str(r.get("operator", ""))
		var field: String = str(r.get("field", ""))
		var value: String = str(r.get("value", ""))
		if rt == "priority" or rt == "check" and op == "matches_city":
			continue
		var fv: Variant = case_field(case_data, field)
		if fv == null:
			continue
		var ok: bool = true
		if rt == "accept":
			ok = _check_operator(op, fv, value)
			if not ok:
				failed.append(str(r.get("label", field)))
		elif rt == "require":
			ok = _check_operator(op, fv, value)
			if not ok:
				failed.append(str(r.get("label", field)))
	var policy_would_accept: bool = failed.is_empty()
	return {
		"policy_would_accept": policy_would_accept,
		"failed_labels": failed,
	}
