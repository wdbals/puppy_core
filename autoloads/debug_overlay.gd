extends Node

@onready var info_label: Label = $UILayer/MarginContainer/VBoxContainer/InfoLabel
@onready var world_draw: Node2D = $WorldDraw

var _monitors: Dictionary = {}
var _draw_requests: Array = []
var _is_debug_visible: bool = true

func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
		
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	world_draw.draw.connect(_on_world_draw)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_debug"):
		_is_debug_visible = not _is_debug_visible
		$UILayer.visible = _is_debug_visible
		world_draw.visible = _is_debug_visible
	
	if _is_debug_visible:
		world_draw.queue_redraw()
	
	_draw_requests.clear()

func track(id: String, value: Variant) -> void:
	_monitors[id] = value
	_update_display()

func untrack(id: String) -> void:
	if _monitors.erase(id):
		_update_display()

func _update_display() -> void:
	if not _is_debug_visible: return
	var text := ""
	for key in _monitors:
		text += str(key) + ": " + str(_monitors[key]) + "\n"
	info_label.text = text

func draw_line_3d(start: Vector2, end: Vector2, color: Color = Color.RED, width: float = 2.0) -> void:
	if not _is_debug_visible: return
	_draw_requests.append({
		"type": "line",
		"start": start,
		"end": end,
		"color": color,
		"width": width
	})

func draw_iso_circle(center: Vector2, radius: float, color: Color = Color.CYAN) -> void:
	if not _is_debug_visible: return
	_draw_requests.append({
		"type": "iso_circle",
		"center": center,
		"radius": radius,
		"color": color
	})

func _on_world_draw() -> void:
	for req in _draw_requests:
		match req.type:
			"line":
				world_draw.draw_line(req.start, req.end, req.color, req.width)
			"iso_circle":
				world_draw.draw_set_transform(req.center, 0.0, Vector2(1.0, 0.5))
				world_draw.draw_circle(Vector2.ZERO, radius_from_squared(req.radius), req.color)
				world_draw.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func radius_from_squared(squared_val: float) -> float:
	return sqrt(squared_val)
