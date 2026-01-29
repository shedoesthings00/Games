extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var ammo_label: Label = $Control/AmmoLabel

func set_health(current: int, max_value: int) -> void:
	if health_bar == null:
		return
	health_bar.max_value = max_value
	health_bar.value = current

func set_ammo(current: int, max_value: int) -> void:
	if ammo_label == null:
		return
	ammo_label.text = str(current, " / ", max_value)
