extends Node3D
## Taberna 3D: barras arriba, personajes abajo. Misión = punto con timeout 6 s.
## Al pulsar el punto se muestra el texto; si no se pulsa en 6 s se cancela.

const MISSION_TIMEOUT := 6.0

var camera: Camera3D
var tables: Array[Node3D] = []
var bar_reputacion: ProgressBar
var bar_caos: ProgressBar
var feedback: RichTextLabel
var oro_label: Label
var btn_reintentar: Button
var mission_point_container: Control
var mission_ring: Control
var mission_point: Button
var table_popup: PanelContainer
var table_popup_mesa: Label
var table_popup_event: Label
var mission_slot_label: Label
var btn_aceptar: Button
var stats_popup: PanelContainer
var stats_popup_nombre: Label
var stats_popup_text: Label
var mission_timer: Timer
var d20_roll_overlay: Control
var d20_die_instance: Node3D
var label_d20: Label
var label_plus_stat: Label
var label_total: Label
var evento_revelado: bool = false
var _timer_ya_iniciado: bool = false
var _tiempo_restante_al_abrir: float = 6.0
var _timer_pausado_por_stats: bool = false
var worker_asignado_mision: String = ""
var _worker_id_pendiente_tirada: String = ""
var _mission_table_index: int = 0  # mesa en la que aparece la misión actual (para posición y texto)
var _roll_data: Dictionary = {}
var _d20_slerp_start: Quaternion = Quaternion.IDENTITY
var _d20_quaternions_final: Array[Quaternion] = []
var _d20_face_centers: Array[Vector3] = []
var _d20_face_normals: Array[Vector3] = []
const _D20_GLB_SCALE := 0.053595103
const _D20_GLB_ORIGIN := Vector3(-0.04229939, 0.0, -0.18636608)


func _build_d20_face_up_quaternions() -> void:
	# Misma geometría que el icosaedro estándar (d20_die_3d.gd): 12 vértices, 20 caras
	var phi: float = (1.0 + sqrt(5.0)) * 0.5
	var inv: float = 1.0 / sqrt(1.0 + phi * phi)
	var verts: PackedVector3Array = [
		Vector3(0, inv, inv * phi), Vector3(0, inv, -inv * phi), Vector3(0, -inv, inv * phi), Vector3(0, -inv, -inv * phi),
		Vector3(inv, inv * phi, 0), Vector3(-inv, inv * phi, 0), Vector3(inv, -inv * phi, 0), Vector3(-inv, -inv * phi, 0),
		Vector3(inv * phi, 0, inv), Vector3(-inv * phi, 0, inv), Vector3(inv * phi, 0, -inv), Vector3(-inv * phi, 0, -inv)
	]
	# 20 triángulos (índices en CCW visto desde fuera)
	var faces: PackedInt32Array = PackedInt32Array([
		0, 8, 4,  0, 4, 1,  0, 1, 6,  0, 6, 2,  0, 2, 8,
		8, 2, 7,  8, 7, 11, 8, 11, 4,  4, 11, 5,  4, 5, 1,
		1, 5, 10, 1, 10, 6,  6, 10, 3,  6, 3, 2,  2, 3, 7,
		7, 3, 10, 7, 10, 11, 7, 11, 5,  5, 11, 10, 3, 5, 10
	])
	var up := Vector3.UP
	for i in range(20):
		var i0: int = faces[i * 3]
		var i1: int = faces[i * 3 + 1]
		var i2: int = faces[i * 3 + 2]
		var e1: Vector3 = verts[i1] - verts[i0]
		var e2: Vector3 = verts[i2] - verts[i0]
		var n: Vector3 = e1.cross(e2).normalized()
		var center: Vector3 = (verts[i0] + verts[i1] + verts[i2]) / 3.0
		_d20_face_centers.append(center)
		_d20_face_normals.append(n)
		# Quaternion que rota la normal n hacia UP (esa cara queda exactamente hacia arriba)
		if n.dot(up) > 0.9999:
			_d20_quaternions_final.append(Quaternion.IDENTITY)
		elif n.dot(up) < -0.9999:
			_d20_quaternions_final.append(Quaternion.from_euler(Vector3(PI, 0, 0)))
		else:
			_d20_quaternions_final.append(Quaternion(n, up))
	return


