class_name PuppyCoreInfo
extends RefCounted
## Immutable Puppy Core package metadata.

const NAME := "Puppy Core"
const VERSION := "0.1.0"
const MINIMUM_GODOT_MAJOR := 4


static func is_debug_build() -> bool:
	return OS.is_debug_build()


static func is_release_build() -> bool:
	return not OS.is_debug_build()


static func is_godot_version_supported() -> bool:
	return int(Engine.get_version_info().major) >= MINIMUM_GODOT_MAJOR
