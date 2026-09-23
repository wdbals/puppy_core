extends Node
## Optional singleton for reading and writing independent save modules.

signal saving(slot: String)
signal save_completed(slot: String, success: bool)

signal loading(slot: String)
signal load_completed(slot: String, success: bool)

const _SECRET_KEY: String = "puppies-x7z-secure"

func write_module(slot_name: String, module: SaveModule) -> void:
	saving.emit(slot_name)
	var config = _load_config_file(slot_name)

	_write_module_data_to_config(config, module)
	_save_config_to_disk(slot_name, config)

func write_modules_batch(slot_name: String, modules: Array[SaveModule]) -> void:
	saving.emit(slot_name)
	var config = _load_config_file(slot_name)

	for module in modules:
		_write_module_data_to_config(config, module)

	_save_config_to_disk(slot_name, config)

# WRITE HELPERS
func _write_module_data_to_config(config: ConfigFile, module: SaveModule) -> void:
	module.pre_save()
	var section = module.get_module_name()
	var data = module.capture_snapshot()

	for key in data:
		config.set_value(section, key, data[key])

	# Refresh the shared timestamp whenever any module is written.
	config.set_value("meta", "last_updated", Time.get_unix_time_from_system())

# READ

## Reads one module from a slot.
func read_module(slot_name: String, module: SaveModule) -> bool:
	loading.emit(slot_name)
	var config = _load_config_file(slot_name)

	var success = _read_module_data_from_config(config, module)

	load_completed.emit(slot_name, success)
	return success

## Reads multiple modules with one disk operation.
func read_modules_batch(slot_name: String, modules: Array[SaveModule]) -> bool:
	loading.emit(slot_name)
	var config = _load_config_file(slot_name)

	var all_success = true

	for module in modules:
		var single_success = _read_module_data_from_config(config, module)
		if not single_success:
			all_success = false

	load_completed.emit(slot_name, all_success)
	return all_success

# READ HELPERS
func _read_module_data_from_config(config: ConfigFile, module: SaveModule) -> bool:
	var section = module.get_module_name()

	if not config.has_section(section):
		return false

	var data = {}
	for key in config.get_section_keys(section):
		data[key] = config.get_value(section, key)

	if module.validate_data(data):
		module.restore_snapshot(data)
		module.post_load()
		return true

	return false

# I/O

func _load_config_file(slot_name: String) -> ConfigFile:
	var config = ConfigFile.new()
	var path = _get_slot_path(slot_name)

	var err = OK
	if EngineConfig.SAVE_USE_ENCRYPTION:
		if FileAccess.file_exists(path):
			err = config.load_encrypted_pass(path, _SECRET_KEY)
	else:
		err = config.load(path)

	# A missing or invalid file behaves like an empty slot.
	if err != OK:
		push_warning("Could not load save file: " + path)

	return config

func _save_config_to_disk(slot_name: String, config: ConfigFile) -> void:
	_ensure_save_dir()
	var path = _get_slot_path(slot_name)

	var err = OK
	if EngineConfig.SAVE_USE_ENCRYPTION:
		err = config.save_encrypted_pass(path, _SECRET_KEY)
	else:
		err = config.save(path)

	save_completed.emit(slot_name, err == OK)

func _get_slot_path(slot_name: String) -> String:
	return "user://saves/%s.cfg" % slot_name

func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_absolute("user://saves")
