class_name PuppyAudioConfig
extends Resource
## Runtime defaults used by AudioManager.
##
## Authored bus topology, routing, effects, and initial mix belong to the project's
## AudioBusLayout. Fallback volumes are used only when a required bus is missing.

@export_group("Playback")
@export_range(1, 64, 1) var sound_pool_size := 10
@export_range(0.0, 10.0, 0.05) var music_fade_duration := 1.0
@export_range(0.0, 1.0, 0.01) var paused_master_volume := 0.45

@export_group("Spatial 2D")
@export_range(0.0, 100000.0, 1.0) var default_2d_max_distance := 2000.0
@export_range(0.0, 10.0, 0.05) var default_2d_attenuation := 1.0

@export_group("Spatial 3D")
@export_range(0.0, 100000.0, 1.0) var default_3d_max_distance := 0.0
@export_range(0.01, 1000.0, 0.01) var default_3d_unit_size := 10.0

@export_group("Missing bus fallback")
@export var fallback_bus_volumes: Dictionary = {
	&"Master": 1.0,
	&"SFX": 0.8,
	&"UI": 0.8,
	&"Music": 0.6,
	&"Voice": 0.9,
}
@export var fallback_muted_buses: Array[StringName] = []
