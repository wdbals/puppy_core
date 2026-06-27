class_name EngineConfig
## Configuraciones para el puppies engine

# CONFIGURACIÓN DE AUDIO
const DEFAULT_AUDIO_BUSES := {
	"Master": {"volume": 1.0, "muted": false},
	"SFX": {"volume": 0.8, "muted": false},
	"Music": {"volume": 0.6, "muted": false},
	"Voice": {"volume": 0.9, "muted": false}
}

const AUDIO_SOUND_POOL_SIZE := 10
const AUDIO_DEFAULT_MUSIC_FADE := 1.0
const AUDIO_DEFAULT_CROSSFADE := 2.0
const AUDIO_DEFAULT_ATTENUATION_PAUSE_SOUND := 0.45
const AUDIO_DEFAULT_ATTENUATION_TANSITION_SOUND := 0.9

const AUDIO_DEFAULT_MUSIC_NAME := "[SIN NOMBRE]"
const AUDIO_MUSIC_STATUS_SILENCE := "[SILENCIO]"

# CONFIGURACIÓN DE VIDEO Y VENTANA
const VIDEO_DEFAULT_WINDOW_SIZE := Vector2i(640, 360)
const VIDEO_DEFAULT_WINDOW_MODE := DisplayServer.WINDOW_MODE_MAXIMIZED
const VIDEO_DEFAULT_VSYNC := DisplayServer.VSYNC_ENABLED

const VIDEO_AVAILABLE_RESOLUTIONS : Array[Vector2i] = [
	Vector2i(640, 360),    # 360p  - Nativo para juegos pixel art
	Vector2i(854, 480),    # 480p  - Resolución estándar baja
	Vector2i(960, 540),    # 540p  - qHD
	Vector2i(1280, 720),   # 720p  - HD
	Vector2i(1366, 768),   # 768p  - Laptop común
	Vector2i(1600, 900),   # 900p  - HD+
	Vector2i(1920, 1080),  # 1080p - Full HD
	Vector2i(2560, 1440),  # 1440p - 2K
	Vector2i(3840, 2160)   # 2160p - 4K
]

# CONFIGURACIÓN DE EXTENSIONES
const EXTENSION_SAVE_FILE := ".save"
const EXTENSION_CONFIG_FILE := ".cfg"

# CONFIGURACIÓN DE GUARDADO
const SAVE_USE_ENCRYPTION := false
const SAVE_MAX_SAVE_SLOTS := 5
const SAVE_AUTOSAVE_INTERVAL := 300.0  # 5 minutos en segundos

# CONFIGURACIÓN DE INPUT
const INPUT_DEFAULT_DEADZONE := 0.2
const INPUT_BUFFER_TIME := 0.1
const INPUT_DEFAULT_MOUSE_SENSITIVITY := 1.0
const INPUT_DEFAULT_GAMEPAD_DEADZONE := 0.25
const INPUT_ALLOW_INPUT_REBINDING := true

# CONFIGURACIÓN DEL JUEGO
const GAME_DEFAULT_SPEED := 1.0
const GAME_MAX_PHYSICS_FPS := 60
const GAME_TIME_SCALE_MIN := 0.1
const GAME_TIME_SCALE_MAX := 3.0

# CONFIGURACIÓN DEL ENGINE
const ENGINE_NAME := "Puppies Engine"
const ENGINE_SUPPORTED_GODOT_VERSIONS := ["4.2", "4.3"]

# MÉTODOS UTILITARIOS

static func get_engine_version() -> String:
	return "1.0.0"

static func get_engine_name() -> String:
	return ENGINE_NAME

static func is_debug_build() -> bool:
	return OS.is_debug_build()

static func is_release_build() -> bool:
	return not OS.is_debug_build()

static func get_supported_godot_versions() -> Array:
	return ENGINE_SUPPORTED_GODOT_VERSIONS

static func is_godot_version_supported(version: String) -> bool:
	return version in ENGINE_SUPPORTED_GODOT_VERSIONS
