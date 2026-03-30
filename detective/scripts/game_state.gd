extends Node

signal cases_updated
signal emails_updated
signal calls_updated
signal day_changed(day_id: String, day_number: int)
signal demo_finished
signal sim_time_changed(minutes_from_midnight: int)

var story_days: Array = []
var cases_template: Array = []
var emails_template: Array = []
var calls_template: Array = []
var office_rules: Array = []
var appointments_template: Array = []
var npcs: Array = []

var day_index: int = 0

## case_id -> runtime dict (plantilla + status + flags)
var case_states: Dictionary = {}
## email_id -> { read: bool, handled: bool }
var email_states: Dictionary = {}
## call_id -> { status: "pending"|"answered"|"missed" }
var call_states: Dictionary = {}

var score_trabajo: int = 70
var errores_graves: int = 0
## clue_tag -> true
var metacase_clues: Dictionary = {}

var last_summary_lines: PackedStringArray = []
var demo_ended: bool = false

## Minutos desde medianoche (oficina ~8:00–21:00). Correos/llamadas usan time_block del JSON.
const SIM_DAY_START: int = 8 * 60
const SIM_DAY_END: int = 21 * 60
var sim_minutes: int = SIM_DAY_START


func _ready() -> void:
	_load_static_data()


func _load_static_data() -> void:
	story_days = StoryDataLoader.load_json("res://data/story_days.json") as Array
	cases_template = StoryDataLoader.load_json("res://data/cases_fixed.json") as Array
	emails_template = StoryDataLoader.load_json("res://data/emails_fixed.json") as Array
	calls_template = StoryDataLoader.load_json("res://data/calls_fixed.json") as Array
	office_rules = StoryDataLoader.load_json("res://data/office_rules.json") as Array
	appointments_template = StoryDataLoader.load_json("res://data/appointments_fixed.json") as Array
	npcs = StoryDataLoader.load_json("res://data/npcs.json") as Array
	if story_days.is_empty():
		push_error("Datos vacíos: story_days")


func current_day_id() -> String:
	if day_index < 0 or day_index >= story_days.size():
		return ""
	var day_row: Dictionary = story_days[day_index] as Dictionary
	return str(day_row.get("day_id", ""))


func current_day_number() -> int:
	if day_index < 0 or day_index >= story_days.size():
		return 1
	var day_row: Dictionary = story_days[day_index] as Dictionary
	return int(day_row.get("day_number", day_index + 1))


func start_week() -> void:
	day_index = 0
	case_states.clear()
	email_states.clear()
	call_states.clear()
	score_trabajo = 70
	errores_graves = 0
	metacase_clues.clear()
	last_summary_lines.clear()
	demo_ended = false
	sim_minutes = SIM_DAY_START
	_hydrate_day()
	day_changed.emit(current_day_id(), current_day_number())
	sim_time_changed.emit(sim_minutes)


func _hydrate_day() -> void:
	sim_minutes = SIM_DAY_START
	var did: String = current_day_id()
	for i in range(cases_template.size()):
		var c: Dictionary = cases_template[i] as Dictionary
		if str(c.get("day_id", "")) != did:
			continue
		var cid: String = str(c.get("case_id", ""))
		var copy: Dictionary = c.duplicate(true)
		copy["status"] = str(c.get("status_initial", "pending"))
		case_states[cid] = copy
	for j in range(emails_template.size()):
		var e: Dictionary = emails_template[j] as Dictionary
		if str(e.get("day_id", "")) != did:
			continue
		var eid: String = str(e.get("email_id", ""))
		email_states[eid] = {"read": false, "handled": false}
	for k in range(calls_template.size()):
		var cl: Dictionary = calls_template[k] as Dictionary
		if str(cl.get("day_id", "")) != did:
			continue
		var cid2: String = str(cl.get("call_id", ""))
		if str(cl.get("direction", "")) == "outbound":
			call_states[cid2] = {"status": "answered"}
		else:
			call_states[cid2] = {"status": "pending"}
	cases_updated.emit()
	emails_updated.emit()
	calls_updated.emit()
	sim_time_changed.emit(sim_minutes)


func parse_time_block(tb: String) -> int:
	var s := tb.strip_edges()
	var parts: PackedStringArray = s.split(":")
	if parts.size() < 2:
		return SIM_DAY_START
	return clampi(int(parts[0]) * 60 + int(parts[1]), 0, 24 * 60)


func format_sim_time() -> String:
	return "%02d:%02d" % [sim_minutes / 60, sim_minutes % 60]


func advance_sim_minutes(delta: int) -> void:
	if demo_ended:
		return
	sim_minutes = clampi(sim_minutes + delta, SIM_DAY_START, SIM_DAY_END)
	sim_time_changed.emit(sim_minutes)
	emails_updated.emit()
	calls_updated.emit()


