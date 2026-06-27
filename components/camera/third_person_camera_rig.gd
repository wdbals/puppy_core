class_name ThirdPersonCameraRig extends Node3D

@export_group("Configuración de Cámara")
@export var spring_arm: SpringArm3D
@export var sensibilidad_mouse: float = 0.003
@export var suavidad_camara: float = 15.0
@export var limite_camara_arriba: float = 60.0
@export var limite_camara_abajo: float = -60.0
@export var min_arm := 0.0
@export var max_arm := 10.0

var rotacion_objetivo_y: float = 0.0
var rotacion_objetivo_x: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	# Iniciar con la rotación actual para evitar tirones
	rotacion_objetivo_y = rotation.y
	if spring_arm:
		rotacion_objetivo_x = spring_arm.rotation.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotacion_objetivo_y -= event.relative.x * sensibilidad_mouse
		rotacion_objetivo_x -= event.relative.y * sensibilidad_mouse
		
		rotacion_objetivo_x = clamp(
			rotacion_objetivo_x, 
			deg_to_rad(limite_camara_abajo), 
			deg_to_rad(limite_camara_arriba)
		)
	
	if event is InputEventMouseButton and event.pressed and spring_arm:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clampf(spring_arm.spring_length - 0.5, min_arm, max_arm)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clampf(spring_arm.spring_length + 0.5, min_arm, max_arm)

func _process(delta: float) -> void:
	# Suavizado independiente: rotación Y (este nodo) y rotación X (spring_arm)
	rotation.y = lerp_angle(rotation.y, rotacion_objetivo_y, suavidad_camara * delta)
	
	if spring_arm:
		spring_arm.rotation.x = lerpf(spring_arm.rotation.x, rotacion_objetivo_x, suavidad_camara * delta)
