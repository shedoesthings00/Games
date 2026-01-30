extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var ammo_label: Label = $Control/AmmoLabel
@onready var enemies_label: Label = $Control/EnemiesLabel

func set_health(current: int, max_value: int) -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_value
	health_bar.value = current

func set_ammo(current: int, max_value: int) -> void:
	if ammo_label == null:
		return
	ammo_label.text = str(current, " / ", max_value)

func set_enemies_remaining(current: int) -> void:
	if enemies_label == null:
		return
	enemies_label.text = str(current)
