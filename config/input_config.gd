class_name PuppyInputConfig
extends Resource
## Runtime defaults used by InputManager.

@export_range(0.0, 1.0, 0.01) var default_gamepad_deadzone := 0.25
@export_range(0.0, 2.0, 0.01) var input_buffer_time := 0.1
@export_range(0.1, 10.0, 0.05) var default_mouse_sensitivity := 1.0
@export var allow_input_rebinding := true