func _add_face_labels_to_die(die_node: Node3D) -> void:
	if die_node == null or _d20_face_centers.size() != 20:
		return
	var label_forward := Vector3(0, 0, -1)
	for i in range(20):
		var lbl := Label3D.new()
		lbl.text = str(i + 1)
		lbl.pixel_size = 0.012
		lbl.outline_size = 8
		lbl.billboard = 0  # BILLBOARD_DISABLED: el número sigue la orientación de la cara
		var center: Vector3 = _d20_face_centers[i]
		var n: Vector3 = _d20_face_normals[i]
		lbl.position = _D20_GLB_SCALE * center + _D20_GLB_ORIGIN
		if n.dot(label_forward) < -0.9999:
			lbl.quaternion = Quaternion.from_euler(Vector3(PI, 0, 0))
		else:
			lbl.quaternion = Quaternion(label_forward, n)
		die_node.add_child(lbl)
	return


func _ready() -> void:
	mission_timer = Timer.new()
	mission_timer.one_shot = true
	mission_timer.timeout.connect(_on_mission_timeout)
	add_child(mission_timer)

	# 20 orientaciones finales: una por cara del icosaedro, cada una con esa cara exactamente hacia arriba
	_build_d20_face_up_quaternions()

	_resolver_nodos()
	var w1: Button = get_node_or_null("UI/MarginContainer/VBox/Trabajadores/Worker1/Btn") as Button
	var w2: Button = get_node_or_null("UI/MarginContainer/VBox/Trabajadores/Worker2/Btn") as Button
	var w3: Button = get_node_or_null("UI/MarginContainer/VBox/Trabajadores/Worker3/Btn") as Button
	if w1:
		w1.pressed.connect(func(): _on_worker_clicked("marina"))
	if w2:
		w2.pressed.connect(func(): _on_worker_clicked("bruno"))
	if w3:
		w3.pressed.connect(func(): _on_worker_clicked("luna"))
	if btn_reintentar:
		btn_reintentar.pressed.connect(_on_reintentar)
	if mission_point:
		mission_point.pressed.connect(_on_mission_point_clicked)
	var btn_cerrar: Button = get_node_or_null("PopupLayer/TablePopup/VBox/BotonesPopup/CerrarMision") as Button
	if btn_cerrar:
		btn_cerrar.pressed.connect(_on_cerrar_mision)
	btn_aceptar = get_node_or_null("PopupLayer/TablePopup/VBox/BotonesPopup/AceptarMision") as Button
	if btn_aceptar:
		btn_aceptar.pressed.connect(_on_aceptar_mision)
	var btn_cerrar_stats: Button = get_node_or_null("PopupLayer/CharacterStatsPopup/VBox/CerrarStats") as Button
	if btn_cerrar_stats:
		btn_cerrar_stats.pressed.connect(_on_cerrar_stats)
	actualizar_ui()
	_actualizar_mission_point()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		# F1 para terminar manualmente la noche y dar oro fijo
		if key_event.keycode == KEY_F1 and not GameState.partida_terminada:
			print("[Main] F1 pulsado -> terminar_noche_manual")
			GameState.terminar_noche_manual()
			actualizar_ui()


