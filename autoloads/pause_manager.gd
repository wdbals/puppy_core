extends Node
## Optional singleton that coordinates the SceneTree pause state.

signal game_paused
signal game_resumed

var _overridden_process_modes: Dictionary[Node, ProcessMode] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


## Pauses the SceneTree while keeping selected nodes active.
func pause(excluded_nodes: Array = []) -> void:
	if get_tree().paused:
		return

	_overridden_process_modes.clear()
	for node in excluded_nodes:
		if node is Node and is_instance_valid(node):
			_overridden_process_modes[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_ALWAYS

	get_tree().paused = true
	game_paused.emit()


## Restores overridden processing modes and resumes the SceneTree.
func resume() -> void:
	if not get_tree().paused and _overridden_process_modes.is_empty():
		return

	for node in _overridden_process_modes:
		if is_instance_valid(node):
			node.process_mode = _overridden_process_modes[node]

	_overridden_process_modes.clear()
	get_tree().paused = false
	game_resumed.emit()


func toggle(excluded_nodes: Array = []) -> void:
	if get_tree().paused:
		resume()
	else:
		pause(excluded_nodes)


func is_paused() -> bool:
	return get_tree().paused
