extends Node
## GameState (Autoload): estado global de la taberna.
## Trabajadores, eventos activos, reputación, caos, turnos, economía y resolución d20+stat.

# --- Constantes de balance ---
const TURNOS_PARA_GANAR := 5
const REPUTACION_INICIAL := 50
const CAOS_INICIAL := 0

# Efectos por resultado (fallo / éxito / crítico)
const CAOS_FALLO := 15
const REP_FALLO := -5
const CAOS_EXITO := -2
const REP_EXITO := 0
const CAOS_CRITICO := -5
const REP_CRITICO := 10

# Recompensas de oro por resultado
const ORO_EXITO := 5
const ORO_CRITICO := 10

# Ruta de guardado para mejoras permanentes
const SAVE_PATH := "user://mejoras_taberna.save"

# Umbrales del d20+stat (antes de aplicar ya son "resultado final")
const UMBRAL_FALLO := 8   # 1-8 fallo
const UMBRAL_EXITO := 14 # 9-14 éxito, 15+ crítico

# --- Estado ---
var trabajadores: Array[Dictionary] = []
var eventos_posibles: Array[Dictionary] = []
var eventos_activos: Array[Dictionary] = []
var reputacion: int = REPUTACION_INICIAL
var caos: int = CAOS_INICIAL
var turno_actual: int = 0
var partida_terminada: bool = false
var victoria: bool = false

# Economía
var oro_partida: int = 0
var mejoras_permanentes: Dictionary = {
	"carisma_bonus": 0,
	"cocina_bonus": 0,
	"limpieza_bonus": 0
}
var mejoras_ronda: Dictionary = {
	"carisma": 0,
	"cocina": 0,
	"limpieza": 0
}

# Último mensaje de feedback (para la UI)
var ultimo_feedback: String = ""

# Roll pendiente de aplicar (para animación: d20, stat, resultado)
var _roll_guardado: Dictionary = {}


func _ready() -> void:
	_inicializar_trabajadores()
	_inicializar_eventos()
	_cargar_mejoras()
	reiniciar_partida()


func _inicializar_trabajadores() -> void:
	trabajadores.clear()
	trabajadores.append({
		"id": "marina",
		"nombre": "Marina",
		"rol": "Camarera",
		"carisma": 5,
		"cocina": 1,
		"limpieza": 1
	})
	trabajadores.append({
		"id": "bruno",
		"nombre": "Bruno",
		"rol": "Cocinero",
		"carisma": 1,
		"cocina": 5,
		"limpieza": 2
	})
	trabajadores.append({
		"id": "luna",
		"nombre": "Luna",
		"rol": "Limpieza",
		"carisma": 2,
		"cocina": 1,
		"limpieza": 5
	})


func _inicializar_eventos() -> void:
	eventos_posibles.clear()
	eventos_posibles.append({
		"tipo": "servir_mesa",
		"stat_relevante": "carisma",
		"texto": "Una mesa pide servicio."
	})
	eventos_posibles.append({
		"tipo": "cocinar_plato",
		"stat_relevante": "cocina",
		"texto": "Hay que preparar un plato."
	})
	eventos_posibles.append({
		"tipo": "limpiar_desastre",
		"stat_relevante": "limpieza",
		"texto": "Hay un desastre que limpiar."
	})


func reiniciar_partida() -> void:
	reputacion = REPUTACION_INICIAL
	caos = CAOS_INICIAL
	turno_actual = 0
	partida_terminada = false
	victoria = false
	oro_partida = 0
	for k in mejoras_ronda.keys():
		mejoras_ronda[k] = 0
	eventos_activos.clear()
	ultimo_feedback = ""
	_roll_guardado = {}
	generar_evento_turno()


func generar_evento_turno() -> void:
	var idx := randi_range(0, eventos_posibles.size() - 1)
	var ev := eventos_posibles[idx].duplicate()
	eventos_activos.append(ev)


