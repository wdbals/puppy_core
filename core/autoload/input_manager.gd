extends Node
## Singleton para gestión de input unificado
##
## Proporciona una capa de abstracción sobre teclado, mouse y gamepad.
## Maneja deadzones por acción, sensibilidad e input buffering.

signal input_device_changed(device_type: InputEnums.InputDevice)
signal control_rebound(action: String, old_event: InputEvent, new_event: InputEvent)
signal input_buffer_triggered(action: String)
signal action_deadzone_changed(action: String, deadzone: float)

var _current_device: InputEnums.InputDevice = InputEnums.InputDevice.KEYBOARD
var _input_buffer: Dictionary = {}
var _action_states: Dictionary = {}
var _action_deadzones: Dictionary = {}
var _mouse_sensitivity: float = EngineConfig.INPUT_DEFAULT_MOUSE_SENSITIVITY

func _ready() -> void:
	_initialize_action_states()
	_initialize_action_deadzones()
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

	print("InputManager iniciado")

func _input(event: InputEvent) -> void:
	_detect_input_device(event)
	_update_input_buffer(event)

func _process(_delta: float) -> void:
	_update_action_states()
	_process_input_buffer()

## Inicializa el estado de seguimiento de todas las acciones
func _initialize_action_states() -> void:
	var actions = InputMap.get_actions()
	for action in actions:
		_action_states[action] = {
			"pressed": false,
			"just_pressed": false,
			"just_released": false,
			"strength": 0.0
		}

## Inicializa los deadzones por acción
func _initialize_action_deadzones() -> void:
	var actions = InputMap.get_actions()
	for action in actions:
		# Usar el deadzone actual del InputMap o el valor por defecto
		var current_deadzone = InputMap.action_get_deadzone(action)
		_action_deadzones[action] = current_deadzone

# GESTIÓN DE DEADZONES POR ACCIÓN

## Establece el deadzone para una acción específica
func set_action_deadzone(action: String, deadzone: float) -> void:
	if not InputMap.has_action(action):
		push_error("La acción no existe: ", action)
		return

	var clamped_deadzone = clampf(deadzone, 0.0, 1.0)
	InputMap.action_set_deadzone(action, clamped_deadzone)
	_action_deadzones[action] = clamped_deadzone
	action_deadzone_changed.emit(action, clamped_deadzone)

	print("Deadzone de '", action, "' establecido a: ", clamped_deadzone)

## Obtiene el deadzone actual de una acción
func get_action_deadzone(action: String) -> float:
	return _action_deadzones.get(action, EngineConfig.INPUT_DEFAULT_GAMEPAD_DEADZONE)

## Establece el deadzone para múltiples acciones a la vez
func set_actions_deadzone(actions: Array[String], deadzone: float) -> void:
	for action in actions:
		if InputMap.has_action(action):
			set_action_deadzone(action, deadzone)

## Aplica el deadzone por defecto a todas las acciones
func apply_default_deadzone_to_all_actions() -> void:
	var actions = InputMap.get_actions()
	for action in actions:
		set_action_deadzone(action, EngineConfig.INPUT_DEFAULT_GAMEPAD_DEADZONE)

## Obtiene todas las acciones que tienen gamepad axes (para deadzones)
func get_axis_actions() -> Array[String]:
	var axis_actions = []
	var actions = InputMap.get_actions()

	for action in actions:
		var events = InputMap.action_get_events(action)
		for event in events:
			if event is InputEventJoypadMotion:
				axis_actions.append(action)
				break

	return axis_actions

## Aplica deadzone solo a acciones de ejes de gamepad
func set_gamepad_axes_deadzone(deadzone: float) -> void:
	var axis_actions = get_axis_actions()
	set_actions_deadzone(axis_actions, deadzone)

# DETECCIÓN DE DISPOSITIVO

## Detecta el tipo de dispositivo de entrada actual
func _detect_input_device(event: InputEvent) -> void:
	var new_device: InputEnums.InputDevice = _current_device

	if event is InputEventKey or event is InputEventMouse:
		new_device = InputEnums.InputDevice.KEYBOARD
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		new_device = InputEnums.InputDevice.GAMEPAD

	if new_device != _current_device:
		_current_device = new_device
		input_device_changed.emit(_current_device)

## Se ejecuta cuando se conecta/desconecta un gamepad
func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		print("Gamepad conectado: ", device_id)
	else:
		print("Gamepad desconectado: ", device_id)

		if _current_device == InputEnums.InputDevice.GAMEPAD:
			_current_device = InputEnums.InputDevice.KEYBOARD
			input_device_changed.emit(_current_device)

# ESTADO DE ACCIONES CON DEADZONE APLICADO

## Actualiza el estado de todas las acciones aplicando deadzones
func _update_action_states() -> void:
	for action in _action_states:
		var state = _action_states[action]
		var deadzone = get_action_deadzone(action)
		var raw_strength = Input.get_action_strength(action)

		# Aplicar deadzone
		var effective_strength = 0.0
		if raw_strength > deadzone:
			# Re-mapear el rango [deadzone, 1.0] a [0.0, 1.0]
			effective_strength = (raw_strength - deadzone) / (1.0 - deadzone)

		var current_pressed = effective_strength > 0.0

		state["just_pressed"] = not state["pressed"] and current_pressed
		state["just_released"] = state["pressed"] and not current_pressed
		state["pressed"] = current_pressed
		state["strength"] = effective_strength

