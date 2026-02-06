extends CanvasLayer

@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var ammo_label: Label = $Control/AmmoLabel
@onready var enemies_label: Label = $Control/EnemiesLabel
@onready var boss_health_bar: ProgressBar = $Control/BossHealthBar
@onready var reload_circle: TextureProgressBar = $Control/ReloadCircle

var _reload_spin_speed: float = 4.0

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


func set_boss_health(current: int, max_value: int) -> void:
	if boss_health_bar == null:
		return
	boss_health_bar.visible = true
	boss_health_bar.max_value = max_value
	boss_health_bar.value = current


func hide_boss_health() -> void:
	if boss_health_bar == null:
		return
	boss_health_bar.visible = false
	
func show_reload_progress() -> void:
	if reload_circle == null:
		return
	reload_circle.visible = true
	reload_circle.value = 0.0


func set_reload_progress(t: float) -> void:
	# t entre 0.0 y 1.0
	if reload_circle == null:
		return
	reload_circle.value = clamp(t, 0.0, 1.0)


func hide_reload_progress() -> void:
	if reload_circle == null:
		return
	reload_circle.visible = false
	
func _process(delta: float) -> void:
	# Si el círculo está visible, lo giramos
	if reload_circle != null and reload_circle.visible:
		reload_circle.rotation += _reload_spin_speed * delta
		