func get_trabajador(worker_id: String) -> Dictionary:
	for t in trabajadores:
		if t["id"] == worker_id:
			return t
	return {}


func get_stat_trabajador(worker_id: String, stat: String) -> int:
	var t := get_trabajador(worker_id)
	var base_val: int = t.get(stat, 0)
	var bonus_key := "%s_bonus" % stat
	var bonus_val: int = mejoras_permanentes.get(bonus_key, 0)
	return base_val + bonus_val


func get_nombre_stat(stat: String) -> String:
	match stat:
		"carisma": return "Carisma"
		"cocina": return "Cocina"
		"limpieza": return "Limpieza"
	return stat


## Hace la tirada d20 para un evento y guarda el resultado para aplicar después.
## Devuelve un diccionario con d20, stat_val, stat_name, resultado, rango (para la animación).
## Llamar después a aplicar_roll_guardado() para aplicar efectos.
func rollar_para_evento(worker_id: String, event_index: int) -> Dictionary:
	if partida_terminada:
		return {}
	if event_index < 0 or event_index >= eventos_activos.size():
		return {}

	var ev: Dictionary = eventos_activos[event_index]
	var stat_key: String = ev["stat_relevante"]
	var stat_val: int = get_stat_trabajador(worker_id, stat_key)
	var worker: Dictionary = get_trabajador(worker_id)
	if worker.is_empty():
		return {}

	var d20: int = randi_range(1, 20)
	var resultado: int = d20 + stat_val

	var rango: String
	if resultado <= UMBRAL_FALLO:
		rango = "fallo"
	elif resultado <= UMBRAL_EXITO:
		rango = "exito"
	else:
		rango = "critico"

	_roll_guardado = {
		"worker_id": worker_id,
		"event_index": event_index,
		"d20": d20,
		"stat_val": stat_val,
		"stat_key": stat_key,
		"resultado": resultado,
		"rango": rango,
		"ev": ev,
		"worker": worker
	}
	return {
		"d20": d20,
		"stat_val": stat_val,
		"stat_name": get_nombre_stat(stat_key),
		"resultado": resultado,
		"rango": rango
	}


## Aplica el roll guardado por rollar_para_evento (efectos, quitar evento, siguiente turno).
func aplicar_roll_guardado() -> bool:
	if _roll_guardado.is_empty():
		return false
	var worker_id: String = _roll_guardado["worker_id"]
	var event_index: int = _roll_guardado["event_index"]
	var rango: String = _roll_guardado["rango"]
	var worker: Dictionary = _roll_guardado["worker"]
	var ev: Dictionary = _roll_guardado["ev"]
	var d20: int = _roll_guardado["d20"]
	var stat_val: int = _roll_guardado["stat_val"]
	var stat_key: String = _roll_guardado["stat_key"]
	var resultado: int = _roll_guardado["resultado"]
	var nombre_stat: String = get_nombre_stat(stat_key)
	var nombre_trabajador: String = worker["nombre"]

	if rango == "fallo":
		caos = clampi(caos + CAOS_FALLO, 0, 100)
		reputacion = clampi(reputacion + REP_FALLO, 0, 100)
	elif rango == "exito":
		caos = clampi(caos + CAOS_EXITO, 0, 100)
		reputacion = clampi(reputacion + REP_EXITO, 0, 100)
	else:
		caos = clampi(caos + CAOS_CRITICO, 0, 100)
		reputacion = clampi(reputacion + REP_CRITICO, 0, 100)

	# Recompensa de oro por el resultado
	_aplicar_recompensa_oro(rango)

	if rango == "fallo":
		ultimo_feedback = "%s intenta atender: %s Resultado %d (d20=%d + %s %d): fallo. La situación empeora." % [
			nombre_trabajador, ev["texto"], resultado, d20, nombre_stat, stat_val
		]
	elif rango == "exito":
		ultimo_feedback = "%s atiende: %s Resultado %d (d20=%d + %s %d): éxito." % [
			nombre_trabajador, ev["texto"], resultado, d20, nombre_stat, stat_val
		]
	else:
		ultimo_feedback = "%s atiende: %s Resultado %d (d20=%d + %s %d): éxito crítico, grandes propinas." % [
			nombre_trabajador, ev["texto"], resultado, d20, nombre_stat, stat_val
		]

	eventos_activos.remove_at(event_index)
	turno_actual += 1
	_roll_guardado = {}

	if caos >= 100:
		partida_terminada = true
		victoria = false
		ultimo_feedback += "\n\nGame Over: noche desastrosa."
		_ir_a_hub()
	elif turno_actual >= TURNOS_PARA_GANAR:
		partida_terminada = true
		victoria = true
		ultimo_feedback += "\n\nNoche completada."
		_ir_a_hub()
	else:
		generar_evento_turno()

	return true


