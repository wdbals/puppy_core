@abstract
class_name IMovementComponent extends Node3D

@export var body: CharacterBody3D
@export var orientation_node: Node3D

@export_group("Configuración de Movimiento")
@export var velocidad_maxima: float = 5.0
@export var velocidad_retroceso: float = 2.5
@export var aceleracion: float = 15.0
@export var friccion: float = 20.0

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var input_dir := Vector2.ZERO

@abstract
func _physics_process(delta: float) -> void
