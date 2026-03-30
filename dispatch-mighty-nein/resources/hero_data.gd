class_name HeroData
extends Resource
## Recurso que define los datos de un héroe (The Mighty Nein).
## Stats base, quotes y ID de habilidad única.

@export var id: String = ""
@export var display_name: String = ""
@export var combat: int = 10
@export var intellect: int = 10
@export var mobility: int = 10
@export var charisma: int = 10
@export var vigor: int = 10
## ID de la habilidad distintiva (ej. "caleb_fire", "jester_heal")
@export var ability_id: String = ""

@export var quote_select: String = ""
@export var quote_success: String = ""
@export var quote_fail: String = ""

## Estado en partida (gestionado por HeroManager)
## Tras éxito: descanso 3 s (rest_until = tiempo en segundos cuando termina)
var rest_until: float = 0.0
## Tras fallo: dañado; si ya estaba dañado y falla de nuevo → is_out
var is_damaged: bool = false
var is_out: bool = false
var level: int = 1
var xp: int = 0

func get_total_stats() -> int:
	return combat + intellect + mobility + charisma + vigor

func can_be_dispatched() -> bool:
	if is_out:
		return false
	if rest_until > 0.0 and Time.get_ticks_msec() / 1000.0 < rest_until:
		return false
	return true

func get_rest_seconds_left() -> float:
	var now: float = Time.get_ticks_msec() / 1000.0
	if rest_until <= 0 or now >= rest_until:
		return 0.0
	return rest_until - now

func duplicate_for_runtime() -> HeroData:
	var h := HeroData.new()
	h.id = id
	h.display_name = display_name
	h.combat = combat
	h.intellect = intellect
	h.mobility = mobility
	h.charisma = charisma
	h.vigor = vigor
	h.ability_id = ability_id
	h.quote_select = quote_select
	h.quote_success = quote_success
	h.quote_fail = quote_fail
	h.rest_until = 0.0
	h.is_damaged = false
	h.is_out = false
	h.level = 1
	h.xp = 0
	return h