## Asigna un trabajador a un evento (por índice en eventos_activos).
## Hace tirada d20 + stat, aplica efectos y devuelve true si se resolvió.
## Feedback queda en ultimo_feedback.
func asignar_trabajador_a_evento(worker_id: String, event_index: int) -> bool:
	if partida_terminada:
		return false
	if event_index < 0 or event_index >= eventos_activos.size():
		return false

	var ev: Dictionary = eventos_activos[event_index]
	var stat_key: String = ev["stat_relevante"]
	var stat_val: int = get_stat_trabajador(worker_id, stat_key)
	var worker: Dictionary = get_trabajador(worker_id)
	if worker.is_empty():
		return false

	var d20: int = randi_range(1, 20)
	var resultado: int = d20 + stat_val

	# Determinar rango
	var rango: String
	if resultado <= UMBRAL_FALLO:
		rango = "fallo"
	elif resultado <= UMBRAL_EXITO:
		rango = "exito"
	else:
		rango = "critico"

	# Aplicar efectos
	if rango == "fallo":
		caos = clampi(caos + CAOS_FALLO, 0, 100)
		reputacion = clampi(reputacion + REP_FALLO, 0, 100)
	elif rango == "exito":
		caos = clampi(caos + CAOS_EXITO, 0, 100)
		reputacion = clampi(reputacion + REP_EXITO, 0, 100)
	else:
		caos = clampi(caos + CAOS_CRITICO, 0, 100)
		reputacion = clampi(reputacion + REP_CRITICO, 0, 100)

	var nombre_trabajador: String = worker["nombre"]
	var nombre_stat: String = get_nombre_stat(stat_key)

	# Texto de feedback
	if rango == "fallo":
		ultimo_feedback = "%s intenta atender: %s Resultado %d (d20=%d + %s %d): fallo. La situación empeora." % [
			nombre_trabajador, ev["texto"], resultado, d20, nombre_stat, stat_val
		]
	elif rango == "exito":
		ultimo_feedback = "%s atiende: %s Resultado %d (d20=%d + %s %d): éxito." % [
			nombre_trabajador, ev["texto"], resultado, d20, nombre_stat, stat_val
		]
	else:
		ultimo_feedback = "%s atiende: %s Resultado %d (d20=%d + %s %d): éxito crítico, grandes propinas." % [
			nombre_trabajador, ev["texto"], resultado, d20, nombre_stat, stat_val
		]

	eventos_activos.remove_at(event_index)
	turno_actual += 1

	# Comprobar fin de partida
	if caos >= 100:
		partida_terminada = true
		victoria = false
		ultimo_feedback += "\n\nGame Over: noche desastrosa."
		_ir_a_hub()
	elif turno_actual >= TURNOS_PARA_GANAR:
		partida_terminada = true
		victoria = true
		ultimo_feedback += "\n\nNoche completada."
		_ir_a_hub()
	else:
		generar_evento_turno()

	return true


