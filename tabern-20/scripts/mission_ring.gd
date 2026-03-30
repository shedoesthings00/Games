extends Control
## Dibuja un anillo circular que se vacía en sentido horario (cuenta atrás).
## time_ratio: 1 = lleno, 0 = vacío. Se actualiza desde fuera (main.gd).

var time_ratio: float = 1.0

func _draw() -> void:
	var center := size * 0.5
	var radius_out: float = min(size.x, size.y) * 0.5 - 4.0
	var radius_in: float = radius_out - 10.0
	# 12h = -PI/2; sentido horario = ángulo decreciente
	var start_angle: float = -TAU / 4.0
	# Arco de fondo (gris)
	draw_arc(center, radius_out, start_angle, start_angle + TAU, 64, Color(0.35, 0.35, 0.4, 0.9))
	# Arco de tiempo restante (verde/amarillo), sentido horario
	var end_angle: float = start_angle + TAU * time_ratio
	if time_ratio > 0.001:
		# Dibujar anillo: dos arcos con grosor (simulado con polyline o segundo arco)
		for i in range(64):
			var t0: float = float(i) / 64.0
			var t1: float = float(i + 1) / 64.0
			var a0: float = start_angle + (end_angle - start_angle) * t0
			var a1: float = start_angle + (end_angle - start_angle) * t1
			var p0_in := center + Vector2(cos(a0), sin(a0)) * radius_in
			var p0_out := center + Vector2(cos(a0), sin(a0)) * radius_out
			var p1_out := center + Vector2(cos(a1), sin(a1)) * radius_out
			var p1_in := center + Vector2(cos(a1), sin(a1)) * radius_in
			var col: Color = Color(0.2, 0.75, 0.35, 0.95)
			draw_colored_polygon(PackedVector2Array([p0_in, p0_out, p1_out, p1_in]), col)