func _event_has_arrived(tb: String) -> bool:
	return parse_time_block(tb) <= sim_minutes


func emails_arrived_today() -> Array:
	var did: String = current_day_id()
	var out: Array = []
	for i in range(emails_template.size()):
		var e: Dictionary = emails_template[i] as Dictionary
		if str(e.get("day_id", "")) != did:
			continue
		if _event_has_arrived(str(e.get("time_block", "08:00"))):
			out.append(e)
	return out


func calls_arrived_today() -> Array:
	var did: String = current_day_id()
	var out: Array = []
	for i in range(calls_template.size()):
		var c: Dictionary = calls_template[i] as Dictionary
		if str(c.get("day_id", "")) != did:
			continue
		if _event_has_arrived(str(c.get("time_block", "12:00"))):
			out.append(c)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("time_block", "")) < str(b.get("time_block", ""))
	)
	return out


func send_email_reply(email_id: String, reply_body: String) -> void:
	if not email_states.has(email_id):
		return
	email_states[email_id]["handled"] = true
	email_states[email_id]["reply_sent"] = reply_body
	emails_updated.emit()


func cases_for_today() -> Array:
	var did: String = current_day_id()
	var out: Array = []
	for cid in case_states.keys():
		var st: Dictionary = case_states[cid] as Dictionary
		if str(st.get("day_id", "")) == did:
			out.append(st)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot_order", 0)) < int(b.get("slot_order", 0))
	)
	return out


## Casos del día ya decididos (historial de la jornada en curso).
func cases_decided_today() -> Array:
	var did: String = current_day_id()
	var out: Array = []
	for cid in case_states.keys():
		var st: Dictionary = case_states[cid] as Dictionary
		if str(st.get("day_id", "")) != did:
			continue
		if str(st.get("status", "pending")) == "pending":
			continue
		out.append(st)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("slot_order", 0)) < int(b.get("slot_order", 0))
	)
	return out


func emails_for_today() -> Array:
	var did: String = current_day_id()
	var out: Array = []
	for i in range(emails_template.size()):
		var e: Dictionary = emails_template[i] as Dictionary
		if str(e.get("day_id", "")) == did:
			out.append(e)
	return out


func calls_for_today() -> Array:
	var did: String = current_day_id()
	var out: Array = []
	for i in range(calls_template.size()):
		var c: Dictionary = calls_template[i] as Dictionary
		if str(c.get("day_id", "")) == did:
			out.append(c)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("time_block", "")) < str(b.get("time_block", ""))
	)
	return out


func appointments_for_today() -> Array:
	var did: String = current_day_id()
	var out: Array = []
	for i in range(appointments_template.size()):
		var a: Dictionary = appointments_template[i] as Dictionary
		if str(a.get("day_id", "")) == did:
			out.append(a)
	return out


func policy_for_case(case_data: Dictionary) -> Dictionary:
	return RulesService.evaluate(case_data, current_day_number(), office_rules)


func mark_email_read(email_id: String) -> void:
	if email_states.has(email_id):
		email_states[email_id]["read"] = true
		emails_updated.emit()


func mark_email_handled(email_id: String) -> void:
	if email_states.has(email_id):
		email_states[email_id]["handled"] = true
		emails_updated.emit()


func decide_case(case_id: String, decision: String) -> void:
	if not case_states.has(case_id):
		return
	var st: Dictionary = case_states[case_id] as Dictionary
	if str(st.get("status", "pending")) != "pending":
		return
	st["status"] = decision
	st["player_decision"] = decision
	var exp: String = str(st.get("official_decision_expected", ""))
	var can_arch: bool = bool(st.get("can_archive_personal", false))
	var ok: bool = _decision_matches_expected(decision, exp, can_arch)
	if not ok:
		score_trabajo = clampi(score_trabajo - 8, 0, 100)
		if decision == "accepted" and exp == "rechazar":
			errores_graves += 1
		if exp == "archivar" and decision != "archived":
			errores_graves += 1
	elif ok:
		score_trabajo = clampi(score_trabajo + 4, 0, 100)
	if decision != "rejected" and bool(st.get("is_metacase", false)):
		var tag: String = str(st.get("clue_tag", ""))
		if tag.strip_edges() != "":
			metacase_clues[tag] = true
	_mark_emails_for_case_handled(case_id)
	cases_updated.emit()


func _decision_matches_expected(decision: String, expected: String, can_archive: bool) -> bool:
	match expected:
		"aceptar":
			return decision == "accepted"
		"rechazar":
			return decision == "rejected" or (decision == "archived" and can_archive)
		"archivar":
			return decision == "archived"
		_:
			return true


