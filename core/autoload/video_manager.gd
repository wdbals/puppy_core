extends Node
## Singleton para gestión de video y pantalla
##
## Maneja resoluciones, modos de pantalla, VSync y configuración gráfica.
## Las resoluciones disponibles se configuran en EngineConfig.

signal resolution_changed(new_resolution: Vector2i)
signal display_mode_changed(new_mode: DisplayServer.WindowMode)
signal vsync_mode_changed(new_mode: DisplayServer.VSyncMode)
signal fullscreen_toggled(is_fullscreen: bool)

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
	# Forzar actualización de viewport al cambiar resolución
	self.resolution_changed.connect(_on_resolution_change)

	_initialize_display_settings()
	print("VideoManager iniciado - Resoluciones disponibles: ", get_available_resolutions().size())

## Inicializa la configuración de pantalla
func _initialize_display_settings() -> void:
	_current_resolution = DisplayServer.window_get_size()
	_current_display_mode = DisplayServer.window_get_mode()
	_current_vsync_mode = DisplayServer.window_get_vsync_mode()

# GESTIÓN DE RESOLUCIÓN

## Cambia la resolución de la ventana y fuerza redibujado
func set_resolution(resolution: Vector2i) -> void:
	if resolution == _current_resolution:
		return

	if not resolution in get_available_resolutions():
		push_warning("Resolución no disponible: ", resolution)
		return

	# Cambiar tamaño de ventana
	DisplayServer.window_set_size(resolution)
	_current_resolution = resolution

	print("Resolución cambiada a: ", resolution)

## Fuerza al viewport a redibujarse después de cambiar resolución
func _force_viewport_redraw(new_resolution: Vector2i = Vector2i.ZERO) -> void:
	if new_resolution == Vector2i.ZERO:
		get_tree().root.set_size(_current_resolution)

	get_tree().root.set_size(new_resolution)

## Cambia la resolución con opciones adicionales de redibujado
func set_resolution_smooth_by_index(index: int, transition_duration: float = 0.0) -> bool:
	var resolutions = get_available_resolutions()
	if index < 0 or index >= resolutions.size():
		push_error("Índice de resolución inválido: ", index)
		return false

	set_resolution_smooth(resolutions[index], transition_duration)
	return true

## Cambia la resolución con opciones adicionales de redibujado
func set_resolution_smooth(resolution: Vector2i, transition_duration: float = 0.0) -> void:
	if resolution == _current_resolution:
		return

	if not resolution in get_available_resolutions():
		push_warning("Resolución no disponible: ", resolution)
		return

	if transition_duration > 0:
		var tween = create_tween()
		tween.tween_method(_animate_resolution_change, _current_resolution, resolution, transition_duration)
		await tween.finished

	set_resolution(resolution)

## Animación para cambio suave de resolución
func _animate_resolution_change(current_size: Vector2) -> void:
	var temp_resolution = Vector2i(current_size)
	DisplayServer.window_set_size(temp_resolution)
	resolution_changed.emit(temp_resolution)

## Obtiene la resolución actual
func get_current_resolution() -> Vector2i:
	return _current_resolution

## Obtiene todas las resoluciones disponibles desde EngineConfig
func get_available_resolutions() -> Array[Vector2i]:
	var screen_size = DisplayServer.screen_get_size()
	var resolutions = EngineConfig.VIDEO_AVAILABLE_RESOLUTIONS.duplicate()

	# Filtrar resoluciones que sean menores o iguales al tamaño de pantalla
	resolutions = resolutions.filter(
		func(res): return res.x <= screen_size.x and res.y <= screen_size.y
	)

	# Agregar la resolución nativa de la pantalla si no está incluida
	if not screen_size in resolutions:
		resolutions.append(screen_size)

	resolutions.sort_custom(_sort_resolutions)
	return resolutions

## Ordena resoluciones de mayor a menor
func _sort_resolutions(a: Vector2i, b: Vector2i) -> bool:
	if a.x == b.x:
		return a.y > b.y
	return a.x > b.x

## Obtiene el índice de la resolución actual en la lista disponible
func get_current_resolution_index() -> int:
	var resolutions = get_available_resolutions()
	return resolutions.find(_current_resolution)

## Establece la resolución por índice de la lista disponible
func set_resolution_by_index(index: int) -> bool:
	var resolutions = get_available_resolutions()
	if index < 0 or index >= resolutions.size():
		push_error("Índice de resolución inválido: ", index)
		return false

	set_resolution(resolutions[index])
	return true

