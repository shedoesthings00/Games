extends Resource
class_name ProductData

@export var id: String = ""
@export var display_name: String = ""
@export var category: String = ""
@export var icon: Texture2D

# Tiempo que tarda en recogerse (rápido/lento).
# Ejemplos: 0.2 rápido, 1.2 lento
@export var pickup_time: float = 0.2

# Precio unitario (para cobrar en caja).
@export var price: float = 1.0

