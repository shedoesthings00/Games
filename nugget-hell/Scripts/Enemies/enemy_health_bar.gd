extends ProgressBar

func set_health(current: int, max_value: int) -> void:
	# Ajustar el máximo a la vida máxima del enemigo
	self.max_value = max_value
	self.min_value = 0
	self.value = current
