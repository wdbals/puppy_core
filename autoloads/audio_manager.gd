extends Node
## Optional singleton for music, non-spatial effects, and one-shot 2D/3D audio.

signal bus_volume_changed(bus_name: AudioEnums.BusName, volume: float)
signal sound_played(sound_name: String, sound_type: AudioEnums.SoundType)
signal music_changed(music_name: String)
signal music_stopped
signal music_finished

var _current_music: AudioStreamPlayer
var _sound_players: Array[AudioStreamPlayer] = []
var _spatial_players: Array[Node] = []
var _pre_pause_volume := -1.0

var current_music_name: String = EngineConfig.AUDIO_DEFAULT_MUSIC_NAME:
	set(value):
		current_music_name = value
		music_changed.emit(value)


func _ready() -> void:
	create_sound_pool()
	setup_audio_buses()


## Creates any missing buses and applies Puppy Core defaults.
func setup_audio_buses() -> void:
	for bus_name in EngineConfig.DEFAULT_AUDIO_BUSES:
		var config: Dictionary = EngineConfig.DEFAULT_AUDIO_BUSES[bus_name]
		var bus_index := AudioServer.get_bus_index(bus_name)
		if bus_index == -1:
			bus_index = AudioServer.get_bus_count()
			AudioServer.add_bus(bus_index)
			AudioServer.set_bus_name(bus_index, bus_name)

		AudioServer.set_bus_volume_db(bus_index, linear_to_db(config.volume))
		AudioServer.set_bus_mute(bus_index, config.muted)


## Creates the initial pool used by non-spatial sound effects.
func create_sound_pool() -> void:
	for _index in EngineConfig.AUDIO_SOUND_POOL_SIZE:
		_sound_players.append(_create_sound_player())


func play_music(
	music_stream: AudioStream,
	music_name: String = "",
	fade_duration: float = -1.0
) -> void:
	if not music_stream:
		return
	if fade_duration < 0.0:
		fade_duration = EngineConfig.AUDIO_DEFAULT_MUSIC_FADE
	if _current_music and _current_music.stream == music_stream and _current_music.playing:
		return

	if _current_music and fade_duration > 0.0:
		await fade_out_music(fade_duration)
	elif _current_music:
		_current_music.stop()

	if not _current_music:
		_current_music = AudioStreamPlayer.new()
		_current_music.bus = "Music"
		_current_music.process_mode = Node.PROCESS_MODE_ALWAYS
		_current_music.finished.connect(_on_music_finished)
		add_child(_current_music)

	_current_music.stream = music_stream
	current_music_name = EngineConfig.AUDIO_DEFAULT_MUSIC_NAME if music_name.is_empty() else music_name
	_current_music.play()
	if fade_duration > 0.0:
		await fade_in_music(fade_duration)


func stop_music(fade_duration: float = -1.0) -> void:
	if fade_duration < 0.0:
		fade_duration = EngineConfig.AUDIO_DEFAULT_MUSIC_FADE
	if not _current_music:
		return

	if fade_duration > 0.0:
		await fade_out_music(fade_duration)
	_current_music.stop()
	current_music_name = EngineConfig.AUDIO_MUSIC_STATUS_SILENCE
	music_stopped.emit()


func fade_out_music(duration: float) -> void:
	if not _current_music:
		return
	var tween := create_tween()
	tween.tween_property(_current_music, "volume_db", -80.0, duration)
	await tween.finished


func fade_in_music(duration: float) -> void:
	if not _current_music:
		return
	_current_music.volume_db = -80.0
	var tween := create_tween()
	tween.tween_property(_current_music, "volume_db", 0.0, duration)
	await tween.finished


## Plays a non-spatial sound from the reusable player pool.
func play_sound(
	sound_stream: AudioStream,
	bus: AudioEnums.BusName = AudioEnums.BusName.SFX
) -> AudioStreamPlayer:
	if not sound_stream:
		return null
	var player := get_available_sound_player()
	player.stream = sound_stream
	player.bus = _get_bus_name_from_enum(bus)
	player.play()
	_emit_sound_played(sound_stream, bus)
	return player


## Plays a one-shot sound at a world-space 2D position.
func play_sound_2d(
	sound_stream: AudioStream,
	position: Vector2,
	bus: AudioEnums.BusName = AudioEnums.BusName.SFX,
	max_distance: float = EngineConfig.AUDIO_DEFAULT_2D_MAX_DISTANCE,
	attenuation: float = EngineConfig.AUDIO_DEFAULT_2D_ATTENUATION
) -> AudioStreamPlayer2D:
	if not sound_stream:
		return null
	var player := AudioStreamPlayer2D.new()
	player.stream = sound_stream
	player.bus = _get_bus_name_from_enum(bus)
	player.max_distance = max_distance
	player.attenuation = attenuation
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.global_position = position
	_register_spatial_player(player)
	player.play()
	_emit_sound_played(sound_stream, bus)
	return player


