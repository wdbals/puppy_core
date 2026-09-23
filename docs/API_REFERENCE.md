# API Reference

## SceneManager

`SceneManager` handles scene navigation and optional full-screen color transitions.
The transition rendering is implemented by the reusable `ScreenTransition`
component.

### Signals

| Signal | Meaning |
| --- | --- |
| `scene_loaded(scene_path)` | A requested scene change succeeded. |
| `transition_started(scene_path, duration)` | A scene transition started. |
| `screen_covered` | The viewport is fully covered. |
| `transition_finished` | The transition completed. |

### Scene methods

```gdscript
var result := SceneManager.change_scene("res://scenes/menu.tscn")
var styled_result := await SceneManager.change_scene_with_transition(
	"res://scenes/level_01.tscn",
	Color("080d1c"),
	0.6
)
```

Both methods return Godot's built-in `Error` enum. Overlapping changes return
`ERR_BUSY`.

## PauseManager

`PauseManager` owns only SceneTree pause coordination. It emits `game_paused` and
`game_resumed` after changing the tree state.

### Pause methods

```gdscript
PauseManager.pause([pause_menu])
PauseManager.resume()
PauseManager.toggle([pause_menu])
var paused := PauseManager.is_paused()
```

Nodes passed in `excluded_nodes` temporarily use `PROCESS_MODE_ALWAYS` and return
to their previous processing mode on resume.

## UISoundManager

`UISoundManager` automatically connects every `BaseButton` added to the SceneTree.
It requires an `AudioManager` autoload registered before it. The dependency is
checked at runtime; without it, the service reports an error and remains inactive.

Supply project-owned audio through a `UISoundProfile`:

```gdscript
const UI_SOUNDS := preload("res://game_content/config/ui_sounds.tres")

func _ready() -> void:
	UISoundManager.set_profile(UI_SOUNDS)
```

The optional groups `ui_sound_silent`, `ui_sound_confirm`, and `ui_sound_cancel`
disable feedback or select role-specific sounds. `pressed` handles mouse, keyboard,
and controller activation; optional hover and focus streams are supported as well.

## AudioManager

`AudioManager` handles music, pooled non-spatial effects, one-shot positional audio,
and bus volume. It does not depend on any other autoload.

The supplied `res://puppy_core/audio/default_bus_layout.tres` defines the standard
bus topology for editor authoring. `setup_audio_buses()` is a runtime fallback: it
creates missing buses without changing existing volumes or mute states.

### Music

```gdscript
AudioManager.play_music(theme, "main_theme", 0.5)
AudioManager.stop_music(0.5)
AudioManager.fade_in_music(0.5)
AudioManager.fade_out_music(0.5)
```

### Non-spatial effects

Use non-spatial playback for UI and sounds that should not be positioned in the
world:

```gdscript
AudioManager.play_sound(click_sound, AudioEnums.BusName.UI)
```

### Positional effects

Use positional playback for one-shot world sounds:

```gdscript
AudioManager.play_sound_2d(
	hit_sound,
	global_position,
	AudioEnums.BusName.SFX,
	1200.0,
	1.0
)

AudioManager.play_sound_3d(
	explosion_sound,
	global_position,
	AudioEnums.BusName.SFX,
	50.0,
	5.0
)
```

The returned `AudioStreamPlayer2D` or `AudioStreamPlayer3D` is automatically freed
when playback finishes. For looping sounds or audio that must follow a moving
object, add a positional player directly below that object instead.

The active viewport needs an `AudioListener2D` or `AudioListener3D` when the default
listener behavior is not sufficient.

### Bus and pause control

```gdscript
AudioManager.set_bus_volume(AudioEnums.BusName.MUSIC, 0.5)
AudioManager.mute_bus(AudioEnums.BusName.SFX)
AudioManager.unmute_bus(AudioEnums.BusName.SFX)
AudioManager.toggle_bus_mute(AudioEnums.BusName.SFX)
AudioManager.set_game_paused(true)
```

`set_game_paused()` is an explicit integration point. A game coordinator may connect
it to `PauseManager`, but AudioManager never assumes that PauseManager exists.

## Combat

### HitData

`HitData` is a runtime payload with these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `damage` | `float` | Health reduction requested by the hit. |
| `knockback` | `Vector2` | World-space impulse or velocity contribution. |
| `source` | `Node2D` | Node that produced the hit. |
| `hit_position` | `Vector2` | World-space position of the target when hit. |

### Hitbox and HurtBox

`Hitbox` builds a `HitData` object and calls `HurtBox.receive_hit()`. A hitbox can
calculate knockback from its facing direction or radially away from itself:

```gdscript
hitbox.knockback_direction = Hitbox.KnockbackDirection.AWAY_FROM_HITBOX
hitbox.knockback_force = 150.0
```

Signals carry the same payload:

```gdscript
func _on_damaged(hit: HitData) -> void:
	velocity += hit.knockback

func _on_hit_delivered(target: HurtBox, hit: HitData) -> void:
	print(target, " received ", hit.damage)
```

## InputManager

The input manager provides device detection, per-action deadzones, buffered input,
and rebinding:

```gdscript
InputManager.is_action_pressed("jump")
InputManager.is_action_just_pressed("attack")
InputManager.get_action_strength("move_right")
InputManager.set_action_deadzone("aim_x", 0.25)
InputManager.rebind_action("jump", new_event)
```

## VideoManager

```gdscript
VideoManager.set_resolution(Vector2i(1280, 720))
VideoManager.set_resolution_by_index(0)
VideoManager.toggle_fullscreen()
VideoManager.set_vsync_mode(DisplayServer.VSYNC_ENABLED)
```

Available resolutions come from `EngineConfig` and are filtered against the current
screen size.

## SaveManager

```gdscript
var save_result: Error = SaveManager.write_module("slot_1", player_save)
if save_result != OK:
	push_error("Save failed: %s" % error_string(save_result))

var load_result: Error = SaveManager.read_modules_batch(
	"slot_1",
	[player_save, world_save]
)
if load_result != OK:
	push_error("Load failed: %s" % error_string(load_result))
```

All write and read methods return Godot's built-in `Error` enum. Batch methods stop
at the first failed module and return its error. Completion signals carry the same
result:

```gdscript
signal save_completed(slot: String, result: Error)
signal load_completed(slot: String, result: Error)
```

See [Save Modules](SAVE_MODULES.md) for the `SaveModule` contract.