func _resolver_nodos() -> void:
	camera = get_node_or_null("Camera3D") as Camera3D
	var tables_node = get_node_or_null("Tavern/Tables")
	if tables_node:
		for i in range(1, 5):
			var t = tables_node.get_node_or_null("Table%d" % i) as Node3D
			if t:
				tables.append(t)

	bar_reputacion = get_node_or_null("UI/MarginContainer/VBox/Barras/ReputacionBox/ReputacionBar") as ProgressBar
	bar_caos = get_node_or_null("UI/MarginContainer/VBox/Barras/CaosBox/CaosBar") as ProgressBar
	var barras: HBoxContainer = get_node_or_null("UI/MarginContainer/VBox/Barras") as HBoxContainer
	if barras:
		barras.visible = false
	feedback = get_node_or_null("UI/MarginContainer/VBox/Feedback") as RichTextLabel
	oro_label = get_node_or_null("UI/MarginContainer/VBox/OroLabel") as Label
	btn_reintentar = get_node_or_null("UI/MarginContainer/VBox/Reintentar") as Button
	mission_point_container = get_node_or_null("PopupLayer/MissionPointContainer") as Control
	mission_ring = get_node_or_null("PopupLayer/MissionPointContainer/MissionRing") as Control
	mission_point = get_node_or_null("PopupLayer/MissionPointContainer/MissionPoint") as Button
	table_popup = get_node_or_null("PopupLayer/TablePopup") as PanelContainer
	table_popup_mesa = get_node_or_null("PopupLayer/TablePopup/VBox/MesaLabel") as Label
	table_popup_event = get_node_or_null("PopupLayer/TablePopup/VBox/EventText") as Label
	mission_slot_label = get_node_or_null("PopupLayer/TablePopup/VBox/SlotRow/MissionSlot/Label") as Label
	stats_popup = get_node_or_null("PopupLayer/CharacterStatsPopup") as PanelContainer
	stats_popup_nombre = get_node_or_null("PopupLayer/CharacterStatsPopup/VBox/StatsNombre") as Label
	stats_popup_text = get_node_or_null("PopupLayer/CharacterStatsPopup/VBox/StatsText") as Label
	d20_roll_overlay = get_node_or_null("PopupLayer/D20RollOverlay") as Control
	d20_die_instance = null
	label_d20 = get_node_or_null("PopupLayer/D20RollOverlay/NumbersPanel/VBox/LabelD20") as Label
	label_plus_stat = get_node_or_null("PopupLayer/D20RollOverlay/NumbersPanel/VBox/LabelPlusStat") as Label
	label_total = get_node_or_null("PopupLayer/D20RollOverlay/NumbersPanel/VBox/LabelTotal") as Label


func _process(_delta: float) -> void:
	if mission_ring and mission_timer and mission_timer.time_left > 0:
		mission_ring.time_ratio = mission_timer.time_left / MISSION_TIMEOUT
		mission_ring.queue_redraw()
	_actualizar_mission_point()


func _actualizar_mission_point() -> void:
	if not mission_point_container:
		return

	if GameState.eventos_activos.is_empty():
		mission_point_container.visible = false
		if table_popup:
			table_popup.visible = false
		return

	if evento_revelado:
		mission_point_container.visible = false
		return

	mission_point_container.visible = true
	if table_popup:
		table_popup.visible = false
	if not _timer_ya_iniciado:
		_timer_ya_iniciado = true
		mission_timer.wait_time = MISSION_TIMEOUT
		mission_timer.start()
		# Nueva misión: elegir mesa al azar y colocar el punto sobre esa mesa en pantalla
		if camera and tables.size() > 0:
			_mission_table_index = randi() % tables.size()
			var table_pos_3d: Vector3 = tables[_mission_table_index].global_position
			var viewport: Viewport = get_viewport()
			var rect_size: Vector2 = viewport.get_visible_rect().size
			var pos_2d: Vector2 = camera.unproject_position(table_pos_3d)
			var container_size: Vector2 = mission_point_container.custom_minimum_size
			var half: Vector2 = container_size * 0.5
			mission_point_container.position.x = clampf(pos_2d.x - half.x, 0.0, rect_size.x - container_size.x)
			mission_point_container.position.y = clampf(pos_2d.y - half.y, 0.0, rect_size.y - container_size.y)
		else:
			var viewport: Viewport = get_viewport()
			var rect_size: Vector2 = viewport.get_visible_rect().size
			var container_size: Vector2 = mission_point_container.custom_minimum_size
			mission_point_container.position = rect_size * 0.5 - container_size * 0.5


func _on_mission_point_clicked() -> void:
	if GameState.eventos_activos.is_empty():
		return
	if mission_timer.time_left > 0:
		_tiempo_restante_al_abrir = mission_timer.time_left
	else:
		_tiempo_restante_al_abrir = MISSION_TIMEOUT
	evento_revelado = true
	_timer_ya_iniciado = false
	mission_timer.stop()
	if table_popup_mesa and tables.size() > 0:
		table_popup_mesa.text = "Mesa %d" % (_mission_table_index + 1)
	if table_popup_event:
		table_popup_event.text = GameState.eventos_activos[0].get("texto", "?")
	worker_asignado_mision = ""
	if mission_slot_label:
		mission_slot_label.text = "Nadie"
	if btn_aceptar:
		btn_aceptar.disabled = true
	if table_popup:
		var viewport: Viewport = get_viewport()
		var popup_w: float = 320.0
		var popup_h: float = 160.0
		table_popup.position = viewport.get_visible_rect().size * 0.5 - Vector2(popup_w * 0.5, popup_h * 0.5)
		table_popup.visible = true
	actualizar_ui()


