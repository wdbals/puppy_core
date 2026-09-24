extends Node
## Optional singleton for window, resolution, and VSync settings.
##
## Available resolutions and reset values come from PuppyVideoConfig.

signal resolution_changed(new_resolution: Vector2i)
signal display_mode_changed(new_mode: DisplayServer.WindowMode)
signal vsync_mode_changed(new_mode: DisplayServer.VSyncMode)
signal fullscreen_toggled(is_fullscreen: bool)

@export var config: PuppyVideoConfig

var _current_resolution: Vector2i:
	set(value):
		_current_resolution = value
		resolution_changed.emit(value)
var _current_display_mode: DisplayServer.WindowMode:
	set(value):
		_current_display_mode = value
		display_mode_changed.emit(value)
var _current_vsync_mode: DisplayServer.VSyncMode:
	set(value):
		_current_vsync_mode = value
		vsync_mode_changed.emit(value)

func _ready() -> void:
	_ensure_config()
	self.resolution_changed.connect(_on_resolution_change)

	_initialize_display_settings()

## Reads the current display settings.
func _initialize_display_settings() -> void:
	_current_resolution = DisplayServer.window_get_size()
	_current_display_mode = DisplayServer.window_get_mode()
	_current_vsync_mode = DisplayServer.window_get_vsync_mode()

# RESOLUTION

## Changes the window resolution.
func set_resolution(resolution: Vector2i) -> void:
	if resolution == _current_resolution:
		return

	if not resolution in get_available_resolutions():
		push_warning("Resolution is unavailable: ", resolution)
		return

	DisplayServer.window_set_size(resolution)
	_current_resolution = resolution

## Updates the root viewport after a resolution change.
func _force_viewport_redraw(new_resolution: Vector2i = Vector2i.ZERO) -> void:
	var target_resolution := _current_resolution if new_resolution == Vector2i.ZERO else new_resolution
	get_tree().root.set_size(target_resolution)

## Changes resolution by index with an optional transition.
func set_resolution_smooth_by_index(index: int, transition_duration: float = 0.0) -> bool:
	var resolutions = get_available_resolutions()
	if index < 0 or index >= resolutions.size():
		push_error("Invalid resolution index: ", index)
		return false

	set_resolution_smooth(resolutions[index], transition_duration)
	return true

## Changes resolution with an optional transition.
func set_resolution_smooth(resolution: Vector2i, transition_duration: float = 0.0) -> void:
	if resolution == _current_resolution:
		return

	if not resolution in get_available_resolutions():
		push_warning("Resolution is unavailable: ", resolution)
		return

	if transition_duration > 0:
		var tween = create_tween()
		tween.tween_method(_animate_resolution_change, _current_resolution, resolution, transition_duration)
		await tween.finished

	set_resolution(resolution)

## Applies one step of a smooth resolution change.
func _animate_resolution_change(current_size: Vector2) -> void:
	var temp_resolution = Vector2i(current_size)
	DisplayServer.window_set_size(temp_resolution)
	resolution_changed.emit(temp_resolution)

## Returns the current resolution.
func get_current_resolution() -> Vector2i:
	return _current_resolution

## Returns resolutions supported by the current display.
func get_available_resolutions() -> Array[Vector2i]:
	var screen_size = DisplayServer.screen_get_size()
	var resolutions = config.available_resolutions.duplicate()

	resolutions = resolutions.filter(
		func(res): return res.x <= screen_size.x and res.y <= screen_size.y
	)

	if not screen_size in resolutions:
		resolutions.append(screen_size)

	resolutions.sort_custom(_sort_resolutions)
	return resolutions

## Sorts resolutions from largest to smallest.
func _sort_resolutions(a: Vector2i, b: Vector2i) -> bool:
	if a.x == b.x:
		return a.y > b.y
	return a.x > b.x

## Returns the current resolution index.
func get_current_resolution_index() -> int:
	var resolutions = get_available_resolutions()
	return resolutions.find(_current_resolution)

