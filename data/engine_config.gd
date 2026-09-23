class_name EngineConfig
## Default configuration shared by Puppy Core services.

const DEFAULT_AUDIO_BUSES := {
	"Master": {"volume": 1.0, "muted": false},
	"SFX": {"volume": 0.8, "muted": false},
	"UI": {"volume": 0.8, "muted": false},
	"Music": {"volume": 0.6, "muted": false},
	"Voice": {"volume": 0.9, "muted": false},
}

const AUDIO_SOUND_POOL_SIZE := 10
const AUDIO_DEFAULT_MUSIC_FADE := 1.0
const AUDIO_DEFAULT_CROSSFADE := 2.0
const AUDIO_DEFAULT_ATTENUATION_PAUSE_SOUND := 0.45
const AUDIO_DEFAULT_2D_MAX_DISTANCE := 2000.0
const AUDIO_DEFAULT_2D_ATTENUATION := 1.0
const AUDIO_DEFAULT_3D_MAX_DISTANCE := 0.0
const AUDIO_DEFAULT_3D_UNIT_SIZE := 10.0
const AUDIO_DEFAULT_MUSIC_NAME := "[UNTITLED]"
const AUDIO_MUSIC_STATUS_SILENCE := "[SILENCE]"

const VIDEO_DEFAULT_WINDOW_SIZE := Vector2i(640, 360)
const VIDEO_DEFAULT_WINDOW_MODE := DisplayServer.WINDOW_MODE_MAXIMIZED
const VIDEO_DEFAULT_VSYNC := DisplayServer.VSYNC_ENABLED
const VIDEO_AVAILABLE_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(640, 360),
	Vector2i(854, 480),
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

const EXTENSION_SAVE_FILE := ".save"
const EXTENSION_CONFIG_FILE := ".cfg"

const SAVE_USE_ENCRYPTION := false
const SAVE_MAX_SAVE_SLOTS := 5
const SAVE_AUTOSAVE_INTERVAL := 300.0

const INPUT_DEFAULT_DEADZONE := 0.2
const INPUT_BUFFER_TIME := 0.1
const INPUT_DEFAULT_MOUSE_SENSITIVITY := 1.0
const INPUT_DEFAULT_GAMEPAD_DEADZONE := 0.25
const INPUT_ALLOW_INPUT_REBINDING := true

const ENGINE_NAME := "Puppy Core"
const ENGINE_VERSION := "0.1.0"
const ENGINE_MINIMUM_GODOT_MAJOR := 4


static func get_engine_version() -> String:
	return ENGINE_VERSION


static func get_engine_name() -> String:
	return ENGINE_NAME


static func is_debug_build() -> bool:
	return OS.is_debug_build()


static func is_release_build() -> bool:
	return not OS.is_debug_build()


static func is_godot_version_supported() -> bool:
	return int(Engine.get_version_info().major) >= ENGINE_MINIMUM_GODOT_MAJOR
