extends Control

## Pantalla de hub/tienda entre noches.
## Muestra el oro ganado y permite subir stats de los personajes pagando.

const COSTE_MEJORA := 5

var oro_label: Label
var lista_trabajadores: VBoxContainer
var feedback_label: Label


func _ready() -> void:
	print("[HUB] _ready. Oro partida = ", GameState.oro_partida)
	oro_label = get_node_or_null("MarginContainer/VBox/OroLabel") as Label
	lista_trabajadores = get_node_or_null("MarginContainer/VBox/TrabajadoresVBox") as VBoxContainer
	feedback_label = get_node_or_null("MarginContainer/VBox/FeedbackLabel") as Label

	_refrescar_oro()
	_crear_ui_trabajadores()


func _refrescar_oro() -> void:
	if oro_label:
		oro_label.text = "Oro disponible: %d" % GameState.oro_partida
	print("[HUB] Oro actualizado: ", GameState.oro_partida)


func _crear_ui_trabajadores() -> void:
	if lista_trabajadores == null:
		return
	# Limpiar hijos anteriores manualmente (no existe queue_free_children en Godot)
	for child in lista_trabajadores.get_children():
		child.queue_free()

	for t in GameState.trabajadores:
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 12)

		var nombre_label := Label.new()
		nombre_label.text = t.get("nombre", "???")
		nombre_label.custom_minimum_size = Vector2(100, 0)
		fila.add_child(nombre_label)

		var stats_label := Label.new()
		var cid: String = t.get("id", "")
		var carisma := GameState.get_stat_trabajador(cid, "carisma")
		var cocina := GameState.get_stat_trabajador(cid, "cocina")
		var limpieza := GameState.get_stat_trabajador(cid, "limpieza")
		stats_label.text = "Carisma %d | Cocina %d | Limpieza %d" % [carisma, cocina, limpieza]
		stats_label.custom_minimum_size = Vector2(260, 0)
		fila.add_child(stats_label)

		fila.add_child(_crear_boton_mejora("carisma", "+ Carisma", true))
		fila.add_child(_crear_boton_mejora("carisma", "- Carisma", false))
		fila.add_child(_crear_boton_mejora("cocina", "+ Cocina", true))
		fila.add_child(_crear_boton_mejora("cocina", "- Cocina", false))
		fila.add_child(_crear_boton_mejora("limpieza", "+ Limpieza", true))
		fila.add_child(_crear_boton_mejora("limpieza", "- Limpieza", false))

		lista_trabajadores.add_child(fila)


func _crear_boton_mejora(stat_key: String, texto: String, subir: bool) -> Button:
	var btn := Button.new()
	btn.text = texto
	btn.pressed.connect(func() -> void:
		if subir:
			_intentar_mejora(stat_key)
		else:
			_intentar_revertir(stat_key)
	)
	return btn


func _intentar_mejora(stat_key: String) -> void:
	var ok := GameState.comprar_mejora(stat_key, COSTE_MEJORA)
	if ok:
		if feedback_label:
			feedback_label.text = "Has mejorado %s por %d de oro." % [GameState.get_nombre_stat(stat_key), COSTE_MEJORA]
		_refrescar_oro()
		_crear_ui_trabajadores()
	else:
		if feedback_label:
			feedback_label.text = "No tienes suficiente oro para mejorar %s." % GameState.get_nombre_stat(stat_key)


func _intentar_revertir(stat_key: String) -> void:
	var ok := GameState.revertir_mejora(stat_key, COSTE_MEJORA)
	if ok:
		if feedback_label:
			feedback_label.text = "Has deshecho una mejora de %s y recuperado %d de oro." % [GameState.get_nombre_stat(stat_key), COSTE_MEJORA]
		_refrescar_oro()
		_crear_ui_trabajadores()
	else:
		if feedback_label:
			feedback_label.text = "Solo puedes quitar mejoras compradas esta ronda en %s." % GameState.get_nombre_stat(stat_key)


func _on_NuevaNocheButton_pressed() -> void:
	GameState.reiniciar_partida()
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file("res://scenes/main.tscn")