# GESTIÓN DE MODO DE PANTALLA

## Cambia el modo de visualización y fuerza redibujado
func set_display_mode(mode: DisplayServer.WindowMode) -> void:
	if mode == _current_display_mode:
		return

	DisplayServer.window_set_mode(mode)
	_current_display_mode = mode

	# Forzar redibujado después de cambiar modo
	#_force_viewport_redraw()

	print("Modo de pantalla cambiado a: ", _get_display_mode_name(mode))

## Alterna entre pantalla completa y ventana
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

## Verifica si está en modo pantalla completa
func is_fullscreen() -> bool:
	return _current_display_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or \
		   _current_display_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

## Obtiene el modo de pantalla actual
func get_current_display_mode() -> DisplayServer.WindowMode:
	return _current_display_mode

# GESTIÓN DE VSYNC

## Cambia el modo VSync
func set_vsync_mode(mode: DisplayServer.VSyncMode) -> void:
	if mode == _current_vsync_mode:
		return

	DisplayServer.window_set_vsync_mode(mode)
	_current_vsync_mode = mode

	print("VSync cambiado a: ", _get_vsync_mode_name(mode))

## Alterna VSync
func toggle_vsync() -> bool:
	var new_mode: DisplayServer.VSyncMode

	if _current_vsync_mode == DisplayServer.VSYNC_ENABLED:
		new_mode = DisplayServer.VSYNC_DISABLED
	else:
		new_mode = DisplayServer.VSYNC_ENABLED

	set_vsync_mode(new_mode)
	return new_mode == DisplayServer.VSYNC_ENABLED

## Verifica si VSync está activado
func is_vsync_enabled() -> bool:
	return _current_vsync_mode == DisplayServer.VSYNC_ENABLED

# UTILIDADES ADICIONALES PARA UI

## Configura el viewport para escalado automático (útil para UI)
func setup_viewport_scaling() -> void:
	var viewport = get_tree().root
	if viewport:
		# Configurar stretch mode para UI responsiva
		#get_tree().set_screen_stretch(SceneTree., SceneTree.STRETCH_ASPECT_KEEP, _current_resolution)
		pass

## Actualiza todos los elementos de UI después de cambiar resolución
func refresh_ui_after_resolution_change() -> void:
	# Notificar a todos los nodos de UI que se redimensionen
	get_tree().call_group("ui_responsive", "_on_resolution_changed", _current_resolution)

## Centra la ventana en la pantalla
func center_window() -> void:
	var screen_size := DisplayServer.screen_get_size()

	@warning_ignore("integer_division")
	var window_position: Vector2i = (screen_size - _current_resolution) / 2
	DisplayServer.window_set_position(window_position)

# UTILIDADES

## Obtiene el nombre legible del modo de pantalla
func _get_display_mode_name(mode: DisplayServer.WindowMode) -> String:
	match mode:
		DisplayServer.WINDOW_MODE_WINDOWED: return "Ventana"
		DisplayServer.WINDOW_MODE_MINIMIZED: return "Minimizado"
		DisplayServer.WINDOW_MODE_MAXIMIZED: return "Maximizado"
		DisplayServer.WINDOW_MODE_FULLSCREEN: return "Pantalla completa"
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: return "Pantalla completa exclusiva"
		_: return "Desconocido"

## Obtiene el nombre legible del modo VSync
func _get_vsync_mode_name(mode: DisplayServer.VSyncMode) -> String:
	match mode:
		DisplayServer.VSYNC_DISABLED: return "Desactivado"
		DisplayServer.VSYNC_ENABLED: return "Activado"
		DisplayServer.VSYNC_ADAPTIVE: return "Adaptativo"
		DisplayServer.VSYNC_MAILBOX: return "Mailbox"
		_: return "Desconocido"

## Aplica la configuración por defecto del engine
func apply_engine_defaults() -> void:
	set_resolution(EngineConfig.VIDEO_DEFAULT_WINDOW_SIZE)
	set_display_mode(EngineConfig.VIDEO_DEFAULT_WINDOW_MODE)
	set_vsync_mode(EngineConfig.VIDEO_DEFAULT_VSYNC)
	setup_viewport_scaling()

## Acciones cuando la resolución cambia
func _on_resolution_change(resolution: Vector2i):
	_force_viewport_redraw(resolution)
	center_window()
