extends Node
## Singleton para gestión central del ciclo de vida del juego

# SEÑALES DE ESTADO

signal game_paused
signal game_resumed
signal game_ready_finished
signal game_state_changed(new_state: GameEnums.GameState)

# SEÑALES DE CICLO DE VIDA

signal close_game_requested
signal language_changed(new_language: GameEnums.GameLanguage)

# SEÑALES DE ESCENA

signal scene_loaded(scene_name: String)

## Inicio: Bloquear input, bajar música
signal transition_started(to_scene_path: String, duration: float, audio_behavior: AudioEnums.AudioBehavior)
## Medio: Pantalla tapada (Ideal para cargas o setup de UI invisible)
signal screen_covered 
## Final: Devolver control, HUD visible
signal transition_finished

var _current_scene_path: String = ""
var _is_game_paused: bool = false
var _playtime: float = 0.0

var _current_game_state: GameEnums.GameState = GameEnums.GameState.BOOTING:
	set(value):
		if _current_game_state != value:
			_current_game_state = value
			game_state_changed.emit(value)
			print("Estado del juego: ", GameEnums.GameState.keys()[value])

func _ready() -> void:    
	close_game_requested.connect(_quit_game)
	
	# Estado inicial
	change_game_state(GameEnums.GameState.MAIN_MENU)
	
	# Usamos call_deferred para dar tiempo a que otros singletons se inicien
	call_deferred("emit_signal", "game_ready_finished")
	
	print("GameManager iniciado - ", EngineConfig.get_engine_name(), " v", EngineConfig.get_engine_version())

func _process(delta: float) -> void:
	if _current_game_state == GameEnums.GameState.PLAYING and not _is_game_paused:
		_playtime += delta

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_game()

# GESTIÓN DE ESCENAS

## Cambio simple de escena sin transiciones
func change_scene(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("La escena no existe: " + path)
		return
	
	# Emitimos con duración 0 para consistencia
	transition_started.emit(path, 0.0, AudioEnums.AudioBehavior.SCENE_AUTO)
	
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Falló el cambio de escena: " + path)
		return
	
	_finish_scene_change(path)

## Cambio de escena con transición visual
func change_scene_styled(
	path: String, 
	audio_behavior: AudioEnums.AudioBehavior = AudioEnums.AudioBehavior.SCENE_AUTO, 
	transition_color: Color = Color("080d1c"), 
	duration: float = 0.6
) -> void:
	if not ResourceLoader.exists(path):
		push_error("La escena no existe: " + path)
		return
	
	transition_started.emit(path, duration, audio_behavior)
	
	await _create_scene_transition(path, transition_color, duration)

## Finaliza el proceso de actualización de datos internos
func _finish_scene_change(path: String) -> void:
	_current_scene_path = path
	
	scene_loaded.emit(path.get_file()) 
	_update_game_state_from_scene(path)

# LÓGICA DE TRANSICIÓN VISUAL
func _create_scene_transition(path: String, transition_color: Color, duration: float) -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 128 
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	
	var color_rect := ColorRect.new()
	color_rect.color = transition_color
	color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color_rect.scale = Vector2(1, 0)
	canvas.add_child(color_rect)
	
	var tween_in := create_tween()
	tween_in.set_parallel(true)
	tween_in.tween_property(color_rect, "scale", Vector2(1, 1), duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	await tween_in.finished
	
	# --- PANTALLA CUBIERTA ---
	screen_covered.emit() # Momento seguro para cargas
	
	var error = get_tree().change_scene_to_file(path)
	if error != OK:
		push_error("Error crítico cambiando escena")
		canvas.queue_free()
		return
	
	_finish_scene_change(path)
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	# --- FADE OUT ---
	var tween_out := create_tween()
	tween_out.set_parallel(true)
	tween_out.tween_property(color_rect, "scale", Vector2(1, 0), duration * 0.8)\
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	await tween_out.finished
	
	# --- FINALIZAR ---
	transition_finished.emit()
	canvas.queue_free()

# SISTEMA DE PAUSA

var _paused_nodes_cache: Dictionary = {}

## Alterna el pausado del juego
func toggle_pause(excluded_nodes: Array[Node] = []) -> void:
	if _is_game_paused: resume_game()
	else: pause_game(excluded_nodes)

## Pausa el juego
func pause_game(excluded_nodes: Array[Node] = []) -> void:
	if _is_game_paused: return
	
	_paused_nodes_cache.clear()
	
	for node in excluded_nodes:
		if is_instance_valid(node):
			_paused_nodes_cache[node] = node.process_mode
			node.process_mode = Node.PROCESS_MODE_ALWAYS
	
	get_tree().paused = true
	_is_game_paused = true
	
	game_paused.emit()
	change_game_state(GameEnums.GameState.PAUSED)

## Resume el jeugo
func resume_game() -> void:
	if not _is_game_paused: return
	
	for node in _paused_nodes_cache:
		if is_instance_valid(node):
			node.process_mode = _paused_nodes_cache[node]
	
	_paused_nodes_cache.clear()
	
	get_tree().paused = false
	_is_game_paused = false
	
	game_resumed.emit()
	change_game_state(GameEnums.GameState.PLAYING)

# GESTIÓN DE ESTADO

func change_game_state(new_state: GameEnums.GameState) -> void:
	_current_game_state = new_state

func _update_game_state_from_scene(scene_path: String) -> void:
	var scene_name = scene_path.get_file()
	
	if scene_name.contains("menu"): change_game_state(GameEnums.GameState.MAIN_MENU)
	elif scene_name.contains("level") or scene_name.contains("gameplay"): change_game_state(GameEnums.GameState.PLAYING)
	elif scene_name.contains("cutscene"): change_game_state(GameEnums.GameState.CUTSCENE)

# UTILIDADES

func _quit_game() -> void:
	print("Saliendo del juego...")
	# TODO: Añadir dependencias de guardado
	get_tree().quit()

func get_playtime() -> float: return _playtime
func is_in_gameplay() -> bool: return _current_game_state == GameEnums.GameState.PLAYING
