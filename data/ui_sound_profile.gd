class_name UISoundProfile
extends Resource
## Sounds used by UISoundManager for automatic BaseButton feedback.

@export_group("Button feedback")
@export var pressed: AudioStream
@export var hovered: AudioStream
@export var focused: AudioStream

@export_group("Button roles")
@export var confirm: AudioStream
@export var cancel: AudioStream
