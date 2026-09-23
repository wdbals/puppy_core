extends Node
## Optional singleton for reading and writing independent save modules.

signal saving(slot: String)
signal save_completed(slot: String, result: Error)
signal loading(slot: String)
signal load_completed(slot: String, result: Error)

const _SECRET_KEY := "puppies-x7z-secure"


## Writes one module and returns the underlying Godot error code.
func write_module(slot_name: String, module: SaveModule) -> Error:
	saving.emit(slot_name)
	var config := ConfigFile.new()
	var result := _load_config_file(slot_name, config, true)

	if result == OK:
		result = _write_module_data_to_config(config, module)
	if result == OK:
		_update_metadata(config)
		result = _save_config_to_disk(slot_name, config)

	save_completed.emit(slot_name, result)
	return result


## Writes multiple modules in one disk operation and returns the first error.
func write_modules_batch(slot_name: String, modules: Array[SaveModule]) -> Error:
	saving.emit(slot_name)
	var config := ConfigFile.new()
	var result := _load_config_file(slot_name, config, true)

	if result == OK:
		for module in modules:
			result = _write_module_data_to_config(config, module)
			if result != OK:
				break

	if result == OK:
		_update_metadata(config)
		result = _save_config_to_disk(slot_name, config)

	save_completed.emit(slot_name, result)
	return result


## Reads and restores one module, preserving its specific error code.
func read_module(slot_name: String, module: SaveModule) -> Error:
	loading.emit(slot_name)
	var config := ConfigFile.new()
	var result := _load_config_file(slot_name, config, false)

	if result == OK:
		result = _read_module_data_from_config(config, module)

	load_completed.emit(slot_name, result)
	return result


## Restores modules in order and returns the first error encountered.
func read_modules_batch(slot_name: String, modules: Array[SaveModule]) -> Error:
	loading.emit(slot_name)
	var config := ConfigFile.new()
	var result := _load_config_file(slot_name, config, false)

	if result == OK:
		for module in modules:
			result = _read_module_data_from_config(config, module)
			if result != OK:
				break

	load_completed.emit(slot_name, result)
	return result


func _write_module_data_to_config(config: ConfigFile, module: SaveModule) -> Error:
	if not module:
		return ERR_INVALID_PARAMETER

	var section := module.get_module_name().strip_edges()
	if section.is_empty():
		return ERR_INVALID_DATA

	module.pre_save()
	var data := module.capture_snapshot()
	config.erase_section(section)
	for key in data:
		config.set_value(section, key, data[key])
	return OK


func _read_module_data_from_config(config: ConfigFile, module: SaveModule) -> Error:
	if not module:
		return ERR_INVALID_PARAMETER

	var section := module.get_module_name().strip_edges()
	if section.is_empty():
		return ERR_INVALID_DATA
	if not config.has_section(section):
		return ERR_DOES_NOT_EXIST

	var data := {}
	for key in config.get_section_keys(section):
		data[key] = config.get_value(section, key)

	if not module.validate_data(data):
		return ERR_INVALID_DATA

	var result := module.restore_snapshot(data)
	if result != OK:
		return result

	module.post_load()
	return OK


func _load_config_file(
	slot_name: String,
	config: ConfigFile,
	allow_missing: bool
) -> Error:
	var validation_result := _validate_slot_name(slot_name)
	if validation_result != OK:
		return validation_result

	var path := _get_slot_path(slot_name)
	if not FileAccess.file_exists(path):
		return OK if allow_missing else ERR_FILE_NOT_FOUND

	if EngineConfig.SAVE_USE_ENCRYPTION:
		return config.load_encrypted_pass(path, _SECRET_KEY)
	return config.load(path)


func _save_config_to_disk(slot_name: String, config: ConfigFile) -> Error:
	var validation_result := _validate_slot_name(slot_name)
	if validation_result != OK:
		return validation_result

	var directory_result := _ensure_save_dir()
	if directory_result != OK:
		return directory_result

	var path := _get_slot_path(slot_name)
	if EngineConfig.SAVE_USE_ENCRYPTION:
		return config.save_encrypted_pass(path, _SECRET_KEY)
	return config.save(path)


func _validate_slot_name(slot_name: String) -> Error:
	var normalized_name := slot_name.strip_edges()
	if normalized_name.is_empty():
		return ERR_INVALID_PARAMETER
	if normalized_name.contains("/") or normalized_name.contains("\\"):
		return ERR_INVALID_PARAMETER
	if normalized_name == "." or normalized_name == "..":
		return ERR_INVALID_PARAMETER
	return OK


func _update_metadata(config: ConfigFile) -> void:
	config.set_value("meta", "last_updated", Time.get_unix_time_from_system())


func _get_slot_path(slot_name: String) -> String:
	return "user://saves/%s.cfg" % slot_name.strip_edges()


func _ensure_save_dir() -> Error:
	if DirAccess.dir_exists_absolute("user://saves"):
		return OK
	return DirAccess.make_dir_recursive_absolute("user://saves")
