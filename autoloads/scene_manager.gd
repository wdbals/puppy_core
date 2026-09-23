extends Node
## Optional singleton for scene navigation and visual scene transitions.

signal scene_loaded(scene_path: String)
signal transition_started(to_scene_path: String, duration: float)
signal screen_covered
signal transition_finished

const DEFAULT_TRANSITION_COLOR := Color("080d1c")
const DEFAULT_TRANSITION_DURATION := 0.6

var _current_scene_path := ""
var _is_transitioning := false
var _screen_transition: ScreenTransition


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_screen_transition = ScreenTransition.new()
	add_child(_screen_transition)


## Changes scene immediately and returns Godot's scene-loading result.
func change_scene(path: String) -> Error:
	var validation_result := _validate_scene_path(path)
	if validation_result != OK:
		return validation_result
	if _is_transitioning:
		return ERR_BUSY

	transition_started.emit(path, 0.0)
	var result := get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("Failed to change scene to: " + path)
		transition_finished.emit()
		return result

	_finish_scene_change(path)
	transition_finished.emit()
	return OK


## Changes scene while covering and revealing the viewport.
func change_scene_with_transition(
	path: String,
	transition_color: Color = DEFAULT_TRANSITION_COLOR,
	duration: float = DEFAULT_TRANSITION_DURATION
) -> Error:
	var validation_result := _validate_scene_path(path)
	if validation_result != OK:
		return validation_result
	if _is_transitioning:
		return ERR_BUSY

	_is_transitioning = true
	transition_started.emit(path, duration)
	await _screen_transition.cover(transition_color, duration)
	screen_covered.emit()

	var result := get_tree().change_scene_to_file(path)
	if result != OK:
		push_error("Failed to change scene to: " + path)
		await _screen_transition.reveal(duration * 0.8)
		_is_transitioning = false
		transition_finished.emit()
		return result

	_finish_scene_change(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _screen_transition.reveal(duration * 0.8)

	_is_transitioning = false
	transition_finished.emit()
	return OK


func get_current_scene_path() -> String:
	return _current_scene_path


func is_transitioning() -> bool:
	return _is_transitioning


func _validate_scene_path(path: String) -> Error:
	if path.is_empty():
		push_error("Scene path cannot be empty.")
		return ERR_INVALID_PARAMETER
	if not ResourceLoader.exists(path, "PackedScene"):
		push_error("Scene does not exist: " + path)
		return ERR_FILE_NOT_FOUND
	return OK


func _finish_scene_change(path: String) -> void:
	_current_scene_path = path
	scene_loaded.emit(path)