## Plays a one-shot sound at a world-space 3D position.
func play_sound_3d(
	sound_stream: AudioStream,
	position: Vector3,
	bus: AudioEnums.BusName = AudioEnums.BusName.SFX,
	max_distance: float = EngineConfig.AUDIO_DEFAULT_3D_MAX_DISTANCE,
	unit_size: float = EngineConfig.AUDIO_DEFAULT_3D_UNIT_SIZE
) -> AudioStreamPlayer3D:
	if not sound_stream:
		return null
	var player := AudioStreamPlayer3D.new()
	player.stream = sound_stream
	player.bus = _get_bus_name_from_enum(bus)
	player.max_distance = max_distance
	player.unit_size = unit_size
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.global_position = position
	_register_spatial_player(player)
	player.play()
	_emit_sound_played(sound_stream, bus)
	return player


func get_available_sound_player() -> AudioStreamPlayer:
	for player in _sound_players:
		if not player.playing:
			return player
	var player := _create_sound_player()
	_sound_players.append(player)
	return player


func stop_all_sounds() -> void:
	for player in _sound_players:
		player.stop()
		player.stream = null
	for player in _spatial_players.duplicate():
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_spatial_players.clear()
	if _current_music:
		_current_music.stop()
		current_music_name = EngineConfig.AUDIO_MUSIC_STATUS_SILENCE


func set_bus_volume(bus: AudioEnums.BusName, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(_get_bus_name_from_enum(bus))
	if bus_index == -1:
		return
	var clamped_volume := clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(clamped_volume))
	bus_volume_changed.emit(bus, clamped_volume)


func get_bus_volume(bus: AudioEnums.BusName) -> float:
	var bus_index := AudioServer.get_bus_index(_get_bus_name_from_enum(bus))
	if bus_index == -1:
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index))


func mute_bus(bus: AudioEnums.BusName) -> void:
	_set_bus_mute(bus, true)


func unmute_bus(bus: AudioEnums.BusName) -> void:
	_set_bus_mute(bus, false)


func toggle_bus_mute(bus: AudioEnums.BusName) -> bool:
	var bus_index := AudioServer.get_bus_index(_get_bus_name_from_enum(bus))
	if bus_index == -1:
		return false
	var muted := not AudioServer.is_bus_mute(bus_index)
	AudioServer.set_bus_mute(bus_index, muted)
	return muted


## Optional integration point for a game-specific pause coordinator.
func set_game_paused(paused: bool) -> void:
	if paused:
		_pre_pause_volume = get_bus_volume(AudioEnums.BusName.MASTER)
		set_bus_volume(
			AudioEnums.BusName.MASTER,
			EngineConfig.AUDIO_DEFAULT_ATTENUATION_PAUSE_SOUND
		)
	else:
		if _pre_pause_volume >= 0.0:
			set_bus_volume(AudioEnums.BusName.MASTER, _pre_pause_volume)
		_pre_pause_volume = -1.0

	for player in _sound_players:
		if player.playing and player.bus in ["SFX", "Voice"]:
			player.stream_paused = paused
	for player in _spatial_players:
		if is_instance_valid(player) and player.bus in ["SFX", "Voice"]:
			player.stream_paused = paused


func get_current_music_name() -> String:
	return current_music_name


func is_music_playing() -> bool:
	return _current_music != null and _current_music.playing


func _create_sound_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "SFX"
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.finished.connect(_on_sound_player_finished.bind(player))
	add_child(player)
	return player


func _register_spatial_player(player: Node) -> void:
	_spatial_players.append(player)
	player.finished.connect(_on_spatial_player_finished.bind(player))


func _on_sound_player_finished(player: AudioStreamPlayer) -> void:
	player.stream = null


func _on_spatial_player_finished(player: Node) -> void:
	_spatial_players.erase(player)
	player.queue_free()


func _on_music_finished() -> void:
	current_music_name = EngineConfig.AUDIO_MUSIC_STATUS_SILENCE
	music_finished.emit()


func _emit_sound_played(stream: AudioStream, bus: AudioEnums.BusName) -> void:
	sound_played.emit(stream.resource_path.get_file(), _get_sound_type_from_bus(bus))


func _set_bus_mute(bus: AudioEnums.BusName, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(_get_bus_name_from_enum(bus))
	if bus_index != -1:
		AudioServer.set_bus_mute(bus_index, muted)


func _get_bus_name_from_enum(bus: AudioEnums.BusName) -> String:
	match bus:
		AudioEnums.BusName.MASTER: return "Master"
		AudioEnums.BusName.SFX: return "SFX"
		AudioEnums.BusName.MUSIC: return "Music"
		AudioEnums.BusName.VOICE: return "Voice"
		_: return "Master"


func _get_sound_type_from_bus(bus: AudioEnums.BusName) -> AudioEnums.SoundType:
	match bus:
		AudioEnums.BusName.SFX: return AudioEnums.SoundType.GAMEPLAY
		AudioEnums.BusName.VOICE: return AudioEnums.SoundType.VOICE
		AudioEnums.BusName.MUSIC: return AudioEnums.SoundType.MUSIC
		_: return AudioEnums.SoundType.UI