func _mark_emails_for_case_handled(case_id: String) -> void:
	for i in range(emails_template.size()):
		var e: Dictionary = emails_template[i] as Dictionary
		if str(e.get("related_case_id", "")) != case_id:
			continue
		var eid: String = str(e.get("email_id", ""))
		if email_states.has(eid):
			email_states[eid]["handled"] = true
	emails_updated.emit()


func call_has_arrived(call_id: String) -> bool:
	var did: String = current_day_id()
	for i in range(calls_template.size()):
		var cl: Dictionary = calls_template[i] as Dictionary
		if str(cl.get("call_id", "")) != call_id:
			continue
		if str(cl.get("day_id", "")) != did:
			return false
		return _event_has_arrived(str(cl.get("time_block", "12:00")))
	return false


func answer_call(call_id: String, answered: bool) -> void:
	if not call_states.has(call_id):
		return
	if not call_has_arrived(call_id):
		return
	var entry: Dictionary = call_states[call_id] as Dictionary
	if str(entry.get("status", "")) != "pending":
		return
	entry["status"] = "answered" if answered else "missed"
	if not answered:
		for j in range(calls_template.size()):
			var cl: Dictionary = calls_template[j] as Dictionary
			if str(cl.get("call_id", "")) != call_id:
				continue
			if bool(cl.get("answer_required", false)):
				score_trabajo = clampi(score_trabajo - 5, 0, 100)
	calls_updated.emit()


func pending_calls() -> Array:
	var out: Array = []
	var today_calls: Array = calls_arrived_today()
	for i in range(today_calls.size()):
		var cl: Dictionary = today_calls[i] as Dictionary
		if str(cl.get("direction", "inbound")) != "inbound":
			continue
		var cid: String = str(cl.get("call_id", ""))
		var st_call: Dictionary = call_states.get(cid, {}) as Dictionary
		if str(st_call.get("status", "")) == "pending":
			out.append(cl)
	return out


func can_finish_day() -> bool:
	for _cid: String in case_states.keys():
		var st: Dictionary = case_states[_cid] as Dictionary
		if str(st.get("day_id", "")) != current_day_id():
			continue
		if str(st.get("status", "")) == "pending":
			return false
	var arrived_emails: Array = emails_arrived_today()
	for i in range(arrived_emails.size()):
		var e: Dictionary = arrived_emails[i] as Dictionary
		if not bool(e.get("requires_player_reply", false)):
			continue
		var eid: String = str(e.get("email_id", ""))
		var es: Dictionary = email_states.get(eid, {}) as Dictionary
		if not bool(es.get("handled", false)):
			var rel: String = str(e.get("related_case_id", ""))
			if rel.is_empty() and bool(es.get("read", false)):
				continue
			return false
	var calls_today: Array = calls_arrived_today()
	for k in range(calls_today.size()):
		var cl: Dictionary = calls_today[k] as Dictionary
		if str(cl.get("direction", "inbound")) != "inbound":
			continue
		if not bool(cl.get("must_happen", false)):
			continue
		var cid3: String = str(cl.get("call_id", ""))
		var st3: Dictionary = call_states.get(cid3, {}) as Dictionary
		if str(st3.get("status", "")) == "pending":
			return false
	return true


func finish_day() -> void:
	last_summary_lines.clear()
	var lines: PackedStringArray = []
	lines.append("Resumen — Día %d (%s)" % [current_day_number(), current_day_id()])
	var decided: int = 0
	for _cid: String in case_states.keys():
		var st: Dictionary = case_states[_cid] as Dictionary
		if str(st.get("day_id", "")) != current_day_id():
			continue
		if str(st.get("status", "")) != "pending":
			decided += 1
	lines.append("Casos cerrados hoy: %d" % decided)
	var answered: int = 0
	var missed: int = 0
	var calls_done: Array = calls_for_today()
	for idx in range(calls_done.size()):
		var cl: Dictionary = calls_done[idx] as Dictionary
		var cid4: String = str(cl.get("call_id", ""))
		var st4: Dictionary = call_states.get(cid4, {}) as Dictionary
		var s: String = str(st4.get("status", "pending"))
		if s == "answered":
			answered += 1
		elif s == "missed":
			missed += 1
	lines.append("Llamadas atendidas: %d | perdidas: %d" % [answered, missed])
	lines.append("Puntuación trabajo: %d | Errores graves: %d" % [score_trabajo, errores_graves])
	lines.append("Pistas metacaso descubiertas: %d" % metacase_clues.size())
	last_summary_lines = lines
	if day_index >= story_days.size() - 1:
		demo_ended = true
		demo_finished.emit()
		return
	day_index += 1
	_hydrate_day()
	day_changed.emit(current_day_id(), current_day_number())
