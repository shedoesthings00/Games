extends Node
## Autoload: gestiona el roster de héroes (The Mighty Nein), estado en partida y aplicación de fatiga/daño/recompensas.

var _heroes: Array[HeroData] = []
var _heroes_by_id: Dictionary = {}

func _ready() -> void:
	# Los datos se inicializan en init_heroes() desde datos estáticos o recursos
	_init_heroes_from_data()

func _init_heroes_from_data() -> void:
	# Se rellenan desde un script de datos o recursos; por ahora vacío, Block 5 lo llenará
	_heroes.clear()
	_heroes_by_id.clear()
	var data_array: Array = _get_static_hero_data()
	for d in data_array:
		var h: HeroData = d.duplicate_for_runtime() if d is HeroData else _dict_to_hero(d)
		_heroes.append(h)
		_heroes_by_id[h.id] = h

func _dict_to_hero(d: Dictionary) -> HeroData:
	var h := HeroData.new()
	h.id = d.get("id", "")
	h.display_name = d.get("display_name", "")
	h.combat = d.get("combat", 10)
	h.intellect = d.get("intellect", 10)
	h.mobility = d.get("mobility", 10)
	h.charisma = d.get("charisma", 10)
	h.vigor = d.get("vigor", 10)
	h.ability_id = d.get("ability_id", "")
	h.quote_select = d.get("quote_select", "")
	h.quote_success = d.get("quote_success", "")
	h.quote_fail = d.get("quote_fail", "")
	return h

func _get_static_hero_data() -> Array:
	return [
		{
			"id": "caleb",
			"display_name": "Caleb",
			"combat": 8,
			"intellect": 22,
			"mobility": 12,
			"charisma": 10,
			"vigor": 14,
			"ability_id": "caleb_fire",
			"quote_select": "Ich werde das überprüfen.",
			"quote_success": "Das hat funktioniert.",
			"quote_fail": "Es tut mir leid."
		},
		{
			"id": "jester",
			"display_name": "Jester",
			"combat": 10,
			"intellect": 14,
			"mobility": 16,
			"charisma": 20,
			"vigor": 16,
			"ability_id": "jester_heal",
			"quote_select": "Oh, I have a great idea!",
			"quote_success": "The Traveler is so proud!",
			"quote_fail": "Oops..."
		},
		{
			"id": "fjord",
			"display_name": "Fjord",
			"combat": 18,
			"intellect": 12,
			"mobility": 14,
			"charisma": 16,
			"vigor": 20,
			"ability_id": "fjord_tank",
			"quote_select": "Let's get this done.",
			"quote_success": "Well, that's that.",
			"quote_fail": "We'll do better next time."
		},
		{
			"id": "beau",
			"display_name": "Beau",
			"combat": 16,
			"intellect": 14,
			"mobility": 22,
			"charisma": 10,
			"vigor": 16,
			"ability_id": "beau_mobility",
			"quote_select": "I'm on it.",
			"quote_success": "Told you.",
			"quote_fail": "Damn it."
		},
		{
			"id": "nott",
			"display_name": "Nott",
			"combat": 12,
			"intellect": 16,
			"mobility": 20,
			"charisma": 8,
			"vigor": 10,
			"ability_id": "nott_stealth",
			"quote_select": "I can steal it. Probably.",
			"quote_success": "See? Nobody saw me.",
			"quote_fail": "It wasn't my fault!"
		},
		{
			"id": "caduceus",
			"display_name": "Caduceus",
			"combat": 14,
			"intellect": 16,
			"mobility": 10,
			"charisma": 18,
			"vigor": 18,
			"ability_id": "caduceus_support",
			"quote_select": "Let's see what we can do.",
			"quote_success": "That's nice.",
			"quote_fail": "It's okay. We'll rest."
		},
		{
			"id": "yasha",
			"display_name": "Yasha",
			"combat": 22,
			"intellect": 8,
			"mobility": 14,
			"charisma": 10,
			"vigor": 24,
			"ability_id": "yasha_resist",
			"quote_select": "I will protect them.",
			"quote_success": "They are safe.",
			"quote_fail": "I... failed."
		}
	]

func reset_heroes_for_new_game() -> void:
	for h in _heroes:
		h.rest_until = 0.0
		h.is_damaged = false
		h.is_out = false
		h.level = 1
		h.xp = 0

func get_all_heroes() -> Array:
	if _heroes.is_empty():
		return []
	return _heroes.duplicate()

func get_hero_by_id(hero_id: String) -> HeroData:
	return _heroes_by_id.get(hero_id, null)

func get_available_heroes() -> Array:
	var out: Array = []
	for h in _heroes:
		if h.can_be_dispatched():
			out.append(h)
	return out

func get_available_hero_ids() -> Array:
	var out: Array = []
	for h in _heroes:
		if h.can_be_dispatched():
			out.append(h.id)
	return out

## Tras éxito: los héroes descansan 3 segundos antes de estar disponibles
func apply_success_rest(hero_ids: Array) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	for id in hero_ids:
		var h: HeroData = get_hero_by_id(str(id))
		if h:
			h.rest_until = now + 3.0

## Tras fallo: si ya estaban dañados quedan fuera; si no, pasan a dañados
func apply_fail_damage(hero_ids: Array) -> void:
	for id in hero_ids:
		var h: HeroData = get_hero_by_id(str(id))
		if h:
			if h.is_damaged:
				h.is_out = true
			else:
				h.is_damaged = true

func apply_rewards(hero_ids: Array, xp_amount: int) -> void:
	for id in hero_ids:
		var h: HeroData = get_hero_by_id(str(id))
		if h:
			h.xp += xp_amount
			# Subir nivel cada 15 XP (simple)
			while h.xp >= 15:
				h.xp -= 15
				h.level += 1
				_improve_one_stat(h)

func _improve_one_stat(hero: HeroData) -> void:
	# Mejorar +1 a un stat aleatorio
	var stats := ["combat", "intellect", "mobility", "charisma", "vigor"]
	var pick: String = stats[randi() % stats.size()]
	match pick:
		"combat":
			hero.combat += 1
		"intellect":
			hero.intellect += 1
		"mobility":
			hero.mobility += 1
		"charisma":
			hero.charisma += 1
		"vigor":
			hero.vigor += 1

func are_all_heroes_out() -> bool:
	for h in _heroes:
		if not h.is_out:
			return false
	return true

func set_heroes_data(data_array: Array) -> void:
	_heroes.clear()
	_heroes_by_id.clear()
	for d in data_array:
		var h: HeroData = d.duplicate_for_runtime() if d is HeroData else _dict_to_hero(d)
		_heroes.append(h)
		_heroes_by_id[h.id] = h
