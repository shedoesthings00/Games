extends Resource
class_name WaveDefinition

# Lista de entradas (idealmente Resources con propiedades `scene` y `count`,
# por ejemplo `SpawnEntry`).
@export var entries: Array = []

# Opcional: permite ajustar cómo spawnea esta oleada.
@export var spawn_interval: float = 2.0
@export var max_alive: int = 5

