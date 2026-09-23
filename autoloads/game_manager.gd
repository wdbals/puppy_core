extends Node
## Optional singleton for application lifecycle, pause control, and scene transitions.

signal game_paused
signal game_resumed
signal game_ready
signal quit_requested
signal scene_loaded(scene_path: String)
signal transition_started(to_scene_path: String, duration: float)
signal screen_covered
signal transition_finished

var _current_scene_path := ""
var _is_game_paused := false
var _paused_nodes_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("emit_signal", "game_ready")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()


## Requests a clean application shutdown. Consumers can perform synchronous cleanup
## from the quit_requested signal before the SceneTree exits.
func request_quit() -> void:
	quit_requested.emit()
	get_tree().quit()


## Changes to a scene without a visual transition.
func change_scene(path: String) -> void:
	if not _is_valid_scene_path(path):
		return

	transition_started.emit(path, 0.0)
	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Failed to change scene to: " + path)
		transition_finished.emit()
		return

	_finish_scene_change(path)
	transition_finished.emit()


## Changes to a scene while covering the viewport with a color transition.
func change_scene_styled(
	path: String,
	transition_color: Color = Color("080d1c"),
	duration: float = 0.6
) -> void:
	if not _is_valid_scene_path(path):
		return

	transition_started.emit(path, duration)
	var overlay := _create_transition_overlay(transition_color)
	var color_rect := overlay.get_child(0) as ColorRect

	await _animate_cover(color_rect, duration)
	screen_covered.emit()

	var error := get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Failed to change scene to: " + path)
		overlay.queue_free()
		transition_finished.emit()
		return

	_finish_scene_change(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _animate_reveal(color_rect, duration * 0.8)

	transition_finished.emit()
	overlay.queue_free()


## Runs an action while the viewport is fully covered.
func execute_with_transition(
	action: Callable,
	transition_color: Color = Color("080d1c"),
	duration: float = 0.6,
	pause_tree: bool = true
) -> void:
	var overlay := _create_transition_overlay(transition_color)
	var color_rect := overlay.get_child(0) as ColorRect
	var was_paused := get_tree().paused

	if pause_tree:
		get_tree().paused = true

	transition_started.emit("", duration)
	await _animate_cover(color_rect, duration)
	screen_covered.emit()

	if action.is_valid():
		action.call()

	await get_tree().process_frame
	await _animate_reveal(color_rect, duration * 0.8)

	if pause_tree and not was_paused:
		get_tree().paused = false

	transition_finished.emit()
	overlay.queue_free()


## Toggles the SceneTree pause state.
func toggle_pause(excluded_nodes: Array[Node] = []) -> void:
	if _is_game_paused:
		resume_game()
	else:
		pause_game(excluded_nodes)


## Pauses the SceneTree while keeping selected nodes active.
func pause_game(excluded_nodes: Array[Node] = []) -> void:
	if _is_game_paused:
		return

	_paused_nodes_cache.clear()
	for node in excluded_nodes:
		if is_instance_valid(node):
			_paused_nodes_cache[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true
	_is_game_paused = true
	game_paused.emit()


## Restores processing modes and resumes the SceneTree.
func resume_game() -> void:
	if not _is_game_paused:
		return

	for node in _paused_nodes_cache:
		if is_instance_valid(node):
			node.process_mode = _paused_nodes_cache[node]

	_paused_nodes_cache.clear()
	get_tree().paused = false
	_is_game_paused = false
	game_resumed.emit()


func is_game_paused() -> bool:
	return _is_game_paused


func get_current_scene_path() -> String:
	return _current_scene_path


func _is_valid_scene_path(path: String) -> bool:
	if ResourceLoader.exists(path):
		return true
	push_error("Scene does not exist: " + path)
	return false


func _finish_scene_change(path: String) -> void:
	_current_scene_path = path
	scene_loaded.emit(path)


func _create_transition_overlay(color: Color) -> CanvasLayer:
	var canvas := CanvasLayer.new()
	canvas.layer = 128
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)

	var color_rect := ColorRect.new()
	color_rect.color = color
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.scale = Vector2(1.0, 0.0)
	canvas.add_child(color_rect)
	return canvas


func _animate_cover(color_rect: ColorRect, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "scale", Vector2.ONE, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished


func _animate_reveal(color_rect: ColorRect, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(color_rect, "scale", Vector2(1.0, 0.0), duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
