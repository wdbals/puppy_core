# API Reference

## GameManager

`GameManager` handles application shutdown, SceneTree pause, scene changes, and a
simple color transition. It does not track game states, difficulty, language, or
playtime.

### Signals

| Signal | Meaning |
| --- | --- |
| `game_paused` | The SceneTree was paused through the manager. |
| `game_resumed` | The SceneTree was resumed through the manager. |
| `game_ready` | The autoload completed `_ready()`. |
| `quit_requested` | The application is about to quit. |
| `scene_loaded(scene_path)` | A requested scene change succeeded. |
| `transition_started(scene_path, duration)` | A scene or action transition started. |
| `screen_covered` | The viewport is fully covered. |
| `transition_finished` | The transition completed. |

### Scene and lifecycle methods

```gdscript
GameManager.change_scene("res://scenes/menu.tscn")
GameManager.change_scene_styled(
	"res://scenes/level_01.tscn",
	Color("080d1c"),
	0.6
)
GameManager.execute_with_transition(setup_level)
GameManager.request_quit()
```

`execute_with_transition()` invokes its callable while the viewport is covered. It
can temporarily pause the SceneTree during the operation.

### Pause methods

```gdscript
GameManager.pause_game([pause_menu])
GameManager.resume_game()
GameManager.toggle_pause([pause_menu])
var paused := GameManager.is_game_paused()
```

Nodes passed in `excluded_nodes` temporarily use `PROCESS_MODE_ALWAYS` and return
to their previous processing mode on resume.

## AudioManager

`AudioManager` handles music, pooled non-spatial effects, one-shot positional audio,
and bus volume. It does not depend on any other autoload.

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
AudioManager.play_sound(click_sound, AudioEnums.BusName.SFX)
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
it to `GameManager`, but AudioManager never assumes that GameManager exists.

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
SaveManager.write_module("slot_1", player_save)
SaveManager.write_modules_batch("slot_1", [player_save, world_save])
SaveManager.read_module("slot_1", player_save)
SaveManager.read_modules_batch("slot_1", [player_save, world_save])
```

See [Save Modules](SAVE_MODULES.md) for the `SaveModule` contract.
