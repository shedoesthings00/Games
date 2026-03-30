extends Node
class_name PickupFeedback

@export var popup_path: NodePath
@export var particles_path: NodePath
@export var audio_path: NodePath

@onready var popup: PickupPopup = get_node_or_null(popup_path) as PickupPopup
@onready var particles: GPUParticles3D = get_node_or_null(particles_path) as GPUParticles3D
@onready var audio: AudioStreamPlayer = get_node_or_null(audio_path) as AudioStreamPlayer

func play_pickup(product_name: String) -> void:
	if popup != null:
		popup.show_text("+1 %s" % product_name)
	if particles != null:
		particles.restart()
		particles.emitting = true
	if audio != null and audio.stream != null:
		audio.play()

func play_not_needed(product_name: String) -> void:
	if popup != null:
		popup.show_text("No está en el pedido: %s" % product_name)

func show_message(text_value: String) -> void:
	if popup != null:
		popup.show_text(text_value)
