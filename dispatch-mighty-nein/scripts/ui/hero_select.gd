extends Control
## Pantalla de selección de héroes: muestra el roster TMN y botón Empezar partida.
## Todos participan por defecto; se puede usar para confirmar antes de jugar.

@onready var hero_list: GridContainer = $Margin/VBox/HeroList
@onready var start_button: Button = $Margin/VBox/StartButton
@onready var back_button: Button = $Margin/VBox/BackButton

func _ready() -> void:
	start_button.pressed.connect(_on_start)
	back_button.pressed.connect(_on_back)
	_build_hero_list()

func _build_hero_list() -> void:
	for c in hero_list.get_children():
		c.queue_free()
	var heroes: Array = HeroManager.get_all_heroes()
	for h in heroes:
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(200, 60)
		var v: VBoxContainer = VBoxContainer.new()
		var name_lbl: Label = Label.new()
		name_lbl.text = h.display_name
		var stats_lbl: Label = Label.new()
		stats_lbl.text = "C:%d I:%d M:%d Ch:%d V:%d" % [h.combat, h.intellect, h.mobility, h.charisma, h.vigor]
		stats_lbl.add_theme_font_size_override("font_size", 12)
		v.add_child(name_lbl)
		v.add_child(stats_lbl)
		panel.add_child(v)
		hero_list.add_child(panel)

func _on_start() -> void:
	GameManager.start_game()
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
