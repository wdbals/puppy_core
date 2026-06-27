class_name SaveEnums
## Enums para sistema de guardado

enum SaveResult {
	SUCCESS = 0,
	ERROR_INVALID_SLOT = 1,
	ERROR_FILE_WRITE = 2,
	ERROR_FILE_READ = 3,
	ERROR_VERSION_MISMATCH = 4,
	ERROR_MODULE_FAILED = 5,
	ERROR_LOAD_IN_PROGRESS = 6
}

enum SavePriority {
	LOW = 0,       # Guardado automático en segundo plano
	NORMAL = 1,    # Guardado manual del jugador
	HIGH = 2,      # Guardado crítico (checkpoint)
	CRITICAL = 3   # Guardado forzado (antes de salir)
}

enum SaveType {
	MANUAL = 0,    # Guardado manual del jugador
	AUTO = 1,      # Guardado automático
	CHECKPOINT = 2, # Guardado en checkpoint
	QUICK = 3      # Guardado rápido
}

enum CompressionMode {
	NONE = 0,      # Sin compresión
	GZIP = 1,      # Compresión GZIP (para texto)
	LZ4 = 2        # Compresión LZ4 (rápida)
}

enum EncryptionMode {
	NONE = 0,      # Sin encriptación
	AES = 1,       # Encriptación AES
	CUSTOM = 2     # Encriptación personalizada
}

# MÉTODOS UTILITARIOS

static func get_save_result_message(result: SaveResult) -> String:
	match result:
		SaveResult.SUCCESS:
			return "Operación completada exitosamente"
		SaveResult.ERROR_INVALID_SLOT:
			return "Slot de guardado inválido"
		SaveResult.ERROR_FILE_WRITE:
			return "Error al escribir archivo de guardado"
		SaveResult.ERROR_FILE_READ:
			return "Error al leer archivo de guardado"
		SaveResult.ERROR_VERSION_MISMATCH:
			return "Versión de guardado incompatible"
		SaveResult.ERROR_MODULE_FAILED:
			return "Error en módulo de guardado"
		SaveResult.ERROR_LOAD_IN_PROGRESS:
			return "No se puede guardar mientras se carga"
		_:
			return "Error desconocido"

static func is_success(result: SaveResult) -> bool:
	return result == SaveResult.SUCCESS

static func is_error(result: SaveResult) -> bool:
	return result != SaveResult.SUCCESS
