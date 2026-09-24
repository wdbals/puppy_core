class_name AudioSettingsModule
extends SaveModule
## Persists volume and mute preferences for buses managed by AudioManager.

const MODULE_NAME := "audio"
const BUSES_KEY := "buses"
const VERSION_KEY := "version"

var _audio_manager: Node


func _init(audio_manager: Node = null) -> void:
	_audio_manager = audio_manager


func get_module_name() -> String:
	return MODULE_NAME


func get_module_version() -> String:
	return "1.0.0"


func capture_snapshot() -> Dictionary:
	if not _is_audio_manager_compatible():
		push_error("AudioSettingsModule requires a compatible AudioManager instance.")
		return {}

	var buses := {}
	for bus in AudioEnums.BusName.values():
		var state: Dictionary = _audio_manager.get_bus_state(bus)
		if state.is_empty():
			continue
		buses[String(state.name)] = {
			"volume": clampf(float(state.volume), 0.0, 1.0),
			"muted": bool(state.muted),
		}

	return {
		VERSION_KEY: get_module_version(),
		BUSES_KEY: buses,
	}


func validate_data(data: Dictionary) -> bool:
	if not data.has(BUSES_KEY) or not data[BUSES_KEY] is Dictionary:
		return false

	var buses: Dictionary = data[BUSES_KEY]
	for bus_name in buses:
		if not bus_name is String and not bus_name is StringName:
			return false
		if not buses[bus_name] is Dictionary:
			return false

		var state: Dictionary = buses[bus_name]
		if state.has("volume") and typeof(state.volume) not in [TYPE_INT, TYPE_FLOAT]:
			return false
		if state.has("muted") and typeof(state.muted) != TYPE_BOOL:
			return false

	return true


func restore_snapshot(data: Dictionary) -> Error:
	if not _is_audio_manager_compatible():
		return ERR_UNCONFIGURED
	if not validate_data(data):
		return ERR_INVALID_DATA

	var buses: Dictionary = data[BUSES_KEY]
	for bus in AudioEnums.BusName.values():
		var current_state: Dictionary = _audio_manager.get_bus_state(bus)
		if current_state.is_empty():
			continue

		var bus_name := String(current_state.name)
		if not buses.has(bus_name):
			continue

		var saved_state: Dictionary = buses[bus_name]
		if saved_state.has("volume"):
			_audio_manager.set_bus_volume(
				bus,
				clampf(float(saved_state.volume), 0.0, 1.0)
			)
		if saved_state.get("muted", false):
			_audio_manager.mute_bus(bus)
		else:
			_audio_manager.unmute_bus(bus)

	return OK


func _is_audio_manager_compatible() -> bool:
	return is_instance_valid(_audio_manager) \
		and _audio_manager.has_method("get_bus_state") \
		and _audio_manager.has_method("set_bus_volume") \
		and _audio_manager.has_method("mute_bus") \
		and _audio_manager.has_method("unmute_bus")
