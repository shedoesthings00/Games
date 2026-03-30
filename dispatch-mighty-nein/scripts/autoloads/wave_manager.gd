extends Node
## Autoload: proporciona los datos de las 7 oleadas (WaveData).
## Los datos se definen en código o en recursos; sin pathfinding ni enemigos físicos.

var _waves: Array[WaveData] = []
var _current_index: int = 0

func _ready() -> void:
	_load_waves()

func _load_waves() -> void:
	_waves.clear()
	var data: Array = _get_static_wave_data()
	for w in data:
		if w is WaveData:
			_waves.append(w)
		else:
			_waves.append(_dict_to_wave(w))

func _dict_to_wave(d: Dictionary) -> WaveData:
	var w := WaveData.new()
	w.wave_index = d.get("wave_index", 0)
	w.briefing = d.get("briefing", "")
	w.difficulty = d.get("difficulty", 1)
	w.mission_type = d.get("mission_type", "")
	w.requirements = d.get("requirements", {})
	w.requirements_description = d.get("requirements_description", "")
	w.xp_reward = d.get("xp_reward", 10)
	w.gold_reward = d.get("gold_reward", 5)
	return w

func _get_static_wave_data() -> Array:
	return [
		{
			"wave_index": 0,
			"briefing": "Un grupo de bandidos ha tomado una taberna.",
			"requirements_description": "Se necesita alguien fuerte y con mano izquierda para negociar.",
			"difficulty": 1,
			"mission_type": "combat",
			"requirements": {"combat": 18, "charisma": 12},
			"xp_reward": 10,
			"gold_reward": 5
		},
		{
			"wave_index": 1,
			"briefing": "Robo en una biblioteca: hay que recuperar un artefacto.",
			"requirements_description": "Hace falta alguien que piense y alguien rápido.",
			"difficulty": 1,
			"mission_type": "investigation",
			"requirements": {"intellect": 20, "mobility": 10},
			"xp_reward": 12,
			"gold_reward": 6
		},
		{
			"wave_index": 2,
			"briefing": "Negociación con contrabandistas en el muelle.",
			"requirements_description": "Buscan a alguien con labia y que aguante el tipo bajo presión.",
			"difficulty": 2,
			"mission_type": "negotiation",
			"requirements": {"charisma": 22, "vigor": 15},
			"xp_reward": 14,
			"gold_reward": 8
		},
		{
			"wave_index": 3,
			"briefing": "Persecución por los tejados: el objetivo se escapa.",
			"requirements_description": "Se necesita velocidad y alguien que sepa pelear en movimiento.",
			"difficulty": 2,
			"mission_type": "mobility",
			"requirements": {"mobility": 25, "combat": 14},
			"xp_reward": 14,
			"gold_reward": 7
		},
		{
			"wave_index": 4,
			"briefing": "Infiltración en un almacén para recuperar pruebas.",
			"requirements_description": "Hace falta sigilo y alguien que desactive trampas y cerraduras.",
			"difficulty": 2,
			"mission_type": "stealth",
			"requirements": {"mobility": 18, "intellect": 20},
			"xp_reward": 16,
			"gold_reward": 9
		},
		{
			"wave_index": 5,
			"briefing": "Enfrentamiento con cultistas en un santuario.",
			"requirements_description": "Se necesita mano dura y mucha resistencia.",
			"difficulty": 3,
			"mission_type": "combat",
			"requirements": {"combat": 28, "vigor": 22},
			"xp_reward": 18,
			"gold_reward": 10
		},
		{
			"wave_index": 6,
			"briefing": "Misión final: rescate y cierre de un portal.",
			"requirements_description": "Un equipo equilibrado: fuerza, cabeza, carisma y aguante.",
			"difficulty": 3,
			"mission_type": "investigation",
			"requirements": {"combat": 20, "intellect": 20, "charisma": 15, "vigor": 18},
			"xp_reward": 25,
			"gold_reward": 15
		}
	]

func reset() -> void:
	_current_index = 0

func get_wave(index: int) -> WaveData:
	if index < 0 or index >= _waves.size():
		return null
	return _waves[index]

func get_wave_count() -> int:
	return _waves.size()

func set_waves_data(waves_array: Array) -> void:
	_waves.clear()
	for w in waves_array:
		if w is WaveData:
			_waves.append(w)
		else:
			_waves.append(_dict_to_wave(w))
