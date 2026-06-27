extends Node
## Singleton para gestión del audio

signal bus_volume_changed(bus_name: AudioEnums.BusName, volume: float)
signal sound_played(sound_name: String, sound_type: AudioEnums.SoundType)
signal music_changed(music_name: String)
signal music_stoped
signal music_finished

var _current_music: AudioStreamPlayer = null
var _sound_players: Array[AudioStreamPlayer] = []
var current_music_name: String = EngineConfig.AUDIO_DEFAULT_MUSIC_NAME:
	set(value):
		current_music_name = value
		music_changed.emit(value)
var _pre_pause_volume: float = -1.0

func _ready() -> void:
	create_sound_pool()
	setup_audio_buses()

	# Conectar a eventos del GameManager
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	GameManager.transition_started.connect(_on_scene_transition)

	# debug
	self.music_changed.connect(_on_music_changed)

	print("AudioManager iniciado")

func _on_scene_transition(path: String, duration: float, behavior: AudioEnums.AudioBehavior) -> void:
	match behavior:
		AudioEnums.AudioBehavior.STOP_ALL:
			stop_all_sounds()
			stop_music(duration) # Usar la duración para fade-out

		AudioEnums.AudioBehavior.STOP_MUSIC:
			stop_music(duration)

		AudioEnums.AudioBehavior.SCENE_AUTO:
			var new_name = path.get_file()
			if new_name.contains("menu"):
				stop_music(1.0)

# CONFIGURACIÓN INICIAL

## Configura los buses de audio usando la configuración del engine
func setup_audio_buses() -> void:
	for bus_name in EngineConfig.DEFAULT_AUDIO_BUSES:
		var config = EngineConfig.DEFAULT_AUDIO_BUSES[bus_name]

		if AudioServer.get_bus_index(bus_name) == -1:
			var bus_idx = AudioServer.get_bus_count()
			AudioServer.add_bus(bus_idx)
			AudioServer.set_bus_name(bus_idx, bus_name)

		# Aplicar configuración por defecto
		AudioServer.set_bus_volume_db(
			AudioServer.get_bus_index(bus_name),
			linear_to_db(config.volume)
		)

		if config.muted:
			AudioServer.set_bus_mute(AudioServer.get_bus_index(bus_name), true)

## Crea el pool de players de sonido
func create_sound_pool() -> void:
	for i in EngineConfig.AUDIO_SOUND_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.process_mode = Node.PROCESS_MODE_ALWAYS
		player.finished.connect(_on_sound_player_finished.bind(player))
		add_child(player)
		_sound_players.append(player)

# GESTIÓN DE MÚSICA

## Reproduce música con fade opcional
func play_music(music_stream: AudioStream, music_name: String = "", fade_duration: float = -1.0) -> void:
	if fade_duration == -1.0:
		fade_duration = EngineConfig.AUDIO_DEFAULT_MUSIC_FADE

	# Si ya está sonando la misma música, no hacer nada
	if _current_music and _current_music.stream == music_stream and _current_music.playing:
		return

	# Fade out de la música actual si existe
	if _current_music and fade_duration > 0:
		await fade_out_music(fade_duration)
	elif _current_music:
		_current_music.stop()

	# Crear nuevo player si es necesario
	if not _current_music:
		_current_music = AudioStreamPlayer.new()
		_current_music.bus = "Music"
		_current_music.process_mode = Node.PROCESS_MODE_ALWAYS
		_current_music.finished.connect(_on_music_finished)
		add_child(_current_music)

	# Reproducir nueva música
	_current_music.stream = music_stream
	current_music_name = EngineConfig.AUDIO_DEFAULT_MUSIC_NAME if music_name.is_empty() else music_name
	_current_music.play()

	# Fade in si se especificó
	if fade_duration > 0:
		await fade_in_music(fade_duration)

## Detiene la música actual con fade opcional
func stop_music(fade_duration: float = -1.0) -> void:
	if fade_duration == -1.0:
		fade_duration = EngineConfig.AUDIO_DEFAULT_MUSIC_FADE

	if _current_music:
		if fade_duration > 0:
			await fade_out_music(fade_duration)
		_current_music.stop()
		music_stoped.emit()
		current_music_name = EngineConfig.AUDIO_MUSIC_STATUS_SILENCE

## Realiza fade out de la música actual
func fade_out_music(duration: float) -> void:
	if not _current_music:
		return

	var tween = create_tween()
	tween.tween_property(_current_music, "volume_db", -80.0, duration)
	await tween.finished

## Realiza fade in de la música actual
func fade_in_music(duration: float) -> void:
	if not _current_music:
		return

	_current_music.volume_db = -80.0
	var tween = create_tween()
	tween.tween_property(_current_music, "volume_db", 0.0, duration)
	await tween.finished

# GESTIÓN DE SONIDOS

## Reproduce un efecto de sonido
func play_sound(sound_stream: AudioStream, bus: AudioEnums.BusName = AudioEnums.BusName.SFX) -> void:
	var player = get_available_sound_player()
	if player and sound_stream:
		player.stream = sound_stream
		player.bus = _get_bus_name_from_enum(bus)
		player.play()

		var sound_type = _get_sound_type_from_bus(bus)
		sound_played.emit(sound_stream.resource_path.get_file(), sound_type)

