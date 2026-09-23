class_name SaveModule
## Base class for one independently serialized section of a save file.
extends RefCounted

## Returns the module's stable, unique section name.
func get_module_name() -> String:
	push_error("SaveModule.get_module_name() must be overridden")
	return ""

## Captures serializable module data.
func capture_snapshot() -> Dictionary:
	push_error("SaveModule.capture_snapshot() must be overridden")
	return {}

## Restores module data and returns a Godot Error code.
func restore_snapshot(_data: Dictionary) -> Error:
	push_error("SaveModule.restore_snapshot() must be overridden")
	return ERR_METHOD_NOT_FOUND

# Hooks

## Returns the module schema version.
func get_module_version() -> String:
	return "1.0.0"

## Validates serialized data before it is restored.
func validate_data(_data: Dictionary) -> bool:
	return true

## Runs immediately before a snapshot is captured.
func pre_save() -> void:
	pass

## Runs after a snapshot is restored.
func post_load() -> void:
	pass
