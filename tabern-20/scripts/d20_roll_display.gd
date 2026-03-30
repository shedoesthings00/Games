extends Control
## Dibuja un dado D20 estilizado (icosaedro simplificado en 2D) y el texto "D20".
## Se usa dentro del overlay de tirada; main.gd anima la rotación de este nodo.

func _draw() -> void:
	var s := size
	var center := s / 2.0
	var r := minf(s.x, s.y) * 0.4
	# Polígono aproximado a un dado (octógono para simular volumen)
	var points: PackedVector2Array = []
	for i in range(8):
		var a := TAU * float(i) / 8.0 - TAU / 8.0
		points.append(center + Vector2(cos(a), sin(a)) * r)
	# Fondo del dado (gris claro)
	draw_colored_polygon(points, Color(0.9, 0.88, 0.82))
	# Borde
	draw_polyline(points, Color(0.3, 0.25, 0.2))
	draw_line(points[points.size() - 1], points[0], Color(0.3, 0.25, 0.2))
