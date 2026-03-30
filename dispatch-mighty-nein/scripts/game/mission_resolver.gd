extends Node
## Calcula éxito/fallo de una misión según stats del equipo vs requisitos de la oleada.
## Aplica umbral ~80%, modificadores por fatiga y habilidades (Block 5).

const SUCCESS_THRESHOLD: float = 0.8

func resolve(hero_ids: Array, wave_data: WaveData) -> Dictionary:
	var total_required: int = wave_data.get_required_total()
	if total_required <= 0:
		return {"success": true, "quote": "", "xp_gained": wave_data.xp_reward, "detail": ""}

	var team_stats: Dictionary = _sum_team_stats(hero_ids)
	var team_total: int = 0
	for key in wave_data.requirements:
		team_total += int(team_stats.get(key, 0))

	# Modificador por habilidades (Block 5: get_ability_modifier)
	var ability_mult: float = _get_ability_modifier(hero_ids, wave_data)
	team_total = int(float(team_total) * ability_mult)

	var ratio: float = float(team_total) / float(total_required)
	var success: bool = ratio >= SUCCESS_THRESHOLD

	var quote: String = _pick_quote(hero_ids, success)
	var xp_gained: int = wave_data.xp_reward if success else 0
	var detail: String = _build_detail_string(wave_data, team_stats, total_required, team_total, success)

	return {
		"success": success,
		"quote": quote,
		"xp_gained": xp_gained,
		"ratio": ratio,
		"detail": detail
	}

func _sum_team_stats(hero_ids: Array) -> Dictionary:
	var out := {"combat": 0, "intellect": 0, "mobility": 0, "charisma": 0, "vigor": 0}
	for id in hero_ids:
		var h: HeroData = HeroManager.get_hero_by_id(str(id))
		if h:
			out["combat"] = out.get("combat", 0) + h.combat
			out["intellect"] = out.get("intellect", 0) + h.intellect
			out["mobility"] = out.get("mobility", 0) + h.mobility
			out["charisma"] = out.get("charisma", 0) + h.charisma
			out["vigor"] = out.get("vigor", 0) + h.vigor
	return out

func _get_ability_modifier(hero_ids: Array, wave_data: WaveData) -> float:
	# Block 5: cada TMN tiene bonus según mission_type
	var mult: float = 1.0
	for id in hero_ids:
		var h: HeroData = HeroManager.get_hero_by_id(str(id))
		if not h:
			continue
		match h.ability_id:
			"caleb_fire":
				if wave_data.mission_type == "investigation":
					mult += 0.15
			"jester_heal":
				mult += 0.05
			"fjord_tank":
				mult += 0.05
			"beau_mobility":
				if wave_data.mission_type == "mobility":
					mult += 0.12
			"nott_stealth":
				if wave_data.mission_type == "stealth":
					mult += 0.15
			"caduceus_support":
				mult += 0.05
			"yasha_resist":
				mult += 0.05
	return mult

func _stat_display_name(key: String) -> String:
	match key:
		"combat": return "Combate"
		"intellect": return "Intelecto"
		"mobility": return "Movilidad"
		"charisma": return "Carisma"
		"vigor": return "Vigor"
	return key.capitalize()

func _build_detail_string(wave_data: WaveData, team_stats: Dictionary, total_required: int, team_total_effective: int, success: bool) -> String:
	var req_parts: Array = []
	for k in wave_data.requirements:
		req_parts.append("%s %d" % [_stat_display_name(k), int(wave_data.requirements[k])])
	var team_parts: Array = []
	for k in wave_data.requirements:
		team_parts.append("%s %d" % [_stat_display_name(k), int(team_stats.get(k, 0))])
	var req_str: String = "Requisitos: " + ", ".join(req_parts) + " → total %d." % total_required
	var team_str: String = "Tu equipo: " + ", ".join(team_parts) + " → total efectivo %d." % team_total_effective
	var result_str: String = "✓ Cumplido (%d/%d)." % [team_total_effective, total_required] if success else "✗ No alcanzaste (%d/%d)." % [team_total_effective, total_required]
	return req_str + "\n" + team_str + "\n" + result_str

func _pick_quote(hero_ids: Array, success: bool) -> String:
	if hero_ids == null or hero_ids.is_empty():
		return ""
	var first_id: Variant = hero_ids[0]
	var h: HeroData = HeroManager.get_hero_by_id(str(first_id))
	if not h:
		return ""
	return h.quote_success if success else h.quote_fail
