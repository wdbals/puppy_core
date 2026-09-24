class_name PuppyVideoConfig
extends Resource
## Display defaults and selectable resolutions used by VideoManager.

@export var default_window_size := Vector2i(640, 360)
@export var default_window_mode: DisplayServer.WindowMode = \
	DisplayServer.WINDOW_MODE_MAXIMIZED
@export var default_vsync_mode: DisplayServer.VSyncMode = \
	DisplayServer.VSYNC_ENABLED
@export var available_resolutions: Array[Vector2i] = [
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