func _on_cerrar_mision() -> void:
	evento_revelado = false
	if table_popup:
		table_popup.visible = false
	mission_timer.wait_time = _tiempo_restante_al_abrir
	mission_timer.start()
	_timer_ya_iniciado = true
	actualizar_ui()
	_actualizar_mission_point()


func _on_mission_timeout() -> void:
	if evento_revelado:
		return
	_timer_ya_iniciado = false
	GameState.cancelar_evento_por_timeout()
	evento_revelado = false
	actualizar_ui()
	_actualizar_mission_point()


func _on_worker_clicked(worker_id: String) -> void:
	if GameState.partida_terminada:
		return
	if table_popup and table_popup.visible:
		# Misión abierta: asignar personaje al slot
		worker_asignado_mision = worker_id
		var w: Dictionary = GameState.get_trabajador(worker_id)
		if mission_slot_label and not w.is_empty():
			mission_slot_label.text = w.get("nombre", worker_id)
		if btn_aceptar:
			btn_aceptar.disabled = false
	else:
		# Sin misión abierta: mostrar stats del personaje
		_mostrar_stats_personaje(worker_id)


func _mostrar_stats_personaje(worker_id: String) -> void:
	var w: Dictionary = GameState.get_trabajador(worker_id)
	if w.is_empty() or not stats_popup:
		return
	# Pausar el temporizador de la misión mientras se ven los stats
	if mission_timer and mission_timer.time_left > 0:
		_tiempo_restante_al_abrir = mission_timer.time_left
		mission_timer.stop()
		_timer_pausado_por_stats = true
	if stats_popup_nombre:
		stats_popup_nombre.text = w.get("nombre", worker_id)
	if stats_popup_text:
		stats_popup_text.text = "Carisma %d | Cocina %d | Limpieza %d" % [
			w.get("carisma", 0), w.get("cocina", 0), w.get("limpieza", 0)
		]
	var viewport: Viewport = get_viewport()
	var popup_w: float = 180.0
	var popup_h: float = 130.0
	stats_popup.position = viewport.get_visible_rect().size * 0.5 - Vector2(popup_w * 0.5, popup_h * 0.5)
	stats_popup.visible = true


func _on_cerrar_stats() -> void:
	if stats_popup:
		stats_popup.visible = false
	# Reanudar el temporizador de la misión con el tiempo que quedaba
	if _timer_pausado_por_stats and mission_timer:
		_timer_pausado_por_stats = false
		mission_timer.wait_time = _tiempo_restante_al_abrir
		mission_timer.start()
		_timer_ya_iniciado = true


func _on_aceptar_mision() -> void:
	if worker_asignado_mision.is_empty():
		return
	if GameState.eventos_activos.is_empty() or not evento_revelado:
		return
	mission_timer.stop()
	_worker_id_pendiente_tirada = worker_asignado_mision
	if table_popup:
		table_popup.visible = false
	if btn_aceptar:
		btn_aceptar.disabled = true
	_iniciar_animacion_d20()


