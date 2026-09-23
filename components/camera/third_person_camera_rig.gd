class_name ThirdPersonCameraRig
extends Node3D

@export_group("Camera Configuration")
@export var spring_arm: SpringArm3D
@export var mouse_sensitivity := 0.003
@export var camera_smoothing := 15.0
@export var upper_camera_limit := 60.0
@export var lower_camera_limit := -60.0
@export var minimum_arm_length := 0.0
@export var maximum_arm_length := 10.0

var _target_y_rotation := 0.0
var _target_x_rotation := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_target_y_rotation = rotation.y
	if spring_arm:
		_target_x_rotation = spring_arm.rotation.x


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_target_y_rotation -= event.relative.x * mouse_sensitivity
		_target_x_rotation -= event.relative.y * mouse_sensitivity
		_target_x_rotation = clampf(
			_target_x_rotation,
			deg_to_rad(lower_camera_limit),
			deg_to_rad(upper_camera_limit)
		)

	if event is InputEventMouseButton and event.pressed and spring_arm:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			spring_arm.spring_length = clampf(
				spring_arm.spring_length - 0.5,
				minimum_arm_length,
				maximum_arm_length
			)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			spring_arm.spring_length = clampf(
				spring_arm.spring_length + 0.5,
				minimum_arm_length,
				maximum_arm_length
			)


func _process(delta: float) -> void:
	rotation.y = lerp_angle(rotation.y, _target_y_rotation, camera_smoothing * delta)
	if spring_arm:
		spring_arm.rotation.x = lerpf(
			spring_arm.rotation.x,
			_target_x_rotation,
			camera_smoothing * delta
		)