## Obtiene un player de sonido disponible del pool
func get_available_sound_player() -> AudioStreamPlayer:
	for player in _sound_players:
		if not player.playing:
			return player

	# Si no hay disponibles, crear uno nuevo (fallback)
	var new_player = AudioStreamPlayer.new()
	new_player.bus = "SFX"
	new_player.process_mode = Node.PROCESS_MODE_ALWAYS
	new_player.finished.connect(_on_sound_player_finished.bind(new_player))
	add_child(new_player)
	_sound_players.append(new_player)
	return new_player

## Detiene todos los sonidos y música
func stop_all_sounds() -> void:
	for player in _sound_players:
		player.stop()

	if _current_music:
		_current_music.stop()
		current_music_name = EngineConfig.AUDIO_MUSIC_STATUS_SILENCE

# CONTROL DE VOLUMEN

## Establece el volumen de un bus específico. De 0.0 a 1.1
func set_bus_volume(bus: AudioEnums.BusName, volume: float) -> void:
	var bus_name = _get_bus_name_from_enum(bus)
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var clamped_volume = clampf(volume, 0.0, 1.0)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_volume))
		bus_volume_changed.emit(bus, clamped_volume)

## Obtiene el volumen actual de un bus
func get_bus_volume(bus: AudioEnums.BusName) -> float:
	var bus_name = _get_bus_name_from_enum(bus)
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		return db_to_linear(AudioServer.get_bus_volume_db(bus_index))
	return 0.0

## Silencia un bus específico
func mute_bus(bus: AudioEnums.BusName) -> void:
	var bus_name = _get_bus_name_from_enum(bus)
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, true)

## Quita el silencio de un bus específico
func unmute_bus(bus: AudioEnums.BusName) -> void:
	var bus_name = _get_bus_name_from_enum(bus)
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, false)

## Alterna el silencio de un bus
func toggle_bus_mute(bus: AudioEnums.BusName) -> bool:
	var bus_name = _get_bus_name_from_enum(bus)
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index != -1:
		var is_muted = AudioServer.is_bus_mute(bus_index)
		AudioServer.set_bus_mute(bus_index, not is_muted)
		return not is_muted
	return false

# MANEJO DE PAUSA

## Se ejecuta cuando el juego se pausa
func _on_game_paused() -> void:
	_pre_pause_volume = get_bus_volume(AudioEnums.BusName.MASTER)

	# Reducir volumen master durante pausa
	set_bus_volume(AudioEnums.BusName.MASTER, EngineConfig.AUDIO_DEFAULT_ATTENUATION_PAUSE_SOUND)

	# Pausar sonidos de gameplay (pero no UI)
	for player in _sound_players:
		if player.playing and player.bus in ["SFX", "Voice"]:
			player.stream_paused = true

## Se ejecuta cuando el juego se reanuda
func _on_game_resumed() -> void:
	# Restaurar volumen master
	if _pre_pause_volume != -1:
		set_bus_volume(AudioEnums.BusName.MASTER, _pre_pause_volume)

	_pre_pause_volume = -1

	# Reanudar sonidos pausados
	for player in _sound_players:
		player.stream_paused = false

# UTILIDADES

## Convierte un enum de bus a nombre de string
func _get_bus_name_from_enum(bus: AudioEnums.BusName) -> String:
	match bus:
		AudioEnums.BusName.MASTER: return "Master"
		AudioEnums.BusName.SFX: return "SFX"
		AudioEnums.BusName.MUSIC: return "Music"
		AudioEnums.BusName.VOICE: return "Voice"
		_: return "Master"

## Determina el tipo de sonido basado en el bus
func _get_sound_type_from_bus(bus: AudioEnums.BusName) -> AudioEnums.SoundType:
	match bus:
		AudioEnums.BusName.SFX: return AudioEnums.SoundType.GAMEPLAY
		AudioEnums.BusName.VOICE: return AudioEnums.SoundType.VOICE
		AudioEnums.BusName.MUSIC: return AudioEnums.SoundType.MUSIC
		_: return AudioEnums.SoundType.UI

## Devuelve el nombre de la música actual
func get_current_music_name() -> String:
	return current_music_name

## Verifica si hay música reproduciéndose
func is_music_playing() -> bool:
	return _current_music != null and _current_music.playing

# SEÑALES INTERNAS

## Se ejecuta cuando la música termina
func _on_music_finished() -> void:
	music_finished.emit()
	current_music_name = EngineConfig.AUDIO_MUSIC_STATUS_SILENCE

## Se ejecuta cuando un sonido termina (para limpieza)
func _on_sound_player_finished(player: AudioStreamPlayer) -> void:
	# Podemos resetear el stream para liberar memoria
	player.stream = null

## Se ejecuta al cambiar la música actual
func _on_music_changed(new_music: String):
	print("Ahora suena: ", new_music)