func _iniciar_animacion_d20() -> void:
	_roll_data = GameState.rollar_para_evento(_worker_id_pendiente_tirada, 0)
	if _roll_data.is_empty():
		_finalizar_tirada_d20()
		return
	if label_d20:
		label_d20.text = "?"
		label_d20.add_theme_color_override("font_color", Color.WHITE)
	if label_plus_stat:
		label_plus_stat.text = ""
		label_plus_stat.add_theme_color_override("font_color", Color.WHITE)
	if label_total:
		label_total.text = ""
		label_total.add_theme_color_override("font_color", Color.WHITE)
	if d20_roll_overlay:
		d20_roll_overlay.visible = true
	# Instanciar la escena 3D del dado y añadirla al mundo principal
	var die_scene: PackedScene = load("res://scenes/d20_die.tscn") as PackedScene
	if die_scene:
		var instance: Node3D = die_scene.instantiate() as Node3D
		if instance:
			add_child(instance)
			instance.position = Vector3(0, 2.0, 0)
			instance.scale = Vector3(1.25, 1.25, 1.25)
			d20_die_instance = instance
			_add_face_labels_to_die(d20_die_instance)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	# Fase 1: giro dramático (Euler)
	if d20_die_instance:
		d20_die_instance.rotation = Vector3.ZERO
		tween.tween_property(d20_die_instance, "rotation", Vector3(TAU * 1.2, TAU * 0.8, TAU * 1.5), 1.2)
	# Fase 2: slerp a la orientación que deja la cara del valor obtenido hacia arriba
	if d20_die_instance and _roll_data.has("d20") and _roll_data["d20"] >= 1 and _roll_data["d20"] <= 20:
		var quat_final: Quaternion = _d20_quaternions_final[_roll_data["d20"] - 1]
		tween.tween_callback(func(): _d20_slerp_start = d20_die_instance.quaternion)
		tween.tween_method(func(t: float) -> void: d20_die_instance.quaternion = _d20_slerp_start.slerp(quat_final, t), 0.0, 1.0, 0.25)
		tween.tween_callback(func(): d20_die_instance.quaternion = quat_final)
	# Mostrar número del d20 cuando "para" el dado
	tween.tween_callback(func(): _mostrar_numero_d20())
	tween.tween_interval(0.4)
	# Mostrar "+ stat"
	tween.tween_callback(func(): _mostrar_plus_stat())
	tween.tween_interval(0.35)
	# Mostrar "= total"
	tween.tween_callback(func(): _mostrar_total())
	tween.tween_interval(0.5)
	tween.tween_callback(_finalizar_tirada_d20)


func _mostrar_numero_d20() -> void:
	if label_d20 and _roll_data.has("d20"):
		label_d20.text = str(_roll_data["d20"])


func _mostrar_plus_stat() -> void:
	if label_plus_stat and _roll_data.has("stat_val"):
		label_plus_stat.text = "+ %s %d" % [_roll_data.get("stat_name", ""), _roll_data["stat_val"]]


func _mostrar_total() -> void:
	if label_total and _roll_data.has("resultado"):
		var resultado: int = _roll_data["resultado"]
		label_total.text = "= %d" % resultado
		var es_fallo: bool = resultado <= GameState.UMBRAL_FALLO
		var color_resultado: Color = Color.RED if es_fallo else Color.WHITE
		if label_d20:
			label_d20.add_theme_color_override("font_color", color_resultado)
		if label_plus_stat:
			label_plus_stat.add_theme_color_override("font_color", color_resultado)
		if label_total:
			label_total.add_theme_color_override("font_color", color_resultado)


func _finalizar_tirada_d20() -> void:
	if d20_roll_overlay:
		d20_roll_overlay.visible = false
	if d20_die_instance:
		d20_die_instance.queue_free()
		d20_die_instance = null
	if not _roll_data.is_empty():
		GameState.aplicar_roll_guardado()
		_roll_data = {}
	_worker_id_pendiente_tirada = ""
	evento_revelado = false
	_timer_ya_iniciado = false
	worker_asignado_mision = ""
	actualizar_ui()
	_actualizar_mission_point()


func _on_reintentar() -> void:
	mission_timer.stop()
	evento_revelado = false
	_timer_ya_iniciado = false
	worker_asignado_mision = ""
	_worker_id_pendiente_tirada = ""
	if d20_roll_overlay:
		d20_roll_overlay.visible = false
	if d20_die_instance:
		d20_die_instance.queue_free()
		d20_die_instance = null
	if stats_popup:
		stats_popup.visible = false
	if table_popup:
		table_popup.visible = false
	GameState.reiniciar_partida()
	actualizar_ui()
	_actualizar_mission_point()


func actualizar_ui() -> void:
	if feedback != null:
		feedback.text = GameState.ultimo_feedback if GameState.ultimo_feedback else "Pulsa el punto (•) para ver la misión. Pulsa un personaje para ver sus stats o para asignarlo (con la misión abierta). Aceptar para resolver. Tienes 6 s."

	if oro_label != null:
		oro_label.text = "Oro: %d" % GameState.oro_partida

	if btn_reintentar != null:
		btn_reintentar.visible = GameState.partida_terminada
