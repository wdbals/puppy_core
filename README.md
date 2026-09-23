# Puppy Core

Puppy Core is a small collection of reusable Godot 4+ services and gameplay
components. Every autoload is optional. Projects choose the services they need and
keep game-specific rules in their own source tree.

The project is currently pre-1.0. Public APIs may change between minor releases
while the module boundaries settle.

## Features

- Independent audio, input, save, video, and lifecycle autoloads.
- Non-spatial, positional 2D, and positional 3D audio playback.
- Scene transitions and pause control without game-specific state assumptions.
- Reusable health, hitbox, hurtbox, movement, camera, and animation components.
- A `HitData` payload that keeps damage, knockback, source, and hit position
  together.
- Modular save data through the `SaveModule` base class.

## Structure

```text
puppy_core/
  autoloads/
    audio_manager.gd
    debug_overlay.gd
    game_manager.gd
    input_manager.gd
    save_manager.gd
    video_manager.gd
  components/
    animation/
    camera/
    combat/
    movement/
  data/
  modules/
  docs/
```

`autoloads/` is flat because there is no second framework layer inside Puppy Core.
Components and data types can be used without enabling any singleton.

## Installation

Add the repository to a Godot project, preferably as a submodule:

```bash
git submodule add https://github.com/wdbals/puppy_core.git puppy_core
git submodule update --init
```

Register only the services needed by the project:

| Autoload name | Path |
| --- | --- |
| `GameManager` | `res://puppy_core/autoloads/game_manager.gd` |
| `AudioManager` | `res://puppy_core/autoloads/audio_manager.gd` |
| `InputManager` | `res://puppy_core/autoloads/input_manager.gd` |
| `SaveManager` | `res://puppy_core/autoloads/save_manager.gd` |
| `VideoManager` | `res://puppy_core/autoloads/video_manager.gd` |

The services do not require each other. A game can connect them from its own
coordinator when it wants integrated behavior:

```gdscript
# game_content/autoloads/game_session.gd
extends Node

func _ready() -> void:
	GameManager.game_paused.connect(AudioManager.set_game_paused.bind(true))
	GameManager.game_resumed.connect(AudioManager.set_game_paused.bind(false))
```

See [Installation](docs/INSTALLATION.md) for the full setup.

## Quick examples

```gdscript
GameManager.change_scene_styled("res://scenes/level_01.tscn")

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