func _aplicar_recompensa_oro(rango: String) -> void:
	if partida_terminada:
		return
	match rango:
		"exito":
			oro_partida += ORO_EXITO
		"critico":
			oro_partida += ORO_CRITICO
		_:
			pass


func puede_comprar_mejora(coste: int) -> bool:
	return coste > 0 and oro_partida >= coste


func comprar_mejora(stat_key: String, coste: int) -> bool:
	if not puede_comprar_mejora(coste):
		return false
	var bonus_key := "%s_bonus" % stat_key
	if not mejoras_permanentes.has(bonus_key):
		return false
	oro_partida -= coste
	mejoras_permanentes[bonus_key] = int(mejoras_permanentes.get(bonus_key, 0)) + 1
	mejoras_ronda[stat_key] = int(mejoras_ronda.get(stat_key, 0)) + 1
	print("[GameState] comprar_mejora ", stat_key, " coste=", coste, " oro_restante=", oro_partida, " mejoras_ronda=", mejoras_ronda)
	_guardar_mejoras()
	return true


func puede_revertir_mejora(stat_key: String) -> bool:
	return int(mejoras_ronda.get(stat_key, 0)) > 0


func revertir_mejora(stat_key: String, coste: int) -> bool:
	if not puede_revertir_mejora(stat_key):
		return false
	var bonus_key := "%s_bonus" % stat_key
	if not mejoras_permanentes.has(bonus_key):
		return false
	var actual_bonus := int(mejoras_permanentes.get(bonus_key, 0))
	if actual_bonus <= 0:
		return false
	mejoras_permanentes[bonus_key] = actual_bonus - 1
	mejoras_ronda[stat_key] = int(mejoras_ronda.get(stat_key, 0)) - 1
	oro_partida += coste
	print("[GameState] revertir_mejora ", stat_key, " coste=", coste, " oro_nuevo=", oro_partida, " mejoras_ronda=", mejoras_ronda)
	_guardar_mejoras()
	return true


func _guardar_mejoras() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	var data := {
		"mejoras_permanentes": mejoras_permanentes
	}
	file.store_var(data)
	file.close()


func _cargar_mejoras() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = file.get_var()
	file.close()
	if typeof(data) == TYPE_DICTIONARY and data.has("mejoras_permanentes"):
		var loaded: Dictionary = data["mejoras_permanentes"]
		if typeof(loaded) == TYPE_DICTIONARY:
			for k in loaded.keys():
				mejoras_permanentes[k] = loaded[k]


func hay_eventos_activos() -> bool:
	return eventos_activos.size() > 0


## Cancela el evento actual por timeout (no se pulsó a tiempo). Sube caos y pasa al siguiente.
func cancelar_evento_por_timeout() -> void:
	if eventos_activos.is_empty():
		return
	eventos_activos.remove_at(0)
	turno_actual += 1
	caos = clampi(caos + 10, 0, 100)
	ultimo_feedback = "Nadie atendió a tiempo. La situación empeora."
	if turno_actual >= TURNOS_PARA_GANAR:
		partida_terminada = true
		victoria = true
		ultimo_feedback += "\n\nNoche completada."
		_ir_a_hub()
	elif caos >= 100:
		partida_terminada = true
		victoria = false
		ultimo_feedback += "\n\nGame Over: noche desastrosa."
		_ir_a_hub()
	else:
		generar_evento_turno()


func terminar_noche_manual() -> void:
	if partida_terminada:
		return
	oro_partida += 20
	partida_terminada = true
	victoria = true
	ultimo_feedback = "Has terminado la noche manualmente. Ganas 20 de oro."
	print("[GameState] terminar_noche_manual -> oro_partida=", oro_partida)
	_ir_a_hub()


func _ir_a_hub() -> void:
	var tree := get_tree()
	if tree == null:
		return
	print("[GameState] Cambiando a escena de hub con oro_partida=", oro_partida)
	tree.change_scene_to_file("res://scenes/hub.tscn")