## Verifica si una acción está presionada (considerando deadzone)
func is_action_pressed(action: String) -> bool:
	return _action_states.get(action, {}).get("pressed", false)

## Verifica si una acción fue presionada en este frame
func is_action_just_pressed(action: String) -> bool:
	return _action_states.get(action, {}).get("just_pressed", false)

## Verifica si una acción fue liberada en este frame
func is_action_just_released(action: String) -> bool:
	return _action_states.get(action, {}).get("just_released", false)

## Obtiene la fuerza/intensidad de una acción (con deadzone aplicado)
func get_action_strength(action: String) -> float:
	return _action_states.get(action, {}).get("strength", 0.0)

## Obtiene la fuerza bruta de una acción (sin deadzone aplicado)
func get_action_raw_strength(action: String) -> float:
	return Input.get_action_strength(action)

# INPUT BUFFERING

## Actualiza el buffer de input
func _update_input_buffer(event: InputEvent) -> void:
	if not event.is_pressed():
		return

	for action in InputMap.get_actions():
		if event.is_action(action):
			_input_buffer[action] = Time.get_ticks_msec()
			break

## Procesa el buffer de input y ejecuta acciones pendientes
func _process_input_buffer() -> void:
	var current_time = Time.get_ticks_msec()
	var expired_actions = []

	for action in _input_buffer:
		if current_time - _input_buffer[action] <= EngineConfig.INPUT_BUFFER_TIME * 1000:
			input_buffer_triggered.emit(action)
		else:
			expired_actions.append(action)

	for action in expired_actions:
		_input_buffer.erase(action)

## Limpia el buffer de input para una acción específica
func clear_input_buffer(action: String) -> void:
	_input_buffer.erase(action)

## Limpia todo el buffer de input
func clear_all_input_buffers() -> void:
	_input_buffer.clear()

# GESTIÓN DE CONTROLES

## Obtiene el evento principal para una acción
func get_action_event(action: String) -> InputEvent:
	var events = InputMap.action_get_events(action)
	if events.size() > 0:
		return events[0]
	return null

## Obtiene todos los eventos para una acción
func get_action_events(action: String) -> Array[InputEvent]:
	return InputMap.action_get_events(action)

## Reasigna un evento a una acción
func rebind_action(action: String, new_event: InputEvent) -> bool:
	if not EngineConfig.INPUT_ALLOW_INPUT_REBINDING:
		push_warning("El rebinding de controles está desactivado en la configuración")
		return false

	var old_events = get_action_events(action)
	if old_events.size() > 0:
		var old_event = old_events[0]

		InputMap.action_erase_event(action, old_event)
		InputMap.action_add_event(action, new_event)

		control_rebound.emit(action, old_event, new_event)
		print("Control reasignado: ", action, " -> ", _get_event_description(new_event))
		return true

	return false

## Restaura los controles por defecto para una acción
func restore_default_binding(action: String) -> void:
	push_warning("Restaurar controles por defecto no implementado para: ", action)

# CONFIGURACIÓN DE MOUSE

## Establece la sensibilidad del mouse
func set_mouse_sensitivity(sensitivity: float) -> void:
	_mouse_sensitivity = maxf(sensitivity, 0.1)

## Obtiene la sensibilidad actual del mouse
func get_mouse_sensitivity() -> float:
	return _mouse_sensitivity

# UTILIDADES

## Obtiene el tipo de dispositivo de entrada actual
func get_current_input_device() -> InputEnums.InputDevice:
	return _current_device

## Verifica si se está usando gamepad
func is_using_gamepad() -> bool:
	return _current_device == InputEnums.InputDevice.GAMEPAD

## Verifica si se está usando teclado/mouse
func is_using_keyboard() -> bool:
	return _current_device == InputEnums.InputDevice.KEYBOARD

## Obtiene una descripción legible de un evento de input
func _get_event_description(event: InputEvent) -> String:
	if event is InputEventKey:
		return "Tecla: " + OS.get_keycode_string(event.keycode)
	elif event is InputEventMouseButton:
		return "Mouse: Botón " + str(event.button_index)
	elif event is InputEventJoypadButton:
		return "Gamepad: Botón " + str(event.button_index)
	elif event is InputEventJoypadMotion:
		return "Gamepad: Eje " + str(event.axis)
	else:
		return "Evento desconocido"

## Aplica la configuración por defecto del engine
func apply_engine_defaults() -> void:
	apply_default_deadzone_to_all_actions()
	set_mouse_sensitivity(EngineConfig.INPUT_DEFAULT_MOUSE_SENSITIVITY)

## Obtiene un resumen de la configuración actual
func get_config_summary() -> Dictionary:
	return {
		"current_device": InputEnums.get_device_name(_current_device),
		"mouse_sensitivity": _mouse_sensitivity,
		"axis_actions_count": get_axis_actions().size(),
		"total_actions": InputMap.get_actions().size()
	}
