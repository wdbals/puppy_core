class_name ScreenTransition
extends CanvasLayer
## Reusable full-screen color cover used during scene or state changes.

signal covered
signal revealed

var _color_rect: ColorRect


func _ready() -> void:
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS

	_color_rect = ColorRect.new()
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_color_rect.scale = Vector2(1.0, 0.0)
	add_child(_color_rect)
	hide()


func cover(color: Color, duration: float) -> void:
	show()
	_color_rect.color = color
	_color_rect.scale = Vector2(1.0, 0.0)

	if duration <= 0.0:
		_color_rect.scale = Vector2.ONE
		covered.emit()
		return

	var tween := create_tween()
	tween.tween_property(_color_rect, "scale", Vector2.ONE, duration) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	covered.emit()


func reveal(duration: float) -> void:
	if duration <= 0.0:
		_color_rect.scale = Vector2(1.0, 0.0)
		hide()
		revealed.emit()
		return

	var tween := create_tween()
	tween.tween_property(_color_rect, "scale", Vector2(1.0, 0.0), duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	hide()
	revealed.emit()
