class_name SaveEnums
## Shared types for the save system.

enum SaveResult {
	SUCCESS,
	ERROR_INVALID_SLOT,
	ERROR_FILE_WRITE,
	ERROR_FILE_READ,
	ERROR_VERSION_MISMATCH,
	ERROR_MODULE_FAILED,
	ERROR_LOAD_IN_PROGRESS,
}

enum SavePriority {
	LOW,
	NORMAL,
	HIGH,
	CRITICAL,
}

enum SaveType {
	MANUAL,
	AUTO,
	CHECKPOINT,
	QUICK,
}

enum CompressionMode {
	NONE,
	GZIP,
	LZ4,
}

enum EncryptionMode {
	NONE,
	AES,
	CUSTOM,
}


static func get_save_result_message(result: SaveResult) -> String:
	match result:
		SaveResult.SUCCESS: return "Operation completed successfully"
		SaveResult.ERROR_INVALID_SLOT: return "Invalid save slot"
		SaveResult.ERROR_FILE_WRITE: return "Could not write save file"
		SaveResult.ERROR_FILE_READ: return "Could not read save file"
		SaveResult.ERROR_VERSION_MISMATCH: return "Incompatible save version"
		SaveResult.ERROR_MODULE_FAILED: return "Save module failed"
		SaveResult.ERROR_LOAD_IN_PROGRESS: return "Cannot save while loading"
		_: return "Unknown error"


static func is_success(result: SaveResult) -> bool:
	return result == SaveResult.SUCCESS


static func is_error(result: SaveResult) -> bool:
	return result != SaveResult.SUCCESS
