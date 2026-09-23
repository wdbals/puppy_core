extends Node
## Optional automatic audio feedback for every BaseButton in the SceneTree.
## Requires an AudioManager autoload registered before this service.

const SILENT_GROUP := &"ui_sound_silent"
const CONFIRM_GROUP := &"ui_sound_confirm"
const CANCEL_GROUP := &"ui_sound_cancel"

@export var profile: UISoundProfile

var _audio_manager: Node


func _ready() -> void:
	_audio_manager = get_node_or_null("/root/AudioManager")
	if not _audio_manager or not _audio_manager.has_method("play_sound"):
		push_error(
			"UISoundManager requires an AudioManager autoload registered before it."
		)
		return

	get_tree().node_added.connect(_on_node_added)
	_register_branch(get_tree().root)


func set_profile(new_profile: UISoundProfile) -> void:
	profile = new_profile


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_register_button.call_deferred(node)


func _register_branch(node: Node) -> void:
	if node is BaseButton:
		_register_button(node)
	for child in node.get_children():
		_register_branch(child)


func _register_button(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return

	var pressed_callback := _on_button_pressed.bind(button)
	if not button.pressed.is_connected(pressed_callback):
		button.pressed.connect(pressed_callback)

	var hovered_callback := _on_button_hovered.bind(button)
	if not button.mouse_entered.is_connected(hovered_callback):
		button.mouse_entered.connect(hovered_callback)

	var focused_callback := _on_button_focused.bind(button)
	if not button.focus_entered.is_connected(focused_callback):
		button.focus_entered.connect(focused_callback)


func _on_button_pressed(button: BaseButton) -> void:
	if _should_ignore(button) or not profile:
		return

	var stream := profile.pressed
	if button.is_in_group(CONFIRM_GROUP) and profile.confirm:
		stream = profile.confirm
	elif button.is_in_group(CANCEL_GROUP) and profile.cancel:
		stream = profile.cancel
	_play(stream)


func _on_button_hovered(button: BaseButton) -> void:
	if _should_ignore(button) or not profile:
		return
	_play(profile.hovered)


func _on_button_focused(button: BaseButton) -> void:
	if _should_ignore(button) or not profile:
		return
	_play(profile.focused)


func _should_ignore(button: BaseButton) -> bool:
	return button.disabled or button.is_in_group(SILENT_GROUP)


func _play(stream: AudioStream) -> void:
	if stream and is_instance_valid(_audio_manager):
		_audio_manager.call("play_sound", stream, AudioEnums.BusName.UI)
