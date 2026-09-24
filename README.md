# Puppy Core

Puppy Core is a small collection of reusable Godot 4+ services and gameplay
components. Every autoload is optional. Projects choose the services they need and
keep game-specific rules in their own source tree.

The project is currently pre-1.0. Public APIs may change between minor releases
while the module boundaries settle.

## Features

- Independent audio, input, save, video, pause, and scene autoloads.
- Optional automatic audio feedback for UI buttons.
- Non-spatial, positional 2D, and positional 3D audio playback.
- Scene transitions and pause control without game-specific state assumptions.
- Reusable health, hitbox, hurtbox, movement, camera, and animation components.
- A `HitData` payload that keeps damage, knockback, source, and hit position
  together.
- Modular save data through the `SaveModule` base class.

## Structure

```text
puppy_core/
  audio/
    default_bus_layout.tres
  autoloads/
    audio_manager.gd
    debug_overlay.gd
    input_manager.gd
    pause_manager.gd
    save_manager.gd
    scene_manager.gd
    ui_sound_manager.gd
    video_manager.gd
  components/
    animation/
    camera/
    combat/
    movement/
  config/
    audio_config.gd
    input_config.gd
    save_config.gd
    ui_sound_profile.gd
    video_config.gd
  data/
  modules/
  docs/
  puppy_core_info.gd
```

`autoloads/` is flat because there is no second framework layer inside Puppy Core.
Components and data types can be used without enabling any singleton.

Each configurable service has an optional typed Resource. A script autoload uses
the built-in defaults; a project can register a small wrapper scene that assigns
its own `.tres` resource before the service enters `_ready()`.

The standard audio layout provides `Master`, `SFX`, `UI`, `Music`, and `Voice`.
Projects may reference it directly or select their own `AudioBusLayout`.

## Installation

Add the repository to a Godot project, preferably as a submodule:

```bash
git submodule add https://github.com/wdbals/puppy_core.git puppy_core
git submodule update --init
```

Register only the services needed by the project:

| Autoload name | Path |
| --- | --- |
| `AudioManager` | `res://puppy_core/autoloads/audio_manager.gd` |
| `PauseManager` | `res://puppy_core/autoloads/pause_manager.gd` |
| `SceneManager` | `res://puppy_core/autoloads/scene_manager.gd` |
| `UISoundManager` | `res://puppy_core/autoloads/ui_sound_manager.gd` |
| `InputManager` | `res://puppy_core/autoloads/input_manager.gd` |
| `SaveManager` | `res://puppy_core/autoloads/save_manager.gd` |
| `VideoManager` | `res://puppy_core/autoloads/video_manager.gd` |

Most services do not require each other. `UISoundManager` is the deliberate
exception: it requires `AudioManager` to be registered before it. A game can
connect otherwise independent services from its own coordinator:

```gdscript
# game_content/autoloads/game_session.gd
extends Node

func _ready() -> void:
	PauseManager.game_paused.connect(AudioManager.set_game_paused.bind(true))
	PauseManager.game_resumed.connect(AudioManager.set_game_paused.bind(false))
```

See [Installation](docs/INSTALLATION.md) for the full setup.

## Quick examples

```gdscript
SceneManager.change_scene_with_transition("res://scenes/level_01.tscn")

AudioManager.play_music(preload("res://audio/theme.ogg"), "theme")
AudioManager.play_sound(preload("res://audio/click.wav"))
AudioManager.play_sound_2d(hit_sound, global_position)
AudioManager.play_sound_3d(explosion_sound, global_position)
```

Combat events carry one object instead of parallel arguments:

```gdscript
func _on_damaged(hit: HitData) -> void:
	velocity += hit.knockback
	print("Damage: ", hit.damage)
```

## Design boundary

Puppy Core owns reusable mechanisms. The consuming project owns rules such as
difficulty modes, story states, wave progression, scene-name conventions, and the
meaning of pause or victory. See the [Reuse Guide](docs/REUSE_GUIDE.md) for examples.

## Documentation

- [Installation](docs/INSTALLATION.md)
- [API Reference](docs/API_REFERENCE.md)
- [Reuse Guide](docs/REUSE_GUIDE.md)
- [Save Modules](docs/SAVE_MODULES.md)