## Changes resolution by index.
func set_resolution_by_index(index: int) -> bool:
	var resolutions = get_available_resolutions()
	if index < 0 or index >= resolutions.size():
		push_error("Invalid resolution index: ", index)
		return false

	set_resolution(resolutions[index])
	return true

# DISPLAY MODE

## Changes the display mode.
func set_display_mode(mode: DisplayServer.WindowMode) -> void:
	if mode == _current_display_mode:
		return

	DisplayServer.window_set_mode(mode)
	_current_display_mode = mode


## Toggles between fullscreen and windowed mode.
func toggle_fullscreen() -> bool:
	var new_mode: DisplayServer.WindowMode
	var is_fullscreen_now: bool

	match _current_display_mode:
		DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
			new_mode = DisplayServer.WINDOW_MODE_WINDOWED
			is_fullscreen_now = false
		_:
			new_mode = DisplayServer.WINDOW_MODE_FULLSCREEN
			is_fullscreen_now = true

	set_display_mode(new_mode)
	fullscreen_toggled.emit(is_fullscreen_now)
	return is_fullscreen_now

## Returns whether the window is fullscreen.
func is_fullscreen() -> bool:
	return _current_display_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or \
		   _current_display_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

## Returns the current display mode.
func get_current_display_mode() -> DisplayServer.WindowMode:
	return _current_display_mode

# VSYNC

## Changes the VSync mode.
func set_vsync_mode(mode: DisplayServer.VSyncMode) -> void:
	if mode == _current_vsync_mode:
		return

	DisplayServer.window_set_vsync_mode(mode)
	_current_vsync_mode = mode


## Toggles VSync.
func toggle_vsync() -> bool:
	var new_mode: DisplayServer.VSyncMode

	if _current_vsync_mode == DisplayServer.VSYNC_ENABLED:
		new_mode = DisplayServer.VSYNC_DISABLED
	else:
		new_mode = DisplayServer.VSYNC_ENABLED

	set_vsync_mode(new_mode)
	return new_mode == DisplayServer.VSYNC_ENABLED

## Returns whether VSync is enabled.
func is_vsync_enabled() -> bool:
	return _current_vsync_mode == DisplayServer.VSYNC_ENABLED

# UI HELPERS

## Notifies responsive UI nodes after a resolution change.
func refresh_ui_after_resolution_change() -> void:
	get_tree().call_group("ui_responsive", "_on_resolution_changed", _current_resolution)

## Centers the window on the current screen.
func center_window() -> void:
	var screen_size := DisplayServer.screen_get_size()

	@warning_ignore("integer_division")
	var window_position: Vector2i = (screen_size - _current_resolution) / 2
	DisplayServer.window_set_position(window_position)

# UTILITIES

## Returns a human-readable display mode name.
func _get_display_mode_name(mode: DisplayServer.WindowMode) -> String:
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED: return "Windowed"
		DisplayServer.WINDOW_MODE_MINIMIZED: return "Minimized"
		DisplayServer.WINDOW_MODE_MAXIMIZED: return "Maximized"
		DisplayServer.WINDOW_MODE_FULLSCREEN: return "Fullscreen"
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: return "Exclusive fullscreen"
		_: return "Unknown"

## Returns a human-readable VSync mode name.
func _get_vsync_mode_name(mode: DisplayServer.VSyncMode) -> String:
	match mode:
		DisplayServer.VSYNC_DISABLED: return "Disabled"
		DisplayServer.VSYNC_ENABLED: return "Enabled"
		DisplayServer.VSYNC_ADAPTIVE: return "Adaptive"
		DisplayServer.VSYNC_MAILBOX: return "Mailbox"
		_: return "Unknown"

## Applies the configured display defaults.
func apply_config_defaults() -> void:
	set_resolution(config.default_window_size)
	set_display_mode(config.default_window_mode)
	set_vsync_mode(config.default_vsync_mode)

## Refreshes the viewport and window position after a resolution change.
func _on_resolution_change(resolution: Vector2i) -> void:
	_force_viewport_redraw(resolution)
	center_window()


func _ensure_config() -> void:
	if not config:
		config = PuppyVideoConfig.new()
