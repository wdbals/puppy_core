class_name SaveEnums
## Optional domain types for save scheduling and storage configuration.

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
