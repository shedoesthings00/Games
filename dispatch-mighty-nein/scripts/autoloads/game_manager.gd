extends Node
## Autoload: orquesta el estado global de partida, oleadas y resolución de misiones.
## Conecta HeroManager, WaveManager y dispara señales para la UI.

signal wave_started(wave_index: int, wave_data: WaveData)
signal wave_completed(wave_index: int, success: bool)
signal mission_resolved(success: bool, quote: String, xp_gained: int, detail: String)
signal game_over(reason: String)
signal victory()

const MAX_FAILURES: int = 3

var current_wave_index: int = 0
var failure_count: int = 0
var in_game: bool = false
var last_game_over_reason: String = ""
var _mission_resolver: Node

func _ready() -> void:
	var ResolverScript: GDScript = load("res://scripts/game/mission_resolver.gd") as GDScript
	_mission_resolver = ResolverScript.new()
	add_child(_mission_resolver)

func start_game() -> void:
	in_game = true
	current_wave_index = 0
	failure_count = 0
	HeroManager.reset_heroes_for_new_game()
	WaveManager.reset()
	_start_current_wave()

func _start_current_wave() -> void:
	var wave_data: WaveData = WaveManager.get_wave(current_wave_index)
	if wave_data == null:
		# No hay más oleadas -> victoria
		victory.emit()
		return
	wave_started.emit(current_wave_index, wave_data)

func send_heroes(hero_ids: Array) -> void:
	if hero_ids.is_empty():
		return
	var wave_data: WaveData = WaveManager.get_wave(current_wave_index)
	if wave_data == null:
		return
	var result: Dictionary = _mission_resolver.resolve(hero_ids, wave_data)
	var success: bool = result.get("success", false)
	var quote: String = result.get("quote", "")
	var xp_gained: int = result.get("xp_gained", 0)
	var detail: String = result.get("detail", "")

	if success:
		HeroManager.apply_rewards(hero_ids, xp_gained)
		HeroManager.apply_success_rest(hero_ids)
		wave_completed.emit(current_wave_index, true)
		mission_resolved.emit(true, quote, xp_gained, detail)
		current_wave_index += 1
		# ¿Siguiente oleada o victoria?
		if WaveManager.get_wave(current_wave_index) == null:
			victory.emit()
		else:
			_start_current_wave()
	else:
		failure_count += 1
		HeroManager.apply_fail_damage(hero_ids)
		wave_completed.emit(current_wave_index, false)
		mission_resolved.emit(false, quote, 0, detail)
		if failure_count >= MAX_FAILURES:
			last_game_over_reason = "Demasiados fallos."
			game_over.emit(last_game_over_reason)
			return
		# Comprobar si todos los héroes han quedado fuera (dañado que falla 2ª vez)
		if HeroManager.are_all_heroes_out():
			last_game_over_reason = "Todos los héroes han quedado fuera."
			game_over.emit(last_game_over_reason)
			return
		_start_current_wave()

func get_current_wave_index() -> int:
	return current_wave_index

func get_failure_count() -> int:
	return failure_count

func is_in_game() -> bool:
	return in_game
